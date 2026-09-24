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
module zen_karatsuba_mul8_block_exact #(
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic signed [8*COEFF_W-1:0] a_vec_i,
  input  logic signed [8*COEFF_W-1:0] b_vec_i,
  output logic signed [15*COEFF_W-1:0] poly_vec_o
);

  import zen_ntt_const_pkg::*;

  function automatic logic signed [COEFF_W-1:0] coeff_get8(
    input logic signed [8*COEFF_W-1:0] vec,
    input int idx
  );
    begin
      coeff_get8 = vec[idx*COEFF_W +: COEFF_W];
    end
  endfunction

  function automatic logic signed [COEFF_W-1:0] coeff_get4(
    input logic signed [4*COEFF_W-1:0] vec,
    input int idx
  );
    begin
      coeff_get4 = vec[idx*COEFF_W +: COEFF_W];
    end
  endfunction

  function automatic logic signed [7*COEFF_W-1:0] poly_mul4_exact(
    input logic signed [4*COEFF_W-1:0] a_vec,
    input logic signed [4*COEFF_W-1:0] b_vec
  );
    logic signed [COEFF_W-1:0] a0;
    logic signed [COEFF_W-1:0] a1;
    logic signed [COEFF_W-1:0] a2;
    logic signed [COEFF_W-1:0] a3;
    logic signed [COEFF_W-1:0] b0;
    logic signed [COEFF_W-1:0] b1;
    logic signed [COEFF_W-1:0] b2;
    logic signed [COEFF_W-1:0] b3;
    logic signed [COEFF_W-1:0] c0;
    logic signed [COEFF_W-1:0] c1;
    logic signed [COEFF_W-1:0] c2;
    logic signed [COEFF_W-1:0] c3;
    logic signed [COEFF_W-1:0] s01;
    logic signed [COEFF_W-1:0] s02;
    logic signed [COEFF_W-1:0] s03;
    logic signed [COEFF_W-1:0] s12;
    logic signed [COEFF_W-1:0] s13;
    logic signed [COEFF_W-1:0] s23;
    begin
      a0 = coeff_get4(a_vec, 0);
      a1 = coeff_get4(a_vec, 1);
      a2 = coeff_get4(a_vec, 2);
      a3 = coeff_get4(a_vec, 3);
      b0 = coeff_get4(b_vec, 0);
      b1 = coeff_get4(b_vec, 1);
      b2 = coeff_get4(b_vec, 2);
      b3 = coeff_get4(b_vec, 3);

      c0 = zen_ntt_const_pkg::fqmul(a0, b0);
      c1 = zen_ntt_const_pkg::fqmul(a1, b1);
      c2 = zen_ntt_const_pkg::fqmul(a2, b2);
      c3 = zen_ntt_const_pkg::fqmul(a3, b3);

      s01 = zen_ntt_const_pkg::fqmul(a0 + a1, b0 + b1) - c0 - c1;
      s02 = zen_ntt_const_pkg::fqmul(a0 + a2, b0 + b2) - c0 - c2;
      s03 = zen_ntt_const_pkg::fqmul(a0 + a3, b0 + b3) - c0 - c3;
      s12 = zen_ntt_const_pkg::fqmul(a1 + a2, b1 + b2) - c1 - c2;
      s13 = zen_ntt_const_pkg::fqmul(a1 + a3, b1 + b3) - c1 - c3;
      s23 = zen_ntt_const_pkg::fqmul(a2 + a3, b2 + b3) - c2 - c3;

      poly_mul4_exact = {
        c3,
        s23,
        s13 + c2,
        s03 + s12,
        s02 + c1,
        s01,
        c0
      };
    end
  endfunction

  function automatic logic signed [COEFF_W-1:0] poly7_get(
    input logic signed [7*COEFF_W-1:0] poly,
    input int idx
  );
    begin
      poly7_get = poly[idx*COEFF_W +: COEFF_W];
    end
  endfunction

  logic signed [4*COEFF_W-1:0] p0_a_vec;
  logic signed [4*COEFF_W-1:0] p0_b_vec;
  logic signed [4*COEFF_W-1:0] p1_a_vec;
  logic signed [4*COEFF_W-1:0] p1_b_vec;
  logic signed [4*COEFF_W-1:0] pm_a_vec;
  logic signed [4*COEFF_W-1:0] pm_b_vec;
  logic signed [7*COEFF_W-1:0] p0_pack;
  logic signed [7*COEFF_W-1:0] p1_pack;
  logic signed [7*COEFF_W-1:0] pm_pack;
  logic signed [14:0][COEFF_W-1:0] r;
  integer i;

  assign p0_a_vec = a_vec_i[0 +: 4*COEFF_W];
  assign p0_b_vec = b_vec_i[0 +: 4*COEFF_W];
  assign p1_a_vec = a_vec_i[4*COEFF_W +: 4*COEFF_W];
  assign p1_b_vec = b_vec_i[4*COEFF_W +: 4*COEFF_W];

  zen_karatsuba_mul4_block #(
    .COEFF_W(COEFF_W)
  ) u_p0 (
    .a_vec_i(p0_a_vec),
    .b_vec_i(p0_b_vec),
    .poly_vec_o(p0_pack)
  );

  zen_karatsuba_mul4_block #(
    .COEFF_W(COEFF_W)
  ) u_p1 (
    .a_vec_i(p1_a_vec),
    .b_vec_i(p1_b_vec),
    .poly_vec_o(p1_pack)
  );

  zen_karatsuba_mul4_block #(
    .COEFF_W(COEFF_W)
  ) u_pm (
    .a_vec_i(pm_a_vec),
    .b_vec_i(pm_b_vec),
    .poly_vec_o(pm_pack)
  );

  always_comb begin
    pm_a_vec = '0;
    pm_b_vec = '0;

    for (i = 0; i < 4; i++) begin
      pm_a_vec[i*COEFF_W +: COEFF_W] = coeff_get8(a_vec_i, i) + coeff_get8(a_vec_i, i + 4);
      pm_b_vec[i*COEFF_W +: COEFF_W] = coeff_get8(b_vec_i, i) + coeff_get8(b_vec_i, i + 4);
    end
  end

  always_comb begin
    r = '0;
    r[0] = poly7_get(p0_pack, 0);
    r[1] = poly7_get(p0_pack, 1);
    r[2] = poly7_get(p0_pack, 2);
    r[3] = poly7_get(p0_pack, 3);
    r[4] = poly7_get(p0_pack, 4) + poly7_get(pm_pack, 0) - poly7_get(p0_pack, 0) - poly7_get(p1_pack, 0);
    r[5] = poly7_get(p0_pack, 5) + poly7_get(pm_pack, 1) - poly7_get(p0_pack, 1) - poly7_get(p1_pack, 1);
    r[6] = poly7_get(p0_pack, 6) + poly7_get(pm_pack, 2) - poly7_get(p0_pack, 2) - poly7_get(p1_pack, 2);
    r[7] = poly7_get(pm_pack, 3) - poly7_get(p0_pack, 3) - poly7_get(p1_pack, 3);
    r[8] = poly7_get(p1_pack, 0) + poly7_get(pm_pack, 4) - poly7_get(p0_pack, 4) - poly7_get(p1_pack, 4);
    r[9] = poly7_get(p1_pack, 1) + poly7_get(pm_pack, 5) - poly7_get(p0_pack, 5) - poly7_get(p1_pack, 5);
    r[10] = poly7_get(p1_pack, 2) + poly7_get(pm_pack, 6) - poly7_get(p0_pack, 6) - poly7_get(p1_pack, 6);
    r[11] = poly7_get(p1_pack, 3);
    r[12] = poly7_get(p1_pack, 4);
    r[13] = poly7_get(p1_pack, 5);
    r[14] = poly7_get(p1_pack, 6);

    poly_vec_o = {
      r[14], r[13], r[12], r[11], r[10], r[9], r[8],
      r[7], r[6], r[5], r[4], r[3], r[2], r[1], r[0]
    };
  end

