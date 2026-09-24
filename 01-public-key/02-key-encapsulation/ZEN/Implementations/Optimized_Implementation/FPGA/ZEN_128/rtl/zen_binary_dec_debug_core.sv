module zen_binary_dec_debug_core #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic signed [NTT_N*COEFF_W-1:0] vec_a_data,
  input  logic signed [NTT_N*COEFF_W-1:0] vec_b_data,
  input  int unsigned                     active_n2_i,
  input  int unsigned                     active_n4_i,
  output logic signed [NTT_N*COEFF_W-1:0] dec_t0_vec_o,
  output logic signed [(NTT_N/4)*COEFF_W-1:0] dec_r2_vec_o,
  output logic signed [NTT_N*COEFF_W-1:0] dec_t2_vec_o
);

  import zen_accel_pkg::*;

  localparam int ZEN_Q2 = ZEN_Q / 2;
  logic signed [COEFF_W-1:0] t0_coeffs [0:NTT_N-1];

  always_comb begin
    integer coeff_idx;
    integer row_idx;
    integer src_idx;
    integer idx0;
    integer idx1;
    integer sel_idx;
    integer c0;
    integer c1;
    integer c2;
    integer c3;
    logic acc_r2_bit;
    logic acc_t2_bit;
    logic t0_lo_bit;
    logic t0_hi_bit;
    logic parity_bit;
    logic signed [15:0] lhs;
    logic signed [15:0] rhs;
    logic signed [15:0] t0_0;
    logic signed [15:0] t0_1;
    logic signed [15:0] t0_2;
    logic signed [15:0] t0_3;
    logic signed [31:0] mont_in;
    logic signed [31:0] mont_t;
    logic signed [15:0] mont_u;

    dec_t0_vec_o = '0;
    dec_r2_vec_o = '0;
    dec_t2_vec_o = '0;

    for (coeff_idx = 0; coeff_idx < NTT_N; coeff_idx++) begin
      t0_coeffs[coeff_idx] = '0;
      if (coeff_idx < (2 * active_n2_i)) begin
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
        t0_coeffs[coeff_idx] = mont_t >>> 16;
        dec_t0_vec_o[coeff_idx*COEFF_W +: COEFF_W] = t0_coeffs[coeff_idx];
      end
    end

    for (coeff_idx = 0; coeff_idx < (NTT_N / 4); coeff_idx++) begin
      if (coeff_idx < active_n4_i) begin
        acc_r2_bit = 1'b0;
        acc_t2_bit = 1'b0;
        for (row_idx = 0; row_idx < (NTT_N / 4); row_idx++) begin
          if (row_idx < active_n4_i) begin
            t0_0 = t0_coeffs[row_idx];
            t0_1 = t0_coeffs[row_idx + active_n4_i];
            t0_2 = t0_coeffs[row_idx + (2 * active_n4_i)];
            t0_3 = t0_coeffs[row_idx + (3 * active_n4_i)];

            t0_lo_bit = (t0_0[0] != 0) ^ (t0_2[0] != 0);
            t0_hi_bit = (t0_1[0] != 0) ^ (t0_3[0] != 0);
            parity_bit = t0_0[0] ^ t0_1[0] ^ t0_2[0] ^ t0_3[0];

            c0 = $signed(t0_0);
            c1 = $signed(t0_1);
            c2 = $signed(t0_2);
            c3 = $signed(t0_3);

            if (c0 >= 0) c0 = ZEN_Q2 - c0; else c0 = ZEN_Q2 + c0;
            if (c1 >= 0) c1 = ZEN_Q2 - c1; else c1 = ZEN_Q2 + c1;
            if (c2 >= 0) c2 = ZEN_Q2 - c2; else c2 = ZEN_Q2 + c2;
            if (c3 >= 0) c3 = ZEN_Q2 - c3; else c3 = ZEN_Q2 + c3;

            if (c0 > c2) c0 = c2;
            if (c1 > c3) c1 = c3;

            if (t0_lo_bit) begin
              src_idx = (coeff_idx + (2 * active_n4_i) - row_idx) & ((2 * active_n4_i) - 1);
              acc_r2_bit = acc_r2_bit ^ (vec_b_data[src_idx*COEFF_W] != 0);
            end
            if (t0_hi_bit) begin
              src_idx = (coeff_idx + (2 * active_n4_i) - (row_idx + active_n4_i)) &
                        ((2 * active_n4_i) - 1);
              acc_r2_bit = acc_r2_bit ^ (vec_b_data[src_idx*COEFF_W] != 0);
            end

            if (parity_bit != 0) begin
              idx0 = row_idx;
              idx1 = row_idx + active_n4_i;
            end else begin
              idx0 = 0;
              idx1 = 0;
            end

            if (c0 <= c1) begin
              sel_idx = idx0;
            end else begin
              sel_idx = idx1;
            end

            src_idx = (coeff_idx + (2 * active_n4_i) - sel_idx) & ((2 * active_n4_i) - 1);
            acc_t2_bit = acc_t2_bit ^ (vec_b_data[src_idx*COEFF_W] != 0);
          end
        end
        dec_r2_vec_o[coeff_idx*COEFF_W +: COEFF_W] = {{(COEFF_W - 1){1'b0}}, acc_r2_bit};
        dec_t2_vec_o[coeff_idx*COEFF_W +: COEFF_W] = {{(COEFF_W - 1){1'b0}}, acc_t2_bit};
      end
    end
  end

endmodule
