module zen_accel_xcv80_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        wr_en,
  input  logic [15:0] wr_addr,
  input  logic [31:0] wr_data,
  input  logic        rd_en,
  input  logic [15:0] rd_addr,
  output logic [31:0] rd_data,
  output logic        busy,
  output logic        done,
  output logic        error,
  output logic        irq
);

  import zen_xcv80_cfg_pkg::*;

  zen_accel_top #(
    .BUF_BANKS          (XCV80_BUF_BANKS),
    .NTT_BFLY_LANES     (XCV80_NTT_BFLY_LANES),
    .BASEMUL_LANES      (XCV80_BASEMUL_LANES),
    .BASEINV_LANES      (XCV80_BASEINV_LANES),
    .BINARY_LANES       (XCV80_BINARY_LANES),
    .BINARY_COL_FACTOR  (XCV80_BINARY_COL_FACTOR),
    .SAMPLE_COEFF_LANES (XCV80_SAMPLE_COEFF_LANES)
  ) u_dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .wr_en   (wr_en),
    .wr_addr (wr_addr),
    .wr_data (wr_data),
    .rd_en   (rd_en),
    .rd_addr (rd_addr),
    .rd_data (rd_data),
    .busy    (busy),
    .done    (done),
    .error   (error),
    .irq     (irq)
  );

endmodule
