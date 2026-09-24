module zen_ntt_addrgen (
  input  zen_accel_pkg::zen_row_addr_t start_idx,
  input  zen_accel_pkg::zen_row_addr_t len_cur,
  output logic [zen_accel_pkg::NTT_BFLY_LANES-1:0][zen_accel_pkg::ADDR_W-1:0] a_addr,
  output logic [zen_accel_pkg::NTT_BFLY_LANES-1:0][zen_accel_pkg::ADDR_W-1:0] b_addr
);

  import zen_accel_pkg::*;
  localparam int ADDR_W = zen_accel_pkg::ADDR_W;
  localparam int LANES = zen_accel_pkg::NTT_BFLY_LANES;

  integer lane;

  always_comb begin
    for (lane = 0; lane < LANES; lane++) begin
      a_addr[lane] = start_idx + lane[ADDR_W-1:0];
      b_addr[lane] = start_idx + len_cur + lane[ADDR_W-1:0];
    end
  end

endmodule