endmodule

(* keep_hierarchy = "yes" *)
module zen_mul_coeff_exact #(
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic signed [COEFF_W-1:0] a_i,
  input  logic signed [COEFF_W-1:0] b_i,
  output logic signed [COEFF_W-1:0] p_o
);

  import zen_ntt_const_pkg::*;

  always_comb begin
    p_o = fqmul(a_i, b_i);
  end

endmodule

(* keep_hierarchy = "yes" *)
module zen_pairmul_diff_exact #(
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic signed [COEFF_W-1:0] ai_i,
  input  logic signed [COEFF_W-1:0] aj_i,
  input  logic signed [COEFF_W-1:0] bi_i,
  input  logic signed [COEFF_W-1:0] bj_i,
  input  logic signed [COEFF_W-1:0] ci_i,
  input  logic signed [COEFF_W-1:0] cj_i,
  output logic signed [COEFF_W-1:0] s_o
);

  import zen_ntt_const_pkg::*;

  always_comb begin
    s_o = fqmul(ai_i + aj_i, bi_i + bj_i) - ci_i - cj_i;
  end

endmodule

(* keep_hierarchy = "yes" *)
module zen_basemul8_block_exact #(
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic signed [8*COEFF_W-1:0] a_vec_i,
  input  logic signed [8*COEFF_W-1:0] b_vec_i,
  input  logic signed [COEFF_W-1:0]   zeta_i,
  output logic signed [8*COEFF_W-1:0] block_o
);

  import zen_ntt_const_pkg::*;

  function automatic logic signed [COEFF_W-1:0] coeff_get8(
    input logic signed [8*COEFF_W-1:0] vec,
    input int idx
  );
    begin
      coeff_get8 = vec[idx*COEFF_W +: COEFF_W];
    end
  endfunction

  logic signed [COEFF_W-1:0] a0;
  logic signed [COEFF_W-1:0] a1;
  logic signed [COEFF_W-1:0] a2;
  logic signed [COEFF_W-1:0] a3;
  logic signed [COEFF_W-1:0] a4;
  logic signed [COEFF_W-1:0] a5;
  logic signed [COEFF_W-1:0] a6;
  logic signed [COEFF_W-1:0] a7;
  logic signed [COEFF_W-1:0] b0;
  logic signed [COEFF_W-1:0] b1;
  logic signed [COEFF_W-1:0] b2;
  logic signed [COEFF_W-1:0] b3;
  logic signed [COEFF_W-1:0] b4;
  logic signed [COEFF_W-1:0] b5;
  logic signed [COEFF_W-1:0] b6;
  logic signed [COEFF_W-1:0] b7;
  logic signed [COEFF_W-1:0] c0;
  logic signed [COEFF_W-1:0] c1;
  logic signed [COEFF_W-1:0] c2;
  logic signed [COEFF_W-1:0] c3;
  logic signed [COEFF_W-1:0] c4;
  logic signed [COEFF_W-1:0] c5;
  logic signed [COEFF_W-1:0] c6;
  logic signed [COEFF_W-1:0] c7;
  logic signed [COEFF_W-1:0] s01;
  logic signed [COEFF_W-1:0] s02;
  logic signed [COEFF_W-1:0] s03;
  logic signed [COEFF_W-1:0] s04;
  logic signed [COEFF_W-1:0] s05;
  logic signed [COEFF_W-1:0] s06;
  logic signed [COEFF_W-1:0] s07;
  logic signed [COEFF_W-1:0] s12;
  logic signed [COEFF_W-1:0] s13;
  logic signed [COEFF_W-1:0] s14;
  logic signed [COEFF_W-1:0] s15;
  logic signed [COEFF_W-1:0] s16;
  logic signed [COEFF_W-1:0] s17;
  logic signed [COEFF_W-1:0] s23;
  logic signed [COEFF_W-1:0] s24;
  logic signed [COEFF_W-1:0] s25;
  logic signed [COEFF_W-1:0] s26;
  logic signed [COEFF_W-1:0] s27;
  logic signed [COEFF_W-1:0] s34;
  logic signed [COEFF_W-1:0] s35;
  logic signed [COEFF_W-1:0] s36;
  logic signed [COEFF_W-1:0] s37;
  logic signed [COEFF_W-1:0] s45;
  logic signed [COEFF_W-1:0] s46;
  logic signed [COEFF_W-1:0] s47;
  logic signed [COEFF_W-1:0] s56;
  logic signed [COEFF_W-1:0] s57;
  logic signed [COEFF_W-1:0] s67;
  logic signed [COEFF_W-1:0] k;
  logic signed [COEFF_W-1:0] r0;
  logic signed [COEFF_W-1:0] r1;
  logic signed [COEFF_W-1:0] r2;
  logic signed [COEFF_W-1:0] r3;
  logic signed [COEFF_W-1:0] r4;
  logic signed [COEFF_W-1:0] r5;
  logic signed [COEFF_W-1:0] r6;
  logic signed [COEFF_W-1:0] r7;

  assign a0 = coeff_get8(a_vec_i, 0);
  assign a1 = coeff_get8(a_vec_i, 1);
  assign a2 = coeff_get8(a_vec_i, 2);
  assign a3 = coeff_get8(a_vec_i, 3);
  assign a4 = coeff_get8(a_vec_i, 4);
  assign a5 = coeff_get8(a_vec_i, 5);
  assign a6 = coeff_get8(a_vec_i, 6);
  assign a7 = coeff_get8(a_vec_i, 7);
  assign b0 = coeff_get8(b_vec_i, 0);
  assign b1 = coeff_get8(b_vec_i, 1);
  assign b2 = coeff_get8(b_vec_i, 2);
  assign b3 = coeff_get8(b_vec_i, 3);
  assign b4 = coeff_get8(b_vec_i, 4);
  assign b5 = coeff_get8(b_vec_i, 5);
  assign b6 = coeff_get8(b_vec_i, 6);
  assign b7 = coeff_get8(b_vec_i, 7);

  zen_mul_coeff_exact #(.COEFF_W(COEFF_W)) u_c0 (.a_i(a0), .b_i(b0), .p_o(c0));
  zen_mul_coeff_exact #(.COEFF_W(COEFF_W)) u_c1 (.a_i(a1), .b_i(b1), .p_o(c1));
  zen_mul_coeff_exact #(.COEFF_W(COEFF_W)) u_c2 (.a_i(a2), .b_i(b2), .p_o(c2));
  zen_mul_coeff_exact #(.COEFF_W(COEFF_W)) u_c3 (.a_i(a3), .b_i(b3), .p_o(c3));
  zen_mul_coeff_exact #(.COEFF_W(COEFF_W)) u_c4 (.a_i(a4), .b_i(b4), .p_o(c4));
  zen_mul_coeff_exact #(.COEFF_W(COEFF_W)) u_c5 (.a_i(a5), .b_i(b5), .p_o(c5));
  zen_mul_coeff_exact #(.COEFF_W(COEFF_W)) u_c6 (.a_i(a6), .b_i(b6), .p_o(c6));
  zen_mul_coeff_exact #(.COEFF_W(COEFF_W)) u_c7 (.a_i(a7), .b_i(b7), .p_o(c7));

  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s01 (.ai_i(a0), .aj_i(a1), .bi_i(b0), .bj_i(b1), .ci_i(c0), .cj_i(c1), .s_o(s01));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s02 (.ai_i(a0), .aj_i(a2), .bi_i(b0), .bj_i(b2), .ci_i(c0), .cj_i(c2), .s_o(s02));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s03 (.ai_i(a0), .aj_i(a3), .bi_i(b0), .bj_i(b3), .ci_i(c0), .cj_i(c3), .s_o(s03));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s04 (.ai_i(a0), .aj_i(a4), .bi_i(b0), .bj_i(b4), .ci_i(c0), .cj_i(c4), .s_o(s04));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s05 (.ai_i(a0), .aj_i(a5), .bi_i(b0), .bj_i(b5), .ci_i(c0), .cj_i(c5), .s_o(s05));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s06 (.ai_i(a0), .aj_i(a6), .bi_i(b0), .bj_i(b6), .ci_i(c0), .cj_i(c6), .s_o(s06));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s07 (.ai_i(a0), .aj_i(a7), .bi_i(b0), .bj_i(b7), .ci_i(c0), .cj_i(c7), .s_o(s07));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s12 (.ai_i(a1), .aj_i(a2), .bi_i(b1), .bj_i(b2), .ci_i(c1), .cj_i(c2), .s_o(s12));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s13 (.ai_i(a1), .aj_i(a3), .bi_i(b1), .bj_i(b3), .ci_i(c1), .cj_i(c3), .s_o(s13));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s14 (.ai_i(a1), .aj_i(a4), .bi_i(b1), .bj_i(b4), .ci_i(c1), .cj_i(c4), .s_o(s14));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s15 (.ai_i(a1), .aj_i(a5), .bi_i(b1), .bj_i(b5), .ci_i(c1), .cj_i(c5), .s_o(s15));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s16 (.ai_i(a1), .aj_i(a6), .bi_i(b1), .bj_i(b6), .ci_i(c1), .cj_i(c6), .s_o(s16));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s17 (.ai_i(a1), .aj_i(a7), .bi_i(b1), .bj_i(b7), .ci_i(c1), .cj_i(c7), .s_o(s17));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s23 (.ai_i(a2), .aj_i(a3), .bi_i(b2), .bj_i(b3), .ci_i(c2), .cj_i(c3), .s_o(s23));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s24 (.ai_i(a2), .aj_i(a4), .bi_i(b2), .bj_i(b4), .ci_i(c2), .cj_i(c4), .s_o(s24));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s25 (.ai_i(a2), .aj_i(a5), .bi_i(b2), .bj_i(b5), .ci_i(c2), .cj_i(c5), .s_o(s25));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s26 (.ai_i(a2), .aj_i(a6), .bi_i(b2), .bj_i(b6), .ci_i(c2), .cj_i(c6), .s_o(s26));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s27 (.ai_i(a2), .aj_i(a7), .bi_i(b2), .bj_i(b7), .ci_i(c2), .cj_i(c7), .s_o(s27));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s34 (.ai_i(a3), .aj_i(a4), .bi_i(b3), .bj_i(b4), .ci_i(c3), .cj_i(c4), .s_o(s34));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s35 (.ai_i(a3), .aj_i(a5), .bi_i(b3), .bj_i(b5), .ci_i(c3), .cj_i(c5), .s_o(s35));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s36 (.ai_i(a3), .aj_i(a6), .bi_i(b3), .bj_i(b6), .ci_i(c3), .cj_i(c6), .s_o(s36));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s37 (.ai_i(a3), .aj_i(a7), .bi_i(b3), .bj_i(b7), .ci_i(c3), .cj_i(c7), .s_o(s37));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s45 (.ai_i(a4), .aj_i(a5), .bi_i(b4), .bj_i(b5), .ci_i(c4), .cj_i(c5), .s_o(s45));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s46 (.ai_i(a4), .aj_i(a6), .bi_i(b4), .bj_i(b6), .ci_i(c4), .cj_i(c6), .s_o(s46));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s47 (.ai_i(a4), .aj_i(a7), .bi_i(b4), .bj_i(b7), .ci_i(c4), .cj_i(c7), .s_o(s47));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s56 (.ai_i(a5), .aj_i(a6), .bi_i(b5), .bj_i(b6), .ci_i(c5), .cj_i(c6), .s_o(s56));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s57 (.ai_i(a5), .aj_i(a7), .bi_i(b5), .bj_i(b7), .ci_i(c5), .cj_i(c7), .s_o(s57));
  zen_pairmul_diff_exact #(.COEFF_W(COEFF_W)) u_s67 (.ai_i(a6), .aj_i(a7), .bi_i(b6), .bj_i(b7), .ci_i(c6), .cj_i(c7), .s_o(s67));

  always_comb begin
    k = s17 + s26 + s35 + c4;
    r0 = c0 + fqmul(k, zeta_i);

    k = s27 + s36 + s45;
    r1 = s01 + fqmul(k, zeta_i);

    k = s37 + s46 + c5;
    r2 = s02 + c1 + fqmul(k, zeta_i);

    k = s47 + s56;
    r3 = s03 + s12 + fqmul(k, zeta_i);

    k = s57 + c6;
    r4 = s04 + s13 + c2 + fqmul(k, zeta_i);

    r5 = s05 + s14 + s23 + fqmul(s67, zeta_i);
    r6 = s06 + s15 + s24 + c3 + fqmul(c7, zeta_i);
    r7 = s07 + s16 + s25 + s34;

    block_o = {r7, r6, r5, r4, r3, r2, r1, r0};
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

