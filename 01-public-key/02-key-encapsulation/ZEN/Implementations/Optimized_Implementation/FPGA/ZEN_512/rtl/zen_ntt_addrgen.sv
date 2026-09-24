module zen_ntt_addrgen #(
  parameter int ADDR_W = zen_accel_pkg::ADDR_W,
  parameter int LANES = zen_accel_pkg::NTT_BFLY_LANES
) (
  input  logic [ADDR_W-1:0] start_idx,
  input  logic [ADDR_W-1:0] len_cur,
  output logic [LANES-1:0][ADDR_W-1:0] a_addr,
  output logic [LANES-1:0][ADDR_W-1:0] b_addr
);

  integer lane;

  always_comb begin
    for (lane = 0; lane < LANES; lane++) begin
      a_addr[lane] = start_idx + lane[ADDR_W-1:0];
      b_addr[lane] = start_idx + len_cur + lane[ADDR_W-1:0];
    end
  end

endmodule
