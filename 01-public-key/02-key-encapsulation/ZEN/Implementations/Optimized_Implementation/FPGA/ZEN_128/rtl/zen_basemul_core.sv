module zen_basemul_core (
  input  logic                         clk,
  input  logic                         rst_n,
  input  logic                         start,
  input  logic [7:0]                   cmd,
  input  logic [31:0]                  cfg,
  input  logic [31:0]                  len,
  input  logic [2:0]                   buf_a_sel,
  input  logic [2:0]                   buf_b_sel,
  input  logic [2:0]                   buf_r_sel,
  input  logic                         vec_in_valid,
  input  zen_accel_pkg::zen_poly_vec_t vec_a_data,
  input  zen_accel_pkg::zen_poly_vec_t vec_b_data,
  output logic                         vec_out_valid,
  output zen_accel_pkg::zen_poly_vec_t vec_r_data,
  output logic                         row_out_valid,
  output zen_accel_pkg::zen_row_addr_t row_out_idx,
  output zen_accel_pkg::zen_stream_row_t row_out_data,
  output logic                         busy,
  output logic                         done,
  output logic                         error
);

  import zen_accel_pkg::*;
  import zen_ntt_const_pkg::*;
  localparam int NTT_N = ZEN_N;
  localparam int BLOCK_LANES = BASEMUL_LANES;

  localparam int BLOCK_COEFFS = NTT_N / 128;
  localparam int SUBBLOCKS = NTT_N / BLOCK_COEFFS;
  localparam int EXEC_SUBBLOCK_LANES = (BLOCK_COEFFS == 16) ? ((BLOCK_LANES > 1) ? (BLOCK_LANES / 2) : 1)
                                   : (BLOCK_COEFFS == 8)  ? BLOCK_LANES
                                                          : (BLOCK_LANES * 2);
  localparam int EXEC_LANE_IDX_W = (EXEC_SUBBLOCK_LANES > 1) ? $clog2(EXEC_SUBBLOCK_LANES) : 1;
  localparam int BLOCK16_COMPUTE_LANES = (EXEC_SUBBLOCK_LANES > 4) ? 4 : EXEC_SUBBLOCK_LANES;
  localparam int BLOCK16_PHASES = (EXEC_SUBBLOCK_LANES + BLOCK16_COMPUTE_LANES - 1) / BLOCK16_COMPUTE_LANES;
  localparam int BLOCK16_PHASE_W = (BLOCK16_PHASES > 1) ? $clog2(BLOCK16_PHASES) : 1;
  localparam int BLOCK16_REDUCE_GROUP_SIZE = 2;
  localparam int BLOCK16_REDUCE_GROUPS = 16 / BLOCK16_REDUCE_GROUP_SIZE;
  localparam int BLOCK16_REDUCE_GROUP_W = (BLOCK16_REDUCE_GROUPS > 1) ? $clog2(BLOCK16_REDUCE_GROUPS) : 1;
  localparam bit SUPPORTS_BLOCK_MUL = (BLOCK_COEFFS == 4) || (BLOCK_COEFFS == 8) || (BLOCK_COEFFS == 16);
  localparam bit COMPILE_BLOCK8 = (BLOCK_COEFFS >= 8);
  localparam bit COMPILE_BLOCK16 = (BLOCK_COEFFS >= 16);
  localparam int BLOCK4_BITS = 4 * COEFF_W;
  localparam int BLOCK8_BITS = 8 * COEFF_W;
  localparam int BLOCK16_BITS = 16 * COEFF_W;
  localparam int POLY15_BITS = 15 * COEFF_W;

  typedef enum logic [4:0] {
    ST_IDLE,
    ST_LOAD,
    ST_C_STAGE,
    ST_C_MUL,
    ST_MUL_PHASE0,
    ST_MUL_PHASE1,
    ST_MUL_PHASE2,
    ST_BLOCK16_REDUCE,
    ST_COMB_STAGE,
    ST_TWIDDLE,
    ST_BLOCK4_ZETA,
    ST_BLOCK4_POST,
    ST_ZETA_WRITE,
    ST_PACK,
    ST_PACK_ROWS,
    ST_DONE,
    ST_ERROR
  } state_t;

  state_t state, state_n;

  logic mq_mode;
  logic mq_mode_reg;
  logic start_mq_mode;
  logic active_block_supported;
  logic active_block4;
  logic active_block8;
  logic active_block16;
  int active_block_coeffs;
  logic [6:0] subblock_idx;
  logic signed [NTT_N*COEFF_W-1:0] vec_a_data_reg;
  logic signed [NTT_N*COEFF_W-1:0] vec_b_data_reg;
