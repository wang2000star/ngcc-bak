module zen_binary_core (
  input  logic                         clk,
  input  logic                         rst_n,
  input  logic                         start,
  input  logic [7:0]                   cmd,
  input  logic [31:0]                  cfg,
  input  logic [31:0]                  len,
  input  logic [2:0]                   buf_a_sel,
  input  logic [2:0]                   buf_b_sel,
  input  logic [2:0]                   buf_r_sel,
  input  logic                         vec_in_valid,
  input  zen_accel_pkg::zen_poly_vec_t vec_a_data,
  input  zen_accel_pkg::zen_poly_vec_t vec_b_data,
  output logic                         vec_out_valid,
  output zen_accel_pkg::zen_poly_vec_t vec_r_data,
  output logic                         row_out_valid,
  output zen_accel_pkg::zen_row_addr_t row_out_idx,
  output zen_accel_pkg::zen_stream_row_t row_out_data,
  output logic                         busy,
  output logic                         done,
  output logic                         error
);

  import zen_accel_pkg::*;

  localparam int NTT_N = ZEN_N;
  localparam int XOR_LANES = BINARY_LANES;
  localparam int LOCAL_N2 = NTT_N / 2;
  localparam int LOCAL_N4 = NTT_N / 4;
  localparam int ZEN_MSG_BYTES = LOCAL_N4 / 8;
  localparam int FIXED_COL_FACTOR = 2;
  localparam int BIN_COL_LANES = ((XOR_LANES * FIXED_COL_FACTOR) > LOCAL_N2) ? LOCAL_N2
                                                                              : (XOR_LANES * FIXED_COL_FACTOR);
  localparam int BINARY_XOR_PHASE_LANES = (XOR_LANES > 32) ? 32 : XOR_LANES;
  localparam int BINARY_XOR_PHASES = (XOR_LANES + BINARY_XOR_PHASE_LANES - 1) /
                                     BINARY_XOR_PHASE_LANES;
  localparam int BINARY_PHASE_W = (BINARY_XOR_PHASES <= 1) ? 1 : $clog2(BINARY_XOR_PHASES);
  localparam int BINARY_CHUNK_COL_LANES = (((2 * BINARY_XOR_PHASE_LANES) > BIN_COL_LANES) ?
                                           BIN_COL_LANES : (2 * BINARY_XOR_PHASE_LANES));
  localparam int BINARY_STAGE_LANES = (BINARY_CHUNK_COL_LANES > XOR_LANES) ?
                                      BINARY_CHUNK_COL_LANES : XOR_LANES;
  localparam int BINARY_COL_PHASES = (BIN_COL_LANES + BINARY_CHUNK_COL_LANES - 1) /
                                     BINARY_CHUNK_COL_LANES;
  localparam int BINARY_COL_PHASE_W = (BINARY_COL_PHASES <= 1) ? 1 :
                                      $clog2(BINARY_COL_PHASES);
  localparam int BINARY_CHUNK_REDUCE_SPLIT0 = (BINARY_XOR_PHASE_LANES <= 1) ? 1 :
                                              ((BINARY_XOR_PHASE_LANES + 2) / 3);
  localparam int BINARY_CHUNK_REDUCE_SPLIT1 = (BINARY_XOR_PHASE_LANES <= 2) ?
                                              BINARY_XOR_PHASE_LANES :
                                              (((2 * BINARY_XOR_PHASE_LANES) + 2) / 3);
  localparam int SCRATCH_LINE_COEFFS = XOR_LANES;
  localparam int SCRATCH_LINE_W = SCRATCH_LINE_COEFFS * COEFF_W;
  localparam int SCRATCH_LINE_COUNT = (NTT_N + SCRATCH_LINE_COEFFS - 1) / SCRATCH_LINE_COEFFS;
  localparam int SCRATCH_LINE_ADDR_W = (SCRATCH_LINE_COUNT <= 1) ? 1 :
                                       $clog2(SCRATCH_LINE_COUNT);
  localparam logic [1:0] BINARY_CHUNK_OP_R2         = 2'd0;
  localparam logic [1:0] BINARY_CHUNK_OP_R2_FROM_T0 = 2'd1;
  localparam logic [1:0] BINARY_CHUNK_OP_DECODE     = 2'd2;
  localparam logic [3:0] STAGE_OP_NONE              = 4'd0;
  localparam logic [3:0] STAGE_OP_CT_DECOMP         = 4'd1;
  localparam logic [3:0] STAGE_OP_MSG_UNPACK        = 4'd2;
  localparam logic [3:0] STAGE_OP_MSG_PACK          = 4'd3;
  localparam logic [3:0] STAGE_OP_T0                = 4'd4;
  localparam logic [3:0] STAGE_OP_A_MOD2            = 4'd5;
  localparam logic [3:0] STAGE_OP_POLY_ADD          = 4'd6;
  localparam logic [3:0] STAGE_OP_ENC_POST          = 4'd7;
  localparam logic [3:0] STAGE_OP_DEC_A_MOD2        = 4'd8;

  typedef enum logic [4:0] {
    ST_IDLE,
    ST_PREP,
    ST_RUN_R2,
    ST_RUN_FAST_INV,
    ST_RUN_DECODE,
    ST_RUN_CT_DECOMP,
    ST_RUN_MSG_UNPACK,
    ST_RUN_MSG_PACK,
    ST_RUN_T0,
    ST_RUN_A_MOD2,
    ST_RUN_POLY_ADD,
    ST_RUN_ENC_POST,
    ST_RUN_DEC_POST_T0,
    ST_RUN_DEC_POST_A_MOD2,
    ST_RUN_DEC_POST_R2,
    ST_RUN_DEC_POST_DECODE,
    ST_DONE,
    ST_ERROR
  } state_t;

  state_t state;
  state_t state_n;
  state_t unary_done_state;
  state_t chunk_done_state;

  logic [15:0] cycle_count;
  logic [ADDR_W:0] row_ptr;
  logic [ADDR_W:0] col_ptr;
  logic valid_cmd;
  logic vec_mode_active;
  logic [7:0] cmd_reg;
  zen_poly_vec_t vec_a_data_reg;
  zen_poly_vec_t vec_b_data_reg;
  logic fast_inv_start;
  logic fast_inv_done;
  logic fast_inv_row_out_valid;
  logic [ADDR_W-1:0] fast_inv_row_out_idx;
  logic signed [(16*COEFF_W)-1:0] fast_inv_row_out_data;
  logic [1:0] binary_chunk_op;
  zen_poly_vec_t binary_chunk_acc_vec;
  zen_poly_vec_t binary_chunk_sel_vec;
  logic signed [BINARY_CHUNK_COL_LANES*COEFF_W-1:0] binary_chunk_data;
  int unsigned binary_chunk_active_ring_n;
  int unsigned binary_chunk_active_acc_n;
  int unsigned active_n;
  int unsigned active_n2;
  int unsigned active_n4;
  int unsigned active_msg_bytes;
  int unsigned active_bin_col_lanes;
  integer idx;
  logic [BINARY_PHASE_W-1:0] xor_phase;
  logic [BINARY_COL_PHASE_W-1:0] col_phase;
  logic [ADDR_W:0] binary_phase_row_base;
  logic [ADDR_W:0] binary_phase_col_base;
  logic binary_phase_last;
  logic binary_col_phase_last;
  logic binary_chunk_cache_pending;
  logic binary_chunk_decode_c23_pending;
  logic binary_chunk_decode_compare_pending;
  logic binary_chunk_decode_pending;
  logic binary_chunk_decode_metric_pending;
  logic binary_chunk_reduce_pending;
  logic binary_chunk_reduce2_pending;
  logic binary_write_pending;
  logic [LOCAL_N2-1:0] binary_chunk_b_lsb_reg;
  logic [BINARY_CHUNK_COL_LANES-1:0] binary_chunk_acc_seed_reg;
  logic [BINARY_CHUNK_COL_LANES-1:0] binary_chunk_partial_lsb;
  logic [BINARY_CHUNK_COL_LANES-1:0] binary_chunk_partial_lsb_reg;
  logic [BINARY_CHUNK_COL_LANES-1:0] binary_chunk_partial_mid_lsb;
  logic [BINARY_CHUNK_COL_LANES-1:0] binary_chunk_partial_mid_lsb_reg;
  logic signed [BINARY_STAGE_LANES*COEFF_W-1:0] binary_stage_data_reg;
  logic                                 binary_src_load_pending;
  logic [SCRATCH_LINE_ADDR_W-1:0]       binary_src_load_addr;
  logic                                 binary_src_wr_en;
  logic [SCRATCH_LINE_ADDR_W-1:0]       binary_src_wr_addr;
  logic [SCRATCH_LINE_W-1:0]            binary_src_wr_data;
  logic [SCRATCH_LINE_ADDR_W-1:0]       binary_src_rd0_addr;
  logic [SCRATCH_LINE_ADDR_W-1:0]       binary_src_rd1_addr;
  logic [SCRATCH_LINE_ADDR_W-1:0]       binary_src_rd2_addr;
  logic [SCRATCH_LINE_ADDR_W-1:0]       binary_src_rd3_addr;
  logic [SCRATCH_LINE_W-1:0]            binary_src_rd0_data_reg;
  logic [SCRATCH_LINE_W-1:0]            binary_src_rd1_data_reg;
  logic [SCRATCH_LINE_W-1:0]            binary_src_rd2_data_reg;
  logic [SCRATCH_LINE_W-1:0]            binary_src_rd3_data_reg;
  logic                                 dec_post_t0_wr_en;
  logic [SCRATCH_LINE_ADDR_W-1:0]       dec_post_t0_wr_addr;
  logic [SCRATCH_LINE_W-1:0]            dec_post_t0_wr_data;
  logic [SCRATCH_LINE_ADDR_W-1:0]       dec_post_t0_rd0_addr;
  logic [SCRATCH_LINE_ADDR_W-1:0]       dec_post_t0_rd1_addr;
  logic [SCRATCH_LINE_ADDR_W-1:0]       dec_post_t0_rd2_addr;
  logic [SCRATCH_LINE_ADDR_W-1:0]       dec_post_t0_rd3_addr;
  logic [SCRATCH_LINE_W-1:0]            dec_post_t0_rd0_data_reg;
  logic [SCRATCH_LINE_W-1:0]            dec_post_t0_rd1_data_reg;
  logic [SCRATCH_LINE_W-1:0]            dec_post_t0_rd2_data_reg;
  logic [SCRATCH_LINE_W-1:0]            dec_post_t0_rd3_data_reg;
  logic [LOCAL_N2-1:0]                  dec_post_a_mod2_bits_reg;
  logic unary_state_active;
  logic [3:0] unary_stage_op;
  logic [ADDR_W:0] unary_write_limit;
  logic unary_write_dec_t0;
  logic unary_write_dec_a_mod2;
  logic unary_reset_iterators_on_done;
  logic unary_pipe_active;
  logic unary_pipe_needs_mont;
  logic unary_prep_pending;
  logic unary_math_pending;
  logic unary_reduce_pending;
  logic unary_reduce2_pending;
  logic chunk_state_active;
  logic [ADDR_W:0] chunk_write_limit;
  logic [ADDR_W:0] chunk_row_limit;
  logic [XOR_LANES*8-1:0] unary_byte_capture;
  logic [XOR_LANES*8-1:0] unary_byte_reg;
  logic signed [XOR_LANES*COEFF_W-1:0] unary_src0_capture;
  logic signed [XOR_LANES*COEFF_W-1:0] unary_src1_capture;
  logic signed [XOR_LANES*COEFF_W-1:0] unary_src0_reg;
  logic signed [XOR_LANES*COEFF_W-1:0] unary_src1_reg;
  logic signed [XOR_LANES*32-1:0] unary_mont_in_data;
  logic signed [XOR_LANES*32-1:0] unary_mont_in_reg;
  logic signed [XOR_LANES*COEFF_W-1:0] unary_mont_u_data;
  logic signed [XOR_LANES*COEFF_W-1:0] unary_mont_u_reg;
  logic signed [XOR_LANES*COEFF_W-1:0] unary_mont_mid_data;
  logic signed [XOR_LANES*COEFF_W-1:0] unary_mont_out_reg;
  logic signed [XOR_LANES*COEFF_W-1:0] unary_pipe_stage_data;
  logic signed [XOR_LANES*COEFF_W-1:0] unary_stage_data;
  localparam int ZEN_MSG_LIFT_VAL = (ZEN_Q + 1) / 2;
  logic [ADDR_W:0] binary_chunk_row_idx_cache [0:BINARY_XOR_PHASE_LANES-1];
  logic [ADDR_W:0] binary_chunk_row_sel_idx_cache [0:BINARY_XOR_PHASE_LANES-1];
  logic binary_chunk_row_active_cache [0:BINARY_XOR_PHASE_LANES-1];
  logic binary_chunk_row_lo_en_cache [0:BINARY_XOR_PHASE_LANES-1];
  logic [ADDR_W:0] binary_chunk_row_idx_reg [0:BINARY_XOR_PHASE_LANES-1];
  logic [ADDR_W:0] binary_chunk_row_sel_idx_reg [0:BINARY_XOR_PHASE_LANES-1];
  logic binary_chunk_row_active_reg [0:BINARY_XOR_PHASE_LANES-1];
  logic binary_chunk_row_lo_en_reg [0:BINARY_XOR_PHASE_LANES-1];
  logic signed [COEFF_W-1:0] binary_chunk_dec_c0_reg [0:BINARY_XOR_PHASE_LANES-1];
  logic signed [COEFF_W-1:0] binary_chunk_dec_c1_reg [0:BINARY_XOR_PHASE_LANES-1];
  logic signed [COEFF_W-1:0] binary_chunk_dec_c2_reg [0:BINARY_XOR_PHASE_LANES-1];
  logic signed [COEFF_W-1:0] binary_chunk_dec_c3_reg [0:BINARY_XOR_PHASE_LANES-1];
  logic [COEFF_W-1:0] binary_chunk_dec_lo_min_reg [0:BINARY_XOR_PHASE_LANES-1];
  logic [COEFF_W-1:0] binary_chunk_dec_hi_min_reg [0:BINARY_XOR_PHASE_LANES-1];
  logic [ADDR_W:0] binary_chunk_dec_lo_sel_idx_reg [0:BINARY_XOR_PHASE_LANES-1];
  logic [ADDR_W:0] binary_chunk_dec_hi_sel_idx_reg [0:BINARY_XOR_PHASE_LANES-1];
  (* ram_style = "block" *) logic [SCRATCH_LINE_W-1:0] binary_src_mem_rd0
    [0:SCRATCH_LINE_COUNT-1];
  (* ram_style = "block" *) logic [SCRATCH_LINE_W-1:0] binary_src_mem_rd1
    [0:SCRATCH_LINE_COUNT-1];
  (* ram_style = "block" *) logic [SCRATCH_LINE_W-1:0] binary_src_mem_rd2
    [0:SCRATCH_LINE_COUNT-1];
  (* ram_style = "block" *) logic [SCRATCH_LINE_W-1:0] binary_src_mem_rd3
    [0:SCRATCH_LINE_COUNT-1];
  (* ram_style = "block" *) logic [SCRATCH_LINE_W-1:0] dec_post_t0_mem_rd0
    [0:SCRATCH_LINE_COUNT-1];
  (* ram_style = "block" *) logic [SCRATCH_LINE_W-1:0] dec_post_t0_mem_rd1
    [0:SCRATCH_LINE_COUNT-1];
  (* ram_style = "block" *) logic [SCRATCH_LINE_W-1:0] dec_post_t0_mem_rd2
    [0:SCRATCH_LINE_COUNT-1];
  (* ram_style = "block" *) logic [SCRATCH_LINE_W-1:0] dec_post_t0_mem_rd3
    [0:SCRATCH_LINE_COUNT-1];

