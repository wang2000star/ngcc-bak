module zen_accel_axil_wrapper (
  input  logic                    s_axil_aclk,
  input  logic                    s_axil_aresetn,
  input  zen_accel_pkg::zen_axil_addr_t s_axil_awaddr,
  input  logic [2:0]              s_axil_awprot,
  input  logic                    s_axil_awvalid,
  output logic                    s_axil_awready,
  input  logic [31:0]             s_axil_wdata,
  input  logic [3:0]              s_axil_wstrb,
  input  logic                    s_axil_wvalid,
  output logic                    s_axil_wready,
  output logic [1:0]              s_axil_bresp,
  output logic                    s_axil_bvalid,
  input  logic                    s_axil_bready,
  input  zen_accel_pkg::zen_axil_addr_t s_axil_araddr,
  input  logic [2:0]              s_axil_arprot,
  input  logic                    s_axil_arvalid,
  output logic                    s_axil_arready,
  output logic [31:0]             s_axil_rdata,
  output logic [1:0]              s_axil_rresp,
  output logic                    s_axil_rvalid,
  input  logic                    s_axil_rready,
  output logic                    busy,
  output logic                    done,
  output logic                    error,
  output logic                    irq
);

  import zen_accel_pkg::*;

  localparam logic [1:0] AXI_RESP_OKAY   = 2'b00;
  localparam logic [1:0] AXI_RESP_SLVERR = 2'b10;

  logic                   core_wr_en;
  logic [15:0]            core_wr_addr;
  logic [31:0]            core_wr_data;
  logic                   core_rd_en;
  logic [15:0]            core_rd_addr;
  logic [31:0]            core_rd_data;

  logic                   aw_captured;
  zen_axil_addr_t awaddr_q;
  logic                   w_captured;
  logic [31:0]            wdata_q;
  logic [3:0]             wstrb_q;

  logic                   bvalid_q;
  logic [1:0]             bresp_q;
  logic                   rvalid_q;
  logic [1:0]             rresp_q;
  logic [31:0]            rdata_q;

  logic                   take_aw;
  logic                   take_w;
  logic                   write_commit;
  zen_axil_addr_t write_addr;
  logic [31:0]            write_data;
  logic [3:0]             write_wstrb;
  logic                   read_fire;

  assign take_aw = s_axil_awvalid && s_axil_awready;
  assign take_w = s_axil_wvalid && s_axil_wready;
  assign write_commit = (aw_captured || take_aw) && (w_captured || take_w) && !bvalid_q;
  assign write_addr = take_aw ? s_axil_awaddr : awaddr_q;
  assign write_data = take_w ? s_axil_wdata : wdata_q;
  assign write_wstrb = take_w ? s_axil_wstrb : wstrb_q;
  assign read_fire = s_axil_arvalid && s_axil_arready;

  assign s_axil_awready = !bvalid_q && !aw_captured;
  assign s_axil_wready = !bvalid_q && !w_captured;
  assign s_axil_bvalid = bvalid_q;
  assign s_axil_bresp = bresp_q;
  assign s_axil_arready = !rvalid_q;
  assign s_axil_rvalid = rvalid_q;
  assign s_axil_rresp = rresp_q;
  assign s_axil_rdata = rdata_q;

  /*
   * Current core register file expects full 32-bit writes. The PS driver will
   * use word writes only, so partial-byte writes are rejected explicitly.
   */
  assign core_wr_en = write_commit && (write_wstrb == 4'hF);
  assign core_wr_addr = write_addr[15:0];
  assign core_wr_data = write_data;

  assign core_rd_en = read_fire;
  assign core_rd_addr = s_axil_araddr[15:0];

  zen_accel_top u_core (
    .clk     (s_axil_aclk),
    .rst_n   (s_axil_aresetn),
    .wr_en   (core_wr_en),
    .wr_addr (core_wr_addr),
    .wr_data (core_wr_data),
    .rd_en   (core_rd_en),
    .rd_addr (core_rd_addr),
    .rd_data (core_rd_data),
    .busy    (busy),
    .done    (done),
    .error   (error),
    .irq     (irq)
  );

  always_ff @(posedge s_axil_aclk or negedge s_axil_aresetn) begin
    if (!s_axil_aresetn) begin
      aw_captured <= 1'b0;
      awaddr_q <= '0;
      w_captured <= 1'b0;
      wdata_q <= '0;
      wstrb_q <= '0;
      bvalid_q <= 1'b0;
      bresp_q <= AXI_RESP_OKAY;
      rvalid_q <= 1'b0;
      rresp_q <= AXI_RESP_OKAY;
      rdata_q <= '0;
    end else begin
      if (take_aw) begin
        aw_captured <= 1'b1;
        awaddr_q <= s_axil_awaddr;
      end

      if (take_w) begin
        w_captured <= 1'b1;
        wdata_q <= s_axil_wdata;
        wstrb_q <= s_axil_wstrb;
      end

      if (write_commit) begin
        aw_captured <= 1'b0;
        w_captured <= 1'b0;
        bvalid_q <= 1'b1;
        bresp_q <= (write_wstrb == 4'hF) ? AXI_RESP_OKAY : AXI_RESP_SLVERR;
      end else if (bvalid_q && s_axil_bready) begin
        bvalid_q <= 1'b0;
      end

      if (read_fire) begin
        rvalid_q <= 1'b1;
        rresp_q <= AXI_RESP_OKAY;
        rdata_q <= core_rd_data;
      end else if (rvalid_q && s_axil_rready) begin
        rvalid_q <= 1'b0;
      end
    end
  end

endmodule
