module zen_vec_prefetch_ctrl #(
  parameter int ADDR_W = 11,
  parameter int READ_LATENCY = 1
) (
  input  logic              clk,
  input  logic              rst_n,
  input  logic              start_i,
  input  logic [ADDR_W-1:0] rows_i,
  output logic              active_o,
  output logic              load_o,
  output logic              done_o,
  output logic [ADDR_W-1:0] req_row_o,
  output logic [ADDR_W-1:0] load_row_o
);

  localparam int PIPE_STAGES = (READ_LATENCY < 1) ? 1 : READ_LATENCY;

  logic              active_q;
  logic [ADDR_W-1:0] issue_row_q;
  logic              load_valid_q [0:PIPE_STAGES-1];
  logic [ADDR_W-1:0] load_row_q   [0:PIPE_STAGES-1];
  logic              issue_req;
  integer            pipe_idx;

  assign active_o = active_q;
  assign issue_req = active_q && (issue_row_q < rows_i);
  assign load_o = load_valid_q[PIPE_STAGES-1];
  assign done_o = load_valid_q[PIPE_STAGES-1] &&
                  ((load_row_q[PIPE_STAGES-1] + 1'b1) >= rows_i);
  assign req_row_o = issue_req ? issue_row_q : '0;
  assign load_row_o = load_row_q[PIPE_STAGES-1];

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      active_q <= 1'b0;
      issue_row_q <= '0;
      for (pipe_idx = 0; pipe_idx < PIPE_STAGES; pipe_idx++) begin
        load_valid_q[pipe_idx] <= 1'b0;
        load_row_q[pipe_idx] <= '0;
      end
    end else if (start_i) begin
      active_q <= (rows_i != '0);
      issue_row_q <= '0;
      for (pipe_idx = 0; pipe_idx < PIPE_STAGES; pipe_idx++) begin
        load_valid_q[pipe_idx] <= 1'b0;
        load_row_q[pipe_idx] <= '0;
      end
    end else if (active_q) begin
      for (pipe_idx = PIPE_STAGES - 1; pipe_idx > 0; pipe_idx--) begin
        load_valid_q[pipe_idx] <= load_valid_q[pipe_idx-1];
        load_row_q[pipe_idx] <= load_row_q[pipe_idx-1];
      end
      load_valid_q[0] <= issue_req;
      load_row_q[0] <= issue_row_q;
      if (issue_req) begin
        issue_row_q <= issue_row_q + 1'b1;
      end
      if (done_o) begin
        active_q <= 1'b0;
      end
    end
  end

endmodule

module zen_vec_row_loader #(
  parameter int NTT_N = 2048,
  parameter int COEFF_W = 16,
  parameter int BUF_BANKS = 8,
  parameter int ADDR_W = 11
) (
  input  logic                             clk,
  input  logic                             rst_n,
  input  logic                             clear_i,
  input  logic                             load_i,
  input  logic [ADDR_W-1:0]                row_i,
  input  logic [BUF_BANKS*COEFF_W-1:0]     row_vec_i,
  output logic [NTT_N*COEFF_W-1:0]         vec_o
);

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
