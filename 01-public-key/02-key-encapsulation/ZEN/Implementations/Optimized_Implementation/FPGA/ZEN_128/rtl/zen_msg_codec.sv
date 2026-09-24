module zen_msg_codec (
  input  logic [1:0] op,
  input  zen_accel_pkg::zen_poly_vec_t msg_bytes_vec_i,
  input  zen_accel_pkg::zen_poly_vec_t msg_poly_vec_i,
  output zen_accel_pkg::zen_poly_vec_t vec_out_o,
  output logic [31:0] bytes_consumed_o,
  output logic [31:0] bytes_produced_o
);

  import zen_accel_pkg::*;

  localparam logic [1:0] OP_MSG_LIFT = 2'd0;
  localparam logic [1:0] OP_MSG_PACK = 2'd1;
  localparam logic signed [15:0] ZEN_MSG_LIFT_VAL_LOCAL = (ZEN_Q + 1) / 2;
  localparam int ACTIVE_N = ZEN_N;
  localparam int ACTIVE_N4 = ACTIVE_N / 4;
  localparam int COEFF_LOOP_CHUNK = 8;
  localparam int COEFF_LOOP_BLOCKS = (ZEN_N + COEFF_LOOP_CHUNK - 1) / COEFF_LOOP_CHUNK;
  localparam int MSG_PACK_MAX_BYTES = ACTIVE_N4 / 8;

  logic [7:0] msg_byte_arr [0:MSG_PACK_MAX_BYTES-1];
  logic signed [COEFF_W-1:0] msg_poly_arr [0:ZEN_N-1];
  integer idx;
  integer idx_outer;
  integer idx_inner;

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
    for (poly_unpack_idx = 0; poly_unpack_idx < ZEN_N; poly_unpack_idx++) begin
      msg_poly_arr[poly_unpack_idx] = msg_poly_vec_i[poly_unpack_idx*COEFF_W +: COEFF_W];
    end

    vec_out_o = '0;
    bytes_consumed_o = 32'd0;
    bytes_produced_o = 32'd0;

    unique case (op)
      OP_MSG_LIFT: begin
        bytes_consumed_o = MSG_PACK_MAX_BYTES;
        bytes_produced_o = MSG_PACK_MAX_BYTES;
        // Chunk large profile loops so Vivado elaboration stays below its 2000-iteration cap.
        for (idx_outer = 0; idx_outer < COEFF_LOOP_BLOCKS; idx_outer++) begin
          for (idx_inner = 0; idx_inner < COEFF_LOOP_CHUNK; idx_inner++) begin
            idx = (idx_outer * COEFF_LOOP_CHUNK) + idx_inner;
            if (idx < ACTIVE_N) begin
              src_idx = idx & (ACTIVE_N4 - 1);
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
        bytes_consumed_o = MSG_PACK_MAX_BYTES;
        bytes_produced_o = MSG_PACK_MAX_BYTES;
        for (idx = 0; idx < MSG_PACK_MAX_BYTES; idx++) begin
          base_idx = idx << 3;
          packed_byte = 8'd0;
          for (bit_idx = 0; bit_idx < 8; bit_idx++) begin
            if ((base_idx + bit_idx) < ACTIVE_N) begin
              packed_byte[bit_idx] = msg_poly_arr[base_idx + bit_idx][0];
            end
          end
          vec_out_o[idx*COEFF_W +: COEFF_W] = $signed({8'd0, packed_byte});
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
