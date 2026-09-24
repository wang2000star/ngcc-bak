module zen_msg_codec #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic [1:0] op,
  input  logic [1:0] profile_id_i,
  input  logic signed [NTT_N*COEFF_W-1:0] msg_bytes_vec_i,
  input  logic signed [NTT_N*COEFF_W-1:0] msg_poly_vec_i,
  output logic signed [NTT_N*COEFF_W-1:0] vec_out_o,
  output logic [31:0] bytes_consumed_o,
  output logic [31:0] bytes_produced_o
);

  import zen_accel_pkg::*;

  localparam logic [1:0] OP_MSG_LIFT = 2'd0;
  localparam logic [1:0] OP_MSG_PACK = 2'd1;
  localparam logic signed [15:0] ZEN_MSG_LIFT_VAL_LOCAL = (ZEN_Q + 1) / 2;
  localparam int COEFF_LOOP_CHUNK = 8;
  localparam int COEFF_LOOP_BLOCKS = (NTT_N + COEFF_LOOP_CHUNK - 1) / COEFF_LOOP_CHUNK;
  localparam int MSG_PACK_MAX_BYTES = NTT_N / 32;

  logic [31:0] active_n;
  logic [31:0] active_n4;
  logic [31:0] active_msg_bytes;
  logic [7:0] msg_byte_arr [0:MSG_PACK_MAX_BYTES-1];
  logic signed [COEFF_W-1:0] msg_poly_arr [0:NTT_N-1];
  integer idx;
  integer idx_outer;
  integer idx_inner;

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

  assign active_n = limited_profile_n(profile_id_i);
  assign active_n4 = active_n / 4;
  assign active_msg_bytes = profile_msg_bytes(profile_id_i);

  always_comb begin
    integer byte_unpack_idx;
    integer poly_unpack_idx;
    integer src_idx;
    integer byte_idx;
    integer bit_idx;
    integer base_idx;
    logic [7:0] packed_byte;

    for (byte_unpack_idx = 0; byte_unpack_idx < MSG_PACK_MAX_BYTES; byte_unpack_idx++) begin
      msg_byte_arr[byte_unpack_idx] = msg_bytes_vec_i[byte_unpack_idx*COEFF_W +: 8];
    end
    for (poly_unpack_idx = 0; poly_unpack_idx < NTT_N; poly_unpack_idx++) begin
      msg_poly_arr[poly_unpack_idx] = msg_poly_vec_i[poly_unpack_idx*COEFF_W +: COEFF_W];
    end

    vec_out_o = '0;
    bytes_consumed_o = 32'd0;
    bytes_produced_o = 32'd0;

    unique case (op)
      OP_MSG_LIFT: begin
        bytes_consumed_o = active_msg_bytes;
        bytes_produced_o = active_msg_bytes;
        // Chunk large profile loops so Vivado elaboration stays below its 2000-iteration cap.
        for (idx_outer = 0; idx_outer < COEFF_LOOP_BLOCKS; idx_outer++) begin
          for (idx_inner = 0; idx_inner < COEFF_LOOP_CHUNK; idx_inner++) begin
            idx = (idx_outer * COEFF_LOOP_CHUNK) + idx_inner;
            if (idx < active_n) begin
              src_idx = idx & (active_n4 - 1);
              byte_idx = src_idx >> 3;
              bit_idx = src_idx & 7;
              if (msg_byte_arr[byte_idx][bit_idx]) begin
                vec_out_o[idx*COEFF_W +: COEFF_W] = ZEN_MSG_LIFT_VAL_LOCAL;
              end else begin
                vec_out_o[idx*COEFF_W +: COEFF_W] = '0;
              end
            end
          end
        end
      end
      OP_MSG_PACK: begin
        bytes_consumed_o = active_msg_bytes;
        bytes_produced_o = active_msg_bytes;
        for (idx = 0; idx < MSG_PACK_MAX_BYTES; idx++) begin
          if (idx < active_msg_bytes) begin
            base_idx = idx << 3;
            packed_byte = 8'd0;
            for (bit_idx = 0; bit_idx < 8; bit_idx++) begin
              if ((base_idx + bit_idx) < active_n) begin
                packed_byte[bit_idx] = msg_poly_arr[base_idx + bit_idx][0];
              end
            end
            vec_out_o[idx*COEFF_W +: COEFF_W] = $signed({8'd0, packed_byte});
          end
        end
      end
      default: begin
        vec_out_o = '0;
        bytes_consumed_o = 32'd0;
        bytes_produced_o = 32'd0;
      end
    endcase
  end

endmodule
