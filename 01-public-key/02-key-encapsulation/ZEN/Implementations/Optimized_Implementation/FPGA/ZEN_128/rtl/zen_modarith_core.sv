module zen_modarith_core #(
  parameter int LANES_P = zen_accel_pkg::MODMUL_LANES
) (
  input  logic                                         clk,
  input  logic                                         rst_n,
  input  logic [LANES_P-1:0]                           op_valid,
  input  logic [LANES_P-1:0]                           reduce_only,
  input  logic signed [LANES_P-1:0][15:0]              mul_a,
  input  logic signed [LANES_P-1:0][15:0]              mul_b,
  input  logic signed [LANES_P-1:0][31:0]              reduce_in,
  output logic [LANES_P-1:0]                           op_ready,
  output logic [LANES_P-1:0]                           res_valid,
  output logic signed [LANES_P-1:0][15:0]              res_data
);

  import zen_accel_pkg::*;
  localparam int LANES = LANES_P;

  localparam logic signed [15:0] QINV = -16'sd767;
  localparam logic [15:0] ZEN_Q = 16'd769;

  logic signed [LANES-1:0][31:0] op_data;
  function automatic logic [15:0] montgomery_reduce_lane(input logic [31:0] a);
    logic signed [15:0] u_local;
    logic signed [31:0] t_local;
    begin
      u_local = a[15:0] * QINV;
      t_local = $signed(a) - ($signed(u_local) * $signed({1'b0, ZEN_Q}));
      montgomery_reduce_lane = t_local[31:16];
    end
  endfunction

  always_comb begin
    for (int lane_idx = 0; lane_idx < LANES; lane_idx++) begin
      op_ready[lane_idx] = 1'b1;
      op_data[lane_idx] = reduce_only[lane_idx] ? reduce_in[lane_idx] : (mul_a[lane_idx] * mul_b[lane_idx]);
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      res_valid <= '0;
      res_data <= '0;
    end else begin
      res_valid <= op_valid;
      for (int lane_idx = 0; lane_idx < LANES; lane_idx++) begin
        if (op_valid[lane_idx]) begin
          res_data[lane_idx] <= montgomery_reduce_lane(op_data[lane_idx]);
        end
      end
    end
  end

endmodule