`ifdef VERILATOR
  logic [EXEC_SUBBLOCK_LANES-1:0][6:0] lane_subidx_reg;
  logic [EXEC_SUBBLOCK_LANES-1:0] lane_active_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] a0_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] a1_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] a2_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] a3_reg;

  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] c0_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] c1_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] c2_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] c3_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] p13_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] p23_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] p01_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] p02_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] p03_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] p12_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] zeta_reg;

  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] a4_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] a5_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] a6_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] a7_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] a8_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] a9_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] a10_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] a11_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] a12_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] a13_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] a14_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] a15_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] b0_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] b1_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] b2_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] b3_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] b4_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] b5_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] b6_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] b7_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] b8_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] b9_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] b10_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] b11_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] b12_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] b13_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] b14_reg;
  logic signed [EXEC_SUBBLOCK_LANES-1:0][15:0] b15_reg;
`else
  logic [6:0] lane_subidx_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic lane_active_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a0_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a1_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a2_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a3_reg [0:EXEC_SUBBLOCK_LANES-1];

  logic signed [15:0] c0_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] c1_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] c2_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] c3_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] p13_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] p23_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] p01_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] p02_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] p03_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] p12_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] zeta_reg [0:EXEC_SUBBLOCK_LANES-1];

  logic signed [15:0] a4_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a5_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a6_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a7_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a8_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a9_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a10_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a11_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a12_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a13_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a14_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] a15_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] b0_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] b1_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] b2_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] b3_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] b4_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] b5_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] b6_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] b7_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] b8_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] b9_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] b10_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] b11_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] b12_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] b13_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] b14_reg [0:EXEC_SUBBLOCK_LANES-1];
  logic signed [15:0] b15_reg [0:EXEC_SUBBLOCK_LANES-1];
