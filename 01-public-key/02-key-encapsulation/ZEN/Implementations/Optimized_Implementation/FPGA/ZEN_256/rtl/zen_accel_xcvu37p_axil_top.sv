module zen_accel_xcvu37p_axil_top (
  input  logic        s_axil_aclk,
  input  logic        s_axil_aresetn,
  input  logic [15:0] s_axil_awaddr,
  input  logic [2:0]  s_axil_awprot,
  input  logic        s_axil_awvalid,
  output logic        s_axil_awready,
  input  logic [31:0] s_axil_wdata,
  input  logic [3:0]  s_axil_wstrb,
  input  logic        s_axil_wvalid,
  output logic        s_axil_wready,
  output logic [1:0]  s_axil_bresp,
  output logic        s_axil_bvalid,
  input  logic        s_axil_bready,
  input  logic [15:0] s_axil_araddr,
  input  logic [2:0]  s_axil_arprot,
  input  logic        s_axil_arvalid,
  output logic        s_axil_arready,
  output logic [31:0] s_axil_rdata,
  output logic [1:0]  s_axil_rresp,
  output logic        s_axil_rvalid,
  input  logic        s_axil_rready,
  output logic        busy,
  output logic        done,
  output logic        error,
  output logic        irq
);

  import zen_xcvu37p_cfg_pkg::*;

  zen_accel_axil_wrapper #(
    .AXIL_ADDR_W        (16),
    .BUF_BANKS          (XCVU37P_BUF_BANKS),
    .NTT_BFLY_LANES     (XCVU37P_NTT_BFLY_LANES),
    .BASEMUL_LANES      (XCVU37P_BASEMUL_LANES),
    .BASEINV_LANES      (XCVU37P_BASEINV_LANES),
    .BINARY_LANES       (XCVU37P_BINARY_LANES),
    .BINARY_COL_FACTOR  (XCVU37P_BINARY_COL_FACTOR),
    .SAMPLE_COEFF_LANES (XCVU37P_SAMPLE_COEFF_LANES)
  ) u_dut (
    .s_axil_aclk    (s_axil_aclk),
    .s_axil_aresetn (s_axil_aresetn),
    .s_axil_awaddr  (s_axil_awaddr),
    .s_axil_awprot  (s_axil_awprot),
    .s_axil_awvalid (s_axil_awvalid),
    .s_axil_awready (s_axil_awready),
    .s_axil_wdata   (s_axil_wdata),
    .s_axil_wstrb   (s_axil_wstrb),
    .s_axil_wvalid  (s_axil_wvalid),
    .s_axil_wready  (s_axil_wready),
    .s_axil_bresp   (s_axil_bresp),
    .s_axil_bvalid  (s_axil_bvalid),
    .s_axil_bready  (s_axil_bready),
    .s_axil_araddr  (s_axil_araddr),
    .s_axil_arprot  (s_axil_arprot),
    .s_axil_arvalid (s_axil_arvalid),
    .s_axil_arready (s_axil_arready),
    .s_axil_rdata   (s_axil_rdata),
    .s_axil_rresp   (s_axil_rresp),
    .s_axil_rvalid  (s_axil_rvalid),
    .s_axil_rready  (s_axil_rready),
    .busy           (busy),
    .done           (done),
    .error          (error),
    .irq            (irq)
  );

endmodule
