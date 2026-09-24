module zen_modarith_core #(
  parameter int LANES = zen_accel_pkg::MODMUL_LANES
) (
  input  logic                             clk,
  input  logic                             rst_n,
  input  logic [LANES-1:0]                 op_valid,
  input  logic [LANES-1:0]                 reduce_only,
  input  logic [LANES-1:0][15:0]           mul_a,
  input  logic [LANES-1:0][15:0]           mul_b,
  input  logic [LANES-1:0][31:0]           reduce_in,
  output logic [LANES-1:0]                 op_ready,
  output logic [LANES-1:0]                 res_valid,
  output logic [LANES-1:0][15:0]           res_data
);

  localparam logic signed [15:0] QINV = -16'sd767;
  localparam logic [15:0] ZEN_Q = 16'd769;

  logic [LANES-1:0][31:0] op_data;
  integer i;

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
    for (i = 0; i < LANES; i++) begin
      op_ready[i] = 1'b1;
      op_data[i] = reduce_only[i] ? reduce_in[i] : (mul_a[i] * mul_b[i]);
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      res_valid <= '0;
      res_data <= '0;
    end else begin
      res_valid <= op_valid;
      for (i = 0; i < LANES; i++) begin
        if (op_valid[i]) begin
          res_data[i] <= montgomery_reduce_lane(op_data[i]);
        end
      end
    end
  end

endmodule
