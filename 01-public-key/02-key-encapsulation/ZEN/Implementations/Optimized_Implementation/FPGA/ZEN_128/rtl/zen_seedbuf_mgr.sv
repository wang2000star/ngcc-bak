module zen_seedbuf_mgr (
  input  logic                         clk,
  input  logic                         wr_en,
  input  zen_accel_pkg::zen_seed_addr_t wr_addr,
  input  logic [7:0]                   wr_data,
  input  zen_accel_pkg::zen_seed_addr_t rd_addr,
  output logic [7:0]                   rd_data
);

  import zen_accel_pkg::*;
  localparam int DEPTH = SEEDBUF_BYTES;

  logic [7:0] mem [0:DEPTH-1];

  always_ff @(posedge clk) begin
    if (wr_en) begin
      mem[wr_addr] <= wr_data;
    end
  end

  always_comb begin
    rd_data = mem[rd_addr];
  end

endmodule