`endif

  localparam int PACK_ROW_COEFFS = 16;
  localparam int PACK_ROW_BITS = PACK_ROW_COEFFS * COEFF_W;
  localparam int PACK_ROW_COUNT = NTT_N / PACK_ROW_COEFFS;
  localparam int PACK_ROW_W = (PACK_ROW_COUNT > 1) ? $clog2(PACK_ROW_COUNT) : 1;
  logic signed [PACK_ROW_BITS-1:0] poly_r_rows [0:PACK_ROW_COUNT-1];
  logic [PACK_ROW_W-1:0] pack_row_idx;
  logic signed [EXEC_SUBBLOCK_LANES*BLOCK4_BITS-1:0] lane4_block_res_flat;
  logic signed [EXEC_SUBBLOCK_LANES*BLOCK4_BITS-1:0] lane4_post_block_flat;
  logic signed [EXEC_SUBBLOCK_LANES*BLOCK4_BITS-1:0] lane4_block_stage_flat;
  logic signed [EXEC_SUBBLOCK_LANES*BLOCK4_BITS-1:0] lane4_post_stage_flat;
  logic signed [EXEC_SUBBLOCK_LANES*BLOCK8_BITS-1:0] lane8_block_res_flat;
  logic signed [EXEC_SUBBLOCK_LANES*BLOCK8_BITS-1:0] lane8_post_block_flat;
  logic signed [BLOCK16_COMPUTE_LANES*POLY15_BITS-1:0] lane16_phase_poly_cur_flat;
  logic signed [EXEC_SUBBLOCK_LANES*POLY15_BITS-1:0] lane16_poly_p0_flat;
  logic signed [EXEC_SUBBLOCK_LANES*POLY15_BITS-1:0] lane16_poly_p1_flat;
  logic signed [EXEC_SUBBLOCK_LANES*POLY15_BITS-1:0] lane16_poly_pm_flat;
  logic signed [EXEC_SUBBLOCK_LANES*(2*COEFF_W)-1:0] lane16_reduce_pair_flat;
  logic [EXEC_LANE_IDX_W-1:0] twiddle_lookup_idx;
  logic [BLOCK16_REDUCE_GROUP_W-1:0] block16_reduce_group_idx;
  logic signed [15:0] shared_twiddle;
  logic [1:0] mul_phase_sel;
  logic [BLOCK16_PHASE_W-1:0] block16_phase_sel;
  logic [7:0] block16_phase_base;
  logic [7:0] block16_phase_remain;
  logic [7:0] block16_phase_lane_count;
  logic [7:0] block16_reduce_coeff_base;
  logic block16_phase_last;
  logic block16_reduce_last_group;

  logic vec_mode_active;
  logic [7:0] active_lane_count;
  logic batch_last;
  genvar g;
  integer i;

  function automatic logic signed [COEFF_W-1:0] flat_get(
    input logic signed [NTT_N*COEFF_W-1:0] flat,
    input integer idx
  );
    begin
      flat_get = flat[idx*COEFF_W +: COEFF_W];
    end
  endfunction

  function automatic logic [7:0] calc_lane_count(input logic [6:0] idx);
    logic [7:0] remain;
    begin
      remain = SUBBLOCKS - idx;
      if (remain > EXEC_SUBBLOCK_LANES) calc_lane_count = EXEC_SUBBLOCK_LANES;
      else calc_lane_count = remain;
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

  function automatic logic signed [15:0] block4_get(
    input logic signed [63:0] block,
    input int idx
  );
    begin
      block4_get = block[idx*16 +: 16];
    end
  endfunction

  assign start_mq_mode = (cmd == CMD_BASEMUL_MQ);
  assign mq_mode = mq_mode_reg;

  always_comb begin
    active_block4 = 1'b1;
    active_block8 = 1'b0;
    active_block16 = 1'b0;
    active_block_coeffs = 4;
    active_block_supported = 1'b1;
    active_lane_count = calc_lane_count(subblock_idx);
    batch_last = (subblock_idx + active_lane_count >= SUBBLOCKS);
    block16_phase_base = block16_phase_sel * BLOCK16_COMPUTE_LANES;
    block16_phase_remain = '0;
    block16_phase_lane_count = '0;
    block16_phase_last = 1'b1;
    if (active_lane_count > block16_phase_base) begin
      block16_phase_remain = active_lane_count - block16_phase_base;
      if (block16_phase_remain > BLOCK16_COMPUTE_LANES) block16_phase_lane_count = BLOCK16_COMPUTE_LANES;
      else block16_phase_lane_count = block16_phase_remain;
      block16_phase_last = ((block16_phase_base + block16_phase_lane_count) >= active_lane_count);
    end
    block16_reduce_coeff_base = block16_reduce_group_idx * BLOCK16_REDUCE_GROUP_SIZE;
    block16_reduce_last_group = (block16_reduce_group_idx == (BLOCK16_REDUCE_GROUPS - 1));
  end

  zen_basemul_twiddle_rom u_twiddle_rom (
    .block_idx  (lane_subidx_reg[twiddle_lookup_idx][6:1]),
    .upper_half (lane_subidx_reg[twiddle_lookup_idx][0]),
    .twiddle    (shared_twiddle)
  );

  generate
    for (g = 0; g < EXEC_SUBBLOCK_LANES; g++) begin : gen_basemul_lane_blocks
      logic signed [BLOCK8_BITS-1:0] lane8_a_vec;
      logic signed [BLOCK8_BITS-1:0] lane8_b_vec;

      assign lane8_a_vec = {a7_reg[g], a6_reg[g], a5_reg[g], a4_reg[g], c3_reg[g], c2_reg[g], c1_reg[g], c0_reg[g]};
      assign lane8_b_vec = {b7_reg[g], b6_reg[g], b5_reg[g], b4_reg[g], b3_reg[g], b2_reg[g], b1_reg[g], b0_reg[g]};

      zen_basemul4_zeta_block #(
        .COEFF_W(COEFF_W)
      ) u_lane4_block (
        .c0_i(c0_reg[g]),
        .c1_i(c1_reg[g]),
        .c2_i(c2_reg[g]),
        .c3_i(c3_reg[g]),
        .p13_i(p13_reg[g]),
        .p23_i(p23_reg[g]),
        .p01_i(p01_reg[g]),
        .p02_i(p02_reg[g]),
        .p03_i(p03_reg[g]),
        .p12_i(p12_reg[g]),
        .zeta_i(zeta_reg[g]),
        .block_o(lane4_block_res_flat[g*BLOCK4_BITS +: BLOCK4_BITS])
      );

      zen_basemul4_post_block #(
        .COEFF_W(COEFF_W)
      ) u_lane4_post_block (
        .block_i(lane4_block_stage_flat[g*BLOCK4_BITS +: BLOCK4_BITS]),
        .mq_mode_i(mq_mode),
        .block_o(lane4_post_block_flat[g*BLOCK4_BITS +: BLOCK4_BITS])
      );

      if (COMPILE_BLOCK8) begin : gen_lane8_block
        zen_basemul8_block_exact #(
          .COEFF_W(COEFF_W)
        ) u_lane8_block (
          .a_vec_i(lane8_a_vec),
          .b_vec_i(lane8_b_vec),
          .zeta_i(zeta_reg[g]),
          .block_o(lane8_block_res_flat[g*BLOCK8_BITS +: BLOCK8_BITS])
        );

        zen_basemul8_post_block #(
          .COEFF_W(COEFF_W)
        ) u_lane8_post_block (
          .block_i(lane8_block_res_flat[g*BLOCK8_BITS +: BLOCK8_BITS]),
          .mq_mode_i(mq_mode),
          .block_o(lane8_post_block_flat[g*BLOCK8_BITS +: BLOCK8_BITS])
        );
      end else begin : gen_lane8_block_stub
        assign lane8_block_res_flat[g*BLOCK8_BITS +: BLOCK8_BITS] = '0;
        assign lane8_post_block_flat[g*BLOCK8_BITS +: BLOCK8_BITS] = '0;
      end

      if (COMPILE_BLOCK16) begin : gen_lane16_reduce2
        zen_basemul16_reduce2_exact #(
          .COEFF_W(COEFF_W)
        ) u_lane16_reduce2 (
          .p0_pack_i(lane16_poly_p0_flat[g*POLY15_BITS +: POLY15_BITS]),
          .p1_pack_i(lane16_poly_p1_flat[g*POLY15_BITS +: POLY15_BITS]),
          .pm_pack_i(lane16_poly_pm_flat[g*POLY15_BITS +: POLY15_BITS]),
          .zeta_i(zeta_reg[g]),
          .group_idx_i(block16_reduce_group_idx),
          .mq_mode_i(mq_mode),
          .coeff_pair_o(lane16_reduce_pair_flat[g*(2*COEFF_W) +: 2*COEFF_W])
        );
      end else begin : gen_lane16_reduce2_stub
        assign lane16_reduce_pair_flat[g*(2*COEFF_W) +: 2*COEFF_W] = '0;
      end

    end

    for (g = 0; g < BLOCK16_COMPUTE_LANES; g++) begin : gen_basemul16_phase_blocks
      logic signed [BLOCK8_BITS-1:0] lane16_mul_a_vec;
      logic signed [BLOCK8_BITS-1:0] lane16_mul_b_vec;
      logic signed [POLY15_BITS-1:0] lane16_poly_cur;
      integer lane16_src_idx;

      always_comb begin
        lane16_src_idx = block16_phase_base + g;
        lane16_mul_a_vec = '0;
        lane16_mul_b_vec = '0;
        if ((lane16_src_idx < EXEC_SUBBLOCK_LANES) && lane_active_reg[lane16_src_idx]) begin
          unique case (mul_phase_sel)
            2'd0: begin
              lane16_mul_a_vec = {
                a7_reg[lane16_src_idx], a6_reg[lane16_src_idx], a5_reg[lane16_src_idx], a4_reg[lane16_src_idx],
                c3_reg[lane16_src_idx], c2_reg[lane16_src_idx], c1_reg[lane16_src_idx], c0_reg[lane16_src_idx]
              };
              lane16_mul_b_vec = {
                b7_reg[lane16_src_idx], b6_reg[lane16_src_idx], b5_reg[lane16_src_idx], b4_reg[lane16_src_idx],
                b3_reg[lane16_src_idx], b2_reg[lane16_src_idx], b1_reg[lane16_src_idx], b0_reg[lane16_src_idx]
              };
            end

            2'd1: begin
              lane16_mul_a_vec = {
                a15_reg[lane16_src_idx], a14_reg[lane16_src_idx], a13_reg[lane16_src_idx], a12_reg[lane16_src_idx],
                a11_reg[lane16_src_idx], a10_reg[lane16_src_idx], a9_reg[lane16_src_idx], a8_reg[lane16_src_idx]
              };
              lane16_mul_b_vec = {
                b15_reg[lane16_src_idx], b14_reg[lane16_src_idx], b13_reg[lane16_src_idx], b12_reg[lane16_src_idx],
                b11_reg[lane16_src_idx], b10_reg[lane16_src_idx], b9_reg[lane16_src_idx], b8_reg[lane16_src_idx]
              };
            end

            default: begin
              lane16_mul_a_vec = {
                a15_reg[lane16_src_idx] + a7_reg[lane16_src_idx],
                a14_reg[lane16_src_idx] + a6_reg[lane16_src_idx],
                a13_reg[lane16_src_idx] + a5_reg[lane16_src_idx],
                a12_reg[lane16_src_idx] + a4_reg[lane16_src_idx],
                a11_reg[lane16_src_idx] + c3_reg[lane16_src_idx],
                a10_reg[lane16_src_idx] + c2_reg[lane16_src_idx],
                a9_reg[lane16_src_idx] + c1_reg[lane16_src_idx],
                a8_reg[lane16_src_idx] + c0_reg[lane16_src_idx]
              };
              lane16_mul_b_vec = {
                b15_reg[lane16_src_idx] + b7_reg[lane16_src_idx],
                b14_reg[lane16_src_idx] + b6_reg[lane16_src_idx],
                b13_reg[lane16_src_idx] + b5_reg[lane16_src_idx],
                b12_reg[lane16_src_idx] + b4_reg[lane16_src_idx],
                b11_reg[lane16_src_idx] + b3_reg[lane16_src_idx],
                b10_reg[lane16_src_idx] + b2_reg[lane16_src_idx],
                b9_reg[lane16_src_idx] + b1_reg[lane16_src_idx],
                b8_reg[lane16_src_idx] + b0_reg[lane16_src_idx]
              };
            end
          endcase
        end
      end

      if (COMPILE_BLOCK16) begin : gen_lane16_poly
        zen_karatsuba_mul8_block_exact #(
          .COEFF_W(COEFF_W)
        ) u_lane16_block (
          .a_vec_i(lane16_mul_a_vec),
          .b_vec_i(lane16_mul_b_vec),
          .poly_vec_o(lane16_poly_cur)
        );

        assign lane16_phase_poly_cur_flat[g*POLY15_BITS +: POLY15_BITS] = lane16_poly_cur;
      end else begin : gen_lane16_poly_stub
        assign lane16_phase_poly_cur_flat[g*POLY15_BITS +: POLY15_BITS] = '0;
      end
    end
  endgenerate

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= ST_IDLE;
      subblock_idx <= '0;
      twiddle_lookup_idx <= '0;
      block16_reduce_group_idx <= '0;
      mul_phase_sel <= '0;
      block16_phase_sel <= '0;
      vec_mode_active <= 1'b0;
      mq_mode_reg <= 1'b0;
      vec_out_valid <= 1'b0;
      vec_a_data_reg <= '0;
      vec_b_data_reg <= '0;
      lane16_poly_p0_flat <= '0;
      lane16_poly_p1_flat <= '0;
      lane16_poly_pm_flat <= '0;
      vec_r_data <= '0;
      row_out_valid <= 1'b0;
      row_out_idx <= '0;
      row_out_data <= '0;
      pack_row_idx <= '0;
      for (i = 0; i < EXEC_SUBBLOCK_LANES; i++) begin
        lane_subidx_reg[i] <= '0;
        lane_active_reg[i] <= 1'b0;
        c0_reg[i] <= '0;
        c1_reg[i] <= '0;
        c2_reg[i] <= '0;
        c3_reg[i] <= '0;
        p13_reg[i] <= '0;
        p23_reg[i] <= '0;
        p01_reg[i] <= '0;
        p02_reg[i] <= '0;
        p03_reg[i] <= '0;
        p12_reg[i] <= '0;
        zeta_reg[i] <= '0;
        a4_reg[i] <= '0;
        a5_reg[i] <= '0;
        a6_reg[i] <= '0;
        a7_reg[i] <= '0;
        a8_reg[i] <= '0;
        a9_reg[i] <= '0;
        a10_reg[i] <= '0;
        a11_reg[i] <= '0;
        a12_reg[i] <= '0;
        a13_reg[i] <= '0;
        a14_reg[i] <= '0;
        a15_reg[i] <= '0;
        b0_reg[i] <= '0;
        b1_reg[i] <= '0;
        b2_reg[i] <= '0;
        b3_reg[i] <= '0;
        b4_reg[i] <= '0;
        b5_reg[i] <= '0;
        b6_reg[i] <= '0;
        b7_reg[i] <= '0;
        b8_reg[i] <= '0;
        b9_reg[i] <= '0;
        b10_reg[i] <= '0;
        b11_reg[i] <= '0;
        b12_reg[i] <= '0;
        b13_reg[i] <= '0;
        b14_reg[i] <= '0;
        b15_reg[i] <= '0;
      end
    end else begin
      state <= state_n;
      vec_out_valid <= (state_n == ST_DONE) && vec_mode_active;
      row_out_valid <= 1'b0;

      case (state)
        ST_IDLE: begin
          if (start) begin
            mq_mode_reg <= start_mq_mode;
            subblock_idx <= '0;
            twiddle_lookup_idx <= '0;
            block16_reduce_group_idx <= '0;
            mul_phase_sel <= '0;
            block16_phase_sel <= '0;
            vec_mode_active <= vec_in_valid;
            vec_a_data_reg <= vec_a_data;
            vec_b_data_reg <= vec_b_data;
            pack_row_idx <= '0;
          end
        end

        ST_C_STAGE: begin
          mul_phase_sel <= '0;
          block16_phase_sel <= '0;
          for (i = 0; i < EXEC_SUBBLOCK_LANES; i++) begin
            lane_active_reg[i] <= (i < active_lane_count);
            if (i < active_lane_count) begin
              lane_subidx_reg[i] <= subblock_idx + i[6:0];
              if (active_block4) begin
                integer base4;
                logic signed [15:0] a0, a1, a2, a3;
                logic signed [15:0] b0, b1, b2, b3;
                base4 = (subblock_idx + i[6:0]) * 4;
                a0 = flat_get(vec_a_data_reg, base4 + 0);
                a1 = flat_get(vec_a_data_reg, base4 + 1);
                a2 = flat_get(vec_a_data_reg, base4 + 2);
                a3 = flat_get(vec_a_data_reg, base4 + 3);
                b0 = flat_get(vec_b_data_reg, base4 + 0);
                b1 = flat_get(vec_b_data_reg, base4 + 1);
                b2 = flat_get(vec_b_data_reg, base4 + 2);
                b3 = flat_get(vec_b_data_reg, base4 + 3);
                a0_reg[i] <= a0;
                a1_reg[i] <= a1;
                a2_reg[i] <= a2;
                a3_reg[i] <= a3;
                b0_reg[i] <= b0;
                b1_reg[i] <= b1;
                b2_reg[i] <= b2;
                b3_reg[i] <= b3;
              end else if (active_block8) begin
                integer base8;
                logic signed [15:0] a0, a1, a2, a3;
                logic signed [15:0] b0, b1, b2, b3;
                base8 = (subblock_idx + i[6:0]) * 8;
                a0 = flat_get(vec_a_data_reg, base8 + 0);
                a1 = flat_get(vec_a_data_reg, base8 + 1);
                a2 = flat_get(vec_a_data_reg, base8 + 2);
                a3 = flat_get(vec_a_data_reg, base8 + 3);
                b0 = flat_get(vec_b_data_reg, base8 + 0);
                b1 = flat_get(vec_b_data_reg, base8 + 1);
                b2 = flat_get(vec_b_data_reg, base8 + 2);
                b3 = flat_get(vec_b_data_reg, base8 + 3);
                a4_reg[i] <= flat_get(vec_a_data_reg, base8 + 4);
                a5_reg[i] <= flat_get(vec_a_data_reg, base8 + 5);
                a6_reg[i] <= flat_get(vec_a_data_reg, base8 + 6);
                a7_reg[i] <= flat_get(vec_a_data_reg, base8 + 7);
                b0_reg[i] <= b0;
                b1_reg[i] <= b1;
                b2_reg[i] <= b2;
                b3_reg[i] <= b3;
                b4_reg[i] <= flat_get(vec_b_data_reg, base8 + 4);
                b5_reg[i] <= flat_get(vec_b_data_reg, base8 + 5);
                b6_reg[i] <= flat_get(vec_b_data_reg, base8 + 6);
                b7_reg[i] <= flat_get(vec_b_data_reg, base8 + 7);
                c0_reg[i] <= a0;
                c1_reg[i] <= a1;
                c2_reg[i] <= a2;
                c3_reg[i] <= a3;
              end else if (active_block16) begin
                integer base16;
                logic signed [15:0] a0, a1, a2, a3;
                logic signed [15:0] b0, b1, b2, b3;
                base16 = (subblock_idx + i[6:0]) * 16;
                a0 = flat_get(vec_a_data_reg, base16 + 0);
                a1 = flat_get(vec_a_data_reg, base16 + 1);
                a2 = flat_get(vec_a_data_reg, base16 + 2);
                a3 = flat_get(vec_a_data_reg, base16 + 3);
                b0 = flat_get(vec_b_data_reg, base16 + 0);
                b1 = flat_get(vec_b_data_reg, base16 + 1);
                b2 = flat_get(vec_b_data_reg, base16 + 2);
                b3 = flat_get(vec_b_data_reg, base16 + 3);
                a4_reg[i] <= flat_get(vec_a_data_reg, base16 + 4);
                a5_reg[i] <= flat_get(vec_a_data_reg, base16 + 5);
                a6_reg[i] <= flat_get(vec_a_data_reg, base16 + 6);
                a7_reg[i] <= flat_get(vec_a_data_reg, base16 + 7);
                b0_reg[i] <= b0;
                b1_reg[i] <= b1;
                b2_reg[i] <= b2;
                b3_reg[i] <= b3;
                b4_reg[i] <= flat_get(vec_b_data_reg, base16 + 4);
                b5_reg[i] <= flat_get(vec_b_data_reg, base16 + 5);
                b6_reg[i] <= flat_get(vec_b_data_reg, base16 + 6);
                b7_reg[i] <= flat_get(vec_b_data_reg, base16 + 7);
                a8_reg[i] <= flat_get(vec_a_data_reg, base16 + 8);
                a9_reg[i] <= flat_get(vec_a_data_reg, base16 + 9);
                a10_reg[i] <= flat_get(vec_a_data_reg, base16 + 10);
                a11_reg[i] <= flat_get(vec_a_data_reg, base16 + 11);
                a12_reg[i] <= flat_get(vec_a_data_reg, base16 + 12);
                a13_reg[i] <= flat_get(vec_a_data_reg, base16 + 13);
                a14_reg[i] <= flat_get(vec_a_data_reg, base16 + 14);
                a15_reg[i] <= flat_get(vec_a_data_reg, base16 + 15);
                b8_reg[i] <= flat_get(vec_b_data_reg, base16 + 8);
                b9_reg[i] <= flat_get(vec_b_data_reg, base16 + 9);
                b10_reg[i] <= flat_get(vec_b_data_reg, base16 + 10);
                b11_reg[i] <= flat_get(vec_b_data_reg, base16 + 11);
                b12_reg[i] <= flat_get(vec_b_data_reg, base16 + 12);
                b13_reg[i] <= flat_get(vec_b_data_reg, base16 + 13);
                b14_reg[i] <= flat_get(vec_b_data_reg, base16 + 14);
                b15_reg[i] <= flat_get(vec_b_data_reg, base16 + 15);
                c0_reg[i] <= a0;
                c1_reg[i] <= a1;
                c2_reg[i] <= a2;
                c3_reg[i] <= a3;
              end
            end
          end
        end

        ST_C_MUL: begin
          for (i = 0; i < EXEC_SUBBLOCK_LANES; i++) begin
            if (lane_active_reg[i] && active_block4) begin
              c0_reg[i] <= fqmul(a0_reg[i], b0_reg[i]);
              c1_reg[i] <= fqmul(a1_reg[i], b1_reg[i]);
              c2_reg[i] <= fqmul(a2_reg[i], b2_reg[i]);
              c3_reg[i] <= fqmul(a3_reg[i], b3_reg[i]);
              p13_reg[i] <= fqmul(a1_reg[i] + a3_reg[i], b1_reg[i] + b3_reg[i]);
              p23_reg[i] <= fqmul(a2_reg[i] + a3_reg[i], b2_reg[i] + b3_reg[i]);
              p01_reg[i] <= fqmul(a0_reg[i] + a1_reg[i], b0_reg[i] + b1_reg[i]);
              p02_reg[i] <= fqmul(a0_reg[i] + a2_reg[i], b0_reg[i] + b2_reg[i]);
              p03_reg[i] <= fqmul(a0_reg[i] + a3_reg[i], b0_reg[i] + b3_reg[i]);
              p12_reg[i] <= fqmul(a1_reg[i] + a2_reg[i], b1_reg[i] + b2_reg[i]);
            end
          end
        end

        ST_MUL_PHASE0: begin
          mul_phase_sel <= 2'd1;
          for (i = 0; i < BLOCK16_COMPUTE_LANES; i++) begin
            integer src_idx;
            src_idx = block16_phase_base + i;
            if ((src_idx < EXEC_SUBBLOCK_LANES) && lane_active_reg[src_idx] && active_block16) begin
              lane16_poly_p0_flat[src_idx*POLY15_BITS +: POLY15_BITS] <=
                lane16_phase_poly_cur_flat[i*POLY15_BITS +: POLY15_BITS];
            end
          end
        end

        ST_MUL_PHASE1: begin
          mul_phase_sel <= 2'd2;
          for (i = 0; i < BLOCK16_COMPUTE_LANES; i++) begin
            integer src_idx;
            src_idx = block16_phase_base + i;
            if ((src_idx < EXEC_SUBBLOCK_LANES) && lane_active_reg[src_idx] && active_block16) begin
              lane16_poly_p1_flat[src_idx*POLY15_BITS +: POLY15_BITS] <=
                lane16_phase_poly_cur_flat[i*POLY15_BITS +: POLY15_BITS];
            end
          end
        end

        ST_MUL_PHASE2: begin
          mul_phase_sel <= '0;
          if (active_block16 && !block16_phase_last) begin
            block16_phase_sel <= block16_phase_sel + 1'b1;
          end
          for (i = 0; i < BLOCK16_COMPUTE_LANES; i++) begin
            integer src_idx;
            src_idx = block16_phase_base + i;
            if ((src_idx < EXEC_SUBBLOCK_LANES) && lane_active_reg[src_idx] && active_block16) begin
              lane16_poly_pm_flat[src_idx*POLY15_BITS +: POLY15_BITS] <=
                lane16_phase_poly_cur_flat[i*POLY15_BITS +: POLY15_BITS];
            end
          end
        end

        ST_COMB_STAGE: begin
          twiddle_lookup_idx <= '0;
        end

        ST_TWIDDLE: begin
          if (lane_active_reg[twiddle_lookup_idx]) begin
            zeta_reg[twiddle_lookup_idx] <= shared_twiddle;
          end
          if (({{8-$clog2(EXEC_SUBBLOCK_LANES){1'b0}}, twiddle_lookup_idx} + 8'd1) < active_lane_count) begin
            twiddle_lookup_idx <= twiddle_lookup_idx + 1'b1;
          end else begin
            twiddle_lookup_idx <= '0;
          end
        end

        ST_BLOCK4_ZETA: begin
          for (i = 0; i < EXEC_SUBBLOCK_LANES; i++) begin
            if (lane_active_reg[i] && active_block4) begin
              lane4_block_stage_flat[i*BLOCK4_BITS +: BLOCK4_BITS] <=
                lane4_block_res_flat[i*BLOCK4_BITS +: BLOCK4_BITS];
            end
          end
        end

        ST_BLOCK4_POST: begin
          for (i = 0; i < EXEC_SUBBLOCK_LANES; i++) begin
            if (lane_active_reg[i] && active_block4) begin
              lane4_post_stage_flat[i*BLOCK4_BITS +: BLOCK4_BITS] <=
                lane4_post_block_flat[i*BLOCK4_BITS +: BLOCK4_BITS];
            end
          end
        end

        ST_ZETA_WRITE: begin
          if (active_block16) begin
            block16_reduce_group_idx <= '0;
          end
          for (i = 0; i < EXEC_SUBBLOCK_LANES; i++) begin
            if (lane_active_reg[i]) begin
              if (active_block4) begin
                integer base4;
                integer row_base4;
                integer row_offset4;
                logic signed [BLOCK4_BITS-1:0] block_res4;
                base4 = lane_subidx_reg[i] * 4;
                row_base4 = base4 >> 4;
                row_offset4 = base4 & (PACK_ROW_COEFFS - 1);
                block_res4 = lane4_post_stage_flat[i*BLOCK4_BITS +: BLOCK4_BITS];
                poly_r_rows[row_base4][(row_offset4 + 0)*COEFF_W +: COEFF_W] <= block4_get(block_res4, 0);
                poly_r_rows[row_base4][(row_offset4 + 1)*COEFF_W +: COEFF_W] <= block4_get(block_res4, 1);
                poly_r_rows[row_base4][(row_offset4 + 2)*COEFF_W +: COEFF_W] <= block4_get(block_res4, 2);
                poly_r_rows[row_base4][(row_offset4 + 3)*COEFF_W +: COEFF_W] <= block4_get(block_res4, 3);
              end else if (active_block8) begin
                integer base8;
                integer row_base8;
                integer row_offset8;
                logic signed [127:0] block_res;
                base8 = lane_subidx_reg[i] * 8;
                row_base8 = base8 >> 4;
                row_offset8 = base8 & (PACK_ROW_COEFFS - 1);
                block_res = lane8_post_block_flat[i*BLOCK8_BITS +: BLOCK8_BITS];
                poly_r_rows[row_base8][(row_offset8 + 0)*COEFF_W +: COEFF_W] <= block_get(block_res, 0);
                poly_r_rows[row_base8][(row_offset8 + 1)*COEFF_W +: COEFF_W] <= block_get(block_res, 1);
                poly_r_rows[row_base8][(row_offset8 + 2)*COEFF_W +: COEFF_W] <= block_get(block_res, 2);
                poly_r_rows[row_base8][(row_offset8 + 3)*COEFF_W +: COEFF_W] <= block_get(block_res, 3);
                poly_r_rows[row_base8][(row_offset8 + 4)*COEFF_W +: COEFF_W] <= block_get(block_res, 4);
                poly_r_rows[row_base8][(row_offset8 + 5)*COEFF_W +: COEFF_W] <= block_get(block_res, 5);
                poly_r_rows[row_base8][(row_offset8 + 6)*COEFF_W +: COEFF_W] <= block_get(block_res, 6);
                poly_r_rows[row_base8][(row_offset8 + 7)*COEFF_W +: COEFF_W] <= block_get(block_res, 7);
              end
            end
          end

          if (!active_block16) begin
            if (batch_last) begin
              subblock_idx <= '0;
            end else begin
              subblock_idx <= subblock_idx + active_lane_count[6:0];
            end
          end
        end

        ST_BLOCK16_REDUCE: begin
          for (i = 0; i < EXEC_SUBBLOCK_LANES; i++) begin
            if (lane_active_reg[i] && active_block16) begin
              integer base16;
              integer row_base16;
              integer row_offset16;
              logic signed [2*COEFF_W-1:0] coeff_pair;
              logic signed [COEFF_W-1:0] coeff0;
              logic signed [COEFF_W-1:0] coeff1;
              base16 = lane_subidx_reg[i] * 16;
              row_base16 = (base16 + block16_reduce_coeff_base) >> 4;
              row_offset16 = (base16 + block16_reduce_coeff_base) & (PACK_ROW_COEFFS - 1);
              coeff_pair = lane16_reduce_pair_flat[i*(2*COEFF_W) +: 2*COEFF_W];
              coeff0 = coeff_pair[0 +: COEFF_W];
              coeff1 = coeff_pair[COEFF_W +: COEFF_W];
              poly_r_rows[row_base16][(row_offset16 + 0)*COEFF_W +: COEFF_W] <= coeff0;
              poly_r_rows[row_base16][(row_offset16 + 1)*COEFF_W +: COEFF_W] <= coeff1;
            end
          end

          if (block16_reduce_last_group) begin
            block16_reduce_group_idx <= '0;
            if (batch_last) begin
              subblock_idx <= '0;
            end else begin
              subblock_idx <= subblock_idx + active_lane_count[6:0];
            end
          end else begin
            block16_reduce_group_idx <= block16_reduce_group_idx + 1'b1;
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
    state_n = state;
    busy = 1'b1;
    done = 1'b0;
    error = 1'b0;

    unique case (state)
      ST_IDLE: begin
        busy = 1'b0;
        if (start) begin
          if (!vec_in_valid) state_n = ST_ERROR;
          else if (!SUPPORTS_BLOCK_MUL) state_n = ST_ERROR;
          else if (!active_block_supported) state_n = ST_ERROR;
          else if ((cmd == CMD_BASEMUL) || (cmd == CMD_BASEMUL_MQ)) state_n = ST_LOAD;
          else state_n = ST_ERROR;
        end
      end

      ST_LOAD: state_n = ST_C_STAGE;
      ST_C_STAGE: begin
        if (active_block4) state_n = ST_C_MUL;
        else if (active_block16) state_n = ST_MUL_PHASE0;
        else state_n = ST_COMB_STAGE;
      end
      ST_C_MUL: state_n = ST_COMB_STAGE;
      ST_MUL_PHASE0: state_n = ST_MUL_PHASE1;
      ST_MUL_PHASE1: state_n = ST_MUL_PHASE2;
      ST_MUL_PHASE2: begin
        if (active_block16 && !block16_phase_last) state_n = ST_MUL_PHASE0;
        else state_n = ST_COMB_STAGE;
      end
      ST_COMB_STAGE: state_n = ST_TWIDDLE;
      ST_TWIDDLE: begin
        if (({{8-$clog2(EXEC_SUBBLOCK_LANES){1'b0}}, twiddle_lookup_idx} + 8'd1) >= active_lane_count) begin
          if (active_block4) state_n = ST_BLOCK4_ZETA;
          else state_n = ST_ZETA_WRITE;
        end
      end
      ST_BLOCK4_ZETA: state_n = ST_BLOCK4_POST;
      ST_BLOCK4_POST: state_n = ST_ZETA_WRITE;

      ST_ZETA_WRITE: begin
        if (active_block16) state_n = ST_BLOCK16_REDUCE;
        else if (batch_last) state_n = ST_PACK;
        else state_n = ST_C_STAGE;
      end

      ST_BLOCK16_REDUCE: begin
        if (block16_reduce_last_group) begin
          if (batch_last) state_n = ST_PACK;
          else state_n = ST_C_STAGE;
        end else begin
          state_n = ST_BLOCK16_REDUCE;
        end
      end

      ST_PACK: state_n = ST_PACK_ROWS;

      ST_PACK_ROWS: begin
        if (pack_row_idx == (PACK_ROW_COUNT - 1)) state_n = ST_DONE;
        else state_n = ST_PACK_ROWS;
      end

      ST_DONE: begin
        busy = 1'b0;
        done = 1'b1;
        state_n = ST_IDLE;
      end

      ST_ERROR: begin
        busy = 1'b0;
        error = 1'b1;
        state_n = ST_IDLE;
      end

      default: begin
        busy = 1'b0;
        error = 1'b1;
        state_n = ST_IDLE;
      end
    endcase
  end

endmodule
