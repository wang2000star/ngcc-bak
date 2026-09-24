module zen_ctrl_if (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        wr_en,
  input  logic [15:0] wr_addr,
  input  logic [31:0] wr_data,
  input  logic        rd_en,
  input  logic [15:0] rd_addr,
  output logic [31:0] rd_data,

  output logic        start_pulse,
  output logic [7:0]  cmd,
  output logic [31:0] cfg,
  output logic [31:0] len,
  output logic [2:0]  buf_a_sel,
  output logic [2:0]  buf_b_sel,
  output logic [2:0]  buf_r_sel,
  output logic        host_buf_wr_en,
  output logic [2:0]  host_buf_sel,
  output logic [zen_accel_pkg::ADDR_W-1:0]  host_buf_addr,
  output logic [15:0] host_buf_wdata,
  output logic [2:0]  host_buf_rd_sel,
  output logic [zen_accel_pkg::ADDR_W-1:0]  host_buf_rd_addr,
  input  logic [15:0] host_buf_rdata,
  output logic        host_seed_wr_en,
  output logic [zen_accel_pkg::SEEDBUF_ADDR_W-1:0]  host_seed_addr,
  output logic [7:0]  host_seed_wdata,
  output logic [zen_accel_pkg::SEEDBUF_ADDR_W-1:0]  host_seed_rd_addr,
  input  logic [7:0]  host_seed_rdata,

  input  logic        core_busy,
  input  logic        core_done,
  input  logic        core_error,
  input  logic        host_access_lock
);

  logic ctrl_start_d;
  logic [31:0] ctrl_reg;
  logic [31:0] status_reg;
  logic [2:0]  host_buf_sel_reg;
  logic [zen_accel_pkg::ADDR_W-1:0]  host_buf_addr_reg;
  logic [15:0] host_buf_wdata_reg;
  logic [15:0] host_buf_rdata_reg;
  logic [zen_accel_pkg::SEEDBUF_ADDR_W-1:0]  host_seed_addr_reg;
  logic [7:0]  host_seed_wdata_reg;
  logic [7:0]  host_seed_rdata_reg;
  logic blocked_host_buf_write;
  logic blocked_host_buf_read;
  logic blocked_host_seed_write;
  logic blocked_host_seed_read;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      ctrl_reg <= '0;
      status_reg <= '0;
      cmd <= '0;
      cfg <= '0;
      len <= '0;
      buf_a_sel <= '0;
      buf_b_sel <= '0;
      buf_r_sel <= '0;
      host_buf_sel_reg <= '0;
      host_buf_addr_reg <= '0;
      host_buf_wdata_reg <= '0;
      host_buf_rdata_reg <= '0;
      host_seed_addr_reg <= '0;
      host_seed_wdata_reg <= '0;
      host_seed_rdata_reg <= '0;
      ctrl_start_d <= 1'b0;
    end else begin
      ctrl_start_d <= ctrl_reg[0];

      status_reg[0] <= core_busy;
      if (core_done) status_reg[1] <= 1'b1;
      if (core_error) status_reg[2] <= 1'b1;
      if (blocked_host_buf_write || blocked_host_buf_read ||
          blocked_host_seed_write || blocked_host_seed_read) begin
        status_reg[3] <= 1'b1;
      end
      host_buf_rdata_reg <= host_buf_rdata;
      host_seed_rdata_reg <= host_seed_rdata;

      if (wr_en) begin
        unique case (wr_addr)
          16'h0000: begin
            ctrl_reg <= wr_data;
            if (wr_data[0]) begin
              status_reg[1] <= 1'b0;
              status_reg[2] <= 1'b0;
              status_reg[3] <= 1'b0;
            end
          end
          16'h0008: cmd <= wr_data[7:0];
          16'h000c: cfg <= wr_data;
          16'h0010: len <= wr_data;
          16'h0020: buf_a_sel <= wr_data[2:0];
          16'h0024: buf_b_sel <= wr_data[2:0];
          16'h0028: buf_r_sel <= wr_data[2:0];
          16'h0100: host_buf_sel_reg <= wr_data[2:0];
          16'h0104: host_buf_addr_reg <= wr_data[zen_accel_pkg::ADDR_W-1:0];
          16'h0108: host_buf_wdata_reg <= wr_data[15:0];
          16'h0120: host_seed_addr_reg <= wr_data[zen_accel_pkg::SEEDBUF_ADDR_W-1:0];
          16'h0124: host_seed_wdata_reg <= wr_data[7:0];
          default: ;
        endcase
      end else if (ctrl_reg[0]) begin
        ctrl_reg[0] <= 1'b0;
      end
    end
  end

  always_comb begin
    blocked_host_buf_write = wr_en && host_access_lock && (wr_addr == 16'h010C);
    blocked_host_buf_read = rd_en && host_access_lock && (rd_addr == 16'h0110);
    blocked_host_seed_write = wr_en && host_access_lock && (wr_addr == 16'h0128);
    blocked_host_seed_read = rd_en && host_access_lock && (rd_addr == 16'h012C);
    start_pulse = ctrl_reg[0] & ~ctrl_start_d;
    host_buf_wr_en = wr_en && (wr_addr == 16'h010C) && !host_access_lock;
    host_buf_sel = host_buf_sel_reg;
    host_buf_addr = host_buf_addr_reg;
    host_buf_wdata = host_buf_wdata_reg;
    host_buf_rd_sel = host_buf_sel_reg;
    host_buf_rd_addr = host_buf_addr_reg;
    host_seed_wr_en = wr_en && (wr_addr == 16'h0128) && !host_access_lock;
    host_seed_addr = host_seed_addr_reg;
    host_seed_wdata = host_seed_wdata_reg;
    host_seed_rd_addr = host_seed_addr_reg;
    rd_data = 32'h0;

    if (rd_en) begin
      unique case (rd_addr)
        16'h0000: rd_data = ctrl_reg;
        16'h0004: rd_data = status_reg;
        16'h0008: rd_data = {24'h0, cmd};
        16'h000c: rd_data = cfg;
        16'h0010: rd_data = len;
        16'h0020: rd_data = {29'h0, buf_a_sel};
        16'h0024: rd_data = {29'h0, buf_b_sel};
        16'h0028: rd_data = {29'h0, buf_r_sel};
        16'h0100: rd_data = {29'h0, host_buf_sel_reg};
        16'h0104: rd_data = {{(32-zen_accel_pkg::ADDR_W){1'b0}}, host_buf_addr_reg};
        16'h0108: rd_data = {16'h0, host_buf_wdata_reg};
        16'h0110: rd_data = host_access_lock ? 32'h0 : {16'h0, host_buf_rdata_reg};
        16'h0120: rd_data = {{(32-zen_accel_pkg::SEEDBUF_ADDR_W){1'b0}}, host_seed_addr_reg};
        16'h0124: rd_data = {24'h0, host_seed_wdata_reg};
        16'h012C: rd_data = host_access_lock ? 32'h0 : {24'h0, host_seed_rdata_reg};
        default: rd_data = 32'h0;
      endcase
    end
  end

endmodule