(* keep_hierarchy = "yes" *)
module zen_basemul8_post_block #(
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic signed [8*COEFF_W-1:0] block_i,
  input  logic                        mq_mode_i,
  output logic signed [8*COEFF_W-1:0] block_o
);

  import zen_ntt_const_pkg::*;

  function automatic logic signed [COEFF_W-1:0] block_get8(
    input logic signed [8*COEFF_W-1:0] block,
    input int idx
  );
    begin
      block_get8 = block[idx*COEFF_W +: COEFF_W];
    end
  endfunction

  logic signed [COEFF_W-1:0] r0;
  logic signed [COEFF_W-1:0] r1;
  logic signed [COEFF_W-1:0] r2;
  logic signed [COEFF_W-1:0] r3;
  logic signed [COEFF_W-1:0] r4;
  logic signed [COEFF_W-1:0] r5;
  logic signed [COEFF_W-1:0] r6;
  logic signed [COEFF_W-1:0] r7;

  always_comb begin
    r0 = block_get8(block_i, 0);
    r1 = block_get8(block_i, 1);
    r2 = block_get8(block_i, 2);
    r3 = block_get8(block_i, 3);
    r4 = block_get8(block_i, 4);
    r5 = block_get8(block_i, 5);
    r6 = block_get8(block_i, 6);
    r7 = block_get8(block_i, 7);
    if (mq_mode_i) begin
      r0 = norm_q(fqmul(r0, 16'sd19));
      r1 = norm_q(fqmul(r1, 16'sd19));
      r2 = norm_q(fqmul(r2, 16'sd19));
      r3 = norm_q(fqmul(r3, 16'sd19));
      r4 = norm_q(fqmul(r4, 16'sd19));
      r5 = norm_q(fqmul(r5, 16'sd19));
      r6 = norm_q(fqmul(r6, 16'sd19));
      r7 = norm_q(fqmul(r7, 16'sd19));
    end
    block_o = {r7, r6, r5, r4, r3, r2, r1, r0};
  end

endmodule

(* keep_hierarchy = "yes" *)
module zen_basemul16_reduce2_exact #(
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic signed [15*COEFF_W-1:0] p0_pack_i,
  input  logic signed [15*COEFF_W-1:0] p1_pack_i,
  input  logic signed [15*COEFF_W-1:0] pm_pack_i,
  input  logic signed [COEFF_W-1:0]    zeta_i,
  input  logic [2:0]                   group_idx_i,
  input  logic                         mq_mode_i,
  output logic signed [2*COEFF_W-1:0]  coeff_pair_o
);

  import zen_ntt_const_pkg::*;

  function automatic logic signed [COEFF_W-1:0] poly15_get(
    input logic signed [15*COEFF_W-1:0] poly,
    input int idx
  );
    begin
      poly15_get = poly[idx*COEFF_W +: COEFF_W];
    end
  endfunction

  function automatic logic signed [COEFF_W-1:0] reduce_coeff(
    input logic signed [15*COEFF_W-1:0] p0_pack,
    input logic signed [15*COEFF_W-1:0] p1_pack,
    input logic signed [15*COEFF_W-1:0] pm_pack,
    input logic signed [COEFF_W-1:0] zeta,
    input int idx
  );
    logic signed [COEFF_W-1:0] cross_term;
    logic signed [COEFF_W-1:0] accum;
    begin
      cross_term = '0;
      accum = '0;
      if (idx < 7) begin
        cross_term = poly15_get(pm_pack, idx + 8)
                   - poly15_get(p0_pack, idx + 8)
                   - poly15_get(p1_pack, idx + 8);
        accum = poly15_get(p0_pack, idx);
        accum = accum + fqmul(poly15_get(p1_pack, idx), zeta);
        accum = accum + fqmul(cross_term, zeta);
        reduce_coeff = fqmul(accum, 16'sd171);
      end else if (idx == 7) begin
        accum = poly15_get(p0_pack, 7);
        accum = accum + fqmul(poly15_get(p1_pack, 7), zeta);
        reduce_coeff = fqmul(accum, 16'sd171);
      end else if (idx < 15) begin
        cross_term = poly15_get(pm_pack, idx - 8)
                   - poly15_get(p0_pack, idx - 8)
                   - poly15_get(p1_pack, idx - 8);
        accum = poly15_get(p0_pack, idx);
        accum = accum + fqmul(poly15_get(p1_pack, idx), zeta);
        accum = accum + cross_term;
        reduce_coeff = fqmul(accum, 16'sd171);
      end else begin
        cross_term = poly15_get(pm_pack, 7)
                   - poly15_get(p0_pack, 7)
                   - poly15_get(p1_pack, 7);
        reduce_coeff = fqmul(cross_term, 16'sd171);
      end
    end
  endfunction

  logic [3:0] coeff_idx_base;
  logic signed [COEFF_W-1:0] coeff0;
  logic signed [COEFF_W-1:0] coeff1;
  logic signed [COEFF_W-1:0] out0;
  logic signed [COEFF_W-1:0] out1;

  always_comb begin
    coeff_idx_base = {group_idx_i, 1'b0};
    coeff0 = reduce_coeff(p0_pack_i, p1_pack_i, pm_pack_i, zeta_i, coeff_idx_base + 0);
    coeff1 = reduce_coeff(p0_pack_i, p1_pack_i, pm_pack_i, zeta_i, coeff_idx_base + 1);
    out0 = coeff0;
    out1 = coeff1;
    if (mq_mode_i) begin
      out0 = norm_q(fqmul(coeff0, 16'sd19));
      out1 = norm_q(fqmul(coeff1, 16'sd19));
    end
    coeff_pair_o = {out1, out0};
  end

endmodule

(* keep_hierarchy = "yes" *)
module zen_basemul16_block_exact #(
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic signed [16*COEFF_W-1:0] a_vec_i,
  input  logic signed [16*COEFF_W-1:0] b_vec_i,
  input  logic signed [COEFF_W-1:0]    zeta_i,
  output logic signed [16*COEFF_W-1:0] block_o
);

  import zen_ntt_const_pkg::*;

  function automatic logic signed [COEFF_W-1:0] coeff_get16(
    input logic signed [16*COEFF_W-1:0] vec,
    input int idx
  );
    begin
      coeff_get16 = vec[idx*COEFF_W +: COEFF_W];
    end
  endfunction

  function automatic logic signed [COEFF_W-1:0] poly15_get(
    input logic signed [15*COEFF_W-1:0] poly,
    input int idx
  );
    begin
      poly15_get = poly[idx*COEFF_W +: COEFF_W];
    end
  endfunction

  logic signed [8*COEFF_W-1:0] p0_a_vec;
  logic signed [8*COEFF_W-1:0] p0_b_vec;
  logic signed [8*COEFF_W-1:0] p1_a_vec;
  logic signed [8*COEFF_W-1:0] p1_b_vec;
  logic signed [8*COEFF_W-1:0] pm_a_vec;
  logic signed [8*COEFF_W-1:0] pm_b_vec;
  logic signed [15*COEFF_W-1:0] p0_pack;
  logic signed [15*COEFF_W-1:0] p1_pack;
  logic signed [15*COEFF_W-1:0] pm_pack;
  logic signed [14:0][COEFF_W-1:0] cross_terms;
  logic signed [15:0][COEFF_W-1:0] r;
  integer i_pm;
  integer i_cross;
  integer i_hi;

  assign p0_a_vec = a_vec_i[0 +: 8*COEFF_W];
  assign p0_b_vec = b_vec_i[0 +: 8*COEFF_W];
  assign p1_a_vec = a_vec_i[8*COEFF_W +: 8*COEFF_W];
  assign p1_b_vec = b_vec_i[8*COEFF_W +: 8*COEFF_W];

  zen_karatsuba_mul8_block_exact #(
    .COEFF_W(COEFF_W)
  ) u_p0 (
    .a_vec_i(p0_a_vec),
    .b_vec_i(p0_b_vec),
    .poly_vec_o(p0_pack)
  );

  zen_karatsuba_mul8_block_exact #(
    .COEFF_W(COEFF_W)
  ) u_p1 (
    .a_vec_i(p1_a_vec),
    .b_vec_i(p1_b_vec),
    .poly_vec_o(p1_pack)
  );

  zen_karatsuba_mul8_block_exact #(
    .COEFF_W(COEFF_W)
  ) u_pm (
    .a_vec_i(pm_a_vec),
    .b_vec_i(pm_b_vec),
    .poly_vec_o(pm_pack)
  );

  always_comb begin
    pm_a_vec = '0;
    pm_b_vec = '0;

    for (i_pm = 0; i_pm < 8; i_pm++) begin
      pm_a_vec[i_pm*COEFF_W +: COEFF_W] = coeff_get16(a_vec_i, i_pm) + coeff_get16(a_vec_i, i_pm + 8);
      pm_b_vec[i_pm*COEFF_W +: COEFF_W] = coeff_get16(b_vec_i, i_pm) + coeff_get16(b_vec_i, i_pm + 8);
    end
  end

  always_comb begin
    cross_terms = '0;
    r = '0;
    for (i_cross = 0; i_cross < 15; i_cross++) begin
      cross_terms[i_cross] = poly15_get(pm_pack, i_cross)
                           - poly15_get(p0_pack, i_cross)
                           - poly15_get(p1_pack, i_cross);
    end

    for (i_hi = 0; i_hi < 7; i_hi++) begin
      r[i_hi] = poly15_get(p0_pack, i_hi);
      r[i_hi] = r[i_hi] + fqmul(poly15_get(p1_pack, i_hi), zeta_i);
      r[i_hi] = r[i_hi] + fqmul(cross_terms[i_hi + 8], zeta_i);
      r[i_hi] = fqmul(r[i_hi], 16'sd171);
    end

    r[7] = poly15_get(p0_pack, 7);
    r[7] = r[7] + fqmul(poly15_get(p1_pack, 7), zeta_i);
    r[7] = fqmul(r[7], 16'sd171);

    for (i_hi = 8; i_hi < 15; i_hi++) begin
      r[i_hi] = poly15_get(p0_pack, i_hi);
      r[i_hi] = r[i_hi] + fqmul(poly15_get(p1_pack, i_hi), zeta_i);
      r[i_hi] = r[i_hi] + cross_terms[i_hi - 8];
      r[i_hi] = fqmul(r[i_hi], 16'sd171);
    end

    r[15] = fqmul(cross_terms[7], 16'sd171);

    block_o = {
      r[15], r[14], r[13], r[12], r[11], r[10], r[9], r[8],
      r[7], r[6], r[5], r[4], r[3], r[2], r[1], r[0]
    };
  end

endmodule
