module zen_ct_pack_row_core (
  input  zen_accel_pkg::zen_row_addr_t row_i,
  input  zen_accel_pkg::zen_poly_vec_t hs_poly_vec_i,
  input  zen_accel_pkg::zen_poly_vec_t e_poly_vec_i,
  input  zen_accel_pkg::zen_poly_vec_t msg_poly_vec_i,
  output zen_accel_pkg::zen_buf_row_t row_vec_o
);

  import zen_accel_pkg::*;

  function automatic logic signed [15:0] montgomery_reduce(
    input logic signed [31:0] a
  );
    logic signed [15:0] u;
    logic signed [31:0] t;
    begin
      u = a * (-16'sd767);
      t = a - (u * 16'sd769);
      montgomery_reduce = t >>> 16;
    end
  endfunction

  function automatic logic [15:0] ct_pack_coeff(
    input logic signed [15:0] hs_coeff,
    input logic signed [15:0] e_coeff,
    input logic signed [15:0] msg_coeff
  );
    logic signed [16:0] accum;
    logic signed [15:0] reduced;
    logic [31:0] d;
    begin
      accum = hs_coeff + e_coeff + msg_coeff;
      reduced = montgomery_reduce(accum * 16'sd171);
      reduced = reduced + ((reduced >>> 15) & 16'sd769);
      d = $unsigned(reduced) << 8;
      d = d + 32'd384;
      d = d * 32'd10908;
      d = d >> 23;
      ct_pack_coeff = {8'd0, d[7:0]};
    end
  endfunction

  always_comb begin
    integer lane_idx;
    integer coeff_idx;
    integer row_base_idx;

    row_vec_o = '0;
    row_base_idx = int'(row_i) * BUF_BANKS;

    for (lane_idx = 0; lane_idx < BUF_BANKS; lane_idx++) begin
      coeff_idx = row_base_idx + lane_idx;
      if (coeff_idx < ZEN_N) begin
        row_vec_o[lane_idx*COEFF_W +: COEFF_W] = ct_pack_coeff(
          hs_poly_vec_i[coeff_idx*COEFF_W +: COEFF_W],
          e_poly_vec_i[coeff_idx*COEFF_W +: COEFF_W],
          msg_poly_vec_i[coeff_idx*COEFF_W +: COEFF_W]
        );
      end
    end
  end

endmodule