`ifndef SYNTHESIS
  logic signed [NTT_N*COEFF_W-1:0] dec_t0_vec;
  logic signed [LOCAL_N4*COEFF_W-1:0] dec_r2_vec;
  logic signed [NTT_N*COEFF_W-1:0] dec_t2_vec;
  logic signed [NTT_N*COEFF_W-1:0] dec_t0_debug_vec;
  logic signed [LOCAL_N4*COEFF_W-1:0] dec_r2_debug_vec;
  logic signed [NTT_N*COEFF_W-1:0] dec_t2_debug_vec;
`endif

  assign fast_inv_start = (state == ST_PREP) && (cmd_reg == CMD_FAST_INV);

  zen_binary_fast_inv_core #(
    .NTT_N   (NTT_N),
    .COEFF_W (COEFF_W)
  ) fast_inv_core (
    .clk            (clk),
    .rst_n          (rst_n),
    .start_i        (fast_inv_start),
    .vec_a_data     (vec_a_data_reg),
    .done_o         (fast_inv_done),
    .row_out_valid_o(fast_inv_row_out_valid),
    .row_out_idx_o  (fast_inv_row_out_idx),
    .row_out_data_o (fast_inv_row_out_data)
  );

`ifndef SYNTHESIS
  zen_binary_dec_debug_core #(
    .NTT_N   (NTT_N),
    .COEFF_W (COEFF_W)
  ) dec_debug_core (
    .vec_a_data   (vec_a_data_reg),
    .vec_b_data   (vec_b_data_reg),
    .active_n2_i  (active_n2),
    .active_n4_i  (active_n4),
    .dec_t0_vec_o (dec_t0_debug_vec),
    .dec_r2_vec_o (dec_r2_debug_vec),
    .dec_t2_vec_o (dec_t2_debug_vec)
  );
`endif

  assign valid_cmd = (cmd == CMD_R2_MUL) || (cmd == CMD_FAST_INV) ||
                     (cmd == CMD_DECODE_HELPER) || (cmd == CMD_T0_TRANSFORM) ||
                     (cmd == CMD_A_MOD2) || (cmd == CMD_POLY_ADD) ||
                     (cmd == CMD_ENC_POSTPROC) || (cmd == CMD_DEC_POSTPROC) ||
                     (cmd == CMD_CT_DECOMP) || (cmd == CMD_MSG_UNPACK) ||
                     (cmd == CMD_MSG_PACK);

  // Keep the chunk/stage math local to zen_binary_core during synthesis to avoid
  // very wide hierarchical ports on helper modules.
  always_comb begin
    integer lane_idx;
    integer row_idx;

    row_idx = 0;

    for (lane_idx = 0; lane_idx < BINARY_XOR_PHASE_LANES; lane_idx++) begin
      binary_chunk_row_idx_cache[lane_idx] = '0;
      binary_chunk_row_sel_idx_cache[lane_idx] = '0;
      binary_chunk_row_active_cache[lane_idx] = 1'b0;
      binary_chunk_row_lo_en_cache[lane_idx] = 1'b0;

      row_idx = $unsigned(binary_phase_row_base) + lane_idx;
      if (row_idx < binary_chunk_active_ring_n) begin
        binary_chunk_row_idx_cache[lane_idx] = row_idx[ADDR_W:0];
        binary_chunk_row_active_cache[lane_idx] = 1'b1;

        unique case (binary_chunk_op)
          BINARY_CHUNK_OP_R2: begin
            if (state == ST_RUN_DEC_POST_R2) begin
              binary_chunk_row_lo_en_cache[lane_idx] = dec_post_a_mod2_bits_reg[row_idx];
            end else begin
              binary_chunk_row_lo_en_cache[lane_idx] =
                binary_chunk_sel_vec[row_idx*COEFF_W];
            end
          end
          BINARY_CHUNK_OP_R2_FROM_T0: begin
            binary_chunk_row_lo_en_cache[lane_idx] =
              binary_chunk_sel_vec[row_idx*COEFF_W] ^
              binary_chunk_sel_vec[(row_idx + binary_chunk_active_ring_n)*COEFF_W];
          end
          BINARY_CHUNK_OP_DECODE: begin
          end
          default: begin
          end
        endcase
      end
    end
  end

  always_comb begin
    integer col_idx;
    integer lane_idx;
    integer src_idx;
    integer ring_n2;
    integer row_idx;
    integer sel_idx;
    logic acc_bit;
    logic row_lo_en_bit;

    acc_bit = 1'b0;
    src_idx = 0;
    ring_n2 = 2 * binary_chunk_active_ring_n;
    row_idx = 0;
    sel_idx = 0;
    row_lo_en_bit = 1'b0;
    binary_chunk_partial_lsb = '0;

    for (col_idx = 0; col_idx < BINARY_CHUNK_COL_LANES; col_idx++) begin
      if (($unsigned(binary_phase_col_base) + col_idx) < binary_chunk_active_acc_n) begin
        acc_bit = binary_chunk_acc_seed_reg[col_idx];
        for (lane_idx = 0; lane_idx < BINARY_CHUNK_REDUCE_SPLIT0; lane_idx++) begin
          if (binary_chunk_row_active_reg[lane_idx]) begin
            row_idx = $unsigned(binary_chunk_row_idx_reg[lane_idx]);
            sel_idx = $unsigned(binary_chunk_row_sel_idx_reg[lane_idx]);
            unique case (binary_chunk_op)
              BINARY_CHUNK_OP_R2,
              BINARY_CHUNK_OP_R2_FROM_T0: begin
                row_lo_en_bit = binary_chunk_row_lo_en_reg[lane_idx];
                if (row_lo_en_bit) begin
                  src_idx = (($unsigned(binary_phase_col_base) + col_idx) +
                             binary_chunk_active_ring_n - row_idx) &
                            (binary_chunk_active_ring_n - 1);
                  acc_bit = acc_bit ^ binary_chunk_b_lsb_reg[src_idx];
                end
              end
              BINARY_CHUNK_OP_DECODE: begin
                src_idx = (($unsigned(binary_phase_col_base) + col_idx) + ring_n2 - sel_idx) &
                          (ring_n2 - 1);
                acc_bit = acc_bit ^ binary_chunk_b_lsb_reg[src_idx];
              end
              default: begin
              end
            endcase
          end
        end
        binary_chunk_partial_lsb[col_idx] = acc_bit;
      end
    end
  end

  always_comb begin
    integer col_idx;
    integer lane_idx;
    integer src_idx;
    integer ring_n2;
    integer row_idx;
    integer sel_idx;
    logic acc_bit;
    logic row_lo_en_bit;

    acc_bit = 1'b0;
    src_idx = 0;
    ring_n2 = 2 * binary_chunk_active_ring_n;
    row_idx = 0;
    sel_idx = 0;
    row_lo_en_bit = 1'b0;
    binary_chunk_partial_mid_lsb = '0;

    for (col_idx = 0; col_idx < BINARY_CHUNK_COL_LANES; col_idx++) begin
      if (($unsigned(binary_phase_col_base) + col_idx) < binary_chunk_active_acc_n) begin
        acc_bit = binary_chunk_partial_lsb_reg[col_idx];
        for (lane_idx = BINARY_CHUNK_REDUCE_SPLIT0;
             lane_idx < BINARY_CHUNK_REDUCE_SPLIT1;
             lane_idx++) begin
          if (binary_chunk_row_active_reg[lane_idx]) begin
            row_idx = $unsigned(binary_chunk_row_idx_reg[lane_idx]);
            sel_idx = $unsigned(binary_chunk_row_sel_idx_reg[lane_idx]);
            unique case (binary_chunk_op)
              BINARY_CHUNK_OP_R2,
              BINARY_CHUNK_OP_R2_FROM_T0: begin
                row_lo_en_bit = binary_chunk_row_lo_en_reg[lane_idx];
                if (row_lo_en_bit) begin
                  src_idx = (($unsigned(binary_phase_col_base) + col_idx) +
                             binary_chunk_active_ring_n - row_idx) &
                            (binary_chunk_active_ring_n - 1);
                  acc_bit = acc_bit ^ binary_chunk_b_lsb_reg[src_idx];
                end
              end
              BINARY_CHUNK_OP_DECODE: begin
                src_idx = (($unsigned(binary_phase_col_base) + col_idx) + ring_n2 - sel_idx) &
                          (ring_n2 - 1);
                acc_bit = acc_bit ^ binary_chunk_b_lsb_reg[src_idx];
              end
              default: begin
              end
            endcase
          end
        end
        binary_chunk_partial_mid_lsb[col_idx] = acc_bit;
      end
    end
  end

  always_comb begin
    integer col_idx;
    integer lane_idx;
    integer src_idx;
    integer ring_n2;
    integer row_idx;
    integer sel_idx;
    logic acc_bit;
    logic row_lo_en_bit;

    acc_bit = 1'b0;
    src_idx = 0;
    ring_n2 = 2 * binary_chunk_active_ring_n;
    row_idx = 0;
    sel_idx = 0;
    row_lo_en_bit = 1'b0;
    binary_chunk_data = '0;

    for (col_idx = 0; col_idx < BINARY_CHUNK_COL_LANES; col_idx++) begin
      if (($unsigned(binary_phase_col_base) + col_idx) < binary_chunk_active_acc_n) begin
        acc_bit = binary_chunk_partial_mid_lsb_reg[col_idx];
        for (lane_idx = BINARY_CHUNK_REDUCE_SPLIT1;
             lane_idx < BINARY_XOR_PHASE_LANES;
             lane_idx++) begin
          if (binary_chunk_row_active_reg[lane_idx]) begin
            row_idx = $unsigned(binary_chunk_row_idx_reg[lane_idx]);
            sel_idx = $unsigned(binary_chunk_row_sel_idx_reg[lane_idx]);
            unique case (binary_chunk_op)
              BINARY_CHUNK_OP_R2,
              BINARY_CHUNK_OP_R2_FROM_T0: begin
                row_lo_en_bit = binary_chunk_row_lo_en_reg[lane_idx];
                if (row_lo_en_bit) begin
                  src_idx = (($unsigned(binary_phase_col_base) + col_idx) +
                             binary_chunk_active_ring_n - row_idx) &
                            (binary_chunk_active_ring_n - 1);
                  acc_bit = acc_bit ^ binary_chunk_b_lsb_reg[src_idx];
                end
              end
              BINARY_CHUNK_OP_DECODE: begin
                src_idx = (($unsigned(binary_phase_col_base) + col_idx) + ring_n2 - sel_idx) &
                          (ring_n2 - 1);
                acc_bit = acc_bit ^ binary_chunk_b_lsb_reg[src_idx];
              end
              default: begin
              end
            endcase
          end
        end

        if (COEFF_W > 1) begin
          binary_chunk_data[col_idx*COEFF_W +: COEFF_W] =
            {{(COEFF_W - 1){1'b0}}, acc_bit};
        end else begin
          binary_chunk_data[col_idx*COEFF_W +: COEFF_W] = acc_bit;
        end
      end
    end
  end

  always_comb begin
    integer lane_idx;
    integer coeff_idx;
    integer byte_idx;
    integer bit_idx;
    integer src_idx;
    integer base_idx;
    logic signed [15:0] coeff_word;
    logic signed [15:0] lo_coeff;
    logic signed [15:0] hi_coeff;
    logic [7:0] packed_byte;
    logic bit_val;

    unary_byte_capture = '0;
    unary_src0_capture = '0;
    unary_src1_capture = '0;

    for (lane_idx = 0; lane_idx < XOR_LANES; lane_idx++) begin
      coeff_idx = $unsigned(col_ptr) + lane_idx;
      coeff_word = '0;
      lo_coeff = '0;
      hi_coeff = '0;
      packed_byte = '0;
      bit_val = 1'b0;
      src_idx = 0;
      base_idx = 0;
      byte_idx = 0;
      bit_idx = 0;

      unique case (unary_stage_op)
        STAGE_OP_CT_DECOMP: begin
          if (coeff_idx < active_n) begin
            coeff_word = vec_a_data_reg[coeff_idx*COEFF_W +: COEFF_W];
            unary_byte_capture[lane_idx*8 +: 8] = coeff_word[7:0];
          end
        end
        STAGE_OP_MSG_UNPACK: begin
          if (coeff_idx < active_n) begin
            src_idx = coeff_idx & (active_n4 - 1);
            byte_idx = src_idx >>> 3;
            bit_idx = src_idx & 7;
            unary_src0_capture[lane_idx*COEFF_W +: COEFF_W] =
              vec_a_data_reg[byte_idx*COEFF_W +: COEFF_W];
            unary_byte_capture[lane_idx*8 +: 8] = {5'd0, bit_idx[2:0]};
          end
        end
        STAGE_OP_MSG_PACK: begin
          if (coeff_idx < active_msg_bytes) begin
            base_idx = coeff_idx << 3;
            packed_byte = 8'd0;
            for (bit_idx = 0; bit_idx < 8; bit_idx++) begin
              packed_byte[bit_idx] = vec_a_data_reg[(base_idx + bit_idx)*COEFF_W];
            end
            unary_byte_capture[lane_idx*8 +: 8] = packed_byte;
          end
        end
        STAGE_OP_T0: begin
          if (coeff_idx < active_n) begin
            if (coeff_idx < active_n2) begin
              unary_src0_capture[lane_idx*COEFF_W +: COEFF_W] =
                vec_a_data_reg[(coeff_idx + active_n2)*COEFF_W +: COEFF_W];
              unary_src1_capture[lane_idx*COEFF_W +: COEFF_W] =
                vec_a_data_reg[coeff_idx*COEFF_W +: COEFF_W];
            end else begin
              unary_src0_capture[lane_idx*COEFF_W +: COEFF_W] =
                vec_a_data_reg[(coeff_idx - active_n2)*COEFF_W +: COEFF_W];
              unary_src1_capture[lane_idx*COEFF_W +: COEFF_W] =
                -vec_a_data_reg[coeff_idx*COEFF_W +: COEFF_W];
            end
          end
        end
        STAGE_OP_A_MOD2: begin
          if (coeff_idx < active_n) begin
            if (coeff_idx < active_n2) begin
              unary_src0_capture[lane_idx*COEFF_W +: COEFF_W] =
                vec_a_data_reg[coeff_idx*COEFF_W +: COEFF_W];
              unary_src1_capture[lane_idx*COEFF_W +: COEFF_W] =
                vec_a_data_reg[(coeff_idx + active_n2)*COEFF_W +: COEFF_W];
            end
          end
        end
        STAGE_OP_POLY_ADD: begin
          if (coeff_idx < active_n) begin
            unary_src0_capture[lane_idx*COEFF_W +: COEFF_W] =
              vec_a_data_reg[coeff_idx*COEFF_W +: COEFF_W];
            unary_src1_capture[lane_idx*COEFF_W +: COEFF_W] =
              vec_b_data_reg[coeff_idx*COEFF_W +: COEFF_W];
          end
        end
        STAGE_OP_ENC_POST: begin
          if (coeff_idx < active_n) begin
            unary_src0_capture[lane_idx*COEFF_W +: COEFF_W] =
              vec_a_data_reg[coeff_idx*COEFF_W +: COEFF_W];
            unary_src1_capture[lane_idx*COEFF_W +: COEFF_W] =
              vec_b_data_reg[coeff_idx*COEFF_W +: COEFF_W];
          end
        end
        STAGE_OP_DEC_A_MOD2: begin
        end
        default: begin
        end
      endcase
    end
  end

  always_comb begin
    integer lane_idx;
    integer coeff_idx;
    integer bit_idx;
    integer src0_off;
    integer src1_off;
    logic signed [15:0] src0_word;
    logic signed [15:0] src1_word;
    logic bit_val;

    unary_stage_data = '0;

    for (lane_idx = 0; lane_idx < XOR_LANES; lane_idx++) begin
      coeff_idx = $unsigned(col_ptr) + lane_idx;
      bit_idx = 0;
      src0_off = 0;
      src1_off = 0;
      src0_word = '0;
      src1_word = '0;
      bit_val = 1'b0;

      unique case (unary_stage_op)
        STAGE_OP_MSG_UNPACK: begin
          if (coeff_idx < active_n) begin
            src0_word = $signed(unary_src0_reg[lane_idx*COEFF_W +: COEFF_W]);
            bit_idx = unary_byte_reg[lane_idx*8 +: 3];
            bit_val = src0_word[bit_idx];
            if (bit_val) begin
              unary_stage_data[lane_idx*COEFF_W +: COEFF_W] = $signed(ZEN_MSG_LIFT_VAL);
            end
          end
        end
        STAGE_OP_MSG_PACK: begin
          if (coeff_idx < active_msg_bytes) begin
            unary_stage_data[lane_idx*COEFF_W +: COEFF_W] =
              $signed({8'd0, unary_byte_reg[lane_idx*8 +: 8]});
          end
        end
        STAGE_OP_A_MOD2: begin
          if (coeff_idx < active_n2) begin
            src0_word = $signed(unary_src0_reg[lane_idx*COEFF_W +: COEFF_W]);
            src1_word = $signed(unary_src1_reg[lane_idx*COEFF_W +: COEFF_W]);
            unary_stage_data[lane_idx*COEFF_W +: COEFF_W] =
              (src0_word & 16'sd1) ^ (src1_word & 16'sd1);
          end
        end
        STAGE_OP_POLY_ADD: begin
          if (coeff_idx < active_n) begin
            src0_word = $signed(unary_src0_reg[lane_idx*COEFF_W +: COEFF_W]);
            src1_word = $signed(unary_src1_reg[lane_idx*COEFF_W +: COEFF_W]);
            unary_stage_data[lane_idx*COEFF_W +: COEFF_W] = src0_word + src1_word;
          end
        end
        STAGE_OP_DEC_A_MOD2: begin
          if (coeff_idx < active_n2) begin
            src0_off = ($unsigned(col_ptr) % SCRATCH_LINE_COEFFS) + lane_idx;
            src1_off = (($unsigned(col_ptr) + active_n2) % SCRATCH_LINE_COEFFS) + lane_idx;

            if (src0_off < SCRATCH_LINE_COEFFS) begin
              src0_word = dec_post_t0_rd0_data_reg[src0_off*COEFF_W +: COEFF_W];
            end else begin
              src0_word =
                dec_post_t0_rd1_data_reg[(src0_off - SCRATCH_LINE_COEFFS)*COEFF_W +: COEFF_W];
            end

            if (src1_off < SCRATCH_LINE_COEFFS) begin
              src1_word = dec_post_t0_rd2_data_reg[src1_off*COEFF_W +: COEFF_W];
            end else begin
              src1_word =
                dec_post_t0_rd3_data_reg[(src1_off - SCRATCH_LINE_COEFFS)*COEFF_W +: COEFF_W];
            end

            unary_stage_data[lane_idx*COEFF_W +: COEFF_W] =
              (src0_word & 16'sd1) ^ (src1_word & 16'sd1);
          end
        end
        default: begin
        end
      endcase
    end
  end

  always_comb begin
    integer lane_idx;
    integer coeff_idx;
    logic signed [15:0] src0_word;
    logic signed [15:0] src1_word;
    logic signed [16:0] accum17_local;

    unary_mont_in_data = '0;

    for (lane_idx = 0; lane_idx < XOR_LANES; lane_idx++) begin
      coeff_idx = $unsigned(col_ptr) + lane_idx;
      src0_word = '0;
      src1_word = '0;
      accum17_local = '0;

      if (unary_stage_op == STAGE_OP_T0) begin
        if (coeff_idx < active_n) begin
          src0_word = $signed(unary_src0_reg[lane_idx*COEFF_W +: COEFF_W]);
          src1_word = $signed(unary_src1_reg[lane_idx*COEFF_W +: COEFF_W]);
          unary_mont_in_data[lane_idx*32 +: 32] = (src0_word - src1_word) * 16'sd171;
        end
      end else if (unary_stage_op == STAGE_OP_ENC_POST) begin
        if (coeff_idx < active_n) begin
          src0_word = $signed(unary_src0_reg[lane_idx*COEFF_W +: COEFF_W]);
          src1_word = $signed(unary_src1_reg[lane_idx*COEFF_W +: COEFF_W]);
          accum17_local = src0_word + src1_word;
          unary_mont_in_data[lane_idx*32 +: 32] = accum17_local * 16'sd171;
        end
      end
    end
  end

  always_comb begin
    integer lane_idx;
    integer coeff_idx;
    logic signed [31:0] mont_in_word;
    logic signed [15:0] mont_u_word;

    unary_mont_u_data = '0;

    for (lane_idx = 0; lane_idx < XOR_LANES; lane_idx++) begin
      coeff_idx = $unsigned(col_ptr) + lane_idx;
      mont_in_word = '0;
      mont_u_word = '0;

      if ((unary_stage_op == STAGE_OP_T0) || (unary_stage_op == STAGE_OP_ENC_POST)) begin
        if (coeff_idx < active_n) begin
          mont_in_word = $signed(unary_mont_in_reg[lane_idx*32 +: 32]);
          mont_u_word = mont_in_word * (-16'sd767);
          unary_mont_u_data[lane_idx*COEFF_W +: COEFF_W] = mont_u_word;
        end
      end
    end
  end

  always_comb begin
    integer lane_idx;
    integer coeff_idx;
    logic signed [31:0] mont_in_word;
    logic signed [31:0] mont_t_word;
    logic signed [15:0] mont_u_word;

    unary_mont_mid_data = '0;

    for (lane_idx = 0; lane_idx < XOR_LANES; lane_idx++) begin
      coeff_idx = $unsigned(col_ptr) + lane_idx;
      mont_in_word = '0;
      mont_t_word = '0;
      mont_u_word = '0;

      if ((unary_stage_op == STAGE_OP_T0) || (unary_stage_op == STAGE_OP_ENC_POST)) begin
        if (coeff_idx < active_n) begin
          mont_in_word = $signed(unary_mont_in_reg[lane_idx*32 +: 32]);
          mont_u_word = $signed(unary_mont_u_reg[lane_idx*COEFF_W +: COEFF_W]);
          mont_t_word = mont_in_word - (mont_u_word * 16'sd769);
          unary_mont_mid_data[lane_idx*COEFF_W +: COEFF_W] = mont_t_word >>> 16;
        end
      end
    end
  end

  always_comb begin
    integer lane_idx;
    integer coeff_idx;
    logic signed [31:0] mont_in_word;
    logic signed [15:0] reduced_word;
    logic [7:0] packed_byte;
    logic [31:0] scaled;

    unary_pipe_stage_data = '0;

    for (lane_idx = 0; lane_idx < XOR_LANES; lane_idx++) begin
      coeff_idx = $unsigned(col_ptr) + lane_idx;
      mont_in_word = '0;
      reduced_word = '0;
      packed_byte = '0;
      scaled = '0;

      unique case (unary_stage_op)
        STAGE_OP_CT_DECOMP: begin
          if (coeff_idx < active_n) begin
            packed_byte = unary_byte_reg[lane_idx*8 +: 8];
            scaled = (((packed_byte * ZEN_Q) + 32'd128) >> 8);
            unary_pipe_stage_data[lane_idx*COEFF_W +: COEFF_W] = $signed(scaled[15:0]);
          end
        end
        STAGE_OP_T0: begin
          if (coeff_idx < active_n) begin
            unary_pipe_stage_data[lane_idx*COEFF_W +: COEFF_W] =
              unary_mont_out_reg[lane_idx*COEFF_W +: COEFF_W];
          end
        end
        STAGE_OP_ENC_POST: begin
          if (coeff_idx < active_n) begin
            reduced_word = $signed(unary_mont_out_reg[lane_idx*COEFF_W +: COEFF_W]);
            unary_pipe_stage_data[lane_idx*COEFF_W +: COEFF_W] =
              reduced_word + ((reduced_word >>> 15) & 16'sd769);
          end
        end
        default: begin
        end
      endcase
    end
  end

  always_comb begin
    integer coeff_idx_local;
    int unsigned line_base_u;
    int unsigned phase_row_base_u;
    int unsigned c0_base_u;
    int unsigned c1_base_u;
    int unsigned c2_base_u;
    int unsigned c3_base_u;
    int unsigned cur_line_u;
    int unsigned next_line_u;

    line_base_u = 0;
    phase_row_base_u = 0;
    c0_base_u = 0;
    c1_base_u = 0;
    c2_base_u = 0;
    c3_base_u = 0;
    cur_line_u = 0;
    next_line_u = 0;

    binary_src_wr_en = 1'b0;
    binary_src_wr_addr = '0;
    binary_src_wr_data = '0;
    binary_src_rd0_addr = '0;
    binary_src_rd1_addr = '0;
    binary_src_rd2_addr = '0;
    binary_src_rd3_addr = '0;

    if (binary_src_load_pending) begin
      line_base_u = $unsigned(binary_src_load_addr) * SCRATCH_LINE_COEFFS;
      binary_src_wr_en = 1'b1;
      binary_src_wr_addr = binary_src_load_addr;
      for (coeff_idx_local = 0; coeff_idx_local < SCRATCH_LINE_COEFFS; coeff_idx_local++) begin
        if ((line_base_u + coeff_idx_local) < active_n) begin
          binary_src_wr_data[coeff_idx_local*COEFF_W +: COEFF_W] =
            vec_a_data_reg[(line_base_u + coeff_idx_local)*COEFF_W +: COEFF_W];
        end
      end
    end

    if ((state == ST_RUN_DECODE) &&
        !binary_chunk_decode_compare_pending &&
        !binary_chunk_decode_metric_pending &&
        !binary_chunk_decode_pending &&
        !binary_chunk_reduce_pending &&
        !binary_chunk_reduce2_pending &&
        !binary_write_pending) begin
      phase_row_base_u = $unsigned(binary_phase_row_base);

      if (!binary_chunk_cache_pending &&
          !binary_chunk_decode_c23_pending) begin
        c0_base_u = phase_row_base_u;
        c1_base_u = phase_row_base_u + binary_chunk_active_ring_n;

        cur_line_u = c0_base_u / SCRATCH_LINE_COEFFS;
        next_line_u = ((cur_line_u + 1) < SCRATCH_LINE_COUNT) ? (cur_line_u + 1) : cur_line_u;
        binary_src_rd0_addr = SCRATCH_LINE_ADDR_W'(cur_line_u);
        binary_src_rd1_addr = SCRATCH_LINE_ADDR_W'(next_line_u);

        cur_line_u = c1_base_u / SCRATCH_LINE_COEFFS;
        next_line_u = ((cur_line_u + 1) < SCRATCH_LINE_COUNT) ? (cur_line_u + 1) : cur_line_u;
        binary_src_rd2_addr = SCRATCH_LINE_ADDR_W'(cur_line_u);
        binary_src_rd3_addr = SCRATCH_LINE_ADDR_W'(next_line_u);
      end else if (binary_chunk_cache_pending &&
                   !binary_chunk_decode_c23_pending) begin
        c2_base_u = phase_row_base_u + (2 * binary_chunk_active_ring_n);
        c3_base_u = phase_row_base_u + (3 * binary_chunk_active_ring_n);

        cur_line_u = c2_base_u / SCRATCH_LINE_COEFFS;
        next_line_u = ((cur_line_u + 1) < SCRATCH_LINE_COUNT) ? (cur_line_u + 1) : cur_line_u;
        binary_src_rd0_addr = SCRATCH_LINE_ADDR_W'(cur_line_u);
        binary_src_rd1_addr = SCRATCH_LINE_ADDR_W'(next_line_u);

        cur_line_u = c3_base_u / SCRATCH_LINE_COEFFS;
        next_line_u = ((cur_line_u + 1) < SCRATCH_LINE_COUNT) ? (cur_line_u + 1) : cur_line_u;
        binary_src_rd2_addr = SCRATCH_LINE_ADDR_W'(cur_line_u);
        binary_src_rd3_addr = SCRATCH_LINE_ADDR_W'(next_line_u);
      end
    end
  end

  always_comb begin
    int unsigned coeff_base;
    int unsigned coeff_base_hi;
    int unsigned row_base_u;
    int unsigned coeff_base_next_u;
    int unsigned coeff_base_hi_next_u;
    int unsigned c0_base_u;
    int unsigned c1_base_u;
    int unsigned c2_base_u;
    int unsigned c3_base_u;
    int unsigned c0_next_u;
    int unsigned c1_next_u;
    int unsigned c2_next_u;
    int unsigned c3_next_u;

    coeff_base = $unsigned(col_ptr);
    coeff_base_hi = coeff_base + active_n2;
    row_base_u = $unsigned(binary_phase_row_base);
    coeff_base_next_u =
      (((coeff_base / SCRATCH_LINE_COEFFS) + 1) < SCRATCH_LINE_COUNT) ?
      ((coeff_base / SCRATCH_LINE_COEFFS) + 1) :
      (coeff_base / SCRATCH_LINE_COEFFS);
    coeff_base_hi_next_u =
      (((coeff_base_hi / SCRATCH_LINE_COEFFS) + 1) < SCRATCH_LINE_COUNT) ?
      ((coeff_base_hi / SCRATCH_LINE_COEFFS) + 1) :
      (coeff_base_hi / SCRATCH_LINE_COEFFS);
    c0_base_u = row_base_u;
    c1_base_u = row_base_u + binary_chunk_active_ring_n;
    c2_base_u = row_base_u + (2 * binary_chunk_active_ring_n);
    c3_base_u = row_base_u + (3 * binary_chunk_active_ring_n);
    c0_next_u = (((c0_base_u / SCRATCH_LINE_COEFFS) + 1) < SCRATCH_LINE_COUNT) ?
                ((c0_base_u / SCRATCH_LINE_COEFFS) + 1) :
                (c0_base_u / SCRATCH_LINE_COEFFS);
    c1_next_u = (((c1_base_u / SCRATCH_LINE_COEFFS) + 1) < SCRATCH_LINE_COUNT) ?
                ((c1_base_u / SCRATCH_LINE_COEFFS) + 1) :
                (c1_base_u / SCRATCH_LINE_COEFFS);
    c2_next_u = (((c2_base_u / SCRATCH_LINE_COEFFS) + 1) < SCRATCH_LINE_COUNT) ?
                ((c2_base_u / SCRATCH_LINE_COEFFS) + 1) :
                (c2_base_u / SCRATCH_LINE_COEFFS);
    c3_next_u = (((c3_base_u / SCRATCH_LINE_COEFFS) + 1) < SCRATCH_LINE_COUNT) ?
                ((c3_base_u / SCRATCH_LINE_COEFFS) + 1) :
                (c3_base_u / SCRATCH_LINE_COEFFS);

    dec_post_t0_wr_en = 1'b0;
    dec_post_t0_wr_addr = '0;
    dec_post_t0_wr_data = '0;
    dec_post_t0_rd0_addr = '0;
    dec_post_t0_rd1_addr = '0;
    dec_post_t0_rd2_addr = '0;
    dec_post_t0_rd3_addr = '0;

    if ((state == ST_RUN_DEC_POST_A_MOD2) &&
        !unary_prep_pending &&
        !binary_write_pending) begin
      dec_post_t0_rd0_addr = SCRATCH_LINE_ADDR_W'(coeff_base / SCRATCH_LINE_COEFFS);
      dec_post_t0_rd1_addr = SCRATCH_LINE_ADDR_W'(coeff_base_next_u);
      dec_post_t0_rd2_addr = SCRATCH_LINE_ADDR_W'(coeff_base_hi / SCRATCH_LINE_COEFFS);
      dec_post_t0_rd3_addr = SCRATCH_LINE_ADDR_W'(coeff_base_hi_next_u);
    end else if ((state == ST_RUN_DEC_POST_DECODE) &&
                 !binary_chunk_cache_pending &&
                 !binary_chunk_decode_c23_pending &&
                 !binary_chunk_decode_compare_pending &&
                 !binary_chunk_decode_metric_pending &&
                 !binary_chunk_decode_pending &&
                 !binary_chunk_reduce_pending &&
                 !binary_chunk_reduce2_pending &&
                 !binary_write_pending) begin
      dec_post_t0_rd0_addr = SCRATCH_LINE_ADDR_W'(c0_base_u / SCRATCH_LINE_COEFFS);
      dec_post_t0_rd1_addr = SCRATCH_LINE_ADDR_W'(c0_next_u);
      dec_post_t0_rd2_addr = SCRATCH_LINE_ADDR_W'(c1_base_u / SCRATCH_LINE_COEFFS);
      dec_post_t0_rd3_addr = SCRATCH_LINE_ADDR_W'(c1_next_u);
    end else if ((state == ST_RUN_DEC_POST_DECODE) &&
                 binary_chunk_cache_pending &&
                 !binary_chunk_decode_c23_pending &&
                 !binary_chunk_decode_compare_pending &&
                 !binary_chunk_decode_metric_pending &&
                 !binary_chunk_decode_pending &&
                 !binary_chunk_reduce_pending &&
                 !binary_chunk_reduce2_pending &&
                 !binary_write_pending) begin
      dec_post_t0_rd0_addr = SCRATCH_LINE_ADDR_W'(c2_base_u / SCRATCH_LINE_COEFFS);
      dec_post_t0_rd1_addr = SCRATCH_LINE_ADDR_W'(c2_next_u);
      dec_post_t0_rd2_addr = SCRATCH_LINE_ADDR_W'(c3_base_u / SCRATCH_LINE_COEFFS);
      dec_post_t0_rd3_addr = SCRATCH_LINE_ADDR_W'(c3_next_u);
    end

    if ((state == ST_RUN_CT_DECOMP ||
         state == ST_RUN_MSG_UNPACK ||
         state == ST_RUN_MSG_PACK ||
         state == ST_RUN_T0 ||
         state == ST_RUN_A_MOD2 ||
         state == ST_RUN_POLY_ADD ||
         state == ST_RUN_ENC_POST ||
         state == ST_RUN_DEC_POST_T0 ||
         state == ST_RUN_DEC_POST_A_MOD2) &&
        binary_write_pending) begin
      if (unary_write_dec_t0) begin
        dec_post_t0_wr_en = 1'b1;
        dec_post_t0_wr_addr = SCRATCH_LINE_ADDR_W'(coeff_base / SCRATCH_LINE_COEFFS);
        dec_post_t0_wr_data = binary_stage_data_reg[SCRATCH_LINE_W-1:0];
      end
    end
  end

  always_comb begin
    binary_phase_row_base = row_ptr + (xor_phase * BINARY_XOR_PHASE_LANES);
    binary_phase_col_base = col_ptr + (col_phase * BINARY_CHUNK_COL_LANES);
    binary_phase_last = (xor_phase == (BINARY_XOR_PHASES - 1));
    binary_col_phase_last = ((col_phase + 1) * BINARY_CHUNK_COL_LANES >= active_bin_col_lanes);

    binary_chunk_op = BINARY_CHUNK_OP_R2;
    binary_chunk_acc_vec = '0;
    binary_chunk_sel_vec = '0;
    binary_chunk_active_ring_n = '0;
    binary_chunk_active_acc_n = '0;

    unary_state_active = 1'b0;
    unary_stage_op = STAGE_OP_NONE;
    unary_write_limit = active_n;
    unary_write_dec_t0 = 1'b0;
    unary_write_dec_a_mod2 = 1'b0;
    unary_done_state = ST_DONE;
    unary_reset_iterators_on_done = 1'b0;
    unary_pipe_active = 1'b0;
    unary_pipe_needs_mont = 1'b0;

    chunk_state_active = 1'b0;
    chunk_write_limit = active_n2;
    chunk_row_limit = active_n2;
    chunk_done_state = ST_DONE;

    unique case (state)
      ST_RUN_R2: begin
        chunk_state_active = 1'b1;
        chunk_write_limit = active_n2;
        chunk_row_limit = active_n2;
        binary_chunk_op = BINARY_CHUNK_OP_R2;
        binary_chunk_acc_vec = vec_r_data;
        binary_chunk_sel_vec = vec_a_data_reg;
        binary_chunk_active_ring_n = active_n2;
        binary_chunk_active_acc_n = active_n2;
      end
      ST_RUN_DECODE: begin
        chunk_state_active = 1'b1;
        chunk_write_limit = active_n2;
        chunk_row_limit = active_n4;
        binary_chunk_op = BINARY_CHUNK_OP_DECODE;
        binary_chunk_acc_vec = vec_r_data;
        binary_chunk_sel_vec = vec_a_data_reg;
        binary_chunk_active_ring_n = active_n4;
        binary_chunk_active_acc_n = active_n2;
      end
      ST_RUN_CT_DECOMP: begin
        unary_state_active = 1'b1;
        unary_stage_op = STAGE_OP_CT_DECOMP;
        unary_write_limit = active_n;
        unary_pipe_active = 1'b1;
      end
      ST_RUN_MSG_UNPACK: begin
        unary_state_active = 1'b1;
        unary_stage_op = STAGE_OP_MSG_UNPACK;
        unary_write_limit = active_n;
      end
      ST_RUN_MSG_PACK: begin
        unary_state_active = 1'b1;
        unary_stage_op = STAGE_OP_MSG_PACK;
        unary_write_limit = active_msg_bytes;
      end
      ST_RUN_T0: begin
        unary_state_active = 1'b1;
        unary_stage_op = STAGE_OP_T0;
        unary_write_limit = active_n;
        unary_pipe_active = 1'b1;
        unary_pipe_needs_mont = 1'b1;
      end
      ST_RUN_A_MOD2: begin
        unary_state_active = 1'b1;
        unary_stage_op = STAGE_OP_A_MOD2;
        unary_write_limit = active_n;
      end
      ST_RUN_POLY_ADD: begin
        unary_state_active = 1'b1;
        unary_stage_op = STAGE_OP_POLY_ADD;
        unary_write_limit = active_n;
      end
      ST_RUN_ENC_POST: begin
        unary_state_active = 1'b1;
        unary_stage_op = STAGE_OP_ENC_POST;
        unary_write_limit = active_n;
        unary_pipe_active = 1'b1;
        unary_pipe_needs_mont = 1'b1;
      end
      ST_RUN_DEC_POST_T0: begin
        unary_state_active = 1'b1;
        unary_stage_op = STAGE_OP_T0;
        unary_write_limit = active_n;
        unary_write_dec_t0 = 1'b1;
        unary_done_state = ST_RUN_DEC_POST_A_MOD2;
        unary_reset_iterators_on_done = 1'b1;
        unary_pipe_active = 1'b1;
        unary_pipe_needs_mont = 1'b1;
      end
      ST_RUN_DEC_POST_A_MOD2: begin
        unary_state_active = 1'b1;
        unary_stage_op = STAGE_OP_DEC_A_MOD2;
        unary_write_limit = active_n2;
        unary_write_dec_a_mod2 = 1'b1;
        unary_done_state = ST_RUN_DEC_POST_R2;
        unary_reset_iterators_on_done = 1'b1;
      end
      ST_RUN_DEC_POST_R2: begin
        chunk_state_active = 1'b1;
        chunk_write_limit = active_n4;
        chunk_row_limit = active_n2;
        chunk_done_state = ST_RUN_DEC_POST_DECODE;
        binary_chunk_op = BINARY_CHUNK_OP_R2;
        binary_chunk_acc_vec = vec_r_data;
        binary_chunk_active_ring_n = active_n2;
        binary_chunk_active_acc_n = active_n4;
      end
      ST_RUN_DEC_POST_DECODE: begin
        chunk_state_active = 1'b1;
        chunk_write_limit = active_n4;
        chunk_row_limit = active_n4;
        binary_chunk_op = BINARY_CHUNK_OP_DECODE;
        binary_chunk_acc_vec = vec_r_data;
        binary_chunk_active_ring_n = active_n4;
        binary_chunk_active_acc_n = active_n4;
      end
      default: begin
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      binary_src_rd0_data_reg <= '0;
      binary_src_rd1_data_reg <= '0;
      binary_src_rd2_data_reg <= '0;
      binary_src_rd3_data_reg <= '0;
    end else begin
      if (binary_src_wr_en) begin
        binary_src_mem_rd0[binary_src_wr_addr] <= binary_src_wr_data;
        binary_src_mem_rd1[binary_src_wr_addr] <= binary_src_wr_data;
        binary_src_mem_rd2[binary_src_wr_addr] <= binary_src_wr_data;
        binary_src_mem_rd3[binary_src_wr_addr] <= binary_src_wr_data;
      end

      binary_src_rd0_data_reg <= binary_src_mem_rd0[binary_src_rd0_addr];
      binary_src_rd1_data_reg <= binary_src_mem_rd1[binary_src_rd1_addr];
      binary_src_rd2_data_reg <= binary_src_mem_rd2[binary_src_rd2_addr];
      binary_src_rd3_data_reg <= binary_src_mem_rd3[binary_src_rd3_addr];
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      dec_post_t0_rd0_data_reg <= '0;
      dec_post_t0_rd1_data_reg <= '0;
      dec_post_t0_rd2_data_reg <= '0;
      dec_post_t0_rd3_data_reg <= '0;
    end else begin
      if (dec_post_t0_wr_en) begin
        dec_post_t0_mem_rd0[dec_post_t0_wr_addr] <= dec_post_t0_wr_data;
        dec_post_t0_mem_rd1[dec_post_t0_wr_addr] <= dec_post_t0_wr_data;
        dec_post_t0_mem_rd2[dec_post_t0_wr_addr] <= dec_post_t0_wr_data;
        dec_post_t0_mem_rd3[dec_post_t0_wr_addr] <= dec_post_t0_wr_data;
      end

      dec_post_t0_rd0_data_reg <= dec_post_t0_mem_rd0[dec_post_t0_rd0_addr];
      dec_post_t0_rd1_data_reg <= dec_post_t0_mem_rd1[dec_post_t0_rd1_addr];
      dec_post_t0_rd2_data_reg <= dec_post_t0_mem_rd2[dec_post_t0_rd2_addr];
      dec_post_t0_rd3_data_reg <= dec_post_t0_mem_rd3[dec_post_t0_rd3_addr];
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= ST_IDLE;
      cycle_count <= '0;
      row_ptr <= '0;
      col_ptr <= '0;
      xor_phase <= '0;
      col_phase <= '0;
      vec_mode_active <= 1'b0;
      cmd_reg <= CMD_NOP;
      active_n <= '0;
      active_n2 <= '0;
      active_n4 <= '0;
      active_msg_bytes <= '0;
      active_bin_col_lanes <= '0;
      vec_a_data_reg <= '0;
      vec_b_data_reg <= '0;
      vec_r_data <= '0;
      binary_src_load_pending <= 1'b0;
      binary_src_load_addr <= '0;
      dec_post_a_mod2_bits_reg <= '0;
      binary_chunk_cache_pending <= 1'b0;
      binary_chunk_decode_c23_pending <= 1'b0;
      binary_chunk_decode_compare_pending <= 1'b0;
      binary_chunk_decode_pending <= 1'b0;
      binary_chunk_decode_metric_pending <= 1'b0;
      binary_chunk_reduce_pending <= 1'b0;
      binary_chunk_reduce2_pending <= 1'b0;
      binary_write_pending <= 1'b0;
      unary_prep_pending <= 1'b0;
      unary_math_pending <= 1'b0;
      unary_reduce_pending <= 1'b0;
      unary_reduce2_pending <= 1'b0;
      unary_byte_reg <= '0;
      unary_src0_reg <= '0;
      unary_src1_reg <= '0;
      unary_mont_in_reg <= '0;
      unary_mont_u_reg <= '0;
      unary_mont_out_reg <= '0;
      binary_chunk_b_lsb_reg <= '0;
      binary_chunk_acc_seed_reg <= '0;
      binary_chunk_partial_lsb_reg <= '0;
      binary_chunk_partial_mid_lsb_reg <= '0;
      binary_stage_data_reg <= '0;
      vec_out_valid <= 1'b0;
      row_out_valid <= 1'b0;
      row_out_idx <= '0;
      row_out_data <= '0;
      for (idx = 0; idx < BINARY_XOR_PHASE_LANES; idx++) begin
        binary_chunk_row_idx_reg[idx] <= '0;
        binary_chunk_row_sel_idx_reg[idx] <= '0;
        binary_chunk_row_active_reg[idx] <= 1'b0;
        binary_chunk_row_lo_en_reg[idx] <= 1'b0;
        binary_chunk_dec_c0_reg[idx] <= '0;
        binary_chunk_dec_c1_reg[idx] <= '0;
        binary_chunk_dec_c2_reg[idx] <= '0;
        binary_chunk_dec_c3_reg[idx] <= '0;
        binary_chunk_dec_lo_min_reg[idx] <= '0;
        binary_chunk_dec_hi_min_reg[idx] <= '0;
        binary_chunk_dec_lo_sel_idx_reg[idx] <= '0;
        binary_chunk_dec_hi_sel_idx_reg[idx] <= '0;
      end
`ifndef SYNTHESIS
      dec_t0_vec <= '0;
      dec_r2_vec <= '0;
      dec_t2_vec <= '0;
`endif
    end else begin
      state <= state_n;
      vec_out_valid <= (state_n == ST_DONE) && vec_mode_active;
      row_out_valid <= 1'b0;

      unique case (state)
        ST_IDLE: begin
          cycle_count <= '0;
          xor_phase <= '0;
          col_phase <= '0;
          if (start) begin
            row_ptr <= '0;
            col_ptr <= '0;
            vec_mode_active <= vec_in_valid;
            cmd_reg <= cmd;
            active_n <= NTT_N;
            active_n2 <= LOCAL_N2;
            active_n4 <= LOCAL_N4;
            active_msg_bytes <= ZEN_MSG_BYTES;
            active_bin_col_lanes <= BIN_COL_LANES;
            vec_a_data_reg <= vec_a_data;
            vec_b_data_reg <= vec_b_data;
            binary_src_load_pending <= (cmd == CMD_DECODE_HELPER);
            binary_src_load_addr <= '0;
            binary_chunk_cache_pending <= 1'b0;
            binary_chunk_decode_c23_pending <= 1'b0;
            binary_chunk_decode_compare_pending <= 1'b0;
            binary_chunk_decode_pending <= 1'b0;
            binary_chunk_decode_metric_pending <= 1'b0;
            binary_chunk_reduce_pending <= 1'b0;
            binary_chunk_reduce2_pending <= 1'b0;
            binary_write_pending <= 1'b0;
            unary_prep_pending <= 1'b0;
            unary_math_pending <= 1'b0;
            unary_reduce_pending <= 1'b0;
            unary_reduce2_pending <= 1'b0;
            unary_byte_reg <= '0;
            unary_src0_reg <= '0;
            unary_src1_reg <= '0;
            unary_mont_in_reg <= '0;
            unary_mont_u_reg <= '0;
            unary_mont_out_reg <= '0;
            for (idx = 0; idx < LOCAL_N2; idx++) begin
              binary_chunk_b_lsb_reg[idx] <= vec_b_data[idx*COEFF_W];
            end
            binary_chunk_acc_seed_reg <= '0;
            binary_chunk_partial_lsb_reg <= '0;
            binary_chunk_partial_mid_lsb_reg <= '0;
            binary_stage_data_reg <= '0;
            for (idx = 0; idx < BINARY_XOR_PHASE_LANES; idx++) begin
              binary_chunk_row_idx_reg[idx] <= '0;
              binary_chunk_row_sel_idx_reg[idx] <= '0;
              binary_chunk_row_active_reg[idx] <= 1'b0;
              binary_chunk_row_lo_en_reg[idx] <= 1'b0;
              binary_chunk_dec_c0_reg[idx] <= '0;
              binary_chunk_dec_c1_reg[idx] <= '0;
              binary_chunk_dec_c2_reg[idx] <= '0;
              binary_chunk_dec_c3_reg[idx] <= '0;
              binary_chunk_dec_lo_min_reg[idx] <= '0;
              binary_chunk_dec_hi_min_reg[idx] <= '0;
              binary_chunk_dec_lo_sel_idx_reg[idx] <= '0;
              binary_chunk_dec_hi_sel_idx_reg[idx] <= '0;
            end
          end
        end
        ST_PREP: begin
          cycle_count <= '0;
          row_ptr <= '0;
          col_ptr <= '0;
          xor_phase <= '0;
          col_phase <= '0;
          vec_r_data <= '0;
          if (binary_src_load_pending) begin
            if ((binary_src_load_addr + 1) < SCRATCH_LINE_COUNT) begin
              binary_src_load_addr <= binary_src_load_addr + 1'b1;
            end else begin
              binary_src_load_pending <= 1'b0;
            end
          end
          dec_post_a_mod2_bits_reg <= '0;
          binary_chunk_cache_pending <= 1'b0;
          binary_chunk_decode_c23_pending <= 1'b0;
          binary_chunk_decode_compare_pending <= 1'b0;
          binary_chunk_decode_pending <= 1'b0;
          binary_chunk_decode_metric_pending <= 1'b0;
          binary_chunk_reduce_pending <= 1'b0;
          binary_chunk_reduce2_pending <= 1'b0;
          binary_write_pending <= 1'b0;
          unary_prep_pending <= 1'b0;
          unary_math_pending <= 1'b0;
          unary_reduce_pending <= 1'b0;
          unary_reduce2_pending <= 1'b0;
          if (!binary_src_load_pending) begin
            binary_src_load_addr <= '0;
          end
          unary_byte_reg <= '0;
          unary_src0_reg <= '0;
          unary_src1_reg <= '0;
          unary_mont_in_reg <= '0;
          unary_mont_u_reg <= '0;
          unary_mont_out_reg <= '0;
          for (idx = 0; idx < LOCAL_N2; idx++) begin
            binary_chunk_b_lsb_reg[idx] <= vec_b_data_reg[idx*COEFF_W];
          end
          binary_chunk_acc_seed_reg <= '0;
          binary_chunk_partial_lsb_reg <= '0;
          binary_chunk_partial_mid_lsb_reg <= '0;
          binary_stage_data_reg <= '0;
          for (idx = 0; idx < BINARY_XOR_PHASE_LANES; idx++) begin
            binary_chunk_row_idx_reg[idx] <= '0;
            binary_chunk_row_sel_idx_reg[idx] <= '0;
            binary_chunk_row_active_reg[idx] <= 1'b0;
            binary_chunk_row_lo_en_reg[idx] <= 1'b0;
            binary_chunk_dec_c0_reg[idx] <= '0;
            binary_chunk_dec_c1_reg[idx] <= '0;
            binary_chunk_dec_c2_reg[idx] <= '0;
            binary_chunk_dec_c3_reg[idx] <= '0;
            binary_chunk_dec_lo_min_reg[idx] <= '0;
            binary_chunk_dec_hi_min_reg[idx] <= '0;
            binary_chunk_dec_lo_sel_idx_reg[idx] <= '0;
            binary_chunk_dec_hi_sel_idx_reg[idx] <= '0;
          end
`ifndef SYNTHESIS
          dec_t0_vec <= '0;
          dec_r2_vec <= '0;
          dec_t2_vec <= '0;
          if (cmd_reg == CMD_DEC_POSTPROC) begin
            dec_t0_vec <= dec_t0_debug_vec;
            dec_r2_vec <= dec_r2_debug_vec;
            dec_t2_vec <= dec_t2_debug_vec;
          end
`endif
        end
        ST_RUN_R2,
        ST_RUN_DECODE,
        ST_RUN_DEC_POST_R2,
        ST_RUN_DEC_POST_DECODE: begin
          cycle_count <= cycle_count + 16'd1;
          if (binary_chunk_op == BINARY_CHUNK_OP_DECODE) begin
            if (!binary_chunk_cache_pending &&
                !binary_chunk_decode_c23_pending &&
                !binary_chunk_decode_compare_pending &&
                !binary_chunk_decode_metric_pending &&
                !binary_chunk_decode_pending &&
                !binary_chunk_reduce_pending &&
                !binary_chunk_reduce2_pending &&
                !binary_write_pending) begin
              for (idx = 0; idx < BINARY_XOR_PHASE_LANES; idx++) begin
                int row_idx_local;

                binary_chunk_row_idx_reg[idx] <= binary_chunk_row_idx_cache[idx];
                binary_chunk_row_sel_idx_reg[idx] <= '0;
                binary_chunk_row_active_reg[idx] <= binary_chunk_row_active_cache[idx];
                binary_chunk_row_lo_en_reg[idx] <= 1'b0;

                if (binary_chunk_row_active_cache[idx]) begin
                  row_idx_local = $unsigned(binary_chunk_row_idx_cache[idx]);
                  binary_chunk_dec_c0_reg[idx] <= '0;
                  binary_chunk_dec_c1_reg[idx] <= '0;
                  binary_chunk_dec_c2_reg[idx] <= '0;
                  binary_chunk_dec_c3_reg[idx] <= '0;
                end else begin
                  binary_chunk_dec_c0_reg[idx] <= '0;
                  binary_chunk_dec_c1_reg[idx] <= '0;
                  binary_chunk_dec_c2_reg[idx] <= '0;
                  binary_chunk_dec_c3_reg[idx] <= '0;
                end
              end
              for (idx = 0; idx < BINARY_CHUNK_COL_LANES; idx++) begin
                if (($unsigned(binary_phase_col_base) + idx) < binary_chunk_active_acc_n) begin
                  binary_chunk_acc_seed_reg[idx] <=
                    vec_r_data[(binary_phase_col_base + idx)*COEFF_W];
                end else begin
                  binary_chunk_acc_seed_reg[idx] <= 1'b0;
                end
              end
              binary_chunk_cache_pending <= 1'b1;
            end else if (binary_chunk_cache_pending &&
                         !binary_chunk_decode_c23_pending &&
                         !binary_chunk_decode_compare_pending &&
                         !binary_chunk_decode_metric_pending &&
                         !binary_chunk_decode_pending &&
                         !binary_chunk_reduce_pending &&
                         !binary_chunk_reduce2_pending &&
                         !binary_write_pending) begin
              for (idx = 0; idx < BINARY_XOR_PHASE_LANES; idx++) begin
                if (binary_chunk_row_active_reg[idx]) begin
                  int unsigned c0_off;
                  int unsigned c1_off;

                  c0_off = ($unsigned(binary_phase_row_base) % SCRATCH_LINE_COEFFS) + idx;
                  c1_off =
                    (($unsigned(binary_phase_row_base) + binary_chunk_active_ring_n) %
                     SCRATCH_LINE_COEFFS) + idx;

                  if (state == ST_RUN_DEC_POST_DECODE) begin
                    if (c0_off < SCRATCH_LINE_COEFFS) begin
                      binary_chunk_dec_c0_reg[idx] <=
                        dec_post_t0_rd0_data_reg[c0_off*COEFF_W +: COEFF_W];
                    end else begin
                      binary_chunk_dec_c0_reg[idx] <=
                        dec_post_t0_rd1_data_reg[(c0_off - SCRATCH_LINE_COEFFS)*COEFF_W +:
                                                 COEFF_W];
                    end

                    if (c1_off < SCRATCH_LINE_COEFFS) begin
                      binary_chunk_dec_c1_reg[idx] <=
                        dec_post_t0_rd2_data_reg[c1_off*COEFF_W +: COEFF_W];
                    end else begin
                      binary_chunk_dec_c1_reg[idx] <=
                        dec_post_t0_rd3_data_reg[(c1_off - SCRATCH_LINE_COEFFS)*COEFF_W +:
                                                 COEFF_W];
                    end
                  end else begin
                    if (c0_off < SCRATCH_LINE_COEFFS) begin
                      binary_chunk_dec_c0_reg[idx] <=
                        binary_src_rd0_data_reg[c0_off*COEFF_W +: COEFF_W];
                    end else begin
                      binary_chunk_dec_c0_reg[idx] <=
                        binary_src_rd1_data_reg[(c0_off - SCRATCH_LINE_COEFFS)*COEFF_W +:
                                                COEFF_W];
                    end

                    if (c1_off < SCRATCH_LINE_COEFFS) begin
                      binary_chunk_dec_c1_reg[idx] <=
                        binary_src_rd2_data_reg[c1_off*COEFF_W +: COEFF_W];
                    end else begin
                      binary_chunk_dec_c1_reg[idx] <=
                        binary_src_rd3_data_reg[(c1_off - SCRATCH_LINE_COEFFS)*COEFF_W +:
                                                COEFF_W];
                    end
                  end
                  binary_chunk_dec_c2_reg[idx] <= '0;
                  binary_chunk_dec_c3_reg[idx] <= '0;
                end else begin
                  binary_chunk_dec_c0_reg[idx] <= '0;
                  binary_chunk_dec_c1_reg[idx] <= '0;
                  binary_chunk_dec_c2_reg[idx] <= '0;
                  binary_chunk_dec_c3_reg[idx] <= '0;
                end
              end
              binary_chunk_cache_pending <= 1'b0;
              binary_chunk_decode_c23_pending <= 1'b1;
            end else if (!binary_chunk_cache_pending &&
                         binary_chunk_decode_c23_pending &&
                         !binary_chunk_decode_compare_pending &&
                         !binary_chunk_decode_metric_pending &&
                         !binary_chunk_decode_pending &&
                         !binary_chunk_reduce_pending &&
                         !binary_chunk_reduce2_pending &&
                         !binary_write_pending) begin
              for (idx = 0; idx < BINARY_XOR_PHASE_LANES; idx++) begin
                if (binary_chunk_row_active_reg[idx]) begin
                  int unsigned c2_off;
                  int unsigned c3_off;

                  c2_off =
                    (($unsigned(binary_phase_row_base) + (2 * binary_chunk_active_ring_n)) %
                     SCRATCH_LINE_COEFFS) + idx;
                  c3_off =
                    (($unsigned(binary_phase_row_base) + (3 * binary_chunk_active_ring_n)) %
                     SCRATCH_LINE_COEFFS) + idx;

                  if (state == ST_RUN_DEC_POST_DECODE) begin
                    if (c2_off < SCRATCH_LINE_COEFFS) begin
                      binary_chunk_dec_c2_reg[idx] <=
                        dec_post_t0_rd0_data_reg[c2_off*COEFF_W +: COEFF_W];
                    end else begin
                      binary_chunk_dec_c2_reg[idx] <=
                        dec_post_t0_rd1_data_reg[(c2_off - SCRATCH_LINE_COEFFS)*COEFF_W +:
                                                 COEFF_W];
                    end

                    if (c3_off < SCRATCH_LINE_COEFFS) begin
                      binary_chunk_dec_c3_reg[idx] <=
                        dec_post_t0_rd2_data_reg[c3_off*COEFF_W +: COEFF_W];
                    end else begin
                      binary_chunk_dec_c3_reg[idx] <=
                        dec_post_t0_rd3_data_reg[(c3_off - SCRATCH_LINE_COEFFS)*COEFF_W +:
                                                 COEFF_W];
                    end
                  end else begin
                    if (c2_off < SCRATCH_LINE_COEFFS) begin
                      binary_chunk_dec_c2_reg[idx] <=
                        binary_src_rd0_data_reg[c2_off*COEFF_W +: COEFF_W];
                    end else begin
                      binary_chunk_dec_c2_reg[idx] <=
                        binary_src_rd1_data_reg[(c2_off - SCRATCH_LINE_COEFFS)*COEFF_W +:
                                                COEFF_W];
                    end

                    if (c3_off < SCRATCH_LINE_COEFFS) begin
                      binary_chunk_dec_c3_reg[idx] <=
                        binary_src_rd2_data_reg[c3_off*COEFF_W +: COEFF_W];
                    end else begin
                      binary_chunk_dec_c3_reg[idx] <=
                        binary_src_rd3_data_reg[(c3_off - SCRATCH_LINE_COEFFS)*COEFF_W +:
                                                COEFF_W];
                    end
                  end
                end else begin
                  binary_chunk_dec_c2_reg[idx] <= '0;
                  binary_chunk_dec_c3_reg[idx] <= '0;
                end
              end
              binary_chunk_decode_c23_pending <= 1'b0;
              binary_chunk_decode_compare_pending <= 1'b1;
            end else if (!binary_chunk_cache_pending &&
                         !binary_chunk_decode_c23_pending &&
                         binary_chunk_decode_compare_pending &&
                         !binary_chunk_decode_metric_pending &&
                         !binary_chunk_decode_pending &&
                         !binary_chunk_reduce_pending &&
                         !binary_chunk_reduce2_pending &&
                         !binary_write_pending) begin
              for (idx = 0; idx < BINARY_XOR_PHASE_LANES; idx++) begin
                int row_idx_local;
                int parity_sel_idx0;
                int parity_sel_idx1;
                int c0_local;
                int c1_local;
                int c2_local;
                int c3_local;
                logic parity_bit_local;

                binary_chunk_dec_lo_min_reg[idx] <= '0;
                binary_chunk_dec_hi_min_reg[idx] <= '0;
                binary_chunk_dec_lo_sel_idx_reg[idx] <= '0;
                binary_chunk_dec_hi_sel_idx_reg[idx] <= '0;
                if (binary_chunk_row_active_reg[idx]) begin
                  row_idx_local = $unsigned(binary_chunk_row_idx_reg[idx]);
                  parity_sel_idx0 = 0;
                  parity_sel_idx1 = 0;
                  c0_local = $signed(binary_chunk_dec_c0_reg[idx]);
                  c1_local = $signed(binary_chunk_dec_c1_reg[idx]);
                  c2_local = $signed(binary_chunk_dec_c2_reg[idx]);
                  c3_local = $signed(binary_chunk_dec_c3_reg[idx]);
                  parity_bit_local =
                    binary_chunk_dec_c0_reg[idx][0] ^
                    binary_chunk_dec_c1_reg[idx][0] ^
                    c2_local[0] ^
                    c3_local[0];

                  if (c0_local >= 0) c0_local = (ZEN_Q / 2) - c0_local;
                  else c0_local = (ZEN_Q / 2) + c0_local;
                  if (c1_local >= 0) c1_local = (ZEN_Q / 2) - c1_local;
                  else c1_local = (ZEN_Q / 2) + c1_local;
                  if (c2_local >= 0) c2_local = (ZEN_Q / 2) - c2_local;
                  else c2_local = (ZEN_Q / 2) + c2_local;
                  if (c3_local >= 0) c3_local = (ZEN_Q / 2) - c3_local;
                  else c3_local = (ZEN_Q / 2) + c3_local;

                  if (c0_local > c2_local) c0_local = c2_local;
                  if (c1_local > c3_local) c1_local = c3_local;

                  if (parity_bit_local != 0) begin
                    parity_sel_idx0 = row_idx_local;
                    parity_sel_idx1 = row_idx_local + binary_chunk_active_ring_n;
                  end

                  binary_chunk_dec_lo_min_reg[idx] <= c0_local[COEFF_W-1:0];
                  binary_chunk_dec_hi_min_reg[idx] <= c1_local[COEFF_W-1:0];
                  binary_chunk_dec_lo_sel_idx_reg[idx] <= parity_sel_idx0[ADDR_W:0];
                  binary_chunk_dec_hi_sel_idx_reg[idx] <= parity_sel_idx1[ADDR_W:0];
                end
              end
              binary_chunk_decode_compare_pending <= 1'b0;
              binary_chunk_decode_metric_pending <= 1'b1;
            end else if (!binary_chunk_cache_pending &&
                         !binary_chunk_decode_compare_pending &&
                         binary_chunk_decode_metric_pending &&
                         !binary_chunk_decode_pending &&
                         !binary_chunk_reduce_pending &&
                         !binary_chunk_reduce2_pending &&
                         !binary_write_pending) begin
              for (idx = 0; idx < BINARY_XOR_PHASE_LANES; idx++) begin
                binary_chunk_row_sel_idx_reg[idx] <= '0;
                if (binary_chunk_row_active_reg[idx]) begin
                  if (binary_chunk_dec_lo_min_reg[idx] <= binary_chunk_dec_hi_min_reg[idx]) begin
                    binary_chunk_row_sel_idx_reg[idx] <= binary_chunk_dec_lo_sel_idx_reg[idx];
                  end else begin
                    binary_chunk_row_sel_idx_reg[idx] <= binary_chunk_dec_hi_sel_idx_reg[idx];
                  end
                end
              end
              binary_chunk_decode_metric_pending <= 1'b0;
              binary_chunk_decode_pending <= 1'b1;
            end else if (!binary_chunk_cache_pending &&
                         !binary_chunk_decode_compare_pending &&
                         !binary_chunk_decode_metric_pending &&
                         binary_chunk_decode_pending &&
                         !binary_chunk_reduce_pending &&
                         !binary_chunk_reduce2_pending &&
                         !binary_write_pending) begin
              binary_chunk_partial_lsb_reg <= binary_chunk_partial_lsb;
              binary_chunk_decode_pending <= 1'b0;
              binary_chunk_reduce_pending <= 1'b1;
            end else if (!binary_chunk_cache_pending &&
                         !binary_chunk_decode_compare_pending &&
                         !binary_chunk_decode_metric_pending &&
                         !binary_chunk_decode_pending &&
                         binary_chunk_reduce_pending &&
                         !binary_chunk_reduce2_pending &&
                         !binary_write_pending) begin
              binary_chunk_partial_mid_lsb_reg <= binary_chunk_partial_mid_lsb;
              binary_chunk_reduce_pending <= 1'b0;
              binary_chunk_reduce2_pending <= 1'b1;
            end else if (!binary_chunk_cache_pending &&
                         !binary_chunk_decode_compare_pending &&
                         !binary_chunk_decode_metric_pending &&
                         !binary_chunk_decode_pending &&
                         !binary_chunk_reduce_pending &&
                         binary_chunk_reduce2_pending &&
                         !binary_write_pending) begin
              binary_stage_data_reg <= '0;
              for (idx = 0; idx < BINARY_CHUNK_COL_LANES; idx++) begin
                if ((((col_phase * BINARY_CHUNK_COL_LANES) + idx) < active_bin_col_lanes) &&
                    ((binary_phase_col_base + idx) < chunk_write_limit)) begin
                  binary_stage_data_reg[idx*COEFF_W +: COEFF_W] <=
                    binary_chunk_data[idx*COEFF_W +: COEFF_W];
                end
              end
              binary_chunk_reduce_pending <= 1'b0;
              binary_write_pending <= 1'b1;
            end else begin
              for (idx = 0; idx < BINARY_CHUNK_COL_LANES; idx++) begin
                if ((((col_phase * BINARY_CHUNK_COL_LANES) + idx) < active_bin_col_lanes) &&
                    ((binary_phase_col_base + idx) < chunk_write_limit)) begin
                  vec_r_data[(binary_phase_col_base + idx)*COEFF_W +: COEFF_W] <=
                    binary_stage_data_reg[idx*COEFF_W +: COEFF_W];
                end
              end
              binary_chunk_cache_pending <= 1'b0;
              binary_chunk_decode_c23_pending <= 1'b0;
              binary_chunk_decode_compare_pending <= 1'b0;
              binary_chunk_decode_metric_pending <= 1'b0;
              binary_chunk_decode_pending <= 1'b0;
              binary_chunk_reduce_pending <= 1'b0;
              binary_chunk_reduce2_pending <= 1'b0;
              binary_write_pending <= 1'b0;
              if (!binary_col_phase_last) begin
                col_phase <= col_phase + 1'b1;
              end else begin
                col_phase <= '0;
                if (!binary_phase_last) begin
                  xor_phase <= xor_phase + 1'b1;
                end else begin
                  xor_phase <= '0;
                  if (col_ptr + active_bin_col_lanes < chunk_write_limit) begin
                    col_ptr <= col_ptr + active_bin_col_lanes;
                  end else begin
                    col_ptr <= '0;
                    if (row_ptr + XOR_LANES < chunk_row_limit) begin
                      row_ptr <= row_ptr + XOR_LANES;
                    end else begin
                      row_ptr <= '0;
                    end
                  end
                end
              end
            end
          end else begin
            if (!binary_chunk_cache_pending &&
                !binary_chunk_decode_compare_pending &&
                !binary_chunk_reduce_pending &&
                !binary_chunk_reduce2_pending &&
                !binary_write_pending) begin
              for (idx = 0; idx < BINARY_XOR_PHASE_LANES; idx++) begin
                binary_chunk_row_idx_reg[idx] <= binary_chunk_row_idx_cache[idx];
                binary_chunk_row_sel_idx_reg[idx] <= binary_chunk_row_sel_idx_cache[idx];
                binary_chunk_row_active_reg[idx] <= binary_chunk_row_active_cache[idx];
                binary_chunk_row_lo_en_reg[idx] <= binary_chunk_row_lo_en_cache[idx];
              end
              for (idx = 0; idx < BINARY_CHUNK_COL_LANES; idx++) begin
                if (($unsigned(binary_phase_col_base) + idx) < binary_chunk_active_acc_n) begin
                  binary_chunk_acc_seed_reg[idx] <=
                    vec_r_data[(binary_phase_col_base + idx)*COEFF_W];
                end else begin
                  binary_chunk_acc_seed_reg[idx] <= 1'b0;
                end
              end
              binary_chunk_cache_pending <= 1'b1;
            end else if (binary_chunk_cache_pending &&
                         !binary_chunk_decode_compare_pending &&
                         !binary_chunk_reduce_pending &&
                         !binary_chunk_reduce2_pending &&
                         !binary_write_pending) begin
              binary_chunk_partial_lsb_reg <= binary_chunk_partial_lsb;
              binary_chunk_cache_pending <= 1'b0;
              binary_chunk_reduce_pending <= 1'b1;
            end else if (!binary_chunk_cache_pending &&
                         !binary_chunk_decode_compare_pending &&
                         binary_chunk_reduce_pending &&
                         !binary_chunk_reduce2_pending &&
                         !binary_write_pending) begin
              binary_chunk_partial_mid_lsb_reg <= binary_chunk_partial_mid_lsb;
              binary_chunk_reduce_pending <= 1'b0;
              binary_chunk_reduce2_pending <= 1'b1;
            end else if (!binary_chunk_cache_pending &&
                         !binary_chunk_decode_compare_pending &&
                         !binary_chunk_reduce_pending &&
                         binary_chunk_reduce2_pending &&
                         !binary_write_pending) begin
              binary_stage_data_reg <= '0;
              for (idx = 0; idx < BINARY_CHUNK_COL_LANES; idx++) begin
                if ((((col_phase * BINARY_CHUNK_COL_LANES) + idx) < active_bin_col_lanes) &&
                    ((binary_phase_col_base + idx) < chunk_write_limit)) begin
                  binary_stage_data_reg[idx*COEFF_W +: COEFF_W] <=
                    binary_chunk_data[idx*COEFF_W +: COEFF_W];
                end
              end
              binary_chunk_reduce_pending <= 1'b0;
              binary_write_pending <= 1'b1;
            end else begin
              for (idx = 0; idx < BINARY_CHUNK_COL_LANES; idx++) begin
                if ((((col_phase * BINARY_CHUNK_COL_LANES) + idx) < active_bin_col_lanes) &&
                    ((binary_phase_col_base + idx) < chunk_write_limit)) begin
                  vec_r_data[(binary_phase_col_base + idx)*COEFF_W +: COEFF_W] <=
                    binary_stage_data_reg[idx*COEFF_W +: COEFF_W];
                end
              end
              binary_chunk_cache_pending <= 1'b0;
              binary_chunk_decode_c23_pending <= 1'b0;
              binary_chunk_decode_compare_pending <= 1'b0;
              binary_chunk_decode_metric_pending <= 1'b0;
              binary_chunk_reduce_pending <= 1'b0;
              binary_chunk_reduce2_pending <= 1'b0;
              binary_write_pending <= 1'b0;
              if (!binary_col_phase_last) begin
                col_phase <= col_phase + 1'b1;
              end else begin
                col_phase <= '0;
                if (!binary_phase_last) begin
                  xor_phase <= xor_phase + 1'b1;
                end else begin
                  xor_phase <= '0;
                  if (col_ptr + active_bin_col_lanes < chunk_write_limit) begin
                    col_ptr <= col_ptr + active_bin_col_lanes;
                  end else begin
                    col_ptr <= '0;
                    if (row_ptr + XOR_LANES < chunk_row_limit) begin
                      row_ptr <= row_ptr + XOR_LANES;
                    end else begin
                      row_ptr <= '0;
                    end
                  end
                end
              end
            end
          end
        end
        ST_RUN_FAST_INV: begin
          cycle_count <= cycle_count + 16'd1;
          if (fast_inv_row_out_valid) begin
            int row_coeff_idx;
            int coeff_base;
            int coeff_idx;
            row_out_valid <= 1'b1;
            row_out_idx <= fast_inv_row_out_idx;
            row_out_data <= fast_inv_row_out_data;
            coeff_base = $unsigned(fast_inv_row_out_idx) * 16;
            for (row_coeff_idx = 0; row_coeff_idx < 16; row_coeff_idx++) begin
              coeff_idx = coeff_base + row_coeff_idx;
              if (coeff_idx < NTT_N) begin
                vec_r_data[coeff_idx*COEFF_W +: COEFF_W] <=
                  fast_inv_row_out_data[row_coeff_idx*COEFF_W +: COEFF_W];
              end
            end
          end
        end
        ST_RUN_CT_DECOMP,
        ST_RUN_MSG_UNPACK,
        ST_RUN_MSG_PACK,
        ST_RUN_T0,
        ST_RUN_A_MOD2,
        ST_RUN_POLY_ADD,
        ST_RUN_ENC_POST,
        ST_RUN_DEC_POST_T0,
        ST_RUN_DEC_POST_A_MOD2: begin
          cycle_count <= cycle_count + 16'd1;
          if (unary_pipe_active) begin
            if (!unary_prep_pending &&
                !unary_math_pending &&
                !unary_reduce_pending &&
                !unary_reduce2_pending &&
                !binary_write_pending) begin
              unary_byte_reg <= unary_byte_capture;
              unary_src0_reg <= unary_src0_capture;
              unary_src1_reg <= unary_src1_capture;
              unary_prep_pending <= 1'b1;
            end else if (unary_prep_pending &&
                         unary_pipe_needs_mont &&
                         !unary_math_pending &&
                         !unary_reduce_pending &&
                         !unary_reduce2_pending &&
                         !binary_write_pending) begin
              unary_mont_in_reg <= unary_mont_in_data;
              unary_prep_pending <= 1'b0;
              unary_math_pending <= 1'b1;
            end else if (!unary_prep_pending &&
                         unary_math_pending &&
                         unary_pipe_needs_mont &&
                         !unary_reduce_pending &&
                         !unary_reduce2_pending &&
                         !binary_write_pending) begin
              unary_mont_u_reg <= unary_mont_u_data;
              unary_math_pending <= 1'b0;
              unary_reduce_pending <= 1'b1;
            end else if (!unary_prep_pending &&
                         !unary_math_pending &&
                         unary_reduce_pending &&
                         unary_pipe_needs_mont &&
                         !unary_reduce2_pending &&
                         !binary_write_pending) begin
              unary_mont_out_reg <= unary_mont_mid_data;
              unary_reduce_pending <= 1'b0;
              unary_reduce2_pending <= 1'b1;
            end else if (((unary_prep_pending && !unary_pipe_needs_mont) ||
                          (unary_reduce2_pending && unary_pipe_needs_mont)) &&
                         !binary_write_pending) begin
              binary_stage_data_reg <= '0;
              binary_stage_data_reg[XOR_LANES*COEFF_W-1:0] <= unary_pipe_stage_data;
              unary_prep_pending <= 1'b0;
              unary_math_pending <= 1'b0;
              unary_reduce_pending <= 1'b0;
              unary_reduce2_pending <= 1'b0;
              binary_write_pending <= 1'b1;
            end else begin
              for (idx = 0; idx < XOR_LANES; idx++) begin
                if ((col_ptr + idx) < unary_write_limit) begin
                  if (unary_write_dec_a_mod2) begin
                    dec_post_a_mod2_bits_reg[col_ptr + idx] <=
                      binary_stage_data_reg[idx*COEFF_W];
                  end else if (!unary_write_dec_t0) begin
                    vec_r_data[(col_ptr + idx)*COEFF_W +: COEFF_W] <=
                      binary_stage_data_reg[idx*COEFF_W +: COEFF_W];
                  end
                end
              end
              binary_write_pending <= 1'b0;
              unary_reduce2_pending <= 1'b0;
              if (col_ptr + XOR_LANES < unary_write_limit) begin
                col_ptr <= col_ptr + XOR_LANES;
              end else if (unary_reset_iterators_on_done) begin
                col_ptr <= '0;
                row_ptr <= '0;
                xor_phase <= '0;
                col_phase <= '0;
              end
            end
          end else begin
            if (!unary_prep_pending &&
                !binary_write_pending) begin
              if (unary_stage_op != STAGE_OP_DEC_A_MOD2) begin
                unary_byte_reg <= unary_byte_capture;
                unary_src0_reg <= unary_src0_capture;
                unary_src1_reg <= unary_src1_capture;
              end
              unary_prep_pending <= 1'b1;
            end else if (unary_prep_pending &&
                         !binary_write_pending) begin
              binary_stage_data_reg <= '0;
              binary_stage_data_reg[XOR_LANES*COEFF_W-1:0] <= unary_stage_data;
              unary_prep_pending <= 1'b0;
              binary_write_pending <= 1'b1;
            end else begin
              for (idx = 0; idx < XOR_LANES; idx++) begin
                if ((col_ptr + idx) < unary_write_limit) begin
                  if (unary_write_dec_a_mod2) begin
                    dec_post_a_mod2_bits_reg[col_ptr + idx] <=
                      binary_stage_data_reg[idx*COEFF_W];
                  end else if (!unary_write_dec_t0) begin
                    vec_r_data[(col_ptr + idx)*COEFF_W +: COEFF_W] <=
                      binary_stage_data_reg[idx*COEFF_W +: COEFF_W];
                  end
                end
              end
              unary_prep_pending <= 1'b0;
              binary_write_pending <= 1'b0;
              if (col_ptr + XOR_LANES < unary_write_limit) begin
                col_ptr <= col_ptr + XOR_LANES;
              end else if (unary_reset_iterators_on_done) begin
                col_ptr <= '0;
                row_ptr <= '0;
                xor_phase <= '0;
                col_phase <= '0;
              end
            end
          end
        end
        ST_DONE: begin
          vec_mode_active <= 1'b0;
          xor_phase <= '0;
          col_phase <= '0;
          binary_chunk_cache_pending <= 1'b0;
          binary_chunk_decode_c23_pending <= 1'b0;
          binary_chunk_decode_compare_pending <= 1'b0;
          binary_chunk_decode_pending <= 1'b0;
          binary_chunk_decode_metric_pending <= 1'b0;
          binary_chunk_reduce_pending <= 1'b0;
          binary_chunk_reduce2_pending <= 1'b0;
          binary_write_pending <= 1'b0;
          binary_src_load_pending <= 1'b0;
          binary_src_load_addr <= '0;
          unary_prep_pending <= 1'b0;
          unary_math_pending <= 1'b0;
          unary_reduce_pending <= 1'b0;
          unary_reduce2_pending <= 1'b0;
        end
        ST_ERROR: begin
          vec_mode_active <= 1'b0;
          xor_phase <= '0;
          col_phase <= '0;
          binary_chunk_cache_pending <= 1'b0;
          binary_chunk_decode_c23_pending <= 1'b0;
          binary_chunk_decode_compare_pending <= 1'b0;
          binary_chunk_decode_pending <= 1'b0;
          binary_chunk_decode_metric_pending <= 1'b0;
          binary_chunk_reduce_pending <= 1'b0;
          binary_chunk_reduce2_pending <= 1'b0;
          binary_write_pending <= 1'b0;
          binary_src_load_pending <= 1'b0;
          binary_src_load_addr <= '0;
          unary_prep_pending <= 1'b0;
          unary_math_pending <= 1'b0;
          unary_reduce_pending <= 1'b0;
          unary_reduce2_pending <= 1'b0;
        end
        default: begin
        end
      endcase
    end
  end

  always_comb begin
    state_n = state;
    busy = 1'b1;
    done = 1'b0;
    error = 1'b0;

    unique case (state)
      ST_IDLE: begin
        busy = 1'b0;
        if (start) begin
          if (!valid_cmd) begin
            state_n = ST_ERROR;
          end else begin
            state_n = ST_PREP;
          end
        end
      end
      ST_PREP: begin
        if ((cmd_reg == CMD_DECODE_HELPER) && binary_src_load_pending) begin
          state_n = ST_PREP;
        end else if (cmd_reg == CMD_R2_MUL) begin
          state_n = ST_RUN_R2;
        end else if (cmd_reg == CMD_FAST_INV) begin
          state_n = ST_RUN_FAST_INV;
        end else if (cmd_reg == CMD_CT_DECOMP) begin
          state_n = ST_RUN_CT_DECOMP;
        end else if (cmd_reg == CMD_MSG_UNPACK) begin
          state_n = ST_RUN_MSG_UNPACK;
        end else if (cmd_reg == CMD_MSG_PACK) begin
          state_n = ST_RUN_MSG_PACK;
        end else if (cmd_reg == CMD_T0_TRANSFORM) begin
          state_n = ST_RUN_T0;
        end else if (cmd_reg == CMD_A_MOD2) begin
          state_n = ST_RUN_A_MOD2;
        end else if (cmd_reg == CMD_POLY_ADD) begin
          state_n = ST_RUN_POLY_ADD;
        end else if (cmd_reg == CMD_ENC_POSTPROC) begin
          state_n = ST_RUN_ENC_POST;
        end else if (cmd_reg == CMD_DEC_POSTPROC) begin
          state_n = ST_RUN_DEC_POST_T0;
        end else begin
          state_n = ST_RUN_DECODE;
        end
      end
      ST_RUN_R2,
      ST_RUN_DECODE,
      ST_RUN_DEC_POST_R2,
      ST_RUN_DEC_POST_DECODE: begin
        if (binary_write_pending &&
            binary_col_phase_last &&
            binary_phase_last &&
            (row_ptr + XOR_LANES >= chunk_row_limit) &&
            (col_ptr + active_bin_col_lanes >= chunk_write_limit)) begin
          state_n = chunk_done_state;
        end
      end
      ST_RUN_FAST_INV: begin
        if (fast_inv_done) begin
          state_n = ST_DONE;
        end
      end
      ST_RUN_CT_DECOMP,
      ST_RUN_MSG_UNPACK,
      ST_RUN_MSG_PACK,
      ST_RUN_T0,
      ST_RUN_A_MOD2,
      ST_RUN_POLY_ADD,
      ST_RUN_ENC_POST,
      ST_RUN_DEC_POST_T0,
      ST_RUN_DEC_POST_A_MOD2: begin
        if (binary_write_pending && (col_ptr + XOR_LANES >= unary_write_limit)) begin
          state_n = unary_done_state;
        end
      end
      ST_DONE: begin
        busy = 1'b0;
        done = 1'b1;
        state_n = ST_IDLE;
      end
      ST_ERROR: begin
        busy = 1'b0;
        error = 1'b1;
        state_n = ST_IDLE;
      end
      default: begin
        busy = 1'b0;
        error = 1'b1;
        state_n = ST_IDLE;
      end
    endcase
  end

endmodule
