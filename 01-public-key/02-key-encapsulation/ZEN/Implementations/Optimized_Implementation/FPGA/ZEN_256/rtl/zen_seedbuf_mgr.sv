module zen_seedbuf_mgr #(
  parameter int DEPTH = zen_accel_pkg::SEEDBUF_BYTES,
  parameter int ADDR_W = zen_accel_pkg::SEEDBUF_ADDR_W
) (
  input  logic              clk,
  input  logic              wr_en,
  input  logic [ADDR_W-1:0] wr_addr,
  input  logic [7:0]        wr_data,
  input  logic [ADDR_W-1:0] rd_addr,
  output logic [7:0]        rd_data
);

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
