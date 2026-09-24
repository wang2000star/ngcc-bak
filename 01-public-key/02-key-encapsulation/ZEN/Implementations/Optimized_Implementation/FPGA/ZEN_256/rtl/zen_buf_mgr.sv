module zen_buf_mgr #(
  parameter int COEFF_W = 16,
  parameter int DEPTH = 512,
  parameter int ADDR_W = 9,
  parameter int BUF_COUNT = 6,
  parameter int BUF_BANKS = 8,
  parameter int BANK_DEPTH = DEPTH / BUF_BANKS
) (
  input  logic                         clk,
  input  logic                         wr_en,
  input  logic [2:0]                   wr_buf_sel,
  input  logic [ADDR_W-1:0]            wr_addr,
  input  logic [COEFF_W-1:0]           wr_data,
  input  logic [2:0]                   rd0_buf_sel,
  input  logic [ADDR_W-1:0]            rd0_addr,
  output logic [COEFF_W-1:0]           rd0_data,
  input  logic [2:0]                   rd1_buf_sel,
  input  logic [ADDR_W-1:0]            rd1_addr,
  output logic [COEFF_W-1:0]           rd1_data,
  input  logic [2:0]                   vec_rd0_buf_sel,
  output logic [BUF_BANKS*COEFF_W-1:0] vec_rd0_row_data,
  input  logic [2:0]                   vec_rd1_buf_sel,
  output logic [BUF_BANKS*COEFF_W-1:0] vec_rd1_row_data,
  input  logic [ADDR_W-1:0]            vec_rd_row,
  input  logic                         vec_wr_en,
  input  logic [2:0]                   vec_wr_buf_sel,
  input  logic [ADDR_W-1:0]            vec_wr_row,
  input  logic [BUF_BANKS*COEFF_W-1:0] vec_wr_data
);

  localparam int BANK_SEL_W = (BUF_BANKS <= 1) ? 1 : $clog2(BUF_BANKS);
  localparam int BANK_INDEX_W = (BANK_DEPTH <= 1) ? 1 : $clog2(BANK_DEPTH);

`ifdef SYNTHESIS
  logic [COEFF_W-1:0] rd0_bank_data [0:BUF_BANKS-1];
  logic [COEFF_W-1:0] rd1_bank_data [0:BUF_BANKS-1];
  logic [COEFF_W-1:0] vec_rd0_bank_data [0:BUF_BANKS-1];
  logic [COEFF_W-1:0] vec_rd1_bank_data [0:BUF_BANKS-1];
  integer bank_mux_idx;
`else
  logic [COEFF_W-1:0] mem [0:BUF_COUNT-1][0:BUF_BANKS-1][0:BANK_DEPTH-1];
  logic [BUF_BANKS*COEFF_W-1:0] vec_rd0_row_data_stage;
  logic [BUF_BANKS*COEFF_W-1:0] vec_rd1_row_data_stage;
