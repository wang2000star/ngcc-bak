module zen_binary_stage_core #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int XOR_LANES = zen_accel_pkg::BINARY_LANES,
  parameter int COL_ADDR_W = zen_accel_pkg::ADDR_W + 1
) (
  input  logic [3:0]                      op_mode_i,
  input  logic signed [NTT_N*COEFF_W-1:0] vec_a_data,
  input  logic signed [NTT_N*COEFF_W-1:0] vec_b_data,
  input  logic signed [NTT_N*COEFF_W-1:0] dec_t0_data,
  input  logic [COL_ADDR_W-1:0]          col_base_i,
  input  int unsigned                    active_n_i,
  input  int unsigned                    active_n2_i,
  input  int unsigned                    active_n4_i,
  input  int unsigned                    active_msg_bytes_i,
  output logic signed [XOR_LANES*COEFF_W-1:0] stage_data_o
);

  import zen_accel_pkg::*;

  localparam int ZEN_MSG_LIFT_VAL = (ZEN_Q + 1) / 2;
  localparam logic [3:0] STAGE_OP_NONE        = 4'd0;
  localparam logic [3:0] STAGE_OP_CT_DECOMP   = 4'd1;
  localparam logic [3:0] STAGE_OP_MSG_UNPACK  = 4'd2;
  localparam logic [3:0] STAGE_OP_MSG_PACK    = 4'd3;
  localparam logic [3:0] STAGE_OP_T0          = 4'd4;
  localparam logic [3:0] STAGE_OP_A_MOD2      = 4'd5;
  localparam logic [3:0] STAGE_OP_POLY_ADD    = 4'd6;
  localparam logic [3:0] STAGE_OP_ENC_POST    = 4'd7;
  localparam logic [3:0] STAGE_OP_DEC_A_MOD2  = 4'd8;

  always_comb begin
    integer lane_idx;
    integer coeff_idx;
    integer byte_idx;
    integer bit_idx;
    integer src_idx;
    integer base_idx;
    logic signed [15:0] coeff_word;
    logic signed [15:0] lhs;
    logic signed [15:0] rhs;
    logic signed [15:0] lo_coeff;
    logic signed [15:0] hi_coeff;
    logic signed [15:0] reduced_word;
    logic signed [16:0] accum17;
    logic signed [31:0] mont_in;
    logic signed [31:0] mont_t;
    logic signed [15:0] mont_u;
    logic [7:0] packed_byte;
    logic [31:0] scaled;
    logic bit_val;

    stage_data_o = '0;

    for (lane_idx = 0; lane_idx < XOR_LANES; lane_idx++) begin
      coeff_idx = $unsigned(col_base_i) + lane_idx;
      coeff_word = '0;
      lhs = '0;
      rhs = '0;
      lo_coeff = '0;
      hi_coeff = '0;
      reduced_word = '0;
      accum17 = '0;
      mont_in = '0;
      mont_t = '0;
      mont_u = '0;
      packed_byte = '0;
      scaled = '0;
      bit_val = 1'b0;

      unique case (op_mode_i)
        STAGE_OP_CT_DECOMP: begin
          if (coeff_idx < active_n_i) begin
            coeff_word = vec_a_data[coeff_idx*COEFF_W +: COEFF_W];
            packed_byte = coeff_word[7:0];
            scaled = (((packed_byte * ZEN_Q) + 32'd128) >> 8);
            stage_data_o[lane_idx*COEFF_W +: COEFF_W] = $signed(scaled[15:0]);
          end
        end
        STAGE_OP_MSG_UNPACK: begin
          if (coeff_idx < active_n_i) begin
            src_idx = coeff_idx & (active_n4_i - 1);
            byte_idx = src_idx >>> 3;
            bit_idx = src_idx & 7;
            coeff_word = vec_a_data[byte_idx*COEFF_W +: COEFF_W];
            bit_val = coeff_word[bit_idx];
            if (bit_val) begin
              stage_data_o[lane_idx*COEFF_W +: COEFF_W] = $signed(ZEN_MSG_LIFT_VAL);
            end
          end
        end
        STAGE_OP_MSG_PACK: begin
          if (coeff_idx < active_msg_bytes_i) begin
            base_idx = coeff_idx << 3;
            packed_byte = 8'd0;
            for (bit_idx = 0; bit_idx < 8; bit_idx++) begin
              packed_byte[bit_idx] = vec_a_data[(base_idx + bit_idx)*COEFF_W];
            end
            stage_data_o[lane_idx*COEFF_W +: COEFF_W] = $signed({8'd0, packed_byte});
          end
        end
        STAGE_OP_T0: begin
          if (coeff_idx < active_n_i) begin
            if (coeff_idx < active_n2_i) begin
              lhs = vec_a_data[(coeff_idx + active_n2_i)*COEFF_W +: COEFF_W];
              rhs = vec_a_data[coeff_idx*COEFF_W +: COEFF_W];
            end else begin
              lhs = vec_a_data[(coeff_idx - active_n2_i)*COEFF_W +: COEFF_W];
              rhs = -vec_a_data[coeff_idx*COEFF_W +: COEFF_W];
            end
            mont_in = (lhs - rhs) * 16'sd171;
            mont_u = mont_in * (-16'sd767);
            mont_t = mont_in - (mont_u * 16'sd769);
            stage_data_o[lane_idx*COEFF_W +: COEFF_W] = mont_t >>> 16;
          end
        end
        STAGE_OP_A_MOD2: begin
          if (coeff_idx < active_n_i) begin
            if (coeff_idx < active_n2_i) begin
              stage_data_o[lane_idx*COEFF_W +: COEFF_W] =
                (vec_a_data[coeff_idx*COEFF_W +: COEFF_W] & 16'sd1) ^
                (vec_a_data[(coeff_idx + active_n2_i)*COEFF_W +: COEFF_W] & 16'sd1);
            end
          end
        end
        STAGE_OP_POLY_ADD: begin
          if (coeff_idx < active_n_i) begin
            stage_data_o[lane_idx*COEFF_W +: COEFF_W] =
              vec_a_data[coeff_idx*COEFF_W +: COEFF_W] +
              vec_b_data[coeff_idx*COEFF_W +: COEFF_W];
          end
        end
        STAGE_OP_ENC_POST: begin
          if (coeff_idx < active_n_i) begin
            accum17 =
              vec_a_data[coeff_idx*COEFF_W +: COEFF_W] +
              vec_b_data[coeff_idx*COEFF_W +: COEFF_W];
            mont_in = accum17 * 16'sd171;
            mont_u = mont_in * (-16'sd767);
            mont_t = mont_in - (mont_u * 16'sd769);
            reduced_word = mont_t >>> 16;
            stage_data_o[lane_idx*COEFF_W +: COEFF_W] =
              reduced_word + ((reduced_word >>> 15) & 16'sd769);
          end
        end
        STAGE_OP_DEC_A_MOD2: begin
          if (coeff_idx < active_n2_i) begin
            lo_coeff = dec_t0_data[coeff_idx*COEFF_W +: COEFF_W];
            hi_coeff = dec_t0_data[(coeff_idx + active_n2_i)*COEFF_W +: COEFF_W];
            stage_data_o[lane_idx*COEFF_W +: COEFF_W] =
              (lo_coeff & 16'sd1) ^ (hi_coeff & 16'sd1);
          end
        end
        default: begin
        end
      endcase
    end
  end

endmodule
