module zen_vec_prefetch_ctrl (
  input  logic                         clk,
  input  logic                         rst_n,
  input  logic                         start_i,
  input  zen_accel_pkg::zen_row_addr_t rows_i,
  output logic                         active_o,
  output logic                         load_o,
  output logic                         done_o,
  output zen_accel_pkg::zen_row_addr_t req_row_o,
  output zen_accel_pkg::zen_row_addr_t load_row_o
);

  import zen_accel_pkg::*;

  logic          active_q;
  logic          have_pending_q;
  zen_row_addr_t issue_row_q;
  zen_row_addr_t pending_row_q;

  assign active_o = active_q;
  assign load_o = active_q && have_pending_q;
  assign done_o = active_q && have_pending_q && (issue_row_q >= rows_i);
  assign req_row_o = (issue_row_q < rows_i) ? issue_row_q : pending_row_q;
  assign load_row_o = pending_row_q;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      active_q <= 1'b0;
      have_pending_q <= 1'b0;
      issue_row_q <= '0;
      pending_row_q <= '0;
    end else if (start_i) begin
      active_q <= (rows_i != '0);
      have_pending_q <= 1'b0;
      issue_row_q <= '0;
      pending_row_q <= '0;
    end else if (active_q) begin
      if (issue_row_q < rows_i) begin
        pending_row_q <= issue_row_q;
        have_pending_q <= 1'b1;
        issue_row_q <= issue_row_q + 1'b1;
      end else if (have_pending_q) begin
        active_q <= 1'b0;
        have_pending_q <= 1'b0;
      end else begin
        active_q <= 1'b0;
      end
    end
  end

endmodule

module zen_vec_row_loader (
  input  logic                        clk,
  input  logic                        rst_n,
  input  logic                        clear_i,
  input  logic                        load_i,
  input  zen_accel_pkg::zen_row_addr_t row_i,
  input  zen_accel_pkg::zen_buf_row_t row_vec_i,
  output zen_accel_pkg::zen_poly_vec_t vec_o
);

  import zen_accel_pkg::*;

  integer bank_idx;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      vec_o <= '0;
    end else if (clear_i) begin
      vec_o <= '0;
    end else if (load_i) begin
      for (bank_idx = 0; bank_idx < BUF_BANKS; bank_idx++) begin
        vec_o[(((row_i * BUF_BANKS) + bank_idx) * COEFF_W) +: COEFF_W]
          <= row_vec_i[(bank_idx * COEFF_W) +: COEFF_W];
      end
    end
  end

endmodule
