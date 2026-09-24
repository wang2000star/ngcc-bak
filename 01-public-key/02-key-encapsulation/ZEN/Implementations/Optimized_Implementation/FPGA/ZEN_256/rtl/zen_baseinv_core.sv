module zen_baseinv_core #(
  parameter int BLOCK_LANES = zen_accel_pkg::BASEINV_LANES,
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic                            clk,
  input  logic                            rst_n,
  input  logic                            start,
  input  logic [1:0]                      profile_id_i,
  input  logic [31:0]                     cfg,
  input  logic [31:0]                     len,
  input  logic [2:0]                      buf_a_sel,
  input  logic [2:0]                      buf_r_sel,
  input  logic                            vec_in_valid,
  input  logic signed [NTT_N*COEFF_W-1:0] vec_a_data,
  output logic                            vec_out_valid,
  output logic signed [NTT_N*COEFF_W-1:0] vec_r_data,
  output logic                            row_out_valid,
  output zen_accel_pkg::zen_row_addr_t    row_out_idx,
  output zen_accel_pkg::zen_stream_row_t  row_out_data,
  output logic                            busy,
  output logic                            done,
  output logic                            error
);

  import zen_accel_pkg::*;
  import zen_ntt_const_pkg::*;

  localparam int BLOCK_COEFFS = NTT_N / 128;
  localparam int SUBBLOCKS = NTT_N / BLOCK_COEFFS;
  localparam int MAX_EXEC_SUBBLOCK_LANES = (BLOCK_LANES > 0) ? (BLOCK_LANES * 2) : 1;
  localparam int BLOCK16_COMPUTE_LANES = 1;
  localparam bit SUPPORTS_BLOCK_INV = (BLOCK_COEFFS == 4) || (BLOCK_COEFFS == 8) || (BLOCK_COEFFS == 16);
  localparam int BLOCK8_BITS = 8 * COEFF_W;
  localparam int BLOCK16_BITS = 16 * COEFF_W;
  localparam int BLOCK16_HALF_BITS = 8 * COEFF_W;
  localparam int BLOCK16_QUARTER_BITS = 4 * COEFF_W;
  localparam int BLOCK16_SCRATCH_CHUNK_COEFFS = 4;
  localparam int BLOCK16_SCRATCH_CHUNKS = 16 / BLOCK16_SCRATCH_CHUNK_COEFFS;
  localparam int BLOCK16_SCRATCH_CHUNK_W =
      (BLOCK16_SCRATCH_CHUNKS > 1) ? $clog2(BLOCK16_SCRATCH_CHUNKS) : 1;
  localparam int PACK_ROW_COEFFS = 16;
  localparam int PACK_ROW_BITS = PACK_ROW_COEFFS * COEFF_W;
  localparam int PACK_ROW_COUNT = NTT_N / PACK_ROW_COEFFS;
  localparam int PACK_ROW_W = (PACK_ROW_COUNT > 1) ? $clog2(PACK_ROW_COUNT) : 1;

  typedef enum logic [4:0] {
    ST_IDLE,
    ST_LOAD,
    ST_PRECOMP,
    ST_COFACTOR,
    ST_TWIDDLE,
    ST_BLOCK8_S0,
    ST_BLOCK8_S1,
    ST_BLOCK8_S2,
    ST_BLOCK8_S3,
    ST_BLOCK8_S4,
    ST_BLOCK8_S5,
    ST_BLOCK16_S0,
    ST_BLOCK16_S1,
    ST_BLOCK16_S2,
    ST_BLOCK16_S3,
    ST_BLOCK16_S4,
    ST_BLOCK16_LOAD,
    ST_BLOCK16_STORE,
    ST_R_STAGE,
    ST_DET_STAGE,
    ST_LOOKUP,
    ST_SCALE,
    ST_PACK,
    ST_PACK_ROWS,
    ST_DONE,
    ST_ERROR
  } state_t;

  state_t state, state_n;

  logic [6:0] subblock_idx;
  logic [7:0] active_lane_count;
  logic [7:0] active_total_subblocks;
  logic [7:0] active_exec_subblock_lanes;
  logic [BLOCK16_SCRATCH_CHUNK_W-1:0] block16_chunk_idx;
  logic [7:0] cfg_total_subblocks;
  logic [7:0] cfg_exec_subblock_lanes;
  logic batch_last;
  logic vec_mode_active;
  logic signed [NTT_N*COEFF_W-1:0] vec_a_data_reg;
  logic signed [PACK_ROW_BITS-1:0] poly_r_rows [0:PACK_ROW_COUNT-1];
  logic [PACK_ROW_W-1:0] pack_row_idx;

  logic lane_active_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic [6:0] lane_subidx_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];

  logic signed [15:0] a0_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a1_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a2_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a3_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a4_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a5_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a6_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a7_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] zeta_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] zeta2_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];

  logic signed [15:0] sq0_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] sq1_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] sq2_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] sq3_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] m13_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] m12_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] m03_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] m02_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];

  logic signed [15:0] a0cube_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a1cube_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] sq0a1_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] sq0a2_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] sq1a0_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] sq0a3_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] m02a1_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];

  logic signed [15:0] u_r0a_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] u_r0b_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] u_r0c_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] u_r1a_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] u_r1b_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] u_r1c_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] u_r2a_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] u_r2b_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] u_r3a_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];

  logic signed [15:0] u_detA_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] u_detB_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] u_detC_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] u_detD_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] u_detE_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] u_detF_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];

  logic signed [15:0] r0pre_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] r1pre_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] r2pre_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] r3pre_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] det_norm_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic [15:0]        lane_qinv [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic [$clog2(MAX_EXEC_SUBBLOCK_LANES)-1:0] lookup_idx;
  logic signed [15:0] block8_pe_reg [0:MAX_EXEC_SUBBLOCK_LANES-1][0:6];
  logic signed [15:0] block8_po_reg [0:MAX_EXEC_SUBBLOCK_LANES-1][0:6];
  logic signed [15:0] block8_b_reg [0:MAX_EXEC_SUBBLOCK_LANES-1][0:3];
  logic signed [15:0] block8_c0_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] block8_c1_reg [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] block8_f_reg [0:MAX_EXEC_SUBBLOCK_LANES-1][0:3];
  logic signed [15:0] block8_c0_stage2_comb [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] block8_c1_stage2_comb [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic [9:0]         block8_inv_addr [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic [15:0]        block8_inv_data [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic [15:0] shared_qinv_data;
  logic signed [15:0] shared_twiddle;
  logic cfg_profile_supported;
  logic cfg_block_supported;
  logic [7:0] active_block_coeffs;
  logic [7:0] cfg_block_coeffs;
  logic active_negate_twiddle;
  logic cfg_negate_twiddle;
  logic signed [MAX_EXEC_SUBBLOCK_LANES*BLOCK8_BITS-1:0] lane8_block_res_flat;
  logic signed [BLOCK16_BITS-1:0] lane16_block_res_flat [0:MAX_EXEC_SUBBLOCK_LANES-1];
  logic signed [BLOCK16_HALF_BITS-1:0] block16_stage0_ae_flat [0:BLOCK16_COMPUTE_LANES-1];
  logic signed [BLOCK16_HALF_BITS-1:0] block16_stage0_ao_flat [0:BLOCK16_COMPUTE_LANES-1];
  logic signed [BLOCK16_QUARTER_BITS-1:0] block16_stage0_he_flat [0:BLOCK16_COMPUTE_LANES-1];
  logic signed [BLOCK16_QUARTER_BITS-1:0] block16_stage0_ho_flat [0:BLOCK16_COMPUTE_LANES-1];
  logic signed [BLOCK16_HALF_BITS-1:0] block16_stage1_mid_flat [0:BLOCK16_COMPUTE_LANES-1];
  logic signed [BLOCK16_HALF_BITS-1:0] block16_stage2_det_flat [0:BLOCK16_COMPUTE_LANES-1];
  logic signed [BLOCK16_HALF_BITS-1:0] block16_stage3_g_flat [0:BLOCK16_COMPUTE_LANES-1];
  logic signed [BLOCK16_BITS-1:0] block16_stage4_res_flat [0:BLOCK16_COMPUTE_LANES-1];
  logic [9:0] block16_inv_addr [0:BLOCK16_COMPUTE_LANES-1];
  logic [15:0] block16_inv_data [0:BLOCK16_COMPUTE_LANES-1];
  logic signed [BLOCK16_HALF_BITS-1:0] block16_ae_reg [0:BLOCK16_COMPUTE_LANES-1];
  logic signed [BLOCK16_HALF_BITS-1:0] block16_ao_reg [0:BLOCK16_COMPUTE_LANES-1];
  logic signed [BLOCK16_QUARTER_BITS-1:0] block16_he_reg [0:BLOCK16_COMPUTE_LANES-1];
  logic signed [BLOCK16_QUARTER_BITS-1:0] block16_ho_reg [0:BLOCK16_COMPUTE_LANES-1];
  logic signed [BLOCK16_HALF_BITS-1:0] block16_mid_reg [0:BLOCK16_COMPUTE_LANES-1];
  logic signed [BLOCK16_HALF_BITS-1:0] block16_det_reg [0:BLOCK16_COMPUTE_LANES-1];
  logic signed [BLOCK16_HALF_BITS-1:0] block16_g_reg [0:BLOCK16_COMPUTE_LANES-1];
  (* ram_style = "distributed" *) logic signed [COEFF_W-1:0] block16_coeff_bank0 [0:BLOCK16_SCRATCH_CHUNKS-1];
  (* ram_style = "distributed" *) logic signed [COEFF_W-1:0] block16_coeff_bank1 [0:BLOCK16_SCRATCH_CHUNKS-1];
  (* ram_style = "distributed" *) logic signed [COEFF_W-1:0] block16_coeff_bank2 [0:BLOCK16_SCRATCH_CHUNKS-1];
  (* ram_style = "distributed" *) logic signed [COEFF_W-1:0] block16_coeff_bank3 [0:BLOCK16_SCRATCH_CHUNKS-1];

  integer i;
  integer j;
  integer k;

  function automatic logic signed [COEFF_W-1:0] flat_get(
    input logic signed [NTT_N*COEFF_W-1:0] flat,
    input integer idx
  );
    begin
      flat_get = flat[idx*COEFF_W +: COEFF_W];
    end
  endfunction

  function automatic logic [7:0] calc_lane_count(
    input logic [6:0] idx,
    input logic [7:0] total_subblocks_i,
    input logic [7:0] exec_lanes_i
  );
    integer remain;
    begin
      remain = total_subblocks_i - idx;
      if (remain > exec_lanes_i) calc_lane_count = exec_lanes_i;
      else calc_lane_count = remain[7:0];
    end
  endfunction

  function automatic logic calc_batch_last(
    input logic [6:0] idx,
    input logic [7:0] lane_count_i,
    input logic [7:0] total_subblocks_i
  );
    integer next_idx;
    begin
      next_idx = idx + lane_count_i;
      calc_batch_last = (next_idx >= total_subblocks_i);
    end
  endfunction

  function automatic logic lookup_reaches_end(
    input logic [$clog2(MAX_EXEC_SUBBLOCK_LANES)-1:0] lookup_idx_i,
    input logic [7:0] lane_count_i
  );
    integer idx_next;
    begin
      idx_next = lookup_idx_i + 1;
      lookup_reaches_end = (idx_next >= lane_count_i);
    end
  endfunction

  function automatic int profile_block_coeffs(input logic [1:0] profile_id);
    begin
      profile_block_coeffs = profile_n(profile_id) / 128;
    end
  endfunction

  function automatic logic signed [127:0] baseinv8_block(
    input logic signed [15:0] a0,
    input logic signed [15:0] a1,
    input logic signed [15:0] a2,
    input logic signed [15:0] a3,
    input logic signed [15:0] a4,
    input logic signed [15:0] a5,
    input logic signed [15:0] a6,
    input logic signed [15:0] a7,
    input logic signed [15:0] zeta
  );
    logic signed [15:0] b0, b1, b2, b3;
    logic signed [15:0] c0, c1;
    logic signed [15:0] f0, f1, f2, f3;
    logic signed [15:0] e, t;
    logic signed [15:0] pe [0:6];
    logic signed [15:0] po [0:6];
    logic signed [15:0] p0, p1, p2, q0, q1, q2, m0, m1, m2;
    logic signed [15:0] sx0, sx1, sy0, sy1;
    logic [15:0] inv_e;
    logic signed [15:0] r0, r1, r2, r3, r4, r5, r6, r7;
    begin
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

      b0 = pe[0] - fqmul(pe[4] - po[3], zeta);
      b1 = pe[1] - po[0] - fqmul(pe[5] - po[4], zeta);
      b2 = pe[2] - po[1] - fqmul(pe[6] - po[5], zeta);
      b3 = pe[3] - po[2] + fqmul(po[6], zeta);

      p0 = fqmul(b0, b0);
      p1 = fqmul(fqmul(b0, b2), 16'sd342);
      p2 = fqmul(b2, b2);

      q0 = fqmul(b1, b1);
      q1 = fqmul(fqmul(b1, b3), 16'sd342);
      q2 = fqmul(b3, b3);

      c0 = p0 - fqmul(p2 - q1, zeta);
      c1 = p1 - q0 + fqmul(q2, zeta);

      e = fqmul(c1, c1);
      e = fqmul(e, zeta);
      t = fqmul(c0, c0);
      e = norm_q(e + t);
      inv_e = inv_mod_q(e);

      c0 = fqmul(inv_e, c0);
      c1 = fqmul(inv_e, c1);
      c1 = fqmul(c1, -16'sd171);

      p0 = fqmul(c0, b0);
      p2 = fqmul(c1, b2);
      p1 = fqmul(c0 + c1, b0 + b2) - p0 - p2;

      q0 = fqmul(c0, b1);
      q2 = fqmul(c1, b3);
      q1 = fqmul(c0 + c1, b1 + b3) - q0 - q2;

      f0 = p0 - fqmul(p2, zeta);
      f1 = fqmul(q2, zeta) - q0;
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

      r0 = pe[0] - fqmul(pe[4], zeta);
      r1 = fqmul(po[4], zeta) - po[0];
      r2 = pe[1] - fqmul(pe[5], zeta);
      r3 = fqmul(po[5], zeta) - po[1];
      r4 = pe[2] - fqmul(pe[6], zeta);
      r5 = fqmul(po[6], zeta) - po[2];
      r6 = pe[3];
      r7 = fqmul(po[3], -16'sd171);

      baseinv8_block = {
        r7, r6, r5, r4, r3, r2, r1, r0
      };
    end
  endfunction

  function automatic logic signed [15:0] poly7_get(
    input logic signed [111:0] poly,
    input int idx
  );
    begin
      poly7_get = poly[idx*16 +: 16];
    end
  endfunction

  function automatic logic signed [111:0] karatsuba_mul4_block_exact(
    input logic signed [15:0] a0,
    input logic signed [15:0] a1,
    input logic signed [15:0] a2,
    input logic signed [15:0] a3,
    input logic signed [15:0] b0,
    input logic signed [15:0] b1,
    input logic signed [15:0] b2,
    input logic signed [15:0] b3
  );
    logic signed [15:0] a01, a23, b01, b23;
    logic signed [15:0] p0_0, p0_1, p0_2;
    logic signed [15:0] p1_0, p1_1, p1_2;
    logic signed [15:0] pm_0, pm_1, pm_2;
    logic signed [15:0] r0, r1, r2, r3, r4, r5, r6;
    begin
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

  function automatic logic signed [15:0] poly15_get(
    input logic signed [239:0] poly,
    input int idx
  );
    begin
      poly15_get = poly[idx*16 +: 16];
    end
  endfunction

  function automatic logic signed [239:0] karatsuba_mul8_block_exact(
    input logic signed [15:0] a0,
    input logic signed [15:0] a1,
    input logic signed [15:0] a2,
    input logic signed [15:0] a3,
    input logic signed [15:0] a4,
    input logic signed [15:0] a5,
    input logic signed [15:0] a6,
    input logic signed [15:0] a7,
    input logic signed [15:0] b0,
    input logic signed [15:0] b1,
    input logic signed [15:0] b2,
    input logic signed [15:0] b3,
    input logic signed [15:0] b4,
    input logic signed [15:0] b5,
    input logic signed [15:0] b6,
    input logic signed [15:0] b7
  );
    logic signed [15:0] as0, as1, as2, as3;
    logic signed [15:0] bs0, bs1, bs2, bs3;
    logic signed [111:0] p0_pack, p1_pack, pm_pack;
    logic signed [15:0] r [0:14];
    begin
      p0_pack = karatsuba_mul4_block_exact(a0, a1, a2, a3, b0, b1, b2, b3);
      p1_pack = karatsuba_mul4_block_exact(a4, a5, a6, a7, b4, b5, b6, b7);

      as0 = a0 + a4;
      as1 = a1 + a5;
      as2 = a2 + a6;
      as3 = a3 + a7;
      bs0 = b0 + b4;
      bs1 = b1 + b5;
      bs2 = b2 + b6;
      bs3 = b3 + b7;

      pm_pack = karatsuba_mul4_block_exact(as0, as1, as2, as3, bs0, bs1, bs2, bs3);

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

  function automatic logic signed [15:0] block_get(
    input logic signed [127:0] block,
    input int idx
  );
    begin
      block_get = block[idx*16 +: 16];
    end
  endfunction

  function automatic logic signed [15:0] block16_get(
    input logic signed [255:0] block,
    input int idx
  );
    begin
      block16_get = block[idx*16 +: 16];
    end
  endfunction

  function automatic logic signed [255:0] baseinv16_block_from_flat(
    input logic signed [NTT_N*COEFF_W-1:0] flat_a,
    input integer base,
    input logic signed [15:0] zeta
  );
    logic signed [15:0] a [0:15];
    logic signed [15:0] ae [0:7];
    logic signed [15:0] ao [0:7];
    logic signed [15:0] h [0:7];
    logic signed [15:0] he [0:3];
    logic signed [15:0] ho [0:3];
    logic signed [15:0] b [0:3];
    logic signed [15:0] g [0:7];
    logic signed [15:0] pe15 [0:14];
    logic signed [15:0] po15 [0:14];
    logic signed [15:0] pe7 [0:6];
    logic signed [15:0] po7 [0:6];
    logic signed [15:0] fvec [0:3];
    logic signed [15:0] r [0:15];
    logic signed [15:0] c0;
    logic signed [15:0] c1;
    logic signed [15:0] e;
    logic signed [15:0] t;
    logic signed [15:0] f0;
    logic signed [15:0] f1;
    logic signed [15:0] f2;
    logic signed [15:0] f3;
    logic signed [15:0] q0e;
    logic signed [15:0] q1e;
    logic signed [15:0] q2e;
    logic signed [15:0] q0o;
    logic signed [15:0] q1o;
    logic signed [15:0] q2o;
    logic signed [239:0] p15_e_pack;
    logic signed [239:0] p15_o_pack;
    logic signed [111:0] p7_e_pack;
    logic signed [111:0] p7_o_pack;
    integer i_local;
    begin
      baseinv16_block_from_flat = '0;

      for (i_local = 0; i_local < 16; i_local++) begin
        a[i_local] = flat_get(flat_a, base + i_local);
        r[i_local] = 16'sd0;
      end

      for (i_local = 0; i_local < 8; i_local++) begin
        ae[i_local] = a[2 * i_local];
        ao[i_local] = a[2 * i_local + 1];
        h[i_local] = 16'sd0;
        g[i_local] = 16'sd0;
      end

      for (i_local = 0; i_local < 4; i_local++) begin
        he[i_local] = 16'sd0;
        ho[i_local] = 16'sd0;
        b[i_local] = 16'sd0;
        fvec[i_local] = 16'sd0;
      end

      p15_e_pack = karatsuba_mul8_block_exact(
        ae[0], ae[1], ae[2], ae[3], ae[4], ae[5], ae[6], ae[7],
        ae[0], ae[1], ae[2], ae[3], ae[4], ae[5], ae[6], ae[7]
      );
      p15_o_pack = karatsuba_mul8_block_exact(
        ao[0], ao[1], ao[2], ao[3], ao[4], ao[5], ao[6], ao[7],
        ao[0], ao[1], ao[2], ao[3], ao[4], ao[5], ao[6], ao[7]
      );
      for (i_local = 0; i_local < 15; i_local++) begin
        pe15[i_local] = poly15_get(p15_e_pack, i_local);
        po15[i_local] = poly15_get(p15_o_pack, i_local);
      end

      h[0] = pe15[0] - fqmul(pe15[8] - po15[7], zeta);
      h[1] = pe15[1] - po15[0] - fqmul(pe15[9] - po15[8], zeta);
      h[2] = pe15[2] - po15[1] - fqmul(pe15[10] - po15[9], zeta);
      h[3] = pe15[3] - po15[2] - fqmul(pe15[11] - po15[10], zeta);
      h[4] = pe15[4] - po15[3] - fqmul(pe15[12] - po15[11], zeta);
      h[5] = pe15[5] - po15[4] - fqmul(pe15[13] - po15[12], zeta);
      h[6] = pe15[6] - po15[5] - fqmul(pe15[14] - po15[13], zeta);
      h[7] = pe15[7] - po15[6] + fqmul(po15[14], zeta);

      he[0] = h[0];
      he[1] = h[2];
      he[2] = h[4];
      he[3] = h[6];
      ho[0] = h[1];
      ho[1] = h[3];
      ho[2] = h[5];
      ho[3] = h[7];

      p7_e_pack = karatsuba_mul4_block_exact(he[0], he[1], he[2], he[3], he[0], he[1], he[2], he[3]);
      p7_o_pack = karatsuba_mul4_block_exact(ho[0], ho[1], ho[2], ho[3], ho[0], ho[1], ho[2], ho[3]);
      for (i_local = 0; i_local < 7; i_local++) begin
        pe7[i_local] = poly7_get(p7_e_pack, i_local);
        po7[i_local] = poly7_get(p7_o_pack, i_local);
      end

      b[0] = pe7[0] - fqmul(pe7[4] - po7[3], zeta);
      b[1] = pe7[1] - po7[0] - fqmul(pe7[5] - po7[4], zeta);
      b[2] = pe7[2] - po7[1] - fqmul(pe7[6] - po7[5], zeta);
      b[3] = pe7[3] - po7[2] + fqmul(po7[6], zeta);

      q0e = fqmul(b[0], b[0]);
      q2e = fqmul(b[2], b[2]);
      q1e = fqmul(fqmul(b[0], b[2]), 16'sd342);
      q0o = fqmul(b[1], b[1]);
      q2o = fqmul(b[3], b[3]);
      q1o = fqmul(fqmul(b[1], b[3]), 16'sd342);

      c0 = q0e - fqmul(q2e - q1o, zeta);
      c1 = q1e - q0o + fqmul(q2o, zeta);

      e = fqmul(c1, c1);
      e = fqmul(e, zeta);
      t = fqmul(c0, c0);
      e = norm_q(e + t);
      e = inv_mod_q(e);

      c0 = fqmul(e, c0);
      c1 = fqmul(e, c1);
      c1 = fqmul(c1, -16'sd171);

      f0 = fqmul(c1, b[2]);
      f0 = fqmul(f0, zeta);
      t = fqmul(c0, b[0]);
      f0 = t - f0;

      f1 = fqmul(c1, b[3]);
      f1 = fqmul(f1, zeta);
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

      p7_e_pack = karatsuba_mul4_block_exact(fvec[0], fvec[1], fvec[2], fvec[3], he[0], he[1], he[2], he[3]);
      p7_o_pack = karatsuba_mul4_block_exact(fvec[0], fvec[1], fvec[2], fvec[3], ho[0], ho[1], ho[2], ho[3]);
      for (i_local = 0; i_local < 7; i_local++) begin
        pe7[i_local] = poly7_get(p7_e_pack, i_local);
        po7[i_local] = poly7_get(p7_o_pack, i_local);
      end

      g[0] = pe7[0] - fqmul(pe7[4], zeta);
      g[1] = fqmul(po7[4], zeta) - po7[0];
      g[2] = pe7[1] - fqmul(pe7[5], zeta);
      g[3] = fqmul(po7[5], zeta) - po7[1];
      g[4] = pe7[2] - fqmul(pe7[6], zeta);
      g[5] = fqmul(po7[6], zeta) - po7[2];
      g[6] = pe7[3];
      g[7] = fqmul(po7[3], -16'sd171);

      p15_e_pack = karatsuba_mul8_block_exact(
        g[0], g[1], g[2], g[3], g[4], g[5], g[6], g[7],
        ae[0], ae[1], ae[2], ae[3], ae[4], ae[5], ae[6], ae[7]
      );
      p15_o_pack = karatsuba_mul8_block_exact(
        g[0], g[1], g[2], g[3], g[4], g[5], g[6], g[7],
        ao[0], ao[1], ao[2], ao[3], ao[4], ao[5], ao[6], ao[7]
      );
      for (i_local = 0; i_local < 15; i_local++) begin
        pe15[i_local] = poly15_get(p15_e_pack, i_local);
        po15[i_local] = poly15_get(p15_o_pack, i_local);
      end

      r[0] = pe15[0] - fqmul(pe15[8], zeta);
      r[1] = fqmul(po15[8], zeta) - po15[0];
      r[2] = pe15[1] - fqmul(pe15[9], zeta);
      r[3] = fqmul(po15[9], zeta) - po15[1];
      r[4] = pe15[2] - fqmul(pe15[10], zeta);
      r[5] = fqmul(po15[10], zeta) - po15[2];
      r[6] = pe15[3] - fqmul(pe15[11], zeta);
      r[7] = fqmul(po15[11], zeta) - po15[3];
      r[8] = pe15[4] - fqmul(pe15[12], zeta);
      r[9] = fqmul(po15[12], zeta) - po15[4];
      r[10] = pe15[5] - fqmul(pe15[13], zeta);
      r[11] = fqmul(po15[13], zeta) - po15[5];
      r[12] = pe15[6] - fqmul(pe15[14], zeta);
      r[13] = fqmul(po15[14], zeta) - po15[6];
      r[14] = pe15[7];
      r[15] = fqmul(po15[7], -16'sd171);

      for (i_local = 0; i_local < 16; i_local++) begin
        baseinv16_block_from_flat[i_local*16 +: 16] = r[i_local];
      end
    end
  endfunction

  assign active_lane_count = calc_lane_count(subblock_idx, active_total_subblocks, active_exec_subblock_lanes);
  assign batch_last = calc_batch_last(subblock_idx, active_lane_count, active_total_subblocks);

  always_comb begin
    for (k = 0; k < MAX_EXEC_SUBBLOCK_LANES; k++) begin
      logic signed [15:0] q0e;
      logic signed [15:0] q1e;
      logic signed [15:0] q2e;
      logic signed [15:0] q0o;
      logic signed [15:0] q1o;
      logic signed [15:0] q2o;
      logic signed [15:0] c0;
      logic signed [15:0] c1;
      logic signed [15:0] e_det;
      logic signed [15:0] t_det;
      q0e = '0;
      q1e = '0;
      q2e = '0;
      q0o = '0;
      q1o = '0;
      q2o = '0;
      c0 = '0;
      c1 = '0;
      e_det = '0;
      t_det = '0;
      block8_c0_stage2_comb[k] = '0;
      block8_c1_stage2_comb[k] = '0;
      block8_inv_addr[k] = '0;
      if (lane_active_reg[k] && (active_block_coeffs == 8)) begin
        q0e = fqmul(block8_b_reg[k][0], block8_b_reg[k][0]);
        q2e = fqmul(block8_b_reg[k][2], block8_b_reg[k][2]);
        q1e = fqmul(fqmul(block8_b_reg[k][0], block8_b_reg[k][2]), 16'sd342);
        q0o = fqmul(block8_b_reg[k][1], block8_b_reg[k][1]);
        q2o = fqmul(block8_b_reg[k][3], block8_b_reg[k][3]);
        q1o = fqmul(fqmul(block8_b_reg[k][1], block8_b_reg[k][3]), 16'sd342);

        c0 = q0e - fqmul(q2e - q1o, zeta_reg[k]);
        c1 = q1e - q0o + fqmul(q2o, zeta_reg[k]);
        e_det = fqmul(c1, c1);
        e_det = fqmul(e_det, zeta_reg[k]);
        t_det = fqmul(c0, c0);
        e_det = norm_q(e_det + t_det);

        block8_c0_stage2_comb[k] = c0;
        block8_c1_stage2_comb[k] = c1;
        block8_inv_addr[k] = e_det[9:0];
      end
    end
  end

  generate
    genvar lane;
    for (lane = 0; lane < MAX_EXEC_SUBBLOCK_LANES; lane++) begin : gen_baseinv_lane_blocks
      zen_qinv_rom u_block8_qinv_rom (
        .addr (block8_inv_addr[lane]),
        .data (block8_inv_data[lane])
      );

      if (lane < BLOCK16_COMPUTE_LANES) begin : gen_baseinv16_lane
        logic signed [BLOCK16_BITS-1:0] lane16_a_vec;
        logic signed [15:0] block16_e_norm_word;

        assign lane16_a_vec = {
          block16_coeff_bank3[3], block16_coeff_bank2[3], block16_coeff_bank1[3], block16_coeff_bank0[3],
          block16_coeff_bank3[2], block16_coeff_bank2[2], block16_coeff_bank1[2], block16_coeff_bank0[2],
          block16_coeff_bank3[1], block16_coeff_bank2[1], block16_coeff_bank1[1], block16_coeff_bank0[1],
          block16_coeff_bank3[0], block16_coeff_bank2[0], block16_coeff_bank1[0], block16_coeff_bank0[0]
        };

        zen_baseinv16_stage_core #(
          .COEFF_W(COEFF_W),
          .STAGE  (0)
        ) u_baseinv16_s0 (
          .a_vec_i (lane16_a_vec),
          .ae_vec_i('0),
          .ao_vec_i('0),
          .he_vec_i('0),
          .ho_vec_i('0),
          .g_vec_i ('0),
          .qinv_i  ('0),
          .zeta_i  (zeta_reg[lane]),
          .ae_vec_o(block16_stage0_ae_flat[lane]),
          .ao_vec_o(block16_stage0_ao_flat[lane]),
          .he_vec_o(block16_stage0_he_flat[lane]),
          .ho_vec_o(block16_stage0_ho_flat[lane]),
          .g_vec_o (),
          .block_o ()
        );

        zen_baseinv16_stage_core #(
          .COEFF_W(COEFF_W),
          .STAGE  (1)
        ) u_baseinv16_s1 (
          .a_vec_i ('0),
          .ae_vec_i('0),
          .ao_vec_i('0),
          .he_vec_i(block16_he_reg[lane]),
          .ho_vec_i(block16_ho_reg[lane]),
          .g_vec_i ('0),
          .qinv_i  ('0),
          .zeta_i  (zeta_reg[lane]),
          .ae_vec_o(),
          .ao_vec_o(),
          .he_vec_o(),
          .ho_vec_o(),
          .g_vec_o (block16_stage1_mid_flat[lane]),
          .block_o ()
        );

        zen_baseinv16_stage_core #(
          .COEFF_W(COEFF_W),
          .STAGE  (2)
        ) u_baseinv16_s2 (
          .a_vec_i ('0),
          .ae_vec_i('0),
          .ao_vec_i('0),
          .he_vec_i('0),
          .ho_vec_i('0),
          .g_vec_i (block16_mid_reg[lane]),
          .qinv_i  ('0),
          .zeta_i  (zeta_reg[lane]),
          .ae_vec_o(),
          .ao_vec_o(),
          .he_vec_o(),
          .ho_vec_o(),
          .g_vec_o (block16_stage2_det_flat[lane]),
          .block_o ()
        );

        assign block16_e_norm_word = block_get(block16_det_reg[lane], 6);
        assign block16_inv_addr[lane] = block16_e_norm_word[9:0];

        zen_qinv_rom u_block16_qinv_rom (
          .addr (block16_inv_addr[lane]),
          .data (block16_inv_data[lane])
        );

        zen_baseinv16_stage_core #(
          .COEFF_W(COEFF_W),
          .STAGE  (3)
        ) u_baseinv16_s3 (
          .a_vec_i ('0),
          .ae_vec_i('0),
          .ao_vec_i('0),
          .he_vec_i(block16_he_reg[lane]),
          .ho_vec_i(block16_ho_reg[lane]),
          .g_vec_i (block16_det_reg[lane]),
          .qinv_i  (block16_inv_data[lane]),
          .zeta_i  (zeta_reg[lane]),
          .ae_vec_o(),
          .ao_vec_o(),
          .he_vec_o(),
          .ho_vec_o(),
          .g_vec_o (block16_stage3_g_flat[lane]),
          .block_o ()
        );

        zen_baseinv16_stage_core #(
          .COEFF_W(COEFF_W),
          .STAGE  (4)
        ) u_baseinv16_s4 (
          .a_vec_i ('0),
          .ae_vec_i(block16_ae_reg[lane]),
          .ao_vec_i(block16_ao_reg[lane]),
          .he_vec_i('0),
          .ho_vec_i('0),
          .g_vec_i (block16_g_reg[lane]),
          .qinv_i  ('0),
          .zeta_i  (zeta_reg[lane]),
          .ae_vec_o(),
          .ao_vec_o(),
          .he_vec_o(),
          .ho_vec_o(),
          .g_vec_o (),
          .block_o  (block16_stage4_res_flat[lane])
        );
      end
    end
  endgenerate

  zen_basemul_twiddle_rom u_twiddle_rom (
    .block_idx  (lane_subidx_reg[lookup_idx][6:1]),
    .upper_half (lane_subidx_reg[lookup_idx][0]),
    .twiddle    (shared_twiddle)
  );

  zen_qinv_rom u_qinv_rom (
    .addr (det_norm_reg[lookup_idx][9:0]),
    .data (shared_qinv_data)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= ST_IDLE;
      subblock_idx <= '0;
      block16_chunk_idx <= '0;
      active_total_subblocks <= '0;
      active_exec_subblock_lanes <= 8'd1;
      active_block_coeffs <= '0;
      active_negate_twiddle <= 1'b0;
      vec_mode_active <= 1'b0;
      vec_a_data_reg <= '0;
      vec_r_data <= '0;
      vec_out_valid <= 1'b0;
      row_out_valid <= 1'b0;
      row_out_idx <= '0;
      row_out_data <= '0;
      done <= 1'b0;
      error <= 1'b0;
      pack_row_idx <= '0;
      for (i = 0; i < MAX_EXEC_SUBBLOCK_LANES; i++) begin
        lane_active_reg[i] <= 1'b0;
        lane_subidx_reg[i] <= '0;
        a0_reg[i] <= '0;
        a1_reg[i] <= '0;
        a2_reg[i] <= '0;
        a3_reg[i] <= '0;
        a4_reg[i] <= '0;
        a5_reg[i] <= '0;
        a6_reg[i] <= '0;
        a7_reg[i] <= '0;
        zeta_reg[i] <= '0;
        zeta2_reg[i] <= '0;
        sq0_reg[i] <= '0;
        sq1_reg[i] <= '0;
        sq2_reg[i] <= '0;
        sq3_reg[i] <= '0;
        m13_reg[i] <= '0;
        m12_reg[i] <= '0;
        m03_reg[i] <= '0;
        m02_reg[i] <= '0;
        a0cube_reg[i] <= '0;
        a1cube_reg[i] <= '0;
        sq0a1_reg[i] <= '0;
        sq0a2_reg[i] <= '0;
        sq1a0_reg[i] <= '0;
        sq0a3_reg[i] <= '0;
        m02a1_reg[i] <= '0;
        u_r0a_reg[i] <= '0;
        u_r0b_reg[i] <= '0;
        u_r0c_reg[i] <= '0;
        u_r1a_reg[i] <= '0;
        u_r1b_reg[i] <= '0;
        u_r1c_reg[i] <= '0;
        u_r2a_reg[i] <= '0;
        u_r2b_reg[i] <= '0;
        u_r3a_reg[i] <= '0;
        u_detA_reg[i] <= '0;
        u_detB_reg[i] <= '0;
        u_detC_reg[i] <= '0;
        u_detD_reg[i] <= '0;
        u_detE_reg[i] <= '0;
        u_detF_reg[i] <= '0;
        r0pre_reg[i] <= '0;
        r1pre_reg[i] <= '0;
        r2pre_reg[i] <= '0;
        r3pre_reg[i] <= '0;
        det_norm_reg[i] <= '0;
        lane_qinv[i] <= '0;
        block8_c0_reg[i] <= '0;
        block8_c1_reg[i] <= '0;
        lane8_block_res_flat[i*BLOCK8_BITS +: BLOCK8_BITS] <= '0;
        lane16_block_res_flat[i] <= '0;
        if (i < BLOCK16_COMPUTE_LANES) begin
          block16_ae_reg[i] <= '0;
          block16_ao_reg[i] <= '0;
          block16_he_reg[i] <= '0;
          block16_ho_reg[i] <= '0;
          block16_mid_reg[i] <= '0;
          block16_det_reg[i] <= '0;
          block16_g_reg[i] <= '0;
        end
        for (j = 0; j < 7; j++) begin
          block8_pe_reg[i][j] <= '0;
          block8_po_reg[i][j] <= '0;
        end
        for (j = 0; j < 4; j++) begin
          block8_b_reg[i][j] <= '0;
          block8_f_reg[i][j] <= '0;
        end
      end
      for (j = 0; j < BLOCK16_SCRATCH_CHUNKS; j++) begin
        block16_coeff_bank0[j] <= '0;
        block16_coeff_bank1[j] <= '0;
        block16_coeff_bank2[j] <= '0;
        block16_coeff_bank3[j] <= '0;
      end
      for (j = 0; j < PACK_ROW_COUNT; j++) begin
        poly_r_rows[j] <= '0;
      end
      lookup_idx <= '0;
    end else begin
      state <= state_n;
      vec_out_valid <= (state_n == ST_DONE) && vec_mode_active;
      row_out_valid <= 1'b0;
      done <= (state_n == ST_DONE) && vec_mode_active;
      error <= (state_n == ST_ERROR);

      case (state)
        ST_IDLE: begin
          if (start) begin
            subblock_idx <= '0;
            lookup_idx <= '0;
            vec_mode_active <= vec_in_valid;
            vec_a_data_reg <= vec_a_data;
            vec_r_data <= '0;
            row_out_idx <= '0;
            row_out_data <= '0;
            pack_row_idx <= '0;
          end
        end

        ST_LOAD: begin
          active_total_subblocks <= cfg_total_subblocks;
          active_exec_subblock_lanes <= cfg_exec_subblock_lanes;
          active_block_coeffs <= cfg_block_coeffs;
          active_negate_twiddle <= cfg_negate_twiddle;
        end

        ST_PRECOMP: begin
          if (active_block_coeffs == 16) begin
            block16_chunk_idx <= '0;
          end
          for (i = 0; i < MAX_EXEC_SUBBLOCK_LANES; i++) begin
            lane_active_reg[i] <= (i < active_lane_count);
            if (i < active_lane_count) begin
              integer base;
              logic signed [15:0] a0, a1, a2, a3;
              lane_subidx_reg[i] <= subblock_idx + i[6:0];
              base = (subblock_idx + i[6:0]) * active_block_coeffs;
              a0 = flat_get(vec_a_data_reg, base + 0);
              a1 = flat_get(vec_a_data_reg, base + 1);
              a2 = flat_get(vec_a_data_reg, base + 2);
              a3 = flat_get(vec_a_data_reg, base + 3);
              a0_reg[i] <= a0;
              a1_reg[i] <= a1;
              a2_reg[i] <= a2;
              a3_reg[i] <= a3;
              if (active_block_coeffs == 4) begin
                sq0_reg[i] <= fqmul(a0, a0);
                sq1_reg[i] <= fqmul(a1, a1);
                sq2_reg[i] <= fqmul(a2, a2);
                sq3_reg[i] <= fqmul(a3, a3);
                m13_reg[i] <= fqmul(a1, a3);
                m12_reg[i] <= fqmul(a1, a2);
                m03_reg[i] <= fqmul(a0, a3);
                m02_reg[i] <= fqmul(a0, a2);
              end else if (active_block_coeffs == 8) begin
                a4_reg[i] <= flat_get(vec_a_data_reg, base + 4);
                a5_reg[i] <= flat_get(vec_a_data_reg, base + 5);
                a6_reg[i] <= flat_get(vec_a_data_reg, base + 6);
                a7_reg[i] <= flat_get(vec_a_data_reg, base + 7);
              end
            end
          end
        end

        ST_BLOCK16_LOAD: begin
          if (lane_active_reg[0] && (active_block_coeffs == 16)) begin
            integer base;
            integer chunk_base;
            chunk_base = block16_chunk_idx * BLOCK16_SCRATCH_CHUNK_COEFFS;
            base = (lane_subidx_reg[0] * active_block_coeffs) + chunk_base;
            block16_coeff_bank0[block16_chunk_idx] <= flat_get(vec_a_data_reg, base + 0);
            block16_coeff_bank1[block16_chunk_idx] <= flat_get(vec_a_data_reg, base + 1);
            block16_coeff_bank2[block16_chunk_idx] <= flat_get(vec_a_data_reg, base + 2);
            block16_coeff_bank3[block16_chunk_idx] <= flat_get(vec_a_data_reg, base + 3);
          end
          if (block16_chunk_idx == BLOCK16_SCRATCH_CHUNKS - 1) begin
            block16_chunk_idx <= '0;
          end else begin
            block16_chunk_idx <= block16_chunk_idx + 1'b1;
          end
        end

        ST_COFACTOR: begin
          for (i = 0; i < MAX_EXEC_SUBBLOCK_LANES; i++) begin
            if (lane_active_reg[i] && (active_block_coeffs == 4)) begin
              a0cube_reg[i] <= fqmul(sq0_reg[i], a0_reg[i]);
              a1cube_reg[i] <= fqmul(sq1_reg[i], a1_reg[i]);
              sq0a1_reg[i] <= fqmul(sq0_reg[i], a1_reg[i]);
              sq0a2_reg[i] <= fqmul(sq0_reg[i], a2_reg[i]);
              sq1a0_reg[i] <= fqmul(sq1_reg[i], a0_reg[i]);
              sq0a3_reg[i] <= fqmul(sq0_reg[i], a3_reg[i]);
              m02a1_reg[i] <= fqmul(m02_reg[i], a1_reg[i]);

              u_r0a_reg[i] <= fqmul(sq2_reg[i] + fqmul(m13_reg[i], 16'sd342), a0_reg[i]);
              u_r0b_reg[i] <= fqmul(sq1_reg[i], a2_reg[i]);
              u_r0c_reg[i] <= fqmul(sq3_reg[i], a2_reg[i]);

              u_r1a_reg[i] <= fqmul(m12_reg[i] - fqmul(m03_reg[i], 16'sd342), a2_reg[i]);
              u_r1b_reg[i] <= fqmul(sq1_reg[i], a3_reg[i]);
              u_r1c_reg[i] <= fqmul(sq3_reg[i], a3_reg[i]);

              u_r2a_reg[i] <= fqmul(fqmul(m13_reg[i], 16'sd342) - sq2_reg[i], a2_reg[i]);
              u_r2b_reg[i] <= fqmul(sq3_reg[i], a0_reg[i]);
              u_r3a_reg[i] <= fqmul(sq2_reg[i] - m13_reg[i], a3_reg[i]);

              u_detA_reg[i] <= fqmul(sq2_reg[i] - fqmul(m13_reg[i], 16'sd684), a2_reg[i]);
              u_detB_reg[i] <= fqmul(fqmul(m02_reg[i], 16'sd342) + sq1_reg[i], a3_reg[i]);
              u_detC_reg[i] <= fqmul(sq3_reg[i], a3_reg[i]);
              u_detD_reg[i] <= fqmul(sq0_reg[i], a0_reg[i]);
              u_detE_reg[i] <= fqmul(fqmul(fqmul(m13_reg[i], 16'sd342) + sq2_reg[i], 16'sd342), a0_reg[i]);
              u_detF_reg[i] <= fqmul(sq1_reg[i] + fqmul(m02_reg[i], -16'sd684), a1_reg[i]);
            end
          end
          lookup_idx <= '0;
        end

        ST_TWIDDLE: begin
          if (lane_active_reg[lookup_idx]) begin
            logic signed [15:0] twiddle_eff;
            twiddle_eff = active_negate_twiddle ? -shared_twiddle : shared_twiddle;
            zeta_reg[lookup_idx] <= twiddle_eff;
            zeta2_reg[lookup_idx] <= fqmul(twiddle_eff, twiddle_eff);
          end
          if (!lookup_reaches_end(lookup_idx, active_lane_count)) begin
            lookup_idx <= lookup_idx + 1'b1;
          end else begin
            lookup_idx <= '0;
          end
        end

        ST_BLOCK8_S0: begin
          for (i = 0; i < MAX_EXEC_SUBBLOCK_LANES; i++) begin
            if (lane_active_reg[i] && (active_block_coeffs == 8)) begin
              logic signed [15:0] p0;
              logic signed [15:0] p1;
              logic signed [15:0] p2;
              logic signed [15:0] q0;
              logic signed [15:0] q1;
              logic signed [15:0] q2;
              logic signed [15:0] m0;
              logic signed [15:0] m1;
              logic signed [15:0] m2;
              logic signed [15:0] sx0;
              logic signed [15:0] sx1;

              p0 = fqmul(a0_reg[i], a0_reg[i]);
              p1 = fqmul(fqmul(a0_reg[i], a2_reg[i]), 16'sd342);
              p2 = fqmul(a2_reg[i], a2_reg[i]);
              q0 = fqmul(a4_reg[i], a4_reg[i]);
              q1 = fqmul(fqmul(a4_reg[i], a6_reg[i]), 16'sd342);
              q2 = fqmul(a6_reg[i], a6_reg[i]);
              sx0 = a0_reg[i] + a4_reg[i];
              sx1 = a2_reg[i] + a6_reg[i];
              m0 = fqmul(sx0, sx0);
              m1 = fqmul(fqmul(sx0, sx1), 16'sd342);
              m2 = fqmul(sx1, sx1);

              block8_pe_reg[i][0] <= p0;
              block8_pe_reg[i][1] <= p1;
              block8_pe_reg[i][2] <= p2 + m0 - p0 - q0;
              block8_pe_reg[i][3] <= m1 - p1 - q1;
              block8_pe_reg[i][4] <= q0 + m2 - p2 - q2;
              block8_pe_reg[i][5] <= q1;
              block8_pe_reg[i][6] <= q2;

              p0 = fqmul(a1_reg[i], a1_reg[i]);
              p1 = fqmul(fqmul(a1_reg[i], a3_reg[i]), 16'sd342);
              p2 = fqmul(a3_reg[i], a3_reg[i]);
              q0 = fqmul(a5_reg[i], a5_reg[i]);
              q1 = fqmul(fqmul(a5_reg[i], a7_reg[i]), 16'sd342);
              q2 = fqmul(a7_reg[i], a7_reg[i]);
              sx0 = a1_reg[i] + a5_reg[i];
              sx1 = a3_reg[i] + a7_reg[i];
              m0 = fqmul(sx0, sx0);
              m1 = fqmul(fqmul(sx0, sx1), 16'sd342);
              m2 = fqmul(sx1, sx1);

              block8_po_reg[i][0] <= p0;
              block8_po_reg[i][1] <= p1;
              block8_po_reg[i][2] <= p2 + m0 - p0 - q0;
              block8_po_reg[i][3] <= m1 - p1 - q1;
              block8_po_reg[i][4] <= q0 + m2 - p2 - q2;
              block8_po_reg[i][5] <= q1;
              block8_po_reg[i][6] <= q2;
            end
          end
        end

        ST_BLOCK8_S1: begin
          for (i = 0; i < MAX_EXEC_SUBBLOCK_LANES; i++) begin
            if (lane_active_reg[i] && (active_block_coeffs == 8)) begin
              block8_b_reg[i][0] <= block8_pe_reg[i][0] -
                                    fqmul(block8_pe_reg[i][4] - block8_po_reg[i][3], zeta_reg[i]);
              block8_b_reg[i][1] <= block8_pe_reg[i][1] - block8_po_reg[i][0] -
                                    fqmul(block8_pe_reg[i][5] - block8_po_reg[i][4], zeta_reg[i]);
              block8_b_reg[i][2] <= block8_pe_reg[i][2] - block8_po_reg[i][1] -
                                    fqmul(block8_pe_reg[i][6] - block8_po_reg[i][5], zeta_reg[i]);
              block8_b_reg[i][3] <= block8_pe_reg[i][3] - block8_po_reg[i][2] +
                                    fqmul(block8_po_reg[i][6], zeta_reg[i]);
            end
          end
        end

        ST_BLOCK8_S2: begin
          for (i = 0; i < MAX_EXEC_SUBBLOCK_LANES; i++) begin
            if (lane_active_reg[i] && (active_block_coeffs == 8)) begin
              logic signed [15:0] scaled_c1;
              block8_c0_reg[i] <= fqmul(block8_inv_data[i], block8_c0_stage2_comb[i]);
              scaled_c1 = fqmul(block8_inv_data[i], block8_c1_stage2_comb[i]);
              block8_c1_reg[i] <= fqmul(scaled_c1, -16'sd171);
            end
          end
        end

        ST_BLOCK8_S3: begin
          for (i = 0; i < MAX_EXEC_SUBBLOCK_LANES; i++) begin
            if (lane_active_reg[i] && (active_block_coeffs == 8)) begin
              logic signed [15:0] p0;
              logic signed [15:0] p1;
              logic signed [15:0] p2;
              logic signed [15:0] q0;
              logic signed [15:0] q1;
              logic signed [15:0] q2;

              p0 = fqmul(block8_c0_reg[i], block8_b_reg[i][0]);
              p2 = fqmul(block8_c1_reg[i], block8_b_reg[i][2]);
              p1 = fqmul(block8_c0_reg[i] + block8_c1_reg[i],
                         block8_b_reg[i][0] + block8_b_reg[i][2]) - p0 - p2;

              q0 = fqmul(block8_c0_reg[i], block8_b_reg[i][1]);
              q2 = fqmul(block8_c1_reg[i], block8_b_reg[i][3]);
              q1 = fqmul(block8_c0_reg[i] + block8_c1_reg[i],
                         block8_b_reg[i][1] + block8_b_reg[i][3]) - q0 - q2;

              block8_f_reg[i][0] <= p0 - fqmul(p2, zeta_reg[i]);
              block8_f_reg[i][1] <= fqmul(q2, zeta_reg[i]) - q0;
              block8_f_reg[i][2] <= p1;
              block8_f_reg[i][3] <= fqmul(q1, -16'sd171);
            end
          end
        end

        ST_BLOCK8_S4: begin
          for (i = 0; i < MAX_EXEC_SUBBLOCK_LANES; i++) begin
            if (lane_active_reg[i] && (active_block_coeffs == 8)) begin
              logic signed [15:0] p0;
              logic signed [15:0] p1;
              logic signed [15:0] p2;
              logic signed [15:0] q0;
              logic signed [15:0] q1;
              logic signed [15:0] q2;
              logic signed [15:0] m0;
              logic signed [15:0] m1;
              logic signed [15:0] m2;
              logic signed [15:0] sx0;
              logic signed [15:0] sx1;
              logic signed [15:0] sy0;
              logic signed [15:0] sy1;

              p0 = fqmul(block8_f_reg[i][0], a0_reg[i]);
              p2 = fqmul(block8_f_reg[i][1], a2_reg[i]);
              p1 = fqmul(block8_f_reg[i][0] + block8_f_reg[i][1],
                         a0_reg[i] + a2_reg[i]) - p0 - p2;
              q0 = fqmul(block8_f_reg[i][2], a4_reg[i]);
              q2 = fqmul(block8_f_reg[i][3], a6_reg[i]);
              q1 = fqmul(block8_f_reg[i][2] + block8_f_reg[i][3],
                         a4_reg[i] + a6_reg[i]) - q0 - q2;
              sx0 = block8_f_reg[i][0] + block8_f_reg[i][2];
              sx1 = block8_f_reg[i][1] + block8_f_reg[i][3];
              sy0 = a0_reg[i] + a4_reg[i];
              sy1 = a2_reg[i] + a6_reg[i];
              m0 = fqmul(sx0, sy0);
              m2 = fqmul(sx1, sy1);
              m1 = fqmul(sx0 + sx1, sy0 + sy1) - m0 - m2;

              block8_pe_reg[i][0] <= p0;
              block8_pe_reg[i][1] <= p1;
              block8_pe_reg[i][2] <= p2 + m0 - p0 - q0;
              block8_pe_reg[i][3] <= m1 - p1 - q1;
              block8_pe_reg[i][4] <= q0 + m2 - p2 - q2;
              block8_pe_reg[i][5] <= q1;
              block8_pe_reg[i][6] <= q2;

              p0 = fqmul(block8_f_reg[i][0], a1_reg[i]);
              p2 = fqmul(block8_f_reg[i][1], a3_reg[i]);
              p1 = fqmul(block8_f_reg[i][0] + block8_f_reg[i][1],
                         a1_reg[i] + a3_reg[i]) - p0 - p2;
              q0 = fqmul(block8_f_reg[i][2], a5_reg[i]);
              q2 = fqmul(block8_f_reg[i][3], a7_reg[i]);
              q1 = fqmul(block8_f_reg[i][2] + block8_f_reg[i][3],
                         a5_reg[i] + a7_reg[i]) - q0 - q2;
              sx0 = block8_f_reg[i][0] + block8_f_reg[i][2];
              sx1 = block8_f_reg[i][1] + block8_f_reg[i][3];
              sy0 = a1_reg[i] + a5_reg[i];
              sy1 = a3_reg[i] + a7_reg[i];
              m0 = fqmul(sx0, sy0);
              m2 = fqmul(sx1, sy1);
              m1 = fqmul(sx0 + sx1, sy0 + sy1) - m0 - m2;

              block8_po_reg[i][0] <= p0;
              block8_po_reg[i][1] <= p1;
              block8_po_reg[i][2] <= p2 + m0 - p0 - q0;
              block8_po_reg[i][3] <= m1 - p1 - q1;
              block8_po_reg[i][4] <= q0 + m2 - p2 - q2;
              block8_po_reg[i][5] <= q1;
              block8_po_reg[i][6] <= q2;
            end
          end
        end

        ST_BLOCK8_S5: begin
          for (i = 0; i < MAX_EXEC_SUBBLOCK_LANES; i++) begin
            if (lane_active_reg[i] && (active_block_coeffs == 8)) begin
              logic signed [15:0] r0;
              logic signed [15:0] r1;
              logic signed [15:0] r2;
              logic signed [15:0] r3;
              logic signed [15:0] r4;
              logic signed [15:0] r5;
              logic signed [15:0] r6;
              logic signed [15:0] r7;
              r0 = block8_pe_reg[i][0] - fqmul(block8_pe_reg[i][4], zeta_reg[i]);
              r1 = fqmul(block8_po_reg[i][4], zeta_reg[i]) - block8_po_reg[i][0];
              r2 = block8_pe_reg[i][1] - fqmul(block8_pe_reg[i][5], zeta_reg[i]);
              r3 = fqmul(block8_po_reg[i][5], zeta_reg[i]) - block8_po_reg[i][1];
              r4 = block8_pe_reg[i][2] - fqmul(block8_pe_reg[i][6], zeta_reg[i]);
              r5 = fqmul(block8_po_reg[i][6], zeta_reg[i]) - block8_po_reg[i][2];
              r6 = block8_pe_reg[i][3];
              r7 = fqmul(block8_po_reg[i][3], -16'sd171);
              lane8_block_res_flat[i*BLOCK8_BITS +: BLOCK8_BITS] <= {
                r7, r6, r5, r4, r3, r2, r1, r0
              };
            end
          end
        end

        ST_BLOCK16_S0: begin
          for (i = 0; i < BLOCK16_COMPUTE_LANES; i++) begin
            if (lane_active_reg[i] && (active_block_coeffs == 16)) begin
              block16_ae_reg[i] <= block16_stage0_ae_flat[i];
              block16_ao_reg[i] <= block16_stage0_ao_flat[i];
              block16_he_reg[i] <= block16_stage0_he_flat[i];
              block16_ho_reg[i] <= block16_stage0_ho_flat[i];
            end
          end
        end

        ST_BLOCK16_S1: begin
          for (i = 0; i < BLOCK16_COMPUTE_LANES; i++) begin
            if (lane_active_reg[i] && (active_block_coeffs == 16)) begin
              block16_mid_reg[i] <= block16_stage1_mid_flat[i];
            end
          end
        end

        ST_BLOCK16_S2: begin
          for (i = 0; i < BLOCK16_COMPUTE_LANES; i++) begin
            if (lane_active_reg[i] && (active_block_coeffs == 16)) begin
              block16_det_reg[i] <= block16_stage2_det_flat[i];
            end
          end
        end

        ST_BLOCK16_S3: begin
          for (i = 0; i < BLOCK16_COMPUTE_LANES; i++) begin
            if (lane_active_reg[i] && (active_block_coeffs == 16)) begin
              block16_g_reg[i] <= block16_stage3_g_flat[i];
            end
          end
        end

        ST_BLOCK16_S4: begin
          for (i = 0; i < BLOCK16_COMPUTE_LANES; i++) begin
            if (lane_active_reg[i] && (active_block_coeffs == 16)) begin
              lane16_block_res_flat[i] <= block16_stage4_res_flat[i];
            end
          end
        end

        ST_BLOCK16_STORE: begin
          if (lane_active_reg[0] && (active_block_coeffs == 16)) begin
            integer base;
            integer chunk_base;
            integer row_base;
            integer row_offset;
            logic signed [255:0] block_res16;
            chunk_base = block16_chunk_idx * BLOCK16_SCRATCH_CHUNK_COEFFS;
            base = (lane_subidx_reg[0] * active_block_coeffs) + chunk_base;
            row_base = base >> 4;
            row_offset = base & (PACK_ROW_COEFFS - 1);
            block_res16 = lane16_block_res_flat[0];
            poly_r_rows[row_base][(row_offset + 0)*COEFF_W +: COEFF_W] <= block16_get(block_res16, chunk_base + 0);
            poly_r_rows[row_base][(row_offset + 1)*COEFF_W +: COEFF_W] <= block16_get(block_res16, chunk_base + 1);
            poly_r_rows[row_base][(row_offset + 2)*COEFF_W +: COEFF_W] <= block16_get(block_res16, chunk_base + 2);
            poly_r_rows[row_base][(row_offset + 3)*COEFF_W +: COEFF_W] <= block16_get(block_res16, chunk_base + 3);
          end
          if (block16_chunk_idx == BLOCK16_SCRATCH_CHUNKS - 1) begin
            block16_chunk_idx <= '0;
          end else begin
            block16_chunk_idx <= block16_chunk_idx + 1'b1;
          end
        end

        ST_R_STAGE: begin
          for (i = 0; i < MAX_EXEC_SUBBLOCK_LANES; i++) begin
            if (lane_active_reg[i] && (active_block_coeffs == 4)) begin
              r0pre_reg[i] <= fqmul(
                fqmul(u_r0a_reg[i] - u_r0b_reg[i], zeta_reg[i]) -
                fqmul(u_r0c_reg[i], zeta2_reg[i]) -
                a0cube_reg[i],
                16'sd173
              );
              r1pre_reg[i] <= fqmul(
                fqmul(u_r1a_reg[i] - u_r1b_reg[i], zeta_reg[i]) +
                fqmul(u_r1c_reg[i], zeta2_reg[i]) +
                sq0a1_reg[i],
                16'sd173
              );
              r2pre_reg[i] <= fqmul(
                fqmul(u_r2a_reg[i] - u_r2b_reg[i], zeta_reg[i]) +
                sq0a2_reg[i] -
                sq1a0_reg[i],
                16'sd173
              );
              r3pre_reg[i] <= fqmul(
                fqmul(u_r3a_reg[i], zeta_reg[i]) +
                a1cube_reg[i] -
                fqmul(m02a1_reg[i], 16'sd342) +
                sq0a3_reg[i],
                16'sd173
              );
            end
          end
        end

        ST_DET_STAGE: begin
          lookup_idx <= '0;
          for (i = 0; i < MAX_EXEC_SUBBLOCK_LANES; i++) begin
            if (lane_active_reg[i] && (active_block_coeffs == 4)) begin
              logic signed [15:0] det_a;
              logic signed [15:0] det_b;
              logic signed [15:0] det_c;
              logic signed [15:0] det_d;
              logic signed [15:0] det_e;
              logic signed [15:0] det_f;
              logic signed [15:0] det_mid0;
              logic signed [15:0] det_mid1;
              logic signed [15:0] det_all;
              det_a = fqmul(u_detA_reg[i], a2_reg[i]);
              det_b = fqmul(fqmul(u_detB_reg[i], a3_reg[i]), 16'sd342);
              det_c = fqmul(fqmul(fqmul(u_detC_reg[i], a3_reg[i]), zeta2_reg[i]), zeta_reg[i]);
              det_d = fqmul(u_detD_reg[i], a0_reg[i]);
              det_e = fqmul(u_detE_reg[i], a0_reg[i]);
              det_f = fqmul(u_detF_reg[i], a1_reg[i]);
              det_mid0 = fqmul(det_a + det_b, zeta2_reg[i]);
              det_mid1 = fqmul(det_e + det_f, zeta_reg[i]);
              det_all = det_c - det_mid0 - det_d + det_mid1;
              det_norm_reg[i] <= norm_q(fqmul(det_all, 16'sd361));
            end
          end
        end

        ST_LOOKUP: begin
          if (lane_active_reg[lookup_idx] && (active_block_coeffs == 4)) begin
            lane_qinv[lookup_idx] <= shared_qinv_data;
          end
          if (!lookup_reaches_end(lookup_idx, active_lane_count)) begin
            lookup_idx <= lookup_idx + 1'b1;
          end else begin
            lookup_idx <= '0;
          end
        end

        ST_SCALE: begin
          if (active_block_coeffs != 16) begin
            for (i = 0; i < MAX_EXEC_SUBBLOCK_LANES; i++) begin
              if (lane_active_reg[i]) begin
                integer base;
                integer row_base;
                integer row_offset;
                base = lane_subidx_reg[i] * active_block_coeffs;
                row_base = base >> 4;
                row_offset = base & (PACK_ROW_COEFFS - 1);
                if (active_block_coeffs == 4) begin
                  poly_r_rows[row_base][(row_offset + 0)*COEFF_W +: COEFF_W] <= fqmul(fqmul(r0pre_reg[i], lane_qinv[i]), 16'sd19);
                  poly_r_rows[row_base][(row_offset + 1)*COEFF_W +: COEFF_W] <= fqmul(fqmul(r1pre_reg[i], lane_qinv[i]), 16'sd19);
                  poly_r_rows[row_base][(row_offset + 2)*COEFF_W +: COEFF_W] <= fqmul(fqmul(r2pre_reg[i], lane_qinv[i]), 16'sd19);
                  poly_r_rows[row_base][(row_offset + 3)*COEFF_W +: COEFF_W] <= fqmul(fqmul(r3pre_reg[i], lane_qinv[i]), 16'sd19);
                end else begin
                  logic signed [127:0] block_res;
                  block_res = lane8_block_res_flat[i*BLOCK8_BITS +: BLOCK8_BITS];
                  poly_r_rows[row_base][(row_offset + 0)*COEFF_W +: COEFF_W] <= block_get(block_res, 0);
                  poly_r_rows[row_base][(row_offset + 1)*COEFF_W +: COEFF_W] <= block_get(block_res, 1);
                  poly_r_rows[row_base][(row_offset + 2)*COEFF_W +: COEFF_W] <= block_get(block_res, 2);
                  poly_r_rows[row_base][(row_offset + 3)*COEFF_W +: COEFF_W] <= block_get(block_res, 3);
                  poly_r_rows[row_base][(row_offset + 4)*COEFF_W +: COEFF_W] <= block_get(block_res, 4);
                  poly_r_rows[row_base][(row_offset + 5)*COEFF_W +: COEFF_W] <= block_get(block_res, 5);
                  poly_r_rows[row_base][(row_offset + 6)*COEFF_W +: COEFF_W] <= block_get(block_res, 6);
                  poly_r_rows[row_base][(row_offset + 7)*COEFF_W +: COEFF_W] <= block_get(block_res, 7);
                end
              end
            end
          end

          if (batch_last) begin
            subblock_idx <= '0;
          end else begin
            subblock_idx <= subblock_idx + active_lane_count[6:0];
          end
        end

        ST_PACK: begin
          pack_row_idx <= '0;
        end

        ST_PACK_ROWS: begin
          integer pack_coeff_idx;
          row_out_valid <= 1'b1;
          row_out_idx <= pack_row_idx;
          for (pack_coeff_idx = 0; pack_coeff_idx < PACK_ROW_COEFFS; pack_coeff_idx++) begin
            vec_r_data[((pack_row_idx * PACK_ROW_COEFFS) + pack_coeff_idx)*COEFF_W +: COEFF_W] <=
              poly_r_rows[pack_row_idx][pack_coeff_idx*COEFF_W +: COEFF_W];
            row_out_data[pack_coeff_idx*COEFF_W +: COEFF_W] <=
              poly_r_rows[pack_row_idx][pack_coeff_idx*COEFF_W +: COEFF_W];
          end
          if (pack_row_idx == (PACK_ROW_COUNT - 1)) begin
            pack_row_idx <= '0;
          end else begin
            pack_row_idx <= pack_row_idx + 1'b1;
          end
        end

        ST_DONE: begin
          vec_mode_active <= 1'b0;
        end

        ST_ERROR: begin
          vec_mode_active <= 1'b0;
        end

        default: begin
        end
      endcase
    end
  end

  always_comb begin
    cfg_block_coeffs = profile_block_coeffs(profile_id_i);
    cfg_negate_twiddle = (cfg_block_coeffs > 8'd4);
    cfg_block_supported = (cfg_block_coeffs == 8'd4) ||
                          (cfg_block_coeffs == 8'd8) ||
                          (cfg_block_coeffs == 8'd16);
    cfg_total_subblocks = 8'd0;
    cfg_exec_subblock_lanes = 8'd1;
    if (cfg_block_supported) begin
      cfg_total_subblocks = profile_n(profile_id_i) / cfg_block_coeffs;
      if (cfg_block_coeffs == 8'd16) begin
        cfg_exec_subblock_lanes = BLOCK16_COMPUTE_LANES;
      end else begin
        cfg_exec_subblock_lanes = MAX_EXEC_SUBBLOCK_LANES;
      end
    end
    cfg_profile_supported = profile_valid(profile_id_i) &&
                            (profile_n(profile_id_i) <= NTT_N) &&
                            cfg_block_supported;
  end

  always_comb begin
    state_n = state;
    busy = 1'b1;

    unique case (state)
      ST_IDLE: begin
        busy = 1'b0;
        if (start) begin
          if (!cfg_profile_supported) state_n = ST_ERROR;
          else if (!vec_in_valid) state_n = ST_ERROR;
          else if (!SUPPORTS_BLOCK_INV) state_n = ST_ERROR;
          else state_n = ST_LOAD;
        end
      end

      ST_LOAD: state_n = ST_PRECOMP;
      ST_PRECOMP: begin
        if (active_block_coeffs == 4) state_n = ST_COFACTOR;
        else if (active_block_coeffs == 8) state_n = ST_TWIDDLE;
        else state_n = ST_BLOCK16_LOAD;
      end
      ST_BLOCK16_LOAD: begin
        if (block16_chunk_idx == BLOCK16_SCRATCH_CHUNKS - 1) state_n = ST_TWIDDLE;
      end
      ST_COFACTOR: state_n = ST_TWIDDLE;
      ST_TWIDDLE: begin
        if (lookup_reaches_end(lookup_idx, active_lane_count)) begin
          if (active_block_coeffs == 4) state_n = ST_R_STAGE;
          else if (active_block_coeffs == 8) state_n = ST_BLOCK8_S0;
          else state_n = ST_BLOCK16_S0;
        end
      end
      ST_BLOCK8_S0: state_n = ST_BLOCK8_S1;
      ST_BLOCK8_S1: state_n = ST_BLOCK8_S2;
      ST_BLOCK8_S2: state_n = ST_BLOCK8_S3;
      ST_BLOCK8_S3: state_n = ST_BLOCK8_S4;
      ST_BLOCK8_S4: state_n = ST_BLOCK8_S5;
      ST_BLOCK8_S5: state_n = ST_SCALE;
      ST_BLOCK16_S0: state_n = ST_BLOCK16_S1;
      ST_BLOCK16_S1: state_n = ST_BLOCK16_S2;
      ST_BLOCK16_S2: state_n = ST_BLOCK16_S3;
      ST_BLOCK16_S3: state_n = ST_BLOCK16_S4;
      ST_BLOCK16_S4: state_n = ST_BLOCK16_STORE;
      ST_BLOCK16_STORE: begin
        if (block16_chunk_idx == BLOCK16_SCRATCH_CHUNKS - 1) state_n = ST_SCALE;
      end
      ST_R_STAGE: state_n = ST_DET_STAGE;
      ST_DET_STAGE: state_n = ST_LOOKUP;
      ST_LOOKUP: begin
        if (lookup_reaches_end(lookup_idx, active_lane_count)) state_n = ST_SCALE;
      end

      ST_SCALE: begin
        if (batch_last) state_n = ST_PACK;
        else state_n = ST_PRECOMP;
      end

      ST_PACK: state_n = ST_PACK_ROWS;

      ST_PACK_ROWS: begin
        if (pack_row_idx == (PACK_ROW_COUNT - 1)) state_n = ST_DONE;
        else state_n = ST_PACK_ROWS;
      end

      ST_DONE: begin
        busy = 1'b0;
        state_n = ST_IDLE;
      end

      ST_ERROR: begin
        busy = 1'b0;
        state_n = ST_IDLE;
      end

      default: begin
        busy = 1'b0;
        state_n = ST_IDLE;
      end
    endcase
  end

endmodule
