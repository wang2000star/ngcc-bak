module zen_ct_pack_row_core #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int ROW_LANES = zen_accel_pkg::BUF_BANKS
) (
  input  logic [1:0] profile_id_i,
  input  logic signed [NTT_N*COEFF_W-1:0] hs_poly_vec_i,
  input  logic signed [NTT_N*COEFF_W-1:0] e_poly_vec_i,
  input  logic signed [NTT_N*COEFF_W-1:0] msg_poly_vec_i,
  output logic signed [ROW_LANES*COEFF_W-1:0] row_vec_o
);

  import zen_accel_pkg::*;

  logic [31:0] active_n;

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
    input logic [31:0] active_n_i,
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
      if (active_n_i == 1024) begin
        d = d * 32'd2727;
        d = d >> 21;
      end else begin
        d = d * 32'd10908;
        d = d >> 23;
      end
      ct_pack_coeff = {8'd0, d[7:0]};
    end
  endfunction

  assign active_n = limited_profile_n(profile_id_i);

  always_comb begin
    integer lane_idx;
    integer coeff_idx;

    row_vec_o = '0;

    for (lane_idx = 0; lane_idx < ROW_LANES; lane_idx++) begin
      coeff_idx = lane_idx;
      if (coeff_idx < active_n) begin
        row_vec_o[lane_idx*COEFF_W +: COEFF_W] = ct_pack_coeff(
          active_n,
          hs_poly_vec_i[coeff_idx*COEFF_W +: COEFF_W],
          e_poly_vec_i[coeff_idx*COEFF_W +: COEFF_W],
          msg_poly_vec_i[coeff_idx*COEFF_W +: COEFF_W]
        );
      end
    end
  end

endmodule
