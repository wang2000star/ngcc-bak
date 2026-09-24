(* keep_hierarchy = "yes" *)
module zen_basemul4_zeta_block #(
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic signed [COEFF_W-1:0] c0_i,
  input  logic signed [COEFF_W-1:0] c1_i,
  input  logic signed [COEFF_W-1:0] c2_i,
  input  logic signed [COEFF_W-1:0] c3_i,
  input  logic signed [COEFF_W-1:0] p13_i,
  input  logic signed [COEFF_W-1:0] p23_i,
  input  logic signed [COEFF_W-1:0] p01_i,
  input  logic signed [COEFF_W-1:0] p02_i,
  input  logic signed [COEFF_W-1:0] p03_i,
  input  logic signed [COEFF_W-1:0] p12_i,
  input  logic signed [COEFF_W-1:0] zeta_i,
  output logic signed [4*COEFF_W-1:0] block_o
);

  import zen_ntt_const_pkg::*;

  logic signed [COEFF_W-1:0] t0;
  logic signed [COEFF_W-1:0] t1;
  logic signed [COEFF_W-1:0] base1;
  logic signed [COEFF_W-1:0] base2;
  logic signed [COEFF_W-1:0] r0;
  logic signed [COEFF_W-1:0] r1;
  logic signed [COEFF_W-1:0] r2;
  logic signed [COEFF_W-1:0] r3;

  always_comb begin
    t0 = p13_i - c1_i - c3_i + c2_i;
    t1 = p23_i - c2_i - c3_i;
    base1 = p01_i - c0_i - c1_i;
    base2 = c1_i + p02_i - c0_i - c2_i;
    r0 = fqmul(t0, zeta_i) + c0_i;
    r1 = fqmul(t1, zeta_i) + base1;
    r2 = fqmul(c3_i, zeta_i) + base2;
    r3 = p03_i - c0_i - c3_i + p12_i - c1_i - c2_i;
    block_o = {r3, r2, r1, r0};
  end

endmodule

(* keep_hierarchy = "yes" *)
module zen_karatsuba_mul4_block #(
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic signed [4*COEFF_W-1:0] a_vec_i,
  input  logic signed [4*COEFF_W-1:0] b_vec_i,
  output logic signed [7*COEFF_W-1:0] poly_vec_o
);

  import zen_ntt_const_pkg::*;

  function automatic logic signed [COEFF_W-1:0] coeff_get4(
    input logic signed [4*COEFF_W-1:0] vec,
    input int idx
  );
    begin
      coeff_get4 = vec[idx*COEFF_W +: COEFF_W];
    end
  endfunction

  logic signed [COEFF_W-1:0] a0;
  logic signed [COEFF_W-1:0] a1;
  logic signed [COEFF_W-1:0] a2;
  logic signed [COEFF_W-1:0] a3;
  logic signed [COEFF_W-1:0] b0;
  logic signed [COEFF_W-1:0] b1;
  logic signed [COEFF_W-1:0] b2;
  logic signed [COEFF_W-1:0] b3;
  logic signed [COEFF_W-1:0] a01;
  logic signed [COEFF_W-1:0] a23;
  logic signed [COEFF_W-1:0] b01;
  logic signed [COEFF_W-1:0] b23;
  logic signed [COEFF_W-1:0] p0_0;
  logic signed [COEFF_W-1:0] p0_1;
  logic signed [COEFF_W-1:0] p0_2;
  logic signed [COEFF_W-1:0] p1_0;
  logic signed [COEFF_W-1:0] p1_1;
  logic signed [COEFF_W-1:0] p1_2;
  logic signed [COEFF_W-1:0] pm_0;
  logic signed [COEFF_W-1:0] pm_1;
  logic signed [COEFF_W-1:0] pm_2;
  logic signed [COEFF_W-1:0] r0;
  logic signed [COEFF_W-1:0] r1;
  logic signed [COEFF_W-1:0] r2;
  logic signed [COEFF_W-1:0] r3;
  logic signed [COEFF_W-1:0] r4;
  logic signed [COEFF_W-1:0] r5;
  logic signed [COEFF_W-1:0] r6;

  always_comb begin
    a0 = coeff_get4(a_vec_i, 0);
    a1 = coeff_get4(a_vec_i, 1);
    a2 = coeff_get4(a_vec_i, 2);
    a3 = coeff_get4(a_vec_i, 3);
    b0 = coeff_get4(b_vec_i, 0);
    b1 = coeff_get4(b_vec_i, 1);
    b2 = coeff_get4(b_vec_i, 2);
    b3 = coeff_get4(b_vec_i, 3);

    p0_0 = fqmul(a0, b0);
    p0_2 = fqmul(a1, b1);
    p0_1 = fqmul(a0 + a1, b0 + b1) - p0_0 - p0_2;

    p1_0 = fqmul(a2, b2);
    p1_2 = fqmul(a3, b3);
    p1_1 = fqmul(a2 + a3, b2 + b3) - p1_0 - p1_2;

    a01 = a0 + a2;
    a23 = a1 + a3;
    b01 = b0 + b2;
    b23 = b1 + b3;

    pm_0 = fqmul(a01, b01);
    pm_2 = fqmul(a23, b23);
    pm_1 = fqmul(a01 + a23, b01 + b23) - pm_0 - pm_2;

    r0 = p0_0;
    r1 = p0_1;
    r2 = p0_2 + pm_0 - p0_0 - p1_0;
    r3 = pm_1 - p0_1 - p1_1;
    r4 = p1_0 + pm_2 - p0_2 - p1_2;
    r5 = p1_1;
    r6 = p1_2;

    poly_vec_o = {r6, r5, r4, r3, r2, r1, r0};
  end

endmodule

(* keep_hierarchy = "yes" *)
module zen_basemul4_post_block #(
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic signed [4*COEFF_W-1:0] block_i,
  input  logic                        mq_mode_i,
  output logic signed [4*COEFF_W-1:0] block_o
);

  import zen_ntt_const_pkg::*;

  function automatic logic signed [COEFF_W-1:0] block_get4(
    input logic signed [4*COEFF_W-1:0] block,
    input int idx
  );
    begin
      block_get4 = block[idx*COEFF_W +: COEFF_W];
    end
  endfunction

  logic signed [COEFF_W-1:0] r0;
  logic signed [COEFF_W-1:0] r1;
  logic signed [COEFF_W-1:0] r2;
  logic signed [COEFF_W-1:0] r3;

  always_comb begin
    r0 = block_get4(block_i, 0);
    r1 = block_get4(block_i, 1);
    r2 = block_get4(block_i, 2);
    r3 = block_get4(block_i, 3);
    if (mq_mode_i) begin
      r0 = norm_q(fqmul(r0, 16'sd19));
      r1 = norm_q(fqmul(r1, 16'sd19));
      r2 = norm_q(fqmul(r2, 16'sd19));
      r3 = norm_q(fqmul(r3, 16'sd19));
    end
    block_o = {r3, r2, r1, r0};
  end

endmodule
