module zen_binary_fast_inv_row_core #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic                             clk,
  input  logic                             rst_n,
  input  logic                             start_i,
  input  logic [31:0]                      init_f_chunk_i,
  output logic                             done_o,
  output logic [zen_accel_pkg::ADDR_W:0]  init_f_work_idx_o,
  output logic                             row_out_valid_o,
  output logic [zen_accel_pkg::ADDR_W-1:0] row_out_idx_o,
  output logic signed [(16*COEFF_W)-1:0]  row_out_data_o
);

  import zen_accel_pkg::*;

  localparam int FAST_INV_N4 = NTT_N / 4;
  localparam int FAST_INV_LOG2 = $clog2(FAST_INV_N4);
  localparam int FAST_INV_STAGE_W = (FAST_INV_LOG2 <= 1) ? 1 : $clog2(FAST_INV_LOG2);
  localparam int FAST_INV_LOG2_W = (FAST_INV_LOG2 <= 1) ? 1 : $clog2(FAST_INV_LOG2 + 1);
  localparam int FAST_INV_CHUNK_LANES = (FAST_INV_N4 >= 32) ? 32 : FAST_INV_N4;
  localparam int FAST_INV_WORK_W = (FAST_INV_N4 <= 1) ? 1 : $clog2(FAST_INV_N4 + 1);
  localparam int FAST_INV_PACK_ROW_COEFFS = 16;
  localparam int FAST_INV_PACK_ROW_COUNT =
      (FAST_INV_N4 + FAST_INV_PACK_ROW_COEFFS - 1) / FAST_INV_PACK_ROW_COEFFS;
  localparam int FAST_INV_PACK_ROW_W =
      (FAST_INV_PACK_ROW_COUNT > 1) ? $clog2(FAST_INV_PACK_ROW_COUNT) : 1;
  localparam logic [FAST_INV_WORK_W-1:0] FAST_INV_ONE = {{(FAST_INV_WORK_W - 1){1'b0}}, 1'b1};
  localparam logic [FAST_INV_WORK_W-1:0] FAST_INV_N4_VAL = FAST_INV_N4;
  localparam logic [FAST_INV_WORK_W-1:0] FAST_INV_CHUNK_STEP = FAST_INV_CHUNK_LANES;

  typedef enum logic [4:0] {
    PH_IDLE,
    PH_INIT_LATCH,
    PH_INIT_F_LOAD,
    PH_INIT_F_LOAD_WRITE,
    PH_INIT_PFX1,
    PH_INIT_PFX1_WRITE,
    PH_INIT_B0,
    PH_INIT_ADJUST,
    PH_INIT_ADJUST_WRITE,
    PH_INIT_PFX2,
    PH_INIT_PFX2_WRITE,
    PH_INIT_FINV,
    PH_STAGE_TMP_LO,
    PH_STAGE_TMP_HI,
    PH_STAGE_TMP_WRITE,
    PH_STAGE_B_LO,
    PH_STAGE_B_HI,
    PH_STAGE_B_WRITE,
    PH_STAGE_PROD_LO,
    PH_STAGE_PROD_HI,
    PH_STAGE_PROD_WRITE,
    PH_STAGE_PREFIX,
    PH_STAGE_PREFIX_WRITE,
    PH_STAGE_FINV,
    PH_STAGE_FINV_WRITE,
    PH_PACK
  } fast_inv_phase_t;

  logic [FAST_INV_WORK_W-1:0] active_n4_calc;
  logic [FAST_INV_LOG2_W-1:0] active_n4_log2_calc;
  logic [FAST_INV_WORK_W-1:0] active_n4_reg;
  logic [FAST_INV_LOG2_W-1:0] active_n4_log2_reg;
  logic [FAST_INV_WORK_W-1:0] stage_n_cur;
  logic [FAST_INV_WORK_W-1:0] stage_finv_limit_cur;
  logic fast_inv_running;
  fast_inv_phase_t phase_reg;
  logic [FAST_INV_STAGE_W-1:0] stage_idx_reg;
  logic [FAST_INV_WORK_W-1:0] work_idx_reg;
  logic [FAST_INV_N4-1:0] f_reg;
  logic [FAST_INV_N4-1:0] k_reg;
  logic [FAST_INV_N4-1:0] f_inv_reg;
  logic [FAST_INV_N4-1:0] tmp_reg;
  logic [FAST_INV_N4-1:0] b_reg;
  logic init_prefix_tail_reg;
  logic init_b0_reg;
  logic [FAST_INV_CHUNK_LANES-1:0] tmp_partial_reg;
  logic [FAST_INV_CHUNK_LANES-1:0] b_partial_reg;
  logic [FAST_INV_CHUNK_LANES-1:0] prod_partial_reg;
  logic [FAST_INV_PACK_ROW_W-1:0] pack_row_idx;
  logic [FAST_INV_CHUNK_LANES-1:0] chunk_pipe_reg;
  logic chunk_tail_pipe_reg;
  logic [FAST_INV_CHUNK_LANES-1:0] init_f_chunk;
  logic [FAST_INV_CHUNK_LANES-1:0] init_prefix_chunk;
  logic [FAST_INV_CHUNK_LANES-1:0] init_adjust_chunk;
  logic [FAST_INV_CHUNK_LANES-1:0] tmp_chunk;
  logic [FAST_INV_CHUNK_LANES-1:0] b_chunk;
  logic [FAST_INV_CHUNK_LANES-1:0] prod_chunk;
  logic [FAST_INV_CHUNK_LANES-1:0] prefix_chunk;
  logic [FAST_INV_CHUNK_LANES-1:0] finv_chunk;
  logic init_reduce_chunk;
  logic init_chunk_tail_bit;
  logic [FAST_INV_WORK_W-1:0] stage_step_limit_cur;
  logic [FAST_INV_WORK_W-1:0] stage_step_half_cur;

  assign init_f_work_idx_o = $unsigned(work_idx_reg);

  always_comb begin
    integer log2_i;

    active_n4_calc = FAST_INV_N4_VAL;
    active_n4_log2_calc = '0;
    for (log2_i = 0; log2_i < FAST_INV_LOG2; log2_i++) begin
      if ((active_n4_calc > (FAST_INV_ONE << log2_i)) &&
          (active_n4_log2_calc == log2_i[FAST_INV_LOG2_W-1:0])) begin
        active_n4_log2_calc = active_n4_log2_calc + 1'b1;
      end
    end
  end

  always_comb begin
    integer lane_idx;
    integer idx_local;
    integer i_local;
    integer j_local;
    integer step_local;
    integer src_idx;
    logic accum_bit;
    logic prefix_src_bit;
    logic [FAST_INV_WORK_W-1:0] stage_n_twice;
    logic [FAST_INV_WORK_W-1:0] stage_half_n_cur;
    logic [FAST_INV_WORK_W-1:0] step_local_w;

    stage_n_cur = FAST_INV_ONE << stage_idx_reg;
    if (stage_n_cur > FAST_INV_N4_VAL) begin
      stage_n_cur = FAST_INV_N4_VAL;
    end

    if (FAST_INV_WORK_W == 1) begin
      stage_n_twice = stage_n_cur;
    end else begin
      stage_n_twice = {stage_n_cur[FAST_INV_WORK_W-2:0], 1'b0};
    end

    if (stage_n_cur > FAST_INV_ONE) begin
      stage_half_n_cur = stage_n_cur >> 1;
    end else begin
      stage_half_n_cur = stage_n_cur;
    end

    if (active_n4_reg < stage_n_twice) begin
      stage_finv_limit_cur = active_n4_reg;
    end else begin
      stage_finv_limit_cur = stage_n_twice;
    end

    stage_step_limit_cur = active_n4_reg >> stage_idx_reg;
    if (stage_step_limit_cur > FAST_INV_ONE) begin
      stage_step_half_cur = stage_step_limit_cur >> 1;
    end else begin
      stage_step_half_cur = stage_step_limit_cur;
    end

    init_f_chunk = '0;
    init_prefix_chunk = '0;
    init_adjust_chunk = '0;
    tmp_chunk = '0;
    b_chunk = '0;
    prod_chunk = '0;
    prefix_chunk = '0;
    finv_chunk = '0;
    init_reduce_chunk = 1'b0;
    init_chunk_tail_bit = init_prefix_tail_reg;
    i_local = 0;
    j_local = 0;
    step_local = 0;
    step_local_w = '0;

    for (lane_idx = 0; lane_idx < FAST_INV_CHUNK_LANES; lane_idx++) begin
      idx_local = $unsigned(work_idx_reg) + lane_idx;
      src_idx = 0;
      accum_bit = 1'b0;
      prefix_src_bit = 1'b0;

      unique case (phase_reg)
        PH_INIT_F_LOAD: begin
          if (idx_local < active_n4_reg) begin
            init_f_chunk[lane_idx] = init_f_chunk_i[lane_idx];
          end
        end
        PH_INIT_PFX1: begin
          if (idx_local < active_n4_reg) begin
            if (lane_idx == 0) begin
              prefix_src_bit = init_prefix_tail_reg;
            end else begin
              prefix_src_bit = init_prefix_chunk[lane_idx - 1];
            end
            init_prefix_chunk[lane_idx] = f_reg[idx_local] ^ prefix_src_bit;
            init_chunk_tail_bit = init_prefix_chunk[lane_idx];
          end
        end
        PH_INIT_B0: begin
          if (idx_local < active_n4_reg) begin
            init_reduce_chunk = init_reduce_chunk ^ k_reg[idx_local];
          end
        end
        PH_INIT_ADJUST: begin
          if (idx_local < active_n4_reg) begin
            init_adjust_chunk[lane_idx] = k_reg[idx_local] ^ (init_b0_reg & f_reg[idx_local]);
          end
        end
        PH_INIT_PFX2: begin
          if (idx_local < active_n4_reg) begin
            if (lane_idx == 0) begin
              prefix_src_bit = init_prefix_tail_reg;
            end else begin
              prefix_src_bit = init_prefix_chunk[lane_idx - 1];
            end
            init_prefix_chunk[lane_idx] = k_reg[idx_local] ^ prefix_src_bit;
            init_chunk_tail_bit = init_prefix_chunk[lane_idx];
          end
        end
        PH_STAGE_TMP_LO: begin
          if ((idx_local < stage_n_cur) && (idx_local < active_n4_reg)) begin
            for (step_local = 0; step_local < FAST_INV_N4; step_local++) begin
              step_local_w = step_local[FAST_INV_WORK_W-1:0];
              if (step_local_w >= stage_step_half_cur) begin
                break;
              end
              j_local = idx_local + (step_local * stage_n_cur);
              if (j_local < active_n4_reg) begin
                accum_bit = accum_bit ^ k_reg[j_local];
              end
            end
            tmp_chunk[lane_idx] = accum_bit;
          end
        end
        PH_STAGE_TMP_HI: begin
          if ((idx_local < stage_n_cur) && (idx_local < active_n4_reg)) begin
            accum_bit = tmp_partial_reg[lane_idx];
            for (step_local = 0; step_local < FAST_INV_N4; step_local++) begin
              step_local_w = step_local[FAST_INV_WORK_W-1:0];
              if (step_local_w >= stage_step_half_cur) begin
                j_local = idx_local + (step_local * stage_n_cur);
                if ((step_local_w < stage_step_limit_cur) && (j_local < active_n4_reg)) begin
                  accum_bit = accum_bit ^ k_reg[j_local];
                end
              end
            end
            tmp_chunk[lane_idx] = accum_bit;
          end
        end
        PH_STAGE_B_LO: begin
          if (idx_local < stage_n_cur) begin
            for (i_local = 0; i_local < FAST_INV_N4; i_local++) begin
              if ((i_local < stage_half_n_cur) && f_inv_reg[i_local]) begin
                src_idx = idx_local + stage_n_cur - i_local;
                if (src_idx >= stage_n_cur) begin
                  src_idx = src_idx - stage_n_cur;
                end
                accum_bit = accum_bit ^ tmp_reg[src_idx];
              end
            end
            b_chunk[lane_idx] = accum_bit;
          end
        end
        PH_STAGE_B_HI: begin
          if (idx_local < stage_n_cur) begin
            accum_bit = b_partial_reg[lane_idx];
            for (i_local = 0; i_local < FAST_INV_N4; i_local++) begin
              if ((i_local >= stage_half_n_cur) && (i_local < stage_n_cur) && f_inv_reg[i_local]) begin
                src_idx = idx_local + stage_n_cur - i_local;
                if (src_idx >= stage_n_cur) begin
                  src_idx = src_idx - stage_n_cur;
                end
                accum_bit = accum_bit ^ tmp_reg[src_idx];
              end
            end
            b_chunk[lane_idx] = accum_bit;
          end
        end
        PH_STAGE_PROD_LO: begin
          if (idx_local < active_n4_reg) begin
            accum_bit = k_reg[idx_local];
            for (i_local = 0; i_local < FAST_INV_N4; i_local++) begin
              if ((i_local < stage_half_n_cur) && b_reg[i_local]) begin
                if (idx_local >= i_local) begin
                  src_idx = idx_local - i_local;
                end else begin
                  src_idx = idx_local + active_n4_reg - i_local;
                end
                accum_bit = accum_bit ^ f_reg[src_idx];
              end
            end
            prod_chunk[lane_idx] = accum_bit;
          end
        end
        PH_STAGE_PROD_HI: begin
          if (idx_local < active_n4_reg) begin
            accum_bit = prod_partial_reg[lane_idx];
            for (i_local = 0; i_local < FAST_INV_N4; i_local++) begin
              if ((i_local >= stage_half_n_cur) && (i_local < stage_n_cur) && b_reg[i_local]) begin
                if (idx_local >= i_local) begin
                  src_idx = idx_local - i_local;
                end else begin
                  src_idx = idx_local + active_n4_reg - i_local;
                end
                accum_bit = accum_bit ^ f_reg[src_idx];
              end
            end
            prod_chunk[lane_idx] = accum_bit;
          end
        end
        PH_STAGE_PREFIX: begin
          if ((idx_local >= stage_n_cur) && (idx_local < active_n4_reg)) begin
            src_idx = idx_local - stage_n_cur;
            if ((src_idx >= $unsigned(work_idx_reg)) &&
                (src_idx < ($unsigned(work_idx_reg) + FAST_INV_CHUNK_STEP))) begin
              prefix_src_bit = prefix_chunk[src_idx - $unsigned(work_idx_reg)];
            end else begin
              prefix_src_bit = k_reg[src_idx];
            end
            prefix_chunk[lane_idx] = k_reg[idx_local] ^ prefix_src_bit;
          end
        end
        PH_STAGE_FINV: begin
          if (idx_local < stage_finv_limit_cur) begin
            if (idx_local < stage_n_cur) begin
              finv_chunk[lane_idx] = f_inv_reg[idx_local] ^ b_reg[idx_local];
            end else begin
              finv_chunk[lane_idx] = f_inv_reg[idx_local] ^ b_reg[idx_local - stage_n_cur];
            end
          end
        end
        default: begin
        end
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      active_n4_reg <= '0;
      active_n4_log2_reg <= '0;
      fast_inv_running <= 1'b0;
      phase_reg <= PH_IDLE;
      stage_idx_reg <= '0;
      work_idx_reg <= '0;
      f_reg <= '0;
      k_reg <= '0;
      f_inv_reg <= '0;
      tmp_reg <= '0;
      b_reg <= '0;
      init_prefix_tail_reg <= 1'b0;
      init_b0_reg <= 1'b0;
      tmp_partial_reg <= '0;
      b_partial_reg <= '0;
      prod_partial_reg <= '0;
      chunk_pipe_reg <= '0;
      chunk_tail_pipe_reg <= 1'b0;
      done_o <= 1'b0;
      row_out_valid_o <= 1'b0;
      row_out_idx_o <= '0;
      row_out_data_o <= '0;
      pack_row_idx <= '0;
    end else begin
      done_o <= 1'b0;
      row_out_valid_o <= 1'b0;

      if (start_i) begin
        active_n4_reg <= active_n4_calc;
        active_n4_log2_reg <= active_n4_log2_calc;
        fast_inv_running <= 1'b1;
        phase_reg <= PH_INIT_LATCH;
        stage_idx_reg <= 1;
        work_idx_reg <= '0;
        f_reg <= '0;
        k_reg <= '0;
        f_inv_reg <= '0;
        tmp_reg <= '0;
        b_reg <= '0;
        init_prefix_tail_reg <= 1'b0;
        init_b0_reg <= 1'b0;
        tmp_partial_reg <= '0;
        b_partial_reg <= '0;
        prod_partial_reg <= '0;
        chunk_pipe_reg <= '0;
        chunk_tail_pipe_reg <= 1'b0;
        row_out_idx_o <= '0;
        row_out_data_o <= '0;
        pack_row_idx <= '0;
      end else if (fast_inv_running) begin
        unique case (phase_reg)
          PH_INIT_LATCH: begin
            f_reg <= '0;
            k_reg <= '0;
            f_inv_reg <= '0;
            tmp_reg <= '0;
            b_reg <= '0;
            init_prefix_tail_reg <= 1'b0;
            init_b0_reg <= 1'b0;
            tmp_partial_reg <= '0;
            b_partial_reg <= '0;
            prod_partial_reg <= '0;
            chunk_pipe_reg <= '0;
            chunk_tail_pipe_reg <= 1'b0;
            work_idx_reg <= '0;
            phase_reg <= PH_INIT_F_LOAD;
          end
          PH_INIT_F_LOAD: begin
            chunk_pipe_reg <= init_f_chunk;
            phase_reg <= PH_INIT_F_LOAD_WRITE;
          end
          PH_INIT_F_LOAD_WRITE: begin
            for (int lane_idx = 0; lane_idx < FAST_INV_CHUNK_LANES; lane_idx++) begin
              int idx_local;
              idx_local = $unsigned(work_idx_reg) + lane_idx;
              if (idx_local < active_n4_reg) begin
                f_reg[idx_local] <= chunk_pipe_reg[lane_idx];
              end
            end
            if (($unsigned(work_idx_reg) + FAST_INV_CHUNK_STEP) >= active_n4_reg) begin
              phase_reg <= PH_INIT_PFX1;
              work_idx_reg <= '0;
              init_prefix_tail_reg <= 1'b0;
            end else begin
              work_idx_reg <= work_idx_reg + FAST_INV_CHUNK_STEP;
              phase_reg <= PH_INIT_F_LOAD;
            end
          end
          PH_INIT_PFX1: begin
            chunk_pipe_reg <= init_prefix_chunk;
            chunk_tail_pipe_reg <= init_chunk_tail_bit;
            phase_reg <= PH_INIT_PFX1_WRITE;
          end
          PH_INIT_PFX1_WRITE: begin
            for (int lane_idx = 0; lane_idx < FAST_INV_CHUNK_LANES; lane_idx++) begin
              int idx_local;
              idx_local = $unsigned(work_idx_reg) + lane_idx;
              if (idx_local < active_n4_reg) begin
                k_reg[idx_local] <= chunk_pipe_reg[lane_idx];
              end
            end
            init_prefix_tail_reg <= chunk_tail_pipe_reg;
            if (($unsigned(work_idx_reg) + FAST_INV_CHUNK_STEP) >= active_n4_reg) begin
              phase_reg <= PH_INIT_B0;
              work_idx_reg <= '0;
              init_b0_reg <= 1'b0;
            end else begin
              work_idx_reg <= work_idx_reg + FAST_INV_CHUNK_STEP;
              phase_reg <= PH_INIT_PFX1;
            end
          end
          PH_INIT_B0: begin
            init_b0_reg <= init_b0_reg ^ init_reduce_chunk;
            if (($unsigned(work_idx_reg) + FAST_INV_CHUNK_STEP) >= active_n4_reg) begin
              phase_reg <= PH_INIT_ADJUST;
              work_idx_reg <= '0;
            end else begin
              work_idx_reg <= work_idx_reg + FAST_INV_CHUNK_STEP;
            end
          end
          PH_INIT_ADJUST: begin
            chunk_pipe_reg <= init_adjust_chunk;
            phase_reg <= PH_INIT_ADJUST_WRITE;
          end
          PH_INIT_ADJUST_WRITE: begin
            for (int lane_idx = 0; lane_idx < FAST_INV_CHUNK_LANES; lane_idx++) begin
              int idx_local;
              idx_local = $unsigned(work_idx_reg) + lane_idx;
              if (idx_local < active_n4_reg) begin
                k_reg[idx_local] <= chunk_pipe_reg[lane_idx];
              end
            end
            if (($unsigned(work_idx_reg) + FAST_INV_CHUNK_STEP) >= active_n4_reg) begin
              phase_reg <= PH_INIT_PFX2;
              work_idx_reg <= '0;
              init_prefix_tail_reg <= 1'b0;
            end else begin
              work_idx_reg <= work_idx_reg + FAST_INV_CHUNK_STEP;
              phase_reg <= PH_INIT_ADJUST;
            end
          end
          PH_INIT_PFX2: begin
            chunk_pipe_reg <= init_prefix_chunk;
            chunk_tail_pipe_reg <= init_chunk_tail_bit;
            phase_reg <= PH_INIT_PFX2_WRITE;
          end
          PH_INIT_PFX2_WRITE: begin
            for (int lane_idx = 0; lane_idx < FAST_INV_CHUNK_LANES; lane_idx++) begin
              int idx_local;
              idx_local = $unsigned(work_idx_reg) + lane_idx;
              if (idx_local < active_n4_reg) begin
                k_reg[idx_local] <= chunk_pipe_reg[lane_idx];
              end
            end
            init_prefix_tail_reg <= chunk_tail_pipe_reg;
            if (($unsigned(work_idx_reg) + FAST_INV_CHUNK_STEP) >= active_n4_reg) begin
              phase_reg <= PH_INIT_FINV;
              work_idx_reg <= '0;
            end else begin
              work_idx_reg <= work_idx_reg + FAST_INV_CHUNK_STEP;
              phase_reg <= PH_INIT_PFX2;
            end
          end
          PH_INIT_FINV: begin
            f_inv_reg <= '0;
            f_inv_reg[0] <= !init_b0_reg;
            if (FAST_INV_N4 > 1) begin
              f_inv_reg[1] <= init_b0_reg;
            end
            tmp_reg <= '0;
            b_reg <= '0;
            tmp_partial_reg <= '0;
            b_partial_reg <= '0;
            prod_partial_reg <= '0;
            if (active_n4_log2_reg > 1) begin
              phase_reg <= PH_STAGE_TMP_LO;
            end else begin
              phase_reg <= PH_PACK;
              pack_row_idx <= '0;
            end
          end
          PH_STAGE_TMP_LO: begin
            tmp_partial_reg <= tmp_chunk;
            phase_reg <= PH_STAGE_TMP_HI;
          end
          PH_STAGE_TMP_HI: begin
            chunk_pipe_reg <= tmp_chunk;
            phase_reg <= PH_STAGE_TMP_WRITE;
          end
          PH_STAGE_TMP_WRITE: begin
            for (int lane_idx = 0; lane_idx < FAST_INV_CHUNK_LANES; lane_idx++) begin
              int idx_local;
              idx_local = $unsigned(work_idx_reg) + lane_idx;
              if ((idx_local < stage_n_cur) && (idx_local < active_n4_reg)) begin
                tmp_reg[idx_local] <= chunk_pipe_reg[lane_idx];
              end
            end
            if (($unsigned(work_idx_reg) + FAST_INV_CHUNK_STEP) >= stage_n_cur) begin
              phase_reg <= PH_STAGE_B_LO;
              work_idx_reg <= '0;
              b_reg <= '0;
              b_partial_reg <= '0;
            end else begin
              work_idx_reg <= work_idx_reg + FAST_INV_CHUNK_STEP;
              phase_reg <= PH_STAGE_TMP_LO;
            end
          end
          PH_STAGE_B_LO: begin
            b_partial_reg <= b_chunk;
            phase_reg <= PH_STAGE_B_HI;
          end
          PH_STAGE_B_HI: begin
            chunk_pipe_reg <= b_chunk;
            phase_reg <= PH_STAGE_B_WRITE;
          end
          PH_STAGE_B_WRITE: begin
            for (int lane_idx = 0; lane_idx < FAST_INV_CHUNK_LANES; lane_idx++) begin
              int idx_local;
              idx_local = $unsigned(work_idx_reg) + lane_idx;
              if (idx_local < stage_n_cur) begin
                b_reg[idx_local] <= chunk_pipe_reg[lane_idx];
              end
            end
            if (($unsigned(work_idx_reg) + FAST_INV_CHUNK_STEP) >= stage_n_cur) begin
              phase_reg <= PH_STAGE_PROD_LO;
              work_idx_reg <= '0;
              prod_partial_reg <= '0;
            end else begin
              work_idx_reg <= work_idx_reg + FAST_INV_CHUNK_STEP;
              phase_reg <= PH_STAGE_B_LO;
            end
          end
          PH_STAGE_PROD_LO: begin
            prod_partial_reg <= prod_chunk;
            phase_reg <= PH_STAGE_PROD_HI;
          end
          PH_STAGE_PROD_HI: begin
            chunk_pipe_reg <= prod_chunk;
            phase_reg <= PH_STAGE_PROD_WRITE;
          end
          PH_STAGE_PROD_WRITE: begin
            for (int lane_idx = 0; lane_idx < FAST_INV_CHUNK_LANES; lane_idx++) begin
              int idx_local;
              idx_local = $unsigned(work_idx_reg) + lane_idx;
              if (idx_local < active_n4_reg) begin
                k_reg[idx_local] <= chunk_pipe_reg[lane_idx];
              end
            end
            if (($unsigned(work_idx_reg) + FAST_INV_CHUNK_STEP) >= active_n4_reg) begin
              phase_reg <= PH_STAGE_PREFIX;
              work_idx_reg <= stage_n_cur;
            end else begin
              work_idx_reg <= work_idx_reg + FAST_INV_CHUNK_STEP;
              phase_reg <= PH_STAGE_PROD_LO;
            end
          end
          PH_STAGE_PREFIX: begin
            chunk_pipe_reg <= prefix_chunk;
            phase_reg <= PH_STAGE_PREFIX_WRITE;
          end
          PH_STAGE_PREFIX_WRITE: begin
            for (int lane_idx = 0; lane_idx < FAST_INV_CHUNK_LANES; lane_idx++) begin
              int idx_local;
              idx_local = $unsigned(work_idx_reg) + lane_idx;
              if ((idx_local >= stage_n_cur) && (idx_local < active_n4_reg)) begin
                k_reg[idx_local] <= chunk_pipe_reg[lane_idx];
              end
            end
            if (($unsigned(work_idx_reg) + FAST_INV_CHUNK_STEP) >= active_n4_reg) begin
              phase_reg <= PH_STAGE_FINV;
              work_idx_reg <= '0;
            end else begin
              work_idx_reg <= work_idx_reg + FAST_INV_CHUNK_STEP;
              phase_reg <= PH_STAGE_PREFIX;
            end
          end
          PH_STAGE_FINV: begin
            chunk_pipe_reg <= finv_chunk;
            phase_reg <= PH_STAGE_FINV_WRITE;
          end
          PH_STAGE_FINV_WRITE: begin
            for (int lane_idx = 0; lane_idx < FAST_INV_CHUNK_LANES; lane_idx++) begin
              int idx_local;
              idx_local = $unsigned(work_idx_reg) + lane_idx;
              if (idx_local < stage_finv_limit_cur) begin
                f_inv_reg[idx_local] <= chunk_pipe_reg[lane_idx];
              end
            end
            if (($unsigned(work_idx_reg) + FAST_INV_CHUNK_STEP) >= stage_finv_limit_cur) begin
              if ((stage_idx_reg + 1) >= active_n4_log2_reg) begin
                phase_reg <= PH_PACK;
                pack_row_idx <= '0;
              end else begin
                stage_idx_reg <= stage_idx_reg + 1'b1;
                work_idx_reg <= '0;
                phase_reg <= PH_STAGE_TMP_LO;
                tmp_reg <= '0;
                b_reg <= '0;
                tmp_partial_reg <= '0;
                b_partial_reg <= '0;
                prod_partial_reg <= '0;
              end
            end else begin
              work_idx_reg <= work_idx_reg + FAST_INV_CHUNK_STEP;
              phase_reg <= PH_STAGE_FINV;
            end
          end
          PH_PACK: begin
            int pack_coeff_idx;
            int coeff_base;
            int coeff_idx;

            coeff_base = pack_row_idx * FAST_INV_PACK_ROW_COEFFS;
            row_out_valid_o <= 1'b1;
            row_out_idx_o <= pack_row_idx;
            for (pack_coeff_idx = 0; pack_coeff_idx < FAST_INV_PACK_ROW_COEFFS; pack_coeff_idx++) begin
              coeff_idx = coeff_base + pack_coeff_idx;
              if (coeff_idx < FAST_INV_N4) begin
                if (COEFF_W > 1) begin
                  row_out_data_o[pack_coeff_idx*COEFF_W +: COEFF_W] <=
                    {{(COEFF_W - 1){1'b0}}, f_inv_reg[coeff_idx]};
                end else begin
                  row_out_data_o[pack_coeff_idx*COEFF_W +: COEFF_W] <= f_inv_reg[coeff_idx];
                end
              end else begin
                row_out_data_o[pack_coeff_idx*COEFF_W +: COEFF_W] <= '0;
              end
            end

            if (pack_row_idx == (FAST_INV_PACK_ROW_COUNT - 1)) begin
              fast_inv_running <= 1'b0;
              phase_reg <= PH_IDLE;
              pack_row_idx <= '0;
              done_o <= 1'b1;
            end else begin
              pack_row_idx <= pack_row_idx + 1'b1;
            end
          end
          default: begin
            fast_inv_running <= 1'b0;
            phase_reg <= PH_IDLE;
          end
        endcase
      end
    end
  end

endmodule
