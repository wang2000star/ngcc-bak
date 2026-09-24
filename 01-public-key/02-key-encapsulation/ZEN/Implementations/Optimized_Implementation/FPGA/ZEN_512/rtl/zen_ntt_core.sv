module zen_ntt_core #(
  parameter int BFLY_LANES = zen_accel_pkg::NTT_BFLY_LANES,
  parameter int ADDR_W = zen_accel_pkg::ADDR_W,
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic                            clk,
  input  logic                            rst_n,
  input  logic                            start,
  input  logic [7:0]                      cmd,
  input  logic [1:0]                      profile_id_i,
  input  logic [31:0]                     cfg,
  input  logic [31:0]                     len,
  input  logic [2:0]                      buf_a_sel,
  input  logic [2:0]                      buf_r_sel,
  input  logic                            vec_in_valid,
  input  logic signed [NTT_N*COEFF_W-1:0] vec_in_data,
  output logic                            vec_out_valid,
  output logic signed [NTT_N*COEFF_W-1:0] vec_out_data,
  output logic                            busy,
  output logic                            done,
  output logic                            error
);

  import zen_accel_pkg::*;
  import zen_ntt_const_pkg::*;

  localparam int EXEC_LANES = (BFLY_LANES < MODMUL_LANES) ? BFLY_LANES : MODMUL_LANES;

  typedef enum logic [3:0] {
    ST_IDLE,
    ST_LOAD,
    ST_FWD_MUL_REQ,
    ST_FWD_WRITE,
    ST_INV_PREP,
    ST_INV_MUL_REQ,
    ST_INV_WRITE,
    ST_SCALE_REQ,
    ST_SCALE_WRITE,
    ST_PACK,
    ST_DONE,
    ST_ERROR
  } state_t;

  state_t state, state_n;

  logic inverse_mode;
  logic mq_mode;
  logic need_final_scale;

  logic [ADDR_W-1:0] len_cur;
  logic [ADDR_W-1:0] block_base;
  logic [ADDR_W-1:0] group_offset;
  logic [ADDR_W-1:0] start_idx;
  logic [ADDR_W-1:0] scale_idx;
  logic [6:0]        twiddle_idx;
  logic [6:0]        twiddle_idx_next;
  logic signed [15:0] twiddle;
  logic signed [15:0] scale_twiddle;

  logic [BFLY_LANES-1:0][ADDR_W-1:0] a_addr;
  logic [BFLY_LANES-1:0][ADDR_W-1:0] b_addr;

  logic signed [NTT_N*COEFF_W-1:0] poly_mem_flat;
  logic [EXEC_LANES-1:0] lane_active_reg;
  logic [EXEC_LANES-1:0][ADDR_W-1:0] lane_a_idx_reg;
  logic [EXEC_LANES-1:0][ADDR_W-1:0] lane_b_idx_reg;
  logic signed [EXEC_LANES-1:0][15:0] lane_a_val_reg;
  logic signed [EXEC_LANES-1:0][15:0] lane_diff_reg;
  logic signed [EXEC_LANES-1:0][15:0] lane_mul_reg;
  logic signed [EXEC_LANES-1:0][15:0] lane_twiddle_reg;
  logic signed [NTT_N*COEFF_W-1:0] vec_in_data_reg;

  logic [ADDR_W:0] active_lane_count;
  logic block_chunk_last;
  logic block_last;
  logic stage_last;
  logic scale_chunk_last;
  logic [ADDR_W:0] active_n;
  logic [ADDR_W-1:0] active_ntt_min_len;
  logic [ADDR_W-1:0] active_ntt_start_len;

  integer i;

  function automatic int limited_profile_n(input logic [1:0] profile_id);
    int profile_n_raw;
    begin
      profile_n_raw = profile_n(profile_id);
      if (profile_n_raw > NTT_N) begin
        limited_profile_n = NTT_N;
      end else begin
        limited_profile_n = profile_n_raw;
      end
    end
  endfunction

  function automatic logic signed [15:0] flat_get(
    input logic signed [NTT_N*COEFF_W-1:0] flat,
    input integer idx
  );
    begin
      flat_get = flat[idx*COEFF_W +: COEFF_W];
    end
  endfunction

  function automatic logic [ADDR_W:0] calc_chunk_count(
    input logic [ADDR_W-1:0] len_val,
    input logic [ADDR_W-1:0] off_val
  );
    logic [ADDR_W:0] remain;
    begin
      remain = {1'b0, len_val} - {1'b0, off_val};
      if (remain == '0) calc_chunk_count = '0;
      else if (remain > EXEC_LANES) calc_chunk_count = EXEC_LANES;
      else calc_chunk_count = remain;
    end
  endfunction

  function automatic logic [ADDR_W:0] calc_scale_count(
    input logic [ADDR_W-1:0] idx_val
  );
    logic [ADDR_W:0] remain;
    begin
      remain = {1'b0, active_n} - {1'b0, idx_val};
      if (remain > EXEC_LANES) calc_scale_count = EXEC_LANES;
      else calc_scale_count = remain;
    end
  endfunction

  assign inverse_mode = (cmd == CMD_INTT);
  assign mq_mode = (cmd == CMD_NTT_MQ);
  assign need_final_scale = mq_mode | inverse_mode;
  assign scale_twiddle = inverse_mode ? get_fn(127) : 16'sd171;
  assign start_idx = block_base + group_offset;
  assign active_n = (ADDR_W+1)'(limited_profile_n(profile_id_i));
  assign active_ntt_min_len = active_n >> 7;
  assign active_ntt_start_len = active_n >> 1;

  zen_ntt_twiddle_rom u_twiddle_rom (
    .inverse (inverse_mode),
    .addr    (twiddle_idx),
    .twiddle (twiddle)
  );

  zen_ntt_addrgen #(
    .ADDR_W (ADDR_W),
    .LANES  (BFLY_LANES)
  ) u_addrgen (
    .start_idx (start_idx),
    .len_cur   (len_cur),
    .a_addr    (a_addr),
    .b_addr    (b_addr)
  );

  always_comb begin
    active_lane_count = ((state == ST_SCALE_REQ) || (state == ST_SCALE_WRITE))
      ? calc_scale_count(scale_idx)
      : calc_chunk_count(len_cur, group_offset);

    block_chunk_last = ({1'b0, group_offset} + active_lane_count >= {1'b0, len_cur});
    block_last = ({1'b0, block_base} + ({1'b0, len_cur} << 1) >= {1'b0, active_n});
    stage_last = inverse_mode ? (len_cur == active_ntt_start_len) : (len_cur == active_ntt_min_len);
    scale_chunk_last = ({1'b0, scale_idx} + active_lane_count >= {1'b0, active_n});
    twiddle_idx_next = twiddle_idx + 7'd1;
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
      vec_in_data_reg <= '0;
      poly_mem_flat <= '0;
      for (i = 0; i < EXEC_LANES; i++) begin
        lane_active_reg[i] <= 1'b0;
        lane_a_idx_reg[i] <= '0;
        lane_b_idx_reg[i] <= '0;
        lane_a_val_reg[i] <= '0;
        lane_diff_reg[i] <= '0;
        lane_mul_reg[i] <= '0;
        lane_twiddle_reg[i] <= '0;
      end
    end else begin
      state <= state_n;
      vec_out_valid <= (state_n == ST_DONE);

      case (state)
        ST_IDLE: begin
          if (start) begin
            len_cur <= inverse_mode ? active_ntt_min_len : active_ntt_start_len;
            block_base <= '0;
            group_offset <= '0;
            scale_idx <= '0;
            twiddle_idx <= inverse_mode ? 7'd0 : 7'd1;
            vec_in_data_reg <= vec_in_data;
          end
        end

        ST_LOAD: begin
          poly_mem_flat <= vec_in_data_reg;
        end

        ST_FWD_MUL_REQ: begin
          for (i = 0; i < EXEC_LANES; i++) begin
            lane_active_reg[i] <= (i < active_lane_count);
            if (i < active_lane_count) begin
              lane_a_idx_reg[i] <= a_addr[i];
              lane_b_idx_reg[i] <= b_addr[i];
              lane_a_val_reg[i] <= flat_get(poly_mem_flat, a_addr[i]);
              lane_mul_reg[i] <= fqmul(twiddle, flat_get(poly_mem_flat, b_addr[i]));
            end
          end
        end

        ST_FWD_WRITE: begin
          for (i = 0; i < EXEC_LANES; i++) begin
            if (lane_active_reg[i]) begin
              poly_mem_flat[lane_a_idx_reg[i]*COEFF_W +: COEFF_W] <= lane_a_val_reg[i] + lane_mul_reg[i];
              poly_mem_flat[lane_b_idx_reg[i]*COEFF_W +: COEFF_W] <= lane_a_val_reg[i] - lane_mul_reg[i];
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

        ST_INV_PREP: begin
          for (i = 0; i < EXEC_LANES; i++) begin
            lane_active_reg[i] <= (i < active_lane_count);
            if (i < active_lane_count) begin
              lane_a_idx_reg[i] <= a_addr[i];
              lane_b_idx_reg[i] <= b_addr[i];
              lane_diff_reg[i] <= flat_get(poly_mem_flat, a_addr[i]) - flat_get(poly_mem_flat, b_addr[i]);
              lane_twiddle_reg[i] <= twiddle;
              poly_mem_flat[a_addr[i]*COEFF_W +: COEFF_W] <=
                flat_get(poly_mem_flat, a_addr[i]) + flat_get(poly_mem_flat, b_addr[i]);
            end
          end
        end

        ST_INV_MUL_REQ: begin
          for (i = 0; i < EXEC_LANES; i++) begin
            if (lane_active_reg[i]) begin
              lane_mul_reg[i] <= fqmul(lane_twiddle_reg[i], lane_diff_reg[i]);
            end
          end
        end

        ST_INV_WRITE: begin
          for (i = 0; i < EXEC_LANES; i++) begin
            if (lane_active_reg[i]) begin
              poly_mem_flat[lane_b_idx_reg[i]*COEFF_W +: COEFF_W] <= lane_mul_reg[i];
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

        ST_SCALE_REQ: begin
          for (i = 0; i < EXEC_LANES; i++) begin
            if (i < active_lane_count) begin
              lane_mul_reg[i] <= fqmul(scale_twiddle, flat_get(poly_mem_flat, scale_idx + i));
            end
          end
        end

        ST_SCALE_WRITE: begin
          for (i = 0; i < EXEC_LANES; i++) begin
            if (i < active_lane_count) begin
              if (inverse_mode) begin
                poly_mem_flat[(scale_idx + i)*COEFF_W +: COEFF_W] <= lane_mul_reg[i];
              end else begin
                poly_mem_flat[(scale_idx + i)*COEFF_W +: COEFF_W] <= norm_q(lane_mul_reg[i]);
              end
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
          if (!vec_in_valid) state_n = ST_ERROR;
          else if ((cmd == CMD_NTT) || (cmd == CMD_NTT_MQ) || (cmd == CMD_INTT)) state_n = ST_LOAD;
          else state_n = ST_ERROR;
        end
      end

      ST_LOAD: begin
        if (inverse_mode) state_n = ST_INV_PREP;
        else state_n = ST_FWD_MUL_REQ;
      end

      ST_FWD_MUL_REQ: state_n = ST_FWD_WRITE;

      ST_FWD_WRITE: begin
        if (block_chunk_last && block_last && stage_last) begin
          if (need_final_scale) state_n = ST_SCALE_REQ;
          else state_n = ST_DONE;
        end else begin
          state_n = ST_FWD_MUL_REQ;
        end
      end

      ST_INV_PREP: state_n = ST_INV_MUL_REQ;

      ST_INV_MUL_REQ: state_n = ST_INV_WRITE;

      ST_INV_WRITE: begin
        if (block_chunk_last && block_last && stage_last) state_n = ST_SCALE_REQ;
        else state_n = ST_INV_PREP;
      end

      ST_SCALE_REQ: state_n = ST_SCALE_WRITE;

      ST_SCALE_WRITE: begin
        if (scale_chunk_last) state_n = ST_DONE;
        else state_n = ST_SCALE_REQ;
      end

      ST_PACK: state_n = ST_DONE;

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

  assign vec_out_data = poly_mem_flat;

endmodule
