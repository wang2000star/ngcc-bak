module zen_msg_seq_core #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int LIFT_COEFFS_PER_CYCLE = 8,
  parameter int PACK_BYTES_PER_CYCLE = 2
) (
  input  logic clk,
  input  logic rst_n,
  input  logic start_i,
  input  logic [1:0] op_i,
  input  logic [1:0] profile_id_i,
  input  logic signed [NTT_N*COEFF_W-1:0] msg_bytes_vec_i,
  input  logic signed [NTT_N*COEFF_W-1:0] msg_poly_vec_i,
  output logic busy_o,
  output logic done_o,
  output logic signed [NTT_N*COEFF_W-1:0] vec_out_o,
  output logic [31:0] bytes_consumed_o,
  output logic [31:0] bytes_produced_o
);

  import zen_accel_pkg::*;

  localparam logic [1:0] OP_MSG_LIFT = 2'd0;
  localparam logic [1:0] OP_MSG_PACK = 2'd1;
  localparam logic signed [15:0] ZEN_MSG_LIFT_VAL_LOCAL = (ZEN_Q + 1) / 2;

  logic [1:0]  op_r;
  logic [31:0] active_n_r;
  logic [31:0] active_n4_r;
  logic [31:0] active_msg_bytes_r;
  logic [31:0] work_idx_r;

  logic [31:0] profile_n_calc;
  logic [31:0] msg_bytes_calc;

  logic [31:0] elem_idx_work;
  logic [31:0] src_idx_work;
  logic [31:0] byte_idx_work;
  logic [31:0] base_idx_work;
  logic [7:0]  packed_byte_work;
  logic signed [COEFF_W-1:0] lift_coeff_work;

  integer lane_idx;
  integer bit_idx;

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

  assign profile_n_calc = limited_profile_n(profile_id_i);
  assign msg_bytes_calc = profile_msg_bytes(profile_id_i);

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      busy_o <= 1'b0;
      done_o <= 1'b0;
      op_r <= OP_MSG_LIFT;
      active_n_r <= 32'd0;
      active_n4_r <= 32'd0;
      active_msg_bytes_r <= 32'd0;
      work_idx_r <= 32'd0;
      vec_out_o <= '0;
      bytes_consumed_o <= 32'd0;
      bytes_produced_o <= 32'd0;
    end else begin
      done_o <= 1'b0;

      if (start_i && !busy_o) begin
        op_r <= op_i;
        active_n_r <= profile_n_calc;
        active_n4_r <= profile_n_calc >> 2;
        active_msg_bytes_r <= msg_bytes_calc;
        work_idx_r <= 32'd0;
        vec_out_o <= '0;
        bytes_consumed_o <= msg_bytes_calc;
        bytes_produced_o <= msg_bytes_calc;
        busy_o <= 1'b1;
      end else if (busy_o) begin
        unique case (op_r)
          OP_MSG_LIFT: begin
            for (lane_idx = 0; lane_idx < LIFT_COEFFS_PER_CYCLE; lane_idx++) begin
              elem_idx_work = work_idx_r + lane_idx;
              if (elem_idx_work < active_n_r) begin
                if (active_n4_r != 0) begin
                  src_idx_work = elem_idx_work & (active_n4_r - 1'b1);
                  byte_idx_work = src_idx_work >> 3;
                  packed_byte_work = msg_bytes_vec_i[byte_idx_work*COEFF_W +: 8];
                  if (packed_byte_work[src_idx_work[2:0]]) begin
                    lift_coeff_work = ZEN_MSG_LIFT_VAL_LOCAL;
                  end else begin
                    lift_coeff_work = '0;
                  end
                end else begin
                  lift_coeff_work = '0;
                end
                vec_out_o[elem_idx_work*COEFF_W +: COEFF_W] <= lift_coeff_work;
              end
            end

            if ((work_idx_r + LIFT_COEFFS_PER_CYCLE) >= active_n_r) begin
              busy_o <= 1'b0;
              done_o <= 1'b1;
            end else begin
              work_idx_r <= work_idx_r + LIFT_COEFFS_PER_CYCLE;
            end
          end

          OP_MSG_PACK: begin
            for (lane_idx = 0; lane_idx < PACK_BYTES_PER_CYCLE; lane_idx++) begin
              elem_idx_work = work_idx_r + lane_idx;
              if (elem_idx_work < active_msg_bytes_r) begin
                base_idx_work = elem_idx_work << 3;
                packed_byte_work = 8'd0;
                for (bit_idx = 0; bit_idx < 8; bit_idx++) begin
                  if ((base_idx_work + bit_idx) < active_n_r) begin
                    packed_byte_work[bit_idx] =
                      msg_poly_vec_i[((base_idx_work + bit_idx) * COEFF_W)];
                  end
                end
                vec_out_o[elem_idx_work*COEFF_W +: COEFF_W] <=
                  $signed({8'd0, packed_byte_work});
              end
            end

            if ((work_idx_r + PACK_BYTES_PER_CYCLE) >= active_msg_bytes_r) begin
              busy_o <= 1'b0;
              done_o <= 1'b1;
            end else begin
              work_idx_r <= work_idx_r + PACK_BYTES_PER_CYCLE;
            end
          end

          default: begin
            busy_o <= 1'b0;
            done_o <= 1'b1;
          end
        endcase
      end
    end
  end

endmodule
