module zen_ntt_core (
  input  logic                         clk,
  input  logic                         rst_n,
  input  logic                         start,
  input  logic [7:0]                   cmd,
  input  logic [31:0]                  cfg,
  input  logic [31:0]                  len,
  input  logic [2:0]                   buf_a_sel,
  input  logic [2:0]                   buf_r_sel,
  input  logic                         vec_in_valid,
  input  zen_accel_pkg::zen_poly_vec_t vec_in_data,
  output logic                         vec_out_valid,
  output zen_accel_pkg::zen_poly_vec_t vec_out_data,
  output logic                         busy,
  output logic                         done,
  output logic                         error
);

  import zen_accel_pkg::*;
  import zen_ntt_const_pkg::*;
  localparam int NTT_N = ZEN_N;
  localparam int BFLY_LANES = NTT_BFLY_LANES;
  localparam int EXEC_LANES = (BFLY_LANES < MODMUL_LANES) ? BFLY_LANES : MODMUL_LANES;
  localparam int ROW_COEFFS = BUF_BANKS;
  localparam int ROW_BITS = ROW_COEFFS * COEFF_W;
  localparam int ROW_COUNT = NTT_N / ROW_COEFFS;
  localparam int ROW_INDEX_W = (ROW_COUNT <= 1) ? 1 : $clog2(ROW_COUNT);
  localparam int ROW_OFFSET_W = (ROW_COEFFS <= 1) ? 1 : $clog2(ROW_COEFFS);
  localparam logic [ADDR_W:0] ACTIVE_N_COUNT = (ADDR_W + 1)'(NTT_N);
  localparam logic [ADDR_W:0] EXEC_LANES_COUNT = (ADDR_W + 1)'(EXEC_LANES);
  localparam logic [ADDR_W-1:0] ACTIVE_NTT_MIN_LEN = ADDR_W'(NTT_N >> 7);
  localparam logic [ADDR_W-1:0] ACTIVE_NTT_START_LEN = ADDR_W'(NTT_N >> 1);

  typedef enum logic [3:0] {
    ST_IDLE,
    ST_LOAD,
    ST_FWD_READ,
    ST_FWD_MUL_REQ,
    ST_FWD_PREP,
    ST_FWD_WRITE,
    ST_INV_READ,
    ST_INV_PREP,
    ST_INV_MUL_REQ,
    ST_INV_WRITE,
    ST_SCALE_READ,
    ST_SCALE_REQ,
    ST_SCALE_WRITE,
    ST_DONE,
    ST_ERROR
  } state_t;

  state_t state, state_n;

  logic inverse_mode;
  logic mq_mode;
  logic need_final_scale;
  logic inverse_mode_reg;
  logic mq_mode_reg;
  logic need_final_scale_reg;
  logic start_inverse_mode;
  logic start_mq_mode;
  logic start_need_final_scale;

  logic [ADDR_W-1:0] len_cur;
  logic [ADDR_W-1:0] block_base;
  logic [ADDR_W-1:0] group_offset;
  logic [ADDR_W-1:0] start_idx;
  logic [ADDR_W-1:0] b_start_idx;
  logic [ADDR_W-1:0] scale_idx;
  logic [6:0] twiddle_idx;
  logic [6:0] twiddle_idx_next;
  logic signed [15:0] twiddle;
  logic signed [15:0] twiddle_reg;
  logic signed [15:0] scale_twiddle;

  logic signed [ROW_BITS-1:0] poly_rows [0:ROW_COUNT-1];
  logic [EXEC_LANES-1:0] lane_active_reg;
  logic signed [EXEC_LANES-1:0][15:0] lane_a_val_reg;
  logic signed [EXEC_LANES-1:0][15:0] lane_b_val_reg;
  logic signed [EXEC_LANES-1:0][15:0] lane_sum_reg;
  logic signed [EXEC_LANES-1:0][15:0] lane_sub_reg;
  logic signed [EXEC_LANES-1:0][15:0] lane_diff_reg;
  logic signed [NTT_N*COEFF_W-1:0] vec_in_data_reg;
  logic [EXEC_LANES-1:0] modmul_op_valid;
  logic [EXEC_LANES-1:0] modmul_reduce_only;
  logic signed [EXEC_LANES-1:0][15:0] modmul_a;
  logic signed [EXEC_LANES-1:0][15:0] modmul_b;
  logic [EXEC_LANES-1:0] modmul_res_valid;
  logic signed [EXEC_LANES-1:0][15:0] modmul_res_data;

  logic [ROW_INDEX_W-1:0] chunk_a_row_idx_cur;
  logic [ROW_INDEX_W-1:0] chunk_b_row_idx_cur;
  logic [ROW_OFFSET_W-1:0] chunk_a_row_off_cur;
  logic [ROW_OFFSET_W-1:0] chunk_b_row_off_cur;
  logic [ROW_INDEX_W-1:0] scale_row_idx_cur;
  logic [ROW_OFFSET_W-1:0] scale_row_off_cur;

  logic [ROW_INDEX_W-1:0] chunk_a_row_idx_reg;
  logic [ROW_INDEX_W-1:0] chunk_b_row_idx_reg;
  logic [ROW_OFFSET_W-1:0] chunk_a_row_off_reg;
  logic [ROW_OFFSET_W-1:0] chunk_b_row_off_reg;
  logic [ROW_INDEX_W-1:0] scale_row_idx_reg;
  logic [ROW_OFFSET_W-1:0] scale_row_off_reg;

  logic [ADDR_W:0] chunk_lane_count;
  logic [ADDR_W:0] scale_lane_count;
  logic [ADDR_W:0] active_lane_count;
  logic [ADDR_W:0] chunk_row_room_a;
  logic [ADDR_W:0] chunk_row_room_b;
  logic [ADDR_W:0] scale_row_room;
  logic block_chunk_last;
  logic block_last;
  logic stage_last;
  logic scale_chunk_last;

  integer row_idx;

  function automatic logic signed [COEFF_W-1:0] row_get(
    input logic signed [ROW_BITS-1:0] row_i,
    input integer idx_i
  );
    begin
      row_get = row_i[idx_i*COEFF_W +: COEFF_W];
    end
  endfunction

  function automatic logic [ADDR_W:0] min_count(
    input logic [ADDR_W:0] lhs_i,
    input logic [ADDR_W:0] rhs_i
  );
    begin
      if (lhs_i < rhs_i) begin
        min_count = lhs_i;
      end else begin
        min_count = rhs_i;
      end
    end
  endfunction

  function automatic logic [ADDR_W:0] calc_chunk_count(
    input logic [ADDR_W-1:0] len_val,
    input logic [ADDR_W-1:0] off_val
  );
    logic [ADDR_W:0] remain;
    begin
      remain = {1'b0, len_val} - {1'b0, off_val};
      if (remain == '0) begin
        calc_chunk_count = '0;
      end else if (remain > EXEC_LANES_COUNT) begin
        calc_chunk_count = EXEC_LANES_COUNT;
      end else begin
        calc_chunk_count = remain;
      end
    end
  endfunction

  function automatic logic [ADDR_W:0] calc_scale_count(
    input logic [ADDR_W-1:0] idx_val
  );
    logic [ADDR_W:0] remain;
    begin
      remain = ACTIVE_N_COUNT - {1'b0, idx_val};
      if (remain > EXEC_LANES_COUNT) begin
        calc_scale_count = EXEC_LANES_COUNT;
      end else begin
        calc_scale_count = remain;
      end
    end
  endfunction

  assign start_inverse_mode = (cmd == CMD_INTT);
  assign start_mq_mode = (cmd == CMD_NTT_MQ);
  assign start_need_final_scale = start_mq_mode | start_inverse_mode;
  assign inverse_mode = inverse_mode_reg;
  assign mq_mode = mq_mode_reg;
  assign need_final_scale = need_final_scale_reg;
  assign scale_twiddle = inverse_mode ? get_fn(127) : 16'sd171;
  assign start_idx = block_base + group_offset;
  assign b_start_idx = start_idx + len_cur;

  zen_ntt_twiddle_rom u_twiddle_rom (
    .inverse (inverse_mode),
    .addr    (twiddle_idx),
    .twiddle (twiddle)
  );

  zen_modarith_core #(
    .LANES_P (EXEC_LANES)
  ) u_lane_modmul (
    .clk         (clk),
    .rst_n       (rst_n),
    .op_valid    (modmul_op_valid),
    .reduce_only (modmul_reduce_only),
    .mul_a       (modmul_a),
    .mul_b       (modmul_b),
    .reduce_in   ('0),
    .op_ready    (),
    .res_valid   (modmul_res_valid),
    .res_data    (modmul_res_data)
  );

  always_comb begin
    chunk_a_row_idx_cur = ROW_INDEX_W'(start_idx >> ROW_OFFSET_W);
    chunk_b_row_idx_cur = ROW_INDEX_W'(b_start_idx >> ROW_OFFSET_W);
    chunk_a_row_off_cur = ROW_OFFSET_W'(start_idx[ROW_OFFSET_W-1:0]);
    chunk_b_row_off_cur = ROW_OFFSET_W'(b_start_idx[ROW_OFFSET_W-1:0]);
    scale_row_idx_cur = ROW_INDEX_W'(scale_idx >> ROW_OFFSET_W);
    scale_row_off_cur = ROW_OFFSET_W'(scale_idx[ROW_OFFSET_W-1:0]);

    chunk_lane_count = calc_chunk_count(len_cur, group_offset);
    scale_lane_count = calc_scale_count(scale_idx);

    chunk_row_room_a =
      (ADDR_W + 1)'(ROW_COEFFS) -
      {{(ADDR_W + 1 - ROW_OFFSET_W){1'b0}}, chunk_a_row_off_cur};
    chunk_row_room_b =
      (ADDR_W + 1)'(ROW_COEFFS) -
      {{(ADDR_W + 1 - ROW_OFFSET_W){1'b0}}, chunk_b_row_off_cur};
    scale_row_room =
      (ADDR_W + 1)'(ROW_COEFFS) -
      {{(ADDR_W + 1 - ROW_OFFSET_W){1'b0}}, scale_row_off_cur};

    if ((state == ST_SCALE_READ) ||
        (state == ST_SCALE_REQ) ||
        (state == ST_SCALE_WRITE)) begin
      active_lane_count = min_count(scale_lane_count, scale_row_room);
    end else begin
      active_lane_count = min_count(
        chunk_lane_count,
        min_count(chunk_row_room_a, chunk_row_room_b)
      );
    end

    block_chunk_last = ({1'b0, group_offset} + active_lane_count >= {1'b0, len_cur});
    block_last = ({1'b0, block_base} + ({1'b0, len_cur} << 1) >= ACTIVE_N_COUNT);
    stage_last = inverse_mode ? (len_cur == ACTIVE_NTT_START_LEN) : (len_cur == ACTIVE_NTT_MIN_LEN);
    scale_chunk_last = ({1'b0, scale_idx} + active_lane_count >= ACTIVE_N_COUNT);
    twiddle_idx_next = twiddle_idx + 7'd1;
  end

  always_comb begin
    modmul_op_valid = '0;
    modmul_reduce_only = '0;
    modmul_a = '0;
    modmul_b = '0;

    case (state)
      ST_FWD_MUL_REQ: begin
        for (int lane_idx = 0; lane_idx < EXEC_LANES; lane_idx++) begin
          modmul_op_valid[lane_idx] = lane_active_reg[lane_idx];
          if (lane_active_reg[lane_idx]) begin
            modmul_a[lane_idx] = twiddle;
            modmul_b[lane_idx] = lane_b_val_reg[lane_idx];
          end
        end
      end

      ST_INV_MUL_REQ: begin
        for (int lane_idx = 0; lane_idx < EXEC_LANES; lane_idx++) begin
          modmul_op_valid[lane_idx] = lane_active_reg[lane_idx];
          if (lane_active_reg[lane_idx]) begin
            modmul_a[lane_idx] = twiddle_reg;
            modmul_b[lane_idx] = lane_diff_reg[lane_idx];
          end
        end
      end

      ST_SCALE_REQ: begin
        for (int lane_idx = 0; lane_idx < EXEC_LANES; lane_idx++) begin
          modmul_op_valid[lane_idx] = lane_active_reg[lane_idx];
          if (lane_active_reg[lane_idx]) begin
            modmul_a[lane_idx] = scale_twiddle;
            modmul_b[lane_idx] = lane_a_val_reg[lane_idx];
          end
        end
      end

      default: begin
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= ST_IDLE;
      len_cur <= '0;
      block_base <= '0;
      group_offset <= '0;
      scale_idx <= '0;
      twiddle_idx <= '0;
      vec_out_valid <= 1'b0;
      inverse_mode_reg <= 1'b0;
      mq_mode_reg <= 1'b0;
      need_final_scale_reg <= 1'b0;
      twiddle_reg <= '0;
      vec_in_data_reg <= '0;
      chunk_a_row_idx_reg <= '0;
      chunk_b_row_idx_reg <= '0;
      chunk_a_row_off_reg <= '0;
      chunk_b_row_off_reg <= '0;
      scale_row_idx_reg <= '0;
      scale_row_off_reg <= '0;
      for (row_idx = 0; row_idx < ROW_COUNT; row_idx++) begin
        poly_rows[row_idx] <= '0;
      end
      for (int lane_idx = 0; lane_idx < EXEC_LANES; lane_idx++) begin
        lane_active_reg[lane_idx] <= 1'b0;
        lane_a_val_reg[lane_idx] <= '0;
        lane_b_val_reg[lane_idx] <= '0;
        lane_sum_reg[lane_idx] <= '0;
        lane_sub_reg[lane_idx] <= '0;
        lane_diff_reg[lane_idx] <= '0;
      end
    end else begin
      state <= state_n;
      vec_out_valid <= (state_n == ST_DONE);

      case (state)
        ST_IDLE: begin
          if (start) begin
            inverse_mode_reg <= start_inverse_mode;
            mq_mode_reg <= start_mq_mode;
            need_final_scale_reg <= start_need_final_scale;
            len_cur <= start_inverse_mode ? ACTIVE_NTT_MIN_LEN : ACTIVE_NTT_START_LEN;
            block_base <= '0;
            group_offset <= '0;
            scale_idx <= '0;
            twiddle_idx <= start_inverse_mode ? 7'd0 : 7'd1;
            vec_in_data_reg <= vec_in_data;
          end
        end

        ST_LOAD: begin
          for (row_idx = 0; row_idx < ROW_COUNT; row_idx++) begin
            poly_rows[row_idx] <= vec_in_data_reg[row_idx*ROW_BITS +: ROW_BITS];
          end
        end

        ST_FWD_READ: begin
          chunk_a_row_idx_reg <= chunk_a_row_idx_cur;
          chunk_b_row_idx_reg <= chunk_b_row_idx_cur;
          chunk_a_row_off_reg <= chunk_a_row_off_cur;
          chunk_b_row_off_reg <= chunk_b_row_off_cur;
          for (int lane_idx = 0; lane_idx < EXEC_LANES; lane_idx++) begin
            lane_active_reg[lane_idx] <= (lane_idx < active_lane_count);
            if (lane_idx < active_lane_count) begin
              lane_a_val_reg[lane_idx] <= row_get(poly_rows[chunk_a_row_idx_cur], $unsigned(chunk_a_row_off_cur) + lane_idx);
              lane_b_val_reg[lane_idx] <= row_get(poly_rows[chunk_b_row_idx_cur], $unsigned(chunk_b_row_off_cur) + lane_idx);
            end
          end
        end

        ST_FWD_MUL_REQ: begin
        end

        ST_FWD_PREP: begin
          for (int lane_idx = 0; lane_idx < EXEC_LANES; lane_idx++) begin
            if (lane_active_reg[lane_idx] && modmul_res_valid[lane_idx]) begin
              lane_sum_reg[lane_idx] <= lane_a_val_reg[lane_idx] + modmul_res_data[lane_idx];
              lane_sub_reg[lane_idx] <= lane_a_val_reg[lane_idx] - modmul_res_data[lane_idx];
            end
          end
        end

        ST_FWD_WRITE: begin
          for (int lane_idx = 0; lane_idx < EXEC_LANES; lane_idx++) begin
            if (lane_active_reg[lane_idx]) begin
              poly_rows[chunk_a_row_idx_reg][($unsigned(chunk_a_row_off_reg) + lane_idx)*COEFF_W +: COEFF_W] <=
                lane_sum_reg[lane_idx];
              poly_rows[chunk_b_row_idx_reg][($unsigned(chunk_b_row_off_reg) + lane_idx)*COEFF_W +: COEFF_W] <=
                lane_sub_reg[lane_idx];
            end
          end

          if (block_chunk_last) begin
            group_offset <= '0;
            twiddle_idx <= twiddle_idx_next;
            if (block_last) begin
              block_base <= '0;
              if (!stage_last) begin
                len_cur <= len_cur >> 1;
              end
            end else begin
              block_base <= block_base + (len_cur << 1);
            end
          end else begin
            group_offset <= group_offset + active_lane_count[ADDR_W-1:0];
          end
        end

        ST_INV_READ: begin
          chunk_a_row_idx_reg <= chunk_a_row_idx_cur;
          chunk_b_row_idx_reg <= chunk_b_row_idx_cur;
          chunk_a_row_off_reg <= chunk_a_row_off_cur;
          chunk_b_row_off_reg <= chunk_b_row_off_cur;
          for (int lane_idx = 0; lane_idx < EXEC_LANES; lane_idx++) begin
            lane_active_reg[lane_idx] <= (lane_idx < active_lane_count);
            if (lane_idx < active_lane_count) begin
              lane_a_val_reg[lane_idx] <= row_get(poly_rows[chunk_a_row_idx_cur], $unsigned(chunk_a_row_off_cur) + lane_idx);
              lane_b_val_reg[lane_idx] <= row_get(poly_rows[chunk_b_row_idx_cur], $unsigned(chunk_b_row_off_cur) + lane_idx);
            end
          end
        end

        ST_INV_PREP: begin
          twiddle_reg <= twiddle;
          for (int lane_idx = 0; lane_idx < EXEC_LANES; lane_idx++) begin
            if (lane_active_reg[lane_idx]) begin
              lane_sum_reg[lane_idx] <= lane_a_val_reg[lane_idx] + lane_b_val_reg[lane_idx];
              lane_diff_reg[lane_idx] <= lane_a_val_reg[lane_idx] - lane_b_val_reg[lane_idx];
            end
          end
        end

        ST_INV_MUL_REQ: begin
        end

        ST_INV_WRITE: begin
          for (int lane_idx = 0; lane_idx < EXEC_LANES; lane_idx++) begin
            if (lane_active_reg[lane_idx] && modmul_res_valid[lane_idx]) begin
              poly_rows[chunk_a_row_idx_reg][($unsigned(chunk_a_row_off_reg) + lane_idx)*COEFF_W +: COEFF_W] <=
                lane_sum_reg[lane_idx];
              poly_rows[chunk_b_row_idx_reg][($unsigned(chunk_b_row_off_reg) + lane_idx)*COEFF_W +: COEFF_W] <=
                modmul_res_data[lane_idx];
            end
          end

          if (block_chunk_last) begin
            group_offset <= '0;
            twiddle_idx <= twiddle_idx_next;
            if (block_last) begin
              block_base <= '0;
              if (!stage_last) begin
                len_cur <= len_cur << 1;
              end
            end else begin
              block_base <= block_base + (len_cur << 1);
            end
          end else begin
            group_offset <= group_offset + active_lane_count[ADDR_W-1:0];
          end
        end

        ST_SCALE_READ: begin
          scale_row_idx_reg <= scale_row_idx_cur;
          scale_row_off_reg <= scale_row_off_cur;
          for (int lane_idx = 0; lane_idx < EXEC_LANES; lane_idx++) begin
            lane_active_reg[lane_idx] <= (lane_idx < active_lane_count);
            if (lane_idx < active_lane_count) begin
              lane_a_val_reg[lane_idx] <= row_get(poly_rows[scale_row_idx_cur], $unsigned(scale_row_off_cur) + lane_idx);
            end
          end
        end

        ST_SCALE_REQ: begin
        end

        ST_SCALE_WRITE: begin
          for (int lane_idx = 0; lane_idx < EXEC_LANES; lane_idx++) begin
            if (lane_active_reg[lane_idx] && modmul_res_valid[lane_idx]) begin
              poly_rows[scale_row_idx_reg][($unsigned(scale_row_off_reg) + lane_idx)*COEFF_W +: COEFF_W] <=
                inverse_mode ? modmul_res_data[lane_idx] : norm_q(modmul_res_data[lane_idx]);
            end
          end

          if (scale_chunk_last) begin
            scale_idx <= '0;
          end else begin
            scale_idx <= scale_idx + active_lane_count[ADDR_W-1:0];
          end
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
          if (!vec_in_valid) begin
            state_n = ST_ERROR;
          end else if ((cmd == CMD_NTT) || (cmd == CMD_NTT_MQ) || (cmd == CMD_INTT)) begin
            state_n = ST_LOAD;
          end else begin
            state_n = ST_ERROR;
          end
        end
      end

      ST_LOAD: begin
        if (inverse_mode) begin
          state_n = ST_INV_READ;
        end else begin
          state_n = ST_FWD_READ;
        end
      end

      ST_FWD_READ: state_n = ST_FWD_MUL_REQ;
      ST_FWD_MUL_REQ: state_n = ST_FWD_PREP;
      ST_FWD_PREP: state_n = ST_FWD_WRITE;

      ST_FWD_WRITE: begin
        if (block_chunk_last && block_last && stage_last) begin
          if (need_final_scale) begin
            state_n = ST_SCALE_READ;
          end else begin
            state_n = ST_DONE;
          end
        end else begin
          state_n = ST_FWD_READ;
        end
      end

      ST_INV_READ: state_n = ST_INV_PREP;
      ST_INV_PREP: state_n = ST_INV_MUL_REQ;
      ST_INV_MUL_REQ: state_n = ST_INV_WRITE;

      ST_INV_WRITE: begin
        if (block_chunk_last && block_last && stage_last) begin
          state_n = ST_SCALE_READ;
        end else begin
          state_n = ST_INV_READ;
        end
      end

      ST_SCALE_READ: state_n = ST_SCALE_REQ;
      ST_SCALE_REQ: state_n = ST_SCALE_WRITE;

      ST_SCALE_WRITE: begin
        if (scale_chunk_last) begin
          state_n = ST_DONE;
        end else begin
          state_n = ST_SCALE_READ;
        end
      end

      ST_DONE: begin
        done = 1'b1;
        busy = 1'b0;
        state_n = ST_IDLE;
      end

      ST_ERROR: begin
        error = 1'b1;
        busy = 1'b0;
        state_n = ST_IDLE;
      end

      default: begin
        error = 1'b1;
        busy = 1'b0;
        state_n = ST_IDLE;
      end
    endcase
  end

  generate
    genvar g_row;
    for (g_row = 0; g_row < ROW_COUNT; g_row++) begin : g_vec_out_rows
      assign vec_out_data[g_row*ROW_BITS +: ROW_BITS] = poly_rows[g_row];
    end
  endgenerate

endmodule