`endif

  logic [BANK_SEL_W-1:0] wr_bank;
  logic [BANK_SEL_W-1:0] rd0_bank;
  logic [BANK_SEL_W-1:0] rd1_bank;
  logic [BANK_INDEX_W-1:0] wr_index;
  logic [BANK_INDEX_W-1:0] rd0_index;
  logic [BANK_INDEX_W-1:0] rd1_index;
  logic [BANK_INDEX_W-1:0] vec_rd_index;
  logic [BANK_INDEX_W-1:0] vec_wr_index;
  integer i;

  always_comb begin
    wr_bank = wr_addr[BANK_SEL_W-1:0];
    rd0_bank = rd0_addr[BANK_SEL_W-1:0];
    rd1_bank = rd1_addr[BANK_SEL_W-1:0];

    wr_index = BANK_INDEX_W'(wr_addr >> BANK_SEL_W);
    rd0_index = BANK_INDEX_W'(rd0_addr >> BANK_SEL_W);
    rd1_index = BANK_INDEX_W'(rd1_addr >> BANK_SEL_W);
    vec_rd_index = BANK_INDEX_W'(vec_rd_row);
    vec_wr_index = BANK_INDEX_W'(vec_wr_row);
  end

`ifdef SYNTHESIS
  generate
    genvar g_bank;
    for (g_bank = 0; g_bank < BUF_BANKS; g_bank++) begin : g_bank_store
      zen_buf_mgr_bank_store #(
        .COEFF_W(COEFF_W),
        .BUF_COUNT(BUF_COUNT),
        .BANK_DEPTH(BANK_DEPTH),
        .BUF_SEL_W(3),
        .BANK_INDEX_W(BANK_INDEX_W)
      ) u_bank_store (
        .clk(clk),
        .scalar_wr_en(wr_en && (wr_bank == BANK_SEL_W'(g_bank))),
        .scalar_wr_buf_sel(wr_buf_sel),
        .scalar_wr_index(wr_index),
        .scalar_wr_data(wr_data),
        .vec_wr_en(vec_wr_en),
        .vec_wr_buf_sel(vec_wr_buf_sel),
        .vec_wr_index(vec_wr_index),
        .vec_wr_data(vec_wr_data[g_bank*COEFF_W +: COEFF_W]),
        .rd0_buf_sel(rd0_buf_sel),
        .rd0_index(rd0_index),
        .rd0_data(rd0_bank_data[g_bank]),
        .rd1_buf_sel(rd1_buf_sel),
        .rd1_index(rd1_index),
        .rd1_data(rd1_bank_data[g_bank]),
        .vec_rd0_buf_sel(vec_rd0_buf_sel),
        .vec_rd0_index(vec_rd_index),
        .vec_rd0_data(vec_rd0_bank_data[g_bank]),
        .vec_rd1_buf_sel(vec_rd1_buf_sel),
        .vec_rd1_index(vec_rd_index),
        .vec_rd1_data(vec_rd1_bank_data[g_bank])
      );
    end

    genvar g_row_bank;
    for (g_row_bank = 0; g_row_bank < BUF_BANKS; g_row_bank++) begin : g_row_bank_map
      assign vec_rd0_row_data[g_row_bank*COEFF_W +: COEFF_W] = vec_rd0_bank_data[g_row_bank];
      assign vec_rd1_row_data[g_row_bank*COEFF_W +: COEFF_W] = vec_rd1_bank_data[g_row_bank];
    end
  endgenerate

  always_comb begin
    rd0_data = '0;
    rd1_data = '0;
    for (bank_mux_idx = 0; bank_mux_idx < BUF_BANKS; bank_mux_idx++) begin
      if (rd0_bank == BANK_SEL_W'(bank_mux_idx)) begin
        rd0_data = rd0_bank_data[bank_mux_idx];
      end
      if (rd1_bank == BANK_SEL_W'(bank_mux_idx)) begin
        rd1_data = rd1_bank_data[bank_mux_idx];
      end
    end
  end
`else
  always_ff @(posedge clk) begin
    if (wr_en) begin
      mem[wr_buf_sel][wr_bank][wr_index] <= wr_data;
    end
    if (vec_wr_en) begin
      for (i = 0; i < BUF_BANKS; i++) begin
        mem[vec_wr_buf_sel][i][vec_wr_index] <= vec_wr_data[i*COEFF_W +: COEFF_W];
      end
    end
    rd0_data <= mem[rd0_buf_sel][rd0_bank][rd0_index];
    rd1_data <= mem[rd1_buf_sel][rd1_bank][rd1_index];
    vec_rd0_row_data <= vec_rd0_row_data_stage;
    vec_rd1_row_data <= vec_rd1_row_data_stage;
    for (i = 0; i < BUF_BANKS; i++) begin
      vec_rd0_row_data_stage[i*COEFF_W +: COEFF_W] <= mem[vec_rd0_buf_sel][i][vec_rd_index];
      vec_rd1_row_data_stage[i*COEFF_W +: COEFF_W] <= mem[vec_rd1_buf_sel][i][vec_rd_index];
    end
  end
`endif

endmodule

`ifdef SYNTHESIS
module zen_buf_mgr_sdp_ram #(
  parameter int COEFF_W = 16,
  parameter int BANK_DEPTH = 64,
  parameter int BANK_INDEX_W = 6,
  parameter bit EXTRA_OUT_REG = 1'b0
) (
  input  logic                    clk,
  input  logic                    wr_en,
  input  logic [BANK_INDEX_W-1:0] wr_addr,
  input  logic [COEFF_W-1:0]      wr_data,
  input  logic [BANK_INDEX_W-1:0] rd_addr,
  output logic [COEFF_W-1:0]      rd_data
);

  (* ram_style = "block" *) logic [COEFF_W-1:0] mem [0:BANK_DEPTH-1];

  generate
    if (EXTRA_OUT_REG) begin : g_extra_out_reg
      logic [COEFF_W-1:0] rd_data_stage_q;

      always_ff @(posedge clk) begin
        if (wr_en) begin
          mem[wr_addr] <= wr_data;
        end
        rd_data_stage_q <= mem[rd_addr];
        rd_data <= rd_data_stage_q;
      end
    end else begin : g_no_extra_out_reg
      always_ff @(posedge clk) begin
        if (wr_en) begin
          mem[wr_addr] <= wr_data;
        end
        rd_data <= mem[rd_addr];
      end
    end
  endgenerate

endmodule

module zen_buf_mgr_bank_store #(
  parameter int COEFF_W = 16,
  parameter int BUF_COUNT = 6,
  parameter int BANK_DEPTH = 64,
  parameter int BUF_SEL_W = 3,
  parameter int BANK_INDEX_W = 6
) (
  input  logic                    clk,
  input  logic                    scalar_wr_en,
  input  logic [BUF_SEL_W-1:0]    scalar_wr_buf_sel,
  input  logic [BANK_INDEX_W-1:0] scalar_wr_index,
  input  logic [COEFF_W-1:0]      scalar_wr_data,
  input  logic                    vec_wr_en,
  input  logic [BUF_SEL_W-1:0]    vec_wr_buf_sel,
  input  logic [BANK_INDEX_W-1:0] vec_wr_index,
  input  logic [COEFF_W-1:0]      vec_wr_data,
  input  logic [BUF_SEL_W-1:0]    rd0_buf_sel,
  input  logic [BANK_INDEX_W-1:0] rd0_index,
  output logic [COEFF_W-1:0]      rd0_data,
  input  logic [BUF_SEL_W-1:0]    rd1_buf_sel,
  input  logic [BANK_INDEX_W-1:0] rd1_index,
  output logic [COEFF_W-1:0]      rd1_data,
  input  logic [BUF_SEL_W-1:0]    vec_rd0_buf_sel,
  input  logic [BANK_INDEX_W-1:0] vec_rd0_index,
  output logic [COEFF_W-1:0]      vec_rd0_data,
  input  logic [BUF_SEL_W-1:0]    vec_rd1_buf_sel,
  input  logic [BANK_INDEX_W-1:0] vec_rd1_index,
  output logic [COEFF_W-1:0]      vec_rd1_data
);

  logic [COEFF_W-1:0] rd0_buf_data_arr [0:BUF_COUNT-1];
  logic [COEFF_W-1:0] rd1_buf_data_arr [0:BUF_COUNT-1];
  logic [COEFF_W-1:0] vec0_buf_data_arr [0:BUF_COUNT-1];
  logic [COEFF_W-1:0] vec1_buf_data_arr [0:BUF_COUNT-1];
  logic                    bank_wr_en;
  logic [BUF_SEL_W-1:0]    bank_wr_buf_sel;
  logic [BANK_INDEX_W-1:0] bank_wr_index;
  logic [COEFF_W-1:0]      bank_wr_data;
  integer                  buf_mux_idx;

  genvar g_buf;
  generate
    for (g_buf = 0; g_buf < BUF_COUNT; g_buf++) begin : g_buf_ram
      zen_buf_mgr_sdp_ram #(
        .COEFF_W(COEFF_W),
        .BANK_DEPTH(BANK_DEPTH),
        .BANK_INDEX_W(BANK_INDEX_W)
      ) u_rd0_ram (
        .clk(clk),
        .wr_en(bank_wr_en && (bank_wr_buf_sel == BUF_SEL_W'(g_buf))),
        .wr_addr(bank_wr_index),
        .wr_data(bank_wr_data),
        .rd_addr(rd0_index),
        .rd_data(rd0_buf_data_arr[g_buf])
      );

      zen_buf_mgr_sdp_ram #(
        .COEFF_W(COEFF_W),
        .BANK_DEPTH(BANK_DEPTH),
        .BANK_INDEX_W(BANK_INDEX_W)
      ) u_rd1_ram (
        .clk(clk),
        .wr_en(bank_wr_en && (bank_wr_buf_sel == BUF_SEL_W'(g_buf))),
        .wr_addr(bank_wr_index),
        .wr_data(bank_wr_data),
        .rd_addr(rd1_index),
        .rd_data(rd1_buf_data_arr[g_buf])
      );

      zen_buf_mgr_sdp_ram #(
        .COEFF_W(COEFF_W),
        .BANK_DEPTH(BANK_DEPTH),
        .BANK_INDEX_W(BANK_INDEX_W),
        .EXTRA_OUT_REG(1'b1)
      ) u_vec0_ram (
        .clk(clk),
        .wr_en(bank_wr_en && (bank_wr_buf_sel == BUF_SEL_W'(g_buf))),
        .wr_addr(bank_wr_index),
        .wr_data(bank_wr_data),
        .rd_addr(vec_rd0_index),
        .rd_data(vec0_buf_data_arr[g_buf])
      );

      zen_buf_mgr_sdp_ram #(
        .COEFF_W(COEFF_W),
        .BANK_DEPTH(BANK_DEPTH),
        .BANK_INDEX_W(BANK_INDEX_W),
        .EXTRA_OUT_REG(1'b1)
      ) u_vec1_ram (
        .clk(clk),
        .wr_en(bank_wr_en && (bank_wr_buf_sel == BUF_SEL_W'(g_buf))),
        .wr_addr(bank_wr_index),
        .wr_data(bank_wr_data),
        .rd_addr(vec_rd1_index),
        .rd_data(vec1_buf_data_arr[g_buf])
      );
    end
  endgenerate

  always_comb begin
    // Top-level write arbitration keeps scalar and row writes mutually exclusive.
    bank_wr_en = scalar_wr_en || vec_wr_en;
    bank_wr_buf_sel = scalar_wr_buf_sel;
    bank_wr_index = scalar_wr_index;
    bank_wr_data = scalar_wr_data;
    if (vec_wr_en) begin
      bank_wr_buf_sel = vec_wr_buf_sel;
      bank_wr_index = vec_wr_index;
      bank_wr_data = vec_wr_data;
    end
    rd0_data = '0;
    rd1_data = '0;
    vec_rd0_data = '0;
    vec_rd1_data = '0;
    for (buf_mux_idx = 0; buf_mux_idx < BUF_COUNT; buf_mux_idx++) begin
      if (rd0_buf_sel == BUF_SEL_W'(buf_mux_idx)) begin
        rd0_data = rd0_buf_data_arr[buf_mux_idx];
      end
      if (rd1_buf_sel == BUF_SEL_W'(buf_mux_idx)) begin
        rd1_data = rd1_buf_data_arr[buf_mux_idx];
      end
      if (vec_rd0_buf_sel == BUF_SEL_W'(buf_mux_idx)) begin
        vec_rd0_data = vec0_buf_data_arr[buf_mux_idx];
      end
      if (vec_rd1_buf_sel == BUF_SEL_W'(buf_mux_idx)) begin
        vec_rd1_data = vec1_buf_data_arr[buf_mux_idx];
      end
    end
  end

endmodule
`endif
