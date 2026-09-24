(* keep_hierarchy = "yes" *)
module zen_baseinv8_block_exact #(
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic signed [8*COEFF_W-1:0] a_vec_i,
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
  logic signed [COEFF_W-1:0] c0;
  logic signed [COEFF_W-1:0] c1;
  logic signed [COEFF_W-1:0] f0;
  logic signed [COEFF_W-1:0] f1;
  logic signed [COEFF_W-1:0] f2;
  logic signed [COEFF_W-1:0] f3;
  logic signed [COEFF_W-1:0] e;
  logic signed [COEFF_W-1:0] t;
  logic signed [COEFF_W-1:0] pe [0:6];
  logic signed [COEFF_W-1:0] po [0:6];
  logic signed [COEFF_W-1:0] p0;
  logic signed [COEFF_W-1:0] p1;
  logic signed [COEFF_W-1:0] p2;
  logic signed [COEFF_W-1:0] q0;
  logic signed [COEFF_W-1:0] q1;
  logic signed [COEFF_W-1:0] q2;
  logic signed [COEFF_W-1:0] m0;
  logic signed [COEFF_W-1:0] m1;
  logic signed [COEFF_W-1:0] m2;
  logic signed [COEFF_W-1:0] sx0;
  logic signed [COEFF_W-1:0] sx1;
  logic signed [COEFF_W-1:0] sy0;
  logic signed [COEFF_W-1:0] sy1;
  logic [9:0]                inv_e_addr;
  logic [15:0]               inv_e_rom_data;
  logic [COEFF_W-1:0] inv_e;
  logic signed [COEFF_W-1:0] r0;
  logic signed [COEFF_W-1:0] r1;
  logic signed [COEFF_W-1:0] r2;
  logic signed [COEFF_W-1:0] r3;
  logic signed [COEFF_W-1:0] r4;
  logic signed [COEFF_W-1:0] r5;
  logic signed [COEFF_W-1:0] r6;
  logic signed [COEFF_W-1:0] r7;

  assign inv_e_addr = e[9:0];

  zen_qinv_rom u_qinv_rom (
    .addr (inv_e_addr),
    .data (inv_e_rom_data)
  );

  always_comb begin
    a0 = coeff_get8(a_vec_i, 0);
    a1 = coeff_get8(a_vec_i, 1);
    a2 = coeff_get8(a_vec_i, 2);
    a3 = coeff_get8(a_vec_i, 3);
    a4 = coeff_get8(a_vec_i, 4);
    a5 = coeff_get8(a_vec_i, 5);
    a6 = coeff_get8(a_vec_i, 6);
    a7 = coeff_get8(a_vec_i, 7);

    p0 = fqmul(a0, a0);
    p1 = fqmul(fqmul(a0, a2), 16'sd342);
    p2 = fqmul(a2, a2);

    q0 = fqmul(a4, a4);
    q1 = fqmul(fqmul(a4, a6), 16'sd342);
    q2 = fqmul(a6, a6);

    sx0 = a0 + a4;
    sx1 = a2 + a6;
    m0 = fqmul(sx0, sx0);
    m1 = fqmul(fqmul(sx0, sx1), 16'sd342);
    m2 = fqmul(sx1, sx1);

    pe[0] = p0;
    pe[1] = p1;
    pe[2] = p2 + m0 - p0 - q0;
    pe[3] = m1 - p1 - q1;
    pe[4] = q0 + m2 - p2 - q2;
    pe[5] = q1;
    pe[6] = q2;

    p0 = fqmul(a1, a1);
    p1 = fqmul(fqmul(a1, a3), 16'sd342);
    p2 = fqmul(a3, a3);

    q0 = fqmul(a5, a5);
    q1 = fqmul(fqmul(a5, a7), 16'sd342);
    q2 = fqmul(a7, a7);

    sx0 = a1 + a5;
    sx1 = a3 + a7;
    m0 = fqmul(sx0, sx0);
    m1 = fqmul(fqmul(sx0, sx1), 16'sd342);
    m2 = fqmul(sx1, sx1);

    po[0] = p0;
    po[1] = p1;
    po[2] = p2 + m0 - p0 - q0;
    po[3] = m1 - p1 - q1;
    po[4] = q0 + m2 - p2 - q2;
    po[5] = q1;
    po[6] = q2;

    b0 = pe[0] - fqmul(pe[4] - po[3], zeta_i);
    b1 = pe[1] - po[0] - fqmul(pe[5] - po[4], zeta_i);
    b2 = pe[2] - po[1] - fqmul(pe[6] - po[5], zeta_i);
    b3 = pe[3] - po[2] + fqmul(po[6], zeta_i);

    p0 = fqmul(b0, b0);
    p1 = fqmul(fqmul(b0, b2), 16'sd342);
    p2 = fqmul(b2, b2);

    q0 = fqmul(b1, b1);
    q1 = fqmul(fqmul(b1, b3), 16'sd342);
    q2 = fqmul(b3, b3);

    c0 = p0 - fqmul(p2 - q1, zeta_i);
    c1 = p1 - q0 + fqmul(q2, zeta_i);

    e = fqmul(c1, c1);
    e = fqmul(e, zeta_i);
    t = fqmul(c0, c0);
    e = norm_q(e + t);
    inv_e = inv_e_rom_data[COEFF_W-1:0];

    c0 = fqmul(inv_e, c0);
    c1 = fqmul(inv_e, c1);
    c1 = fqmul(c1, -16'sd171);

    p0 = fqmul(c0, b0);
    p2 = fqmul(c1, b2);
    p1 = fqmul(c0 + c1, b0 + b2) - p0 - p2;

    q0 = fqmul(c0, b1);
    q2 = fqmul(c1, b3);
    q1 = fqmul(c0 + c1, b1 + b3) - q0 - q2;

    f0 = p0 - fqmul(p2, zeta_i);
    f1 = fqmul(q2, zeta_i) - q0;
    f2 = p1;
    f3 = fqmul(q1, -16'sd171);

    p0 = fqmul(f0, a0);
    p2 = fqmul(f1, a2);
    p1 = fqmul(f0 + f1, a0 + a2) - p0 - p2;

    q0 = fqmul(f2, a4);
    q2 = fqmul(f3, a6);
    q1 = fqmul(f2 + f3, a4 + a6) - q0 - q2;

    sx0 = f0 + f2;
    sx1 = f1 + f3;
    sy0 = a0 + a4;
    sy1 = a2 + a6;
    m0 = fqmul(sx0, sy0);
    m2 = fqmul(sx1, sy1);
    m1 = fqmul(sx0 + sx1, sy0 + sy1) - m0 - m2;

    pe[0] = p0;
    pe[1] = p1;
    pe[2] = p2 + m0 - p0 - q0;
    pe[3] = m1 - p1 - q1;
    pe[4] = q0 + m2 - p2 - q2;
    pe[5] = q1;
    pe[6] = q2;

    p0 = fqmul(f0, a1);
    p2 = fqmul(f1, a3);
    p1 = fqmul(f0 + f1, a1 + a3) - p0 - p2;

    q0 = fqmul(f2, a5);
    q2 = fqmul(f3, a7);
    q1 = fqmul(f2 + f3, a5 + a7) - q0 - q2;

    sx0 = f0 + f2;
    sx1 = f1 + f3;
    sy0 = a1 + a5;
    sy1 = a3 + a7;
    m0 = fqmul(sx0, sy0);
    m2 = fqmul(sx1, sy1);
    m1 = fqmul(sx0 + sx1, sy0 + sy1) - m0 - m2;

    po[0] = p0;
    po[1] = p1;
    po[2] = p2 + m0 - p0 - q0;
    po[3] = m1 - p1 - q1;
    po[4] = q0 + m2 - p2 - q2;
    po[5] = q1;
    po[6] = q2;

    r0 = pe[0] - fqmul(pe[4], zeta_i);
    r1 = fqmul(po[4], zeta_i) - po[0];
    r2 = pe[1] - fqmul(pe[5], zeta_i);
    r3 = fqmul(po[5], zeta_i) - po[1];
    r4 = pe[2] - fqmul(pe[6], zeta_i);
    r5 = fqmul(po[6], zeta_i) - po[2];
    r6 = pe[3];
    r7 = fqmul(po[3], -16'sd171);

    block_o = {r7, r6, r5, r4, r3, r2, r1, r0};
  end

endmodule

module zen_baseinv16_stage_core #(
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int STAGE = 0
) (
  input  logic signed [16*COEFF_W-1:0] a_vec_i,
  input  logic signed [8*COEFF_W-1:0]  ae_vec_i,
  input  logic signed [8*COEFF_W-1:0]  ao_vec_i,
  input  logic signed [4*COEFF_W-1:0]  he_vec_i,
  input  logic signed [4*COEFF_W-1:0]  ho_vec_i,
  input  logic signed [8*COEFF_W-1:0]  g_vec_i,
  input  logic signed [COEFF_W-1:0]    qinv_i,
  input  logic signed [COEFF_W-1:0]    zeta_i,
  output logic signed [8*COEFF_W-1:0]  ae_vec_o,
  output logic signed [8*COEFF_W-1:0]  ao_vec_o,
  output logic signed [4*COEFF_W-1:0]  he_vec_o,
  output logic signed [4*COEFF_W-1:0]  ho_vec_o,
  output logic signed [8*COEFF_W-1:0]  g_vec_o,
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

  function automatic logic signed [COEFF_W-1:0] poly7_get(
    input logic signed [7*COEFF_W-1:0] poly,
    input int idx
  );
    begin
      poly7_get = poly[idx*COEFF_W +: COEFF_W];
    end
  endfunction

  function automatic logic signed [7*COEFF_W-1:0] karatsuba_mul4_block_exact(
    input logic signed [4*COEFF_W-1:0] a_vec,
    input logic signed [4*COEFF_W-1:0] b_vec
  );
    logic signed [COEFF_W-1:0] a0, a1, a2, a3;
    logic signed [COEFF_W-1:0] b0, b1, b2, b3;
    logic signed [COEFF_W-1:0] a01, a23, b01, b23;
    logic signed [COEFF_W-1:0] p0_0, p0_1, p0_2;
    logic signed [COEFF_W-1:0] p1_0, p1_1, p1_2;
    logic signed [COEFF_W-1:0] pm_0, pm_1, pm_2;
    logic signed [COEFF_W-1:0] r0, r1, r2, r3, r4, r5, r6;
    begin
      a0 = a_vec[0*COEFF_W +: COEFF_W];
      a1 = a_vec[1*COEFF_W +: COEFF_W];
      a2 = a_vec[2*COEFF_W +: COEFF_W];
      a3 = a_vec[3*COEFF_W +: COEFF_W];
      b0 = b_vec[0*COEFF_W +: COEFF_W];
      b1 = b_vec[1*COEFF_W +: COEFF_W];
      b2 = b_vec[2*COEFF_W +: COEFF_W];
      b3 = b_vec[3*COEFF_W +: COEFF_W];

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

      karatsuba_mul4_block_exact = {r6, r5, r4, r3, r2, r1, r0};
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

  function automatic logic signed [15*COEFF_W-1:0] karatsuba_mul8_block_exact(
    input logic signed [8*COEFF_W-1:0] a_vec,
    input logic signed [8*COEFF_W-1:0] b_vec
  );
    logic signed [4*COEFF_W-1:0] a0_vec;
    logic signed [4*COEFF_W-1:0] a1_vec;
    logic signed [4*COEFF_W-1:0] b0_vec;
    logic signed [4*COEFF_W-1:0] b1_vec;
    logic signed [4*COEFF_W-1:0] as_vec;
    logic signed [4*COEFF_W-1:0] bs_vec;
    logic signed [7*COEFF_W-1:0] p0_pack;
    logic signed [7*COEFF_W-1:0] p1_pack;
    logic signed [7*COEFF_W-1:0] pm_pack;
    logic signed [COEFF_W-1:0] r [0:14];
    integer i_local;
    begin
      a0_vec = a_vec[0 +: 4*COEFF_W];
      a1_vec = a_vec[4*COEFF_W +: 4*COEFF_W];
      b0_vec = b_vec[0 +: 4*COEFF_W];
      b1_vec = b_vec[4*COEFF_W +: 4*COEFF_W];

      for (i_local = 0; i_local < 4; i_local++) begin
        as_vec[i_local*COEFF_W +: COEFF_W] =
          a_vec[i_local*COEFF_W +: COEFF_W] + a_vec[(i_local + 4)*COEFF_W +: COEFF_W];
        bs_vec[i_local*COEFF_W +: COEFF_W] =
          b_vec[i_local*COEFF_W +: COEFF_W] + b_vec[(i_local + 4)*COEFF_W +: COEFF_W];
      end

      p0_pack = karatsuba_mul4_block_exact(a0_vec, b0_vec);
      p1_pack = karatsuba_mul4_block_exact(a1_vec, b1_vec);
      pm_pack = karatsuba_mul4_block_exact(as_vec, bs_vec);

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

      karatsuba_mul8_block_exact = {
        r[14], r[13], r[12], r[11], r[10], r[9], r[8], r[7],
        r[6], r[5], r[4], r[3], r[2], r[1], r[0]
      };
    end
  endfunction

  if (STAGE == 0) begin : g_stage0
    logic signed [COEFF_W-1:0] a [0:15];
    logic signed [COEFF_W-1:0] ae [0:7];
    logic signed [COEFF_W-1:0] ao [0:7];
    logic signed [COEFF_W-1:0] h [0:7];
    logic signed [COEFF_W-1:0] pe15 [0:14];
    logic signed [COEFF_W-1:0] po15 [0:14];
    logic signed [15*COEFF_W-1:0] p15_e_pack;
    logic signed [15*COEFF_W-1:0] p15_o_pack;
    integer i_local;

    always_comb begin
      ae_vec_o = '0;
      ao_vec_o = '0;
      he_vec_o = '0;
      ho_vec_o = '0;
      g_vec_o = '0;
      block_o = '0;

      for (i_local = 0; i_local < 16; i_local++) begin
        a[i_local] = coeff_get16(a_vec_i, i_local);
      end

      for (i_local = 0; i_local < 8; i_local++) begin
        ae[i_local] = a[2 * i_local];
        ao[i_local] = a[2 * i_local + 1];
      end

      ae_vec_o = {ae[7], ae[6], ae[5], ae[4], ae[3], ae[2], ae[1], ae[0]};
      ao_vec_o = {ao[7], ao[6], ao[5], ao[4], ao[3], ao[2], ao[1], ao[0]};

      p15_e_pack = karatsuba_mul8_block_exact(ae_vec_o, ae_vec_o);
      p15_o_pack = karatsuba_mul8_block_exact(ao_vec_o, ao_vec_o);
      for (i_local = 0; i_local < 15; i_local++) begin
        pe15[i_local] = poly15_get(p15_e_pack, i_local);
        po15[i_local] = poly15_get(p15_o_pack, i_local);
      end

      h[0] = pe15[0] - fqmul(pe15[8] - po15[7], zeta_i);
      h[1] = pe15[1] - po15[0] - fqmul(pe15[9] - po15[8], zeta_i);
      h[2] = pe15[2] - po15[1] - fqmul(pe15[10] - po15[9], zeta_i);
      h[3] = pe15[3] - po15[2] - fqmul(pe15[11] - po15[10], zeta_i);
      h[4] = pe15[4] - po15[3] - fqmul(pe15[12] - po15[11], zeta_i);
      h[5] = pe15[5] - po15[4] - fqmul(pe15[13] - po15[12], zeta_i);
      h[6] = pe15[6] - po15[5] - fqmul(pe15[14] - po15[13], zeta_i);
      h[7] = pe15[7] - po15[6] + fqmul(po15[14], zeta_i);

      he_vec_o = {h[6], h[4], h[2], h[0]};
      ho_vec_o = {h[7], h[5], h[3], h[1]};
    end
  end else if (STAGE == 1) begin : g_stage1
    logic signed [COEFF_W-1:0] b [0:3];
    logic signed [COEFF_W-1:0] pe7 [0:6];
    logic signed [COEFF_W-1:0] po7 [0:6];
    logic signed [COEFF_W-1:0] c0_pre;
    logic signed [COEFF_W-1:0] c1_pre;
    logic signed [COEFF_W-1:0] q0e;
    logic signed [COEFF_W-1:0] q1e;
    logic signed [COEFF_W-1:0] q2e;
    logic signed [COEFF_W-1:0] q0o;
    logic signed [COEFF_W-1:0] q1o;
    logic signed [COEFF_W-1:0] q2o;
    logic signed [7*COEFF_W-1:0] p7_e_pack;
    logic signed [7*COEFF_W-1:0] p7_o_pack;
    integer i_local;

    always_comb begin
      ae_vec_o = '0;
      ao_vec_o = '0;
      he_vec_o = '0;
      ho_vec_o = '0;
      g_vec_o = '0;
      block_o = '0;

      p7_e_pack = karatsuba_mul4_block_exact(he_vec_i, he_vec_i);
      p7_o_pack = karatsuba_mul4_block_exact(ho_vec_i, ho_vec_i);
      for (i_local = 0; i_local < 7; i_local++) begin
        pe7[i_local] = poly7_get(p7_e_pack, i_local);
        po7[i_local] = poly7_get(p7_o_pack, i_local);
      end

      b[0] = pe7[0] - fqmul(pe7[4] - po7[3], zeta_i);
      b[1] = pe7[1] - po7[0] - fqmul(pe7[5] - po7[4], zeta_i);
      b[2] = pe7[2] - po7[1] - fqmul(pe7[6] - po7[5], zeta_i);
      b[3] = pe7[3] - po7[2] + fqmul(po7[6], zeta_i);

      q0e = fqmul(b[0], b[0]);
      q2e = fqmul(b[2], b[2]);
      q1e = fqmul(fqmul(b[0], b[2]), 16'sd342);
      q0o = fqmul(b[1], b[1]);
      q2o = fqmul(b[3], b[3]);
      q1o = fqmul(fqmul(b[1], b[3]), 16'sd342);

      c0_pre = q0e - fqmul(q2e - q1o, zeta_i);
      c1_pre = q1e - q0o + fqmul(q2o, zeta_i);

      g_vec_o = {
        16'sd0, 16'sd0, c1_pre, c0_pre, b[3], b[2], b[1], b[0]
      };
    end
  end else if (STAGE == 2) begin : g_stage2
    logic signed [COEFF_W-1:0] b0;
    logic signed [COEFF_W-1:0] b1;
    logic signed [COEFF_W-1:0] b2;
    logic signed [COEFF_W-1:0] b3;
    logic signed [COEFF_W-1:0] c0_pre;
    logic signed [COEFF_W-1:0] c1_pre;
    logic signed [COEFF_W-1:0] e_mul;
    logic signed [COEFF_W-1:0] c_sq;
    logic signed [COEFF_W-1:0] c0;
    logic signed [COEFF_W-1:0] c1;
    logic signed [COEFF_W-1:0] f0;
    logic signed [COEFF_W-1:0] f1;
    logic signed [COEFF_W-1:0] f2;
    logic signed [COEFF_W-1:0] f3;
    logic signed [COEFF_W-1:0] g [0:7];
    logic signed [COEFF_W-1:0] pe7 [0:6];
    logic signed [COEFF_W-1:0] po7 [0:6];
    logic signed [COEFF_W-1:0] e_norm;
    logic signed [COEFF_W-1:0] t;
    logic signed [7*COEFF_W-1:0] p7_e_pack;
    logic signed [7*COEFF_W-1:0] p7_o_pack;
    logic signed [4*COEFF_W-1:0] f_vec;
    logic signed [COEFF_W-1:0]   inv_e;
    integer i_local;

    always_comb begin
      ae_vec_o = '0;
      ao_vec_o = '0;
      he_vec_o = '0;
      ho_vec_o = '0;
      g_vec_o = '0;
      block_o = '0;

      b0 = coeff_get8(g_vec_i, 0);
      b1 = coeff_get8(g_vec_i, 1);
      b2 = coeff_get8(g_vec_i, 2);
      b3 = coeff_get8(g_vec_i, 3);
      c0_pre = coeff_get8(g_vec_i, 4);
      c1_pre = coeff_get8(g_vec_i, 5);

      e_mul = fqmul(c1_pre, c1_pre);
      e_mul = fqmul(e_mul, zeta_i);
      c_sq = fqmul(c0_pre, c0_pre);
      e_norm = norm_q(e_mul + c_sq);
      g_vec_o = {
        16'sd0, e_norm, c1_pre, c0_pre, b3, b2, b1, b0
      };
    end
  end else if (STAGE == 3) begin : g_stage3
    logic signed [COEFF_W-1:0] b0;
    logic signed [COEFF_W-1:0] b1;
    logic signed [COEFF_W-1:0] b2;
    logic signed [COEFF_W-1:0] b3;
    logic signed [COEFF_W-1:0] c0_pre;
    logic signed [COEFF_W-1:0] c1_pre;
    logic signed [COEFF_W-1:0] c0;
    logic signed [COEFF_W-1:0] c1;
    logic signed [COEFF_W-1:0] f0;
    logic signed [COEFF_W-1:0] f1;
    logic signed [COEFF_W-1:0] f2;
    logic signed [COEFF_W-1:0] f3;
    logic signed [COEFF_W-1:0] g [0:7];
    logic signed [COEFF_W-1:0] pe7 [0:6];
    logic signed [COEFF_W-1:0] po7 [0:6];
    logic signed [COEFF_W-1:0] t;
    logic signed [7*COEFF_W-1:0] p7_e_pack;
    logic signed [7*COEFF_W-1:0] p7_o_pack;
    logic signed [4*COEFF_W-1:0] f_vec;
    logic signed [COEFF_W-1:0]   inv_e;
    integer i_local;

    always_comb begin
      ae_vec_o = '0;
      ao_vec_o = '0;
      he_vec_o = '0;
      ho_vec_o = '0;
      g_vec_o = '0;
      block_o = '0;

      b0 = coeff_get8(g_vec_i, 0);
      b1 = coeff_get8(g_vec_i, 1);
      b2 = coeff_get8(g_vec_i, 2);
      b3 = coeff_get8(g_vec_i, 3);
      c0_pre = coeff_get8(g_vec_i, 4);
      c1_pre = coeff_get8(g_vec_i, 5);
      inv_e = qinv_i;

      c0 = fqmul(inv_e, c0_pre);
      c1 = fqmul(inv_e, c1_pre);
      c1 = fqmul(c1, -16'sd171);

      f0 = fqmul(c1, b2);
      f0 = fqmul(f0, zeta_i);
      t = fqmul(c0, b0);
      f0 = t - f0;

      f1 = fqmul(c1, b3);
      f1 = fqmul(f1, zeta_i);
      t = fqmul(c0, b1);
      f1 = f1 - t;

      f2 = fqmul(c0, b2);
      t = fqmul(c1, b0);
      f2 = f2 + t;

      f3 = fqmul(c0, b3);
      t = fqmul(c1, b1);
      f3 = f3 + t;
      f3 = fqmul(f3, -16'sd171);

      f_vec = {f3, f2, f1, f0};

      p7_e_pack = karatsuba_mul4_block_exact(f_vec, he_vec_i);
      p7_o_pack = karatsuba_mul4_block_exact(f_vec, ho_vec_i);
      for (i_local = 0; i_local < 7; i_local++) begin
        pe7[i_local] = poly7_get(p7_e_pack, i_local);
        po7[i_local] = poly7_get(p7_o_pack, i_local);
      end

      g[0] = pe7[0] - fqmul(pe7[4], zeta_i);
      g[1] = fqmul(po7[4], zeta_i) - po7[0];
      g[2] = pe7[1] - fqmul(pe7[5], zeta_i);
      g[3] = fqmul(po7[5], zeta_i) - po7[1];
      g[4] = pe7[2] - fqmul(pe7[6], zeta_i);
      g[5] = fqmul(po7[6], zeta_i) - po7[2];
      g[6] = pe7[3];
      g[7] = fqmul(po7[3], -16'sd171);

      g_vec_o = {g[7], g[6], g[5], g[4], g[3], g[2], g[1], g[0]};
    end
  end else begin : g_stage4
    logic signed [COEFF_W-1:0] pe15 [0:14];
    logic signed [COEFF_W-1:0] po15 [0:14];
    logic signed [COEFF_W-1:0] r [0:15];
    logic signed [15*COEFF_W-1:0] p15_e_pack;
    logic signed [15*COEFF_W-1:0] p15_o_pack;
    integer i_local;

    always_comb begin
      ae_vec_o = '0;
      ao_vec_o = '0;
      he_vec_o = '0;
      ho_vec_o = '0;
      g_vec_o = '0;
      block_o = '0;

      p15_e_pack = karatsuba_mul8_block_exact(g_vec_i, ae_vec_i);
      p15_o_pack = karatsuba_mul8_block_exact(g_vec_i, ao_vec_i);
      for (i_local = 0; i_local < 15; i_local++) begin
        pe15[i_local] = poly15_get(p15_e_pack, i_local);
        po15[i_local] = poly15_get(p15_o_pack, i_local);
      end

      r[0] = pe15[0] - fqmul(pe15[8], zeta_i);
      r[1] = fqmul(po15[8], zeta_i) - po15[0];
      r[2] = pe15[1] - fqmul(pe15[9], zeta_i);
      r[3] = fqmul(po15[9], zeta_i) - po15[1];
      r[4] = pe15[2] - fqmul(pe15[10], zeta_i);
      r[5] = fqmul(po15[10], zeta_i) - po15[2];
      r[6] = pe15[3] - fqmul(pe15[11], zeta_i);
      r[7] = fqmul(po15[11], zeta_i) - po15[3];
      r[8] = pe15[4] - fqmul(pe15[12], zeta_i);
      r[9] = fqmul(po15[12], zeta_i) - po15[4];
      r[10] = pe15[5] - fqmul(pe15[13], zeta_i);
      r[11] = fqmul(po15[13], zeta_i) - po15[5];
      r[12] = pe15[6] - fqmul(pe15[14], zeta_i);
      r[13] = fqmul(po15[14], zeta_i) - po15[6];
      r[14] = pe15[7];
      r[15] = fqmul(po15[7], -16'sd171);

      block_o = {
        r[15], r[14], r[13], r[12], r[11], r[10], r[9], r[8],
        r[7], r[6], r[5], r[4], r[3], r[2], r[1], r[0]
      };
    end
  end

endmodule

(* keep_hierarchy = "yes" *)
module zen_baseinv16_block_exact #(
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic signed [16*COEFF_W-1:0] a_vec_i,
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

  function automatic logic signed [COEFF_W-1:0] poly7_get(
    input logic signed [7*COEFF_W-1:0] poly,
    input int idx
  );
    begin
      poly7_get = poly[idx*COEFF_W +: COEFF_W];
    end
  endfunction

  function automatic logic signed [7*COEFF_W-1:0] karatsuba_mul4_block_exact(
    input logic signed [4*COEFF_W-1:0] a_vec,
    input logic signed [4*COEFF_W-1:0] b_vec
  );
    logic signed [COEFF_W-1:0] a0, a1, a2, a3;
    logic signed [COEFF_W-1:0] b0, b1, b2, b3;
    logic signed [COEFF_W-1:0] a01, a23, b01, b23;
    logic signed [COEFF_W-1:0] p0_0, p0_1, p0_2;
    logic signed [COEFF_W-1:0] p1_0, p1_1, p1_2;
    logic signed [COEFF_W-1:0] pm_0, pm_1, pm_2;
    logic signed [COEFF_W-1:0] r0, r1, r2, r3, r4, r5, r6;
    begin
      a0 = a_vec[0*COEFF_W +: COEFF_W];
      a1 = a_vec[1*COEFF_W +: COEFF_W];
      a2 = a_vec[2*COEFF_W +: COEFF_W];
      a3 = a_vec[3*COEFF_W +: COEFF_W];
      b0 = b_vec[0*COEFF_W +: COEFF_W];
      b1 = b_vec[1*COEFF_W +: COEFF_W];
      b2 = b_vec[2*COEFF_W +: COEFF_W];
      b3 = b_vec[3*COEFF_W +: COEFF_W];

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

      karatsuba_mul4_block_exact = {r6, r5, r4, r3, r2, r1, r0};
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

  function automatic logic signed [15*COEFF_W-1:0] karatsuba_mul8_block_exact(
    input logic signed [8*COEFF_W-1:0] a_vec,
    input logic signed [8*COEFF_W-1:0] b_vec
  );
    logic signed [4*COEFF_W-1:0] a0_vec;
    logic signed [4*COEFF_W-1:0] a1_vec;
    logic signed [4*COEFF_W-1:0] b0_vec;
    logic signed [4*COEFF_W-1:0] b1_vec;
    logic signed [4*COEFF_W-1:0] as_vec;
    logic signed [4*COEFF_W-1:0] bs_vec;
    logic signed [7*COEFF_W-1:0] p0_pack;
    logic signed [7*COEFF_W-1:0] p1_pack;
    logic signed [7*COEFF_W-1:0] pm_pack;
    logic signed [COEFF_W-1:0] r [0:14];
    integer i_local;
    begin
      a0_vec = a_vec[0 +: 4*COEFF_W];
      a1_vec = a_vec[4*COEFF_W +: 4*COEFF_W];
      b0_vec = b_vec[0 +: 4*COEFF_W];
      b1_vec = b_vec[4*COEFF_W +: 4*COEFF_W];

      for (i_local = 0; i_local < 4; i_local++) begin
        as_vec[i_local*COEFF_W +: COEFF_W] =
          a_vec[i_local*COEFF_W +: COEFF_W] + a_vec[(i_local + 4)*COEFF_W +: COEFF_W];
        bs_vec[i_local*COEFF_W +: COEFF_W] =
          b_vec[i_local*COEFF_W +: COEFF_W] + b_vec[(i_local + 4)*COEFF_W +: COEFF_W];
      end

      p0_pack = karatsuba_mul4_block_exact(a0_vec, b0_vec);
      p1_pack = karatsuba_mul4_block_exact(a1_vec, b1_vec);
      pm_pack = karatsuba_mul4_block_exact(as_vec, bs_vec);

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

      karatsuba_mul8_block_exact = {
        r[14], r[13], r[12], r[11], r[10], r[9], r[8], r[7],
        r[6], r[5], r[4], r[3], r[2], r[1], r[0]
      };
    end
  endfunction

  logic signed [COEFF_W-1:0] a [0:15];
  logic signed [COEFF_W-1:0] ae [0:7];
  logic signed [COEFF_W-1:0] ao [0:7];
  logic signed [COEFF_W-1:0] h [0:7];
  logic signed [COEFF_W-1:0] he [0:3];
  logic signed [COEFF_W-1:0] ho [0:3];
  logic signed [COEFF_W-1:0] b [0:3];
  logic signed [COEFF_W-1:0] g [0:7];
  logic signed [COEFF_W-1:0] pe15 [0:14];
  logic signed [COEFF_W-1:0] po15 [0:14];
  logic signed [COEFF_W-1:0] pe7 [0:6];
  logic signed [COEFF_W-1:0] po7 [0:6];
  logic signed [COEFF_W-1:0] fvec [0:3];
  logic signed [COEFF_W-1:0] r [0:15];
  logic signed [COEFF_W-1:0] c0;
  logic signed [COEFF_W-1:0] c1;
  logic signed [COEFF_W-1:0] c0_pre;
  logic signed [COEFF_W-1:0] c1_pre;
  logic signed [COEFF_W-1:0] e;
  logic signed [COEFF_W-1:0] t;
  logic signed [COEFF_W-1:0] f0;
  logic signed [COEFF_W-1:0] f1;
  logic signed [COEFF_W-1:0] f2;
  logic signed [COEFF_W-1:0] f3;
  logic signed [COEFF_W-1:0] q0e;
  logic signed [COEFF_W-1:0] q1e;
  logic signed [COEFF_W-1:0] q2e;
  logic signed [COEFF_W-1:0] q0o;
  logic signed [COEFF_W-1:0] q1o;
  logic signed [COEFF_W-1:0] q2o;
  logic [9:0]                inv_e_addr;
  logic [15:0]               inv_e_rom_data;
  logic [COEFF_W-1:0]        inv_e;
  logic signed [15*COEFF_W-1:0] p15_e_pack;
  logic signed [15*COEFF_W-1:0] p15_o_pack;
  logic signed [7*COEFF_W-1:0] p7_e_pack;
  logic signed [7*COEFF_W-1:0] p7_o_pack;
  logic signed [8*COEFF_W-1:0] ae_vec;
  logic signed [8*COEFF_W-1:0] ao_vec;
  logic signed [4*COEFF_W-1:0] he_vec;
  logic signed [4*COEFF_W-1:0] ho_vec;
  logic signed [4*COEFF_W-1:0] f_vec;
  logic signed [8*COEFF_W-1:0] g_vec;
  integer i_local;

  assign inv_e_addr = e[9:0];

  zen_qinv_rom u_qinv_rom (
    .addr (inv_e_addr),
    .data (inv_e_rom_data)
  );

  always_comb begin
    block_o = '0;

    for (i_local = 0; i_local < 16; i_local++) begin
      a[i_local] = coeff_get16(a_vec_i, i_local);
      r[i_local] = '0;
    end

    for (i_local = 0; i_local < 8; i_local++) begin
      ae[i_local] = a[2 * i_local];
      ao[i_local] = a[2 * i_local + 1];
      h[i_local] = '0;
      g[i_local] = '0;
    end

    for (i_local = 0; i_local < 4; i_local++) begin
      he[i_local] = '0;
      ho[i_local] = '0;
      b[i_local] = '0;
      fvec[i_local] = '0;
    end

    ae_vec = {ae[7], ae[6], ae[5], ae[4], ae[3], ae[2], ae[1], ae[0]};
    ao_vec = {ao[7], ao[6], ao[5], ao[4], ao[3], ao[2], ao[1], ao[0]};

    p15_e_pack = karatsuba_mul8_block_exact(ae_vec, ae_vec);
    p15_o_pack = karatsuba_mul8_block_exact(ao_vec, ao_vec);
    for (i_local = 0; i_local < 15; i_local++) begin
      pe15[i_local] = poly15_get(p15_e_pack, i_local);
      po15[i_local] = poly15_get(p15_o_pack, i_local);
    end

    h[0] = pe15[0] - fqmul(pe15[8] - po15[7], zeta_i);
    h[1] = pe15[1] - po15[0] - fqmul(pe15[9] - po15[8], zeta_i);
    h[2] = pe15[2] - po15[1] - fqmul(pe15[10] - po15[9], zeta_i);
    h[3] = pe15[3] - po15[2] - fqmul(pe15[11] - po15[10], zeta_i);
    h[4] = pe15[4] - po15[3] - fqmul(pe15[12] - po15[11], zeta_i);
    h[5] = pe15[5] - po15[4] - fqmul(pe15[13] - po15[12], zeta_i);
    h[6] = pe15[6] - po15[5] - fqmul(pe15[14] - po15[13], zeta_i);
    h[7] = pe15[7] - po15[6] + fqmul(po15[14], zeta_i);

    he[0] = h[0];
    he[1] = h[2];
    he[2] = h[4];
    he[3] = h[6];
    ho[0] = h[1];
    ho[1] = h[3];
    ho[2] = h[5];
    ho[3] = h[7];

    he_vec = {he[3], he[2], he[1], he[0]};
    ho_vec = {ho[3], ho[2], ho[1], ho[0]};

    p7_e_pack = karatsuba_mul4_block_exact(he_vec, he_vec);
    p7_o_pack = karatsuba_mul4_block_exact(ho_vec, ho_vec);
    for (i_local = 0; i_local < 7; i_local++) begin
      pe7[i_local] = poly7_get(p7_e_pack, i_local);
      po7[i_local] = poly7_get(p7_o_pack, i_local);
    end

    b[0] = pe7[0] - fqmul(pe7[4] - po7[3], zeta_i);
    b[1] = pe7[1] - po7[0] - fqmul(pe7[5] - po7[4], zeta_i);
    b[2] = pe7[2] - po7[1] - fqmul(pe7[6] - po7[5], zeta_i);
    b[3] = pe7[3] - po7[2] + fqmul(po7[6], zeta_i);

    q0e = fqmul(b[0], b[0]);
    q2e = fqmul(b[2], b[2]);
    q1e = fqmul(fqmul(b[0], b[2]), 16'sd342);
    q0o = fqmul(b[1], b[1]);
    q2o = fqmul(b[3], b[3]);
    q1o = fqmul(fqmul(b[1], b[3]), 16'sd342);

    c0_pre = q0e - fqmul(q2e - q1o, zeta_i);
    c1_pre = q1e - q0o + fqmul(q2o, zeta_i);

    e = fqmul(c1_pre, c1_pre);
    e = fqmul(e, zeta_i);
    t = fqmul(c0_pre, c0_pre);
    e = norm_q(e + t);
    inv_e = inv_e_rom_data[COEFF_W-1:0];

    c0 = fqmul(inv_e, c0_pre);
    c1 = fqmul(inv_e, c1_pre);
    c1 = fqmul(c1, -16'sd171);

    f0 = fqmul(c1, b[2]);
    f0 = fqmul(f0, zeta_i);
    t = fqmul(c0, b[0]);
    f0 = t - f0;

    f1 = fqmul(c1, b[3]);
    f1 = fqmul(f1, zeta_i);
    t = fqmul(c0, b[1]);
    f1 = f1 - t;

    f2 = fqmul(c0, b[2]);
    t = fqmul(c1, b[0]);
    f2 = f2 + t;

    f3 = fqmul(c0, b[3]);
    t = fqmul(c1, b[1]);
    f3 = f3 + t;
    f3 = fqmul(f3, -16'sd171);

    fvec[0] = f0;
    fvec[1] = f1;
    fvec[2] = f2;
    fvec[3] = f3;
    f_vec = {fvec[3], fvec[2], fvec[1], fvec[0]};

    p7_e_pack = karatsuba_mul4_block_exact(f_vec, he_vec);
    p7_o_pack = karatsuba_mul4_block_exact(f_vec, ho_vec);
    for (i_local = 0; i_local < 7; i_local++) begin
      pe7[i_local] = poly7_get(p7_e_pack, i_local);
      po7[i_local] = poly7_get(p7_o_pack, i_local);
    end

    g[0] = pe7[0] - fqmul(pe7[4], zeta_i);
    g[1] = fqmul(po7[4], zeta_i) - po7[0];
    g[2] = pe7[1] - fqmul(pe7[5], zeta_i);
    g[3] = fqmul(po7[5], zeta_i) - po7[1];
    g[4] = pe7[2] - fqmul(pe7[6], zeta_i);
    g[5] = fqmul(po7[6], zeta_i) - po7[2];
    g[6] = pe7[3];
    g[7] = fqmul(po7[3], -16'sd171);

    g_vec = {g[7], g[6], g[5], g[4], g[3], g[2], g[1], g[0]};

    p15_e_pack = karatsuba_mul8_block_exact(g_vec, ae_vec);
    p15_o_pack = karatsuba_mul8_block_exact(g_vec, ao_vec);
    for (i_local = 0; i_local < 15; i_local++) begin
      pe15[i_local] = poly15_get(p15_e_pack, i_local);
      po15[i_local] = poly15_get(p15_o_pack, i_local);
    end

    r[0] = pe15[0] - fqmul(pe15[8], zeta_i);
    r[1] = fqmul(po15[8], zeta_i) - po15[0];
    r[2] = pe15[1] - fqmul(pe15[9], zeta_i);
    r[3] = fqmul(po15[9], zeta_i) - po15[1];
    r[4] = pe15[2] - fqmul(pe15[10], zeta_i);
    r[5] = fqmul(po15[10], zeta_i) - po15[2];
    r[6] = pe15[3] - fqmul(pe15[11], zeta_i);
    r[7] = fqmul(po15[11], zeta_i) - po15[3];
    r[8] = pe15[4] - fqmul(pe15[12], zeta_i);
    r[9] = fqmul(po15[12], zeta_i) - po15[4];
    r[10] = pe15[5] - fqmul(pe15[13], zeta_i);
    r[11] = fqmul(po15[13], zeta_i) - po15[5];
    r[12] = pe15[6] - fqmul(pe15[14], zeta_i);
    r[13] = fqmul(po15[14], zeta_i) - po15[6];
    r[14] = pe15[7];
    r[15] = fqmul(po15[7], -16'sd171);

    for (i_local = 0; i_local < 16; i_local++) begin
      block_o[i_local*COEFF_W +: COEFF_W] = r[i_local];
    end
  end

endmodule
