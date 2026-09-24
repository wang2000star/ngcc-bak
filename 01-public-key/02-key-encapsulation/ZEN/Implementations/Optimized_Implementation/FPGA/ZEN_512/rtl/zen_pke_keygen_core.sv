module zen_pke_keygen_core #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int ADDR_W = zen_accel_pkg::ADDR_W,
  parameter int BUF_BANKS = zen_accel_pkg::BUF_BANKS
) (
  input  logic clk,
  input  logic rst_n,

  input  logic        start_i,
  input  logic [1:0]  profile_id_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [2:0]  buf_a_sel_i,
  input  logic [2:0]  buf_b_sel_i,
  input  logic [2:0]  buf_r_sel_i,

  input  logic sampler_done_i,
  input  logic sampler_error_i,
  input  logic sampler_vec_out_valid_i,
  input  logic signed [NTT_N*COEFF_W-1:0] sampler_vec_out_i,

  input  logic ntt_done_i,
  input  logic ntt_error_i,
  input  logic ntt_vec_out_valid_i,
  input  logic signed [NTT_N*COEFF_W-1:0] ntt_vec_out_i,

  input  logic basemul_done_i,
  input  logic basemul_error_i,
  input  logic basemul_vec_out_valid_i,
  input  logic signed [NTT_N*COEFF_W-1:0] basemul_vec_out_i,
  input  logic basemul_row_valid_i,
  input  logic [ADDR_W-1:0] basemul_row_idx_i,
  input  logic signed [(16*COEFF_W)-1:0] basemul_row_data_i,

  input  logic baseinv_done_i,
  input  logic baseinv_error_i,
  input  logic baseinv_vec_out_valid_i,
  input  logic signed [NTT_N*COEFF_W-1:0] baseinv_vec_out_i,

  input  logic binary_done_i,
  input  logic binary_error_i,
  input  logic binary_vec_out_valid_i,
  input  logic signed [NTT_N*COEFF_W-1:0] binary_vec_out_i,
  input  logic binary_row_valid_i,
  input  logic [ADDR_W-1:0] binary_row_idx_i,
  input  logic signed [(16*COEFF_W)-1:0] binary_row_data_i,

  output logic busy_o,
  output logic done_o,
  output logic error_o,
  output logic [7:0] errcode_o,
  output logic [31:0] out_bytes0_o,
  output logic [31:0] out_bytes1_o,
  output logic sampler_seed_active_o,

  output logic sampler_start_o,
  output logic [7:0] sample_cmd_o,
  output logic [31:0] sample_cfg_o,
  output logic [31:0] sample_len_o,
  output logic [2:0] sample_buf_r_sel_o,

  output logic ntt_start_o,
  output logic basemul_start_o,
  output logic baseinv_start_o,
  output logic binary_start_o,
  output logic [7:0] arith_cmd_o,
  output logic vec_in_valid_o,
  output logic signed [NTT_N*COEFF_W-1:0] vec_in_a_o,
  output logic signed [NTT_N*COEFF_W-1:0] vec_in_b_o,

  output logic vec_wr_en_o,
  output logic [2:0] vec_wr_buf_sel_o,
  output logic [ADDR_W-1:0] vec_wr_row_o,
  output logic [BUF_BANKS*COEFF_W-1:0] vec_wr_data_o
);

  import zen_accel_pkg::*;

  localparam logic [7:0] ERR_SAMPLE_F = 8'h10;
  localparam logic [7:0] ERR_NTT_F    = 8'h11;
  localparam logic [7:0] ERR_BASEINV  = 8'h12;
  localparam logic [7:0] ERR_FAST_INV = 8'h13;
  localparam logic [7:0] ERR_SAMPLE_G = 8'h14;
  localparam logic [7:0] ERR_NTT_G    = 8'h15;
  localparam logic [7:0] ERR_BASEMUL  = 8'h16;
  localparam int KEYGEN_STREAM_ROW_COEFFS = 16;
  localparam int KEYGEN_VEC_ROW_COUNT =
      (NTT_N + KEYGEN_STREAM_ROW_COEFFS - 1) / KEYGEN_STREAM_ROW_COEFFS;
  localparam int KEYGEN_F2_ROW_COUNT =
      ((NTT_N / 4) + KEYGEN_STREAM_ROW_COEFFS - 1) / KEYGEN_STREAM_ROW_COEFFS;

  typedef enum logic [4:0] {
    PKE_KEYGEN_IDLE,
    PKE_KEYGEN_LAUNCH_SAMPLE_F,
    PKE_KEYGEN_WAIT_SAMPLE_F,
    PKE_KEYGEN_CHECK_F_Z2,
    PKE_KEYGEN_LAUNCH_NTT_F,
    PKE_KEYGEN_WAIT_NTT_F,
    PKE_KEYGEN_CHECK_F_ZQ,
    PKE_KEYGEN_LAUNCH_BASEINV_F,
    PKE_KEYGEN_WAIT_BASEINV_F,
    PKE_KEYGEN_LAUNCH_FAST_INV_F,
    PKE_KEYGEN_WAIT_FAST_INV_F,
    PKE_KEYGEN_LAUNCH_SAMPLE_G,
    PKE_KEYGEN_WAIT_SAMPLE_G,
    PKE_KEYGEN_LAUNCH_NTT_G,
    PKE_KEYGEN_WAIT_NTT_G,
    PKE_KEYGEN_CHECK_G_ZQ,
    PKE_KEYGEN_LAUNCH_BASEMUL,
    PKE_KEYGEN_WAIT_BASEMUL,
    PKE_KEYGEN_PREP_OUT,
    PKE_KEYGEN_WAIT_PREP_OUT,
    PKE_KEYGEN_WRITEBACK_PK,
    PKE_KEYGEN_WRITEBACK_SK_LO,
    PKE_KEYGEN_WRITEBACK_SK_HI,
    PKE_KEYGEN_WAIT_SK_LO_READY,
    PKE_KEYGEN_WAIT_SK_HI_READY
  } pke_keygen_state_t;

  pke_keygen_state_t pke_keygen_state, pke_keygen_state_n;

  logic [31:0] sample_cfg_base_r;
  logic [31:0] len_r;
  logic [2:0] buf_a_sel_r;
  logic [2:0] buf_b_sel_r;
  logic [2:0] buf_r_sel_r;
  logic [7:0] nonce_cur;
  logic signed [NTT_N*COEFF_W-1:0] f_vec;
  logic signed [NTT_N*COEFF_W-1:0] f_nttmq_vec;
  logic signed [NTT_N*COEFF_W-1:0] f_inv_ntt_vec;
  logic signed [NTT_N*COEFF_W-1:0] f2_vec;
  logic signed [NTT_N*COEFF_W-1:0] g_vec;
  logic signed [NTT_N*COEFF_W-1:0] g_nttmq_vec;
  logic signed [NTT_N*COEFF_W-1:0] pkpoly_vec;
  logic signed [NTT_N*COEFF_W-1:0] pk_packed_vec;
  logic signed [NTT_N*COEFF_W-1:0] sk_lo_vec;
  logic signed [NTT_N*COEFF_W-1:0] sk_hi_vec;
  logic [ADDR_W-1:0] pk_wr_row;
  logic [ADDR_W-1:0] sk_lo_wr_row;
  logic [ADDR_W-1:0] sk_hi_wr_row;
  logic sample_g_ready;
  logic sample_g_started_early_r;
  logic sample_g_nonce_bumped_r;
  logic baseinv_ready;
  logic fast_inv_ready;
  logic fast_inv_started_r;
  logic pk_poly_ready;
  logic keypair_pack_start;

  logic signed [NTT_N*COEFF_W-1:0] keypair_pack_pk_bytes_vec_out;
  logic signed [NTT_N*COEFF_W-1:0] keypair_pack_sk_lo_bytes_vec_out;
  logic signed [NTT_N*COEFF_W-1:0] keypair_pack_sk_hi_bytes_vec_out;
  logic keypair_pack_busy;
  logic keypair_pack_done;
  logic keypair_pack_pk_ready;
  logic keypair_pack_sk_lo_ready;
  logic keypair_pack_sk_hi_ready;
  logic [31:0] keypair_pack_bytes_produced0;
  logic [31:0] keypair_pack_bytes_produced1;
  logic [31:0] active_writeback_rows;
  logic [31:0] active_n;
  logic [31:0] active_n4;
  logic [31:0] active_pk_pack_bytes;
  logic [31:0] active_sk_pack_bytes;
  logic [31:0] pkpoly_ready_coeffs_r;
  logic [31:0] f2_ready_coeffs_r;
  logic [31:0] pkpoly_ready_coeffs_cur;
  logic [31:0] f2_ready_coeffs_cur;
  logic pk_pack_ready;
  logic sk_lo_pack_ready;
  logic sk_hi_pack_ready;
  logic [31:0] z2_check_idx;
  logic [31:0] z2_group_limit;
  logic z2_acc;
  logic z2_group_xor;
  logic z2_scan_last;
  logic z2_scan_noninvertible;
  logic [31:0] zq_check_idx;
  logic [31:0] zq_group_limit;
  logic [31:0] zq_base_idx;
  logic signed [COEFF_W+1:0] zq_group_sum;
  logic zq_group_is_zero;
  logic zq_scan_last;
  integer keygen_coeff_idx;

  assign active_writeback_rows = profile_writeback_rows_for_banks(profile_id_i, BUF_BANKS);
  assign active_n = profile_n(profile_id_i);
  assign active_n4 = profile_n4(profile_id_i);
  assign active_pk_pack_bytes = profile_pk_pack_bytes(profile_id_i);
  assign active_sk_pack_bytes = profile_sk_pack_bytes(profile_id_i);
  assign pkpoly_ready_coeffs_cur =
      (basemul_row_valid_i && (basemul_row_idx_i < KEYGEN_VEC_ROW_COUNT)) ?
        keygen_ready_coeff_limit(active_n, {{(32-ADDR_W){1'b0}}, basemul_row_idx_i}) :
        (pk_poly_ready ? active_n : pkpoly_ready_coeffs_r);
  assign f2_ready_coeffs_cur =
      (binary_row_valid_i && (binary_row_idx_i < KEYGEN_F2_ROW_COUNT)) ?
        keygen_ready_coeff_limit(active_n4, {{(32-ADDR_W){1'b0}}, binary_row_idx_i}) :
        (fast_inv_ready ? active_n4 : f2_ready_coeffs_r);

  function automatic logic [31:0] keygen_ready_coeff_limit(
    input logic [31:0] active_coeffs_i,
    input logic [31:0] row_idx_i
  );
    logic [31:0] next_coeff_limit;
    begin
      next_coeff_limit = (row_idx_i + 1) * KEYGEN_STREAM_ROW_COEFFS;
      if (next_coeff_limit > active_coeffs_i) begin
        keygen_ready_coeff_limit = active_coeffs_i;
      end else begin
        keygen_ready_coeff_limit = next_coeff_limit;
      end
    end
  endfunction

  always_comb begin
    z2_group_limit = active_n4;
    if (z2_group_limit > (NTT_N / 4)) begin
      z2_group_limit = NTT_N / 4;
    end
    z2_group_xor = 1'b0;
    if (z2_check_idx < z2_group_limit) begin
      z2_group_xor =
        f_vec[(z2_check_idx + 0 * z2_group_limit) * COEFF_W] ^
        f_vec[(z2_check_idx + 1 * z2_group_limit) * COEFF_W] ^
        f_vec[(z2_check_idx + 2 * z2_group_limit) * COEFF_W] ^
        f_vec[(z2_check_idx + 3 * z2_group_limit) * COEFF_W];
    end
    z2_scan_last = (z2_group_limit <= 1) || ((z2_check_idx + 1) >= z2_group_limit);
    z2_scan_noninvertible = ~((z2_group_limit == 0) ? 1'b0 : (z2_acc ^ z2_group_xor));
  end

  always_comb begin
    zq_group_limit = active_n;
    if (zq_group_limit > NTT_N) begin
      zq_group_limit = NTT_N;
    end
    zq_group_limit = (zq_group_limit + 3) >> 2;
    zq_base_idx = zq_check_idx << 2;
    zq_group_sum = '0;
    if (zq_check_idx < zq_group_limit) begin
      if (pke_keygen_state == PKE_KEYGEN_CHECK_G_ZQ) begin
        zq_group_sum =
          $signed(g_nttmq_vec[(zq_base_idx + 0) * COEFF_W +: COEFF_W]) +
          $signed(g_nttmq_vec[(zq_base_idx + 1) * COEFF_W +: COEFF_W]) +
          $signed(g_nttmq_vec[(zq_base_idx + 2) * COEFF_W +: COEFF_W]) +
          $signed(g_nttmq_vec[(zq_base_idx + 3) * COEFF_W +: COEFF_W]);
      end else begin
        zq_group_sum =
          $signed(f_nttmq_vec[(zq_base_idx + 0) * COEFF_W +: COEFF_W]) +
          $signed(f_nttmq_vec[(zq_base_idx + 1) * COEFF_W +: COEFF_W]) +
          $signed(f_nttmq_vec[(zq_base_idx + 2) * COEFF_W +: COEFF_W]) +
          $signed(f_nttmq_vec[(zq_base_idx + 3) * COEFF_W +: COEFF_W]);
      end
    end
    zq_group_is_zero = (zq_check_idx < zq_group_limit) && (zq_group_sum == '0);
    zq_scan_last = (zq_group_limit <= 1) || ((zq_check_idx + 1) >= zq_group_limit);
  end

  zen_keypair_pack_seq_core #(
    .NTT_N(NTT_N),
    .COEFF_W(COEFF_W)
  ) u_keypair_pack_seq_core (
    .clk(clk),
    .rst_n(rst_n),
    .start_i(keypair_pack_start),
    .pk_poly_ready_i(pk_poly_ready),
    .pk_poly_ready_coeffs_i(pkpoly_ready_coeffs_cur),
    .sk_f2_ready_i(fast_inv_ready),
    .sk_f2_ready_coeffs_i(f2_ready_coeffs_r),
    .profile_id_i(profile_id_i),
    .pk_poly_vec_i(pkpoly_vec),
    .sk_f_ntt_poly_vec_i(f_nttmq_vec),
    .sk_f2_poly_vec_i(f2_vec),
    .busy_o(keypair_pack_busy),
    .done_o(keypair_pack_done),
    .pk_ready_o(keypair_pack_pk_ready),
    .sk_lo_ready_o(keypair_pack_sk_lo_ready),
    .sk_hi_ready_o(keypair_pack_sk_hi_ready),
    .pk_bytes_vec_o(keypair_pack_pk_bytes_vec_out),
    .sk_lo_bytes_vec_o(keypair_pack_sk_lo_bytes_vec_out),
    .sk_hi_bytes_vec_o(keypair_pack_sk_hi_bytes_vec_out),
    .bytes_produced0_o(keypair_pack_bytes_produced0),
    .bytes_produced1_o(keypair_pack_bytes_produced1)
  );

  assign out_bytes0_o = active_pk_pack_bytes;
  assign out_bytes1_o = active_sk_pack_bytes;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      pke_keygen_state <= PKE_KEYGEN_IDLE;
      sample_cfg_base_r <= '0;
      len_r <= '0;
      buf_a_sel_r <= '0;
      buf_b_sel_r <= '0;
      buf_r_sel_r <= '0;
      nonce_cur <= '0;
      f_vec <= '0;
      f_nttmq_vec <= '0;
      f_inv_ntt_vec <= '0;
      f2_vec <= '0;
      g_vec <= '0;
      g_nttmq_vec <= '0;
      pkpoly_vec <= '0;
      pk_packed_vec <= '0;
      sk_lo_vec <= '0;
      sk_hi_vec <= '0;
      pk_wr_row <= '0;
      sk_lo_wr_row <= '0;
      sk_hi_wr_row <= '0;
      z2_check_idx <= '0;
      z2_acc <= 1'b0;
      zq_check_idx <= '0;
      sample_g_ready <= 1'b0;
      sample_g_started_early_r <= 1'b0;
      sample_g_nonce_bumped_r <= 1'b0;
      baseinv_ready <= 1'b0;
      fast_inv_ready <= 1'b0;
      fast_inv_started_r <= 1'b0;
      pk_poly_ready <= 1'b0;
      pkpoly_ready_coeffs_r <= 32'd0;
      f2_ready_coeffs_r <= 32'd0;
      pk_pack_ready <= 1'b0;
      sk_lo_pack_ready <= 1'b0;
      sk_hi_pack_ready <= 1'b0;
    end else begin
      pke_keygen_state <= pke_keygen_state_n;

      if ((pke_keygen_state == PKE_KEYGEN_IDLE) && start_i) begin
        sample_cfg_base_r <= 32'h8000_0000 | {16'h0, cfg_i[15:0]};
        len_r <= len_i;
        buf_a_sel_r <= buf_a_sel_i;
        buf_b_sel_r <= buf_b_sel_i;
        buf_r_sel_r <= buf_r_sel_i;
        sample_g_ready <= 1'b0;
        sample_g_started_early_r <= 1'b0;
        sample_g_nonce_bumped_r <= 1'b0;
        baseinv_ready <= 1'b0;
        fast_inv_ready <= 1'b0;
        fast_inv_started_r <= 1'b0;
        pk_poly_ready <= 1'b0;
        pkpoly_ready_coeffs_r <= 32'd0;
        f2_ready_coeffs_r <= 32'd0;
        pk_pack_ready <= 1'b0;
        sk_lo_pack_ready <= 1'b0;
        sk_hi_pack_ready <= 1'b0;
        z2_check_idx <= '0;
        z2_acc <= 1'b0;
        zq_check_idx <= '0;
      end

      if ((pke_keygen_state == PKE_KEYGEN_IDLE) && start_i) begin
        nonce_cur <= 8'd0;
        fast_inv_started_r <= 1'b0;
      end else if (sampler_start_o && (sample_cmd_o == CMD_SAMPLE_F)) begin
        fast_inv_started_r <= 1'b0;
        sample_g_started_early_r <= 1'b0;
        sample_g_nonce_bumped_r <= 1'b0;
      end else if (sampler_start_o && (sample_cmd_o == CMD_SAMPLE_G)) begin
        sample_g_started_early_r <= (pke_keygen_state == PKE_KEYGEN_LAUNCH_NTT_F);
        sample_g_nonce_bumped_r <= 1'b0;
        sample_g_ready <= 1'b0;
      end else if (baseinv_start_o) begin
        baseinv_ready <= 1'b0;
      end else if (binary_start_o && (arith_cmd_o == CMD_FAST_INV)) begin
        fast_inv_ready <= 1'b0;
        fast_inv_started_r <= 1'b1;
        f2_ready_coeffs_r <= 32'd0;
      end else if (basemul_start_o) begin
        pk_poly_ready <= 1'b0;
        pkpoly_ready_coeffs_r <= 32'd0;
      end else if ((pke_keygen_state == PKE_KEYGEN_WAIT_SAMPLE_F) &&
                   sampler_done_i && sampler_vec_out_valid_i) begin
        nonce_cur <= nonce_cur + 1'b1;
      end else if (((pke_keygen_state == PKE_KEYGEN_WAIT_NTT_F) ||
                    (pke_keygen_state == PKE_KEYGEN_WAIT_BASEINV_F) ||
                    (pke_keygen_state == PKE_KEYGEN_WAIT_FAST_INV_F) ||
                    (pke_keygen_state == PKE_KEYGEN_WAIT_SAMPLE_G)) &&
                   sampler_done_i && sampler_vec_out_valid_i &&
                   !sample_g_started_early_r) begin
        nonce_cur <= nonce_cur + 1'b1;
      end else if ((pke_keygen_state == PKE_KEYGEN_CHECK_F_ZQ) &&
                   !zq_group_is_zero &&
                   zq_scan_last &&
                   sample_g_started_early_r &&
                   !sample_g_nonce_bumped_r) begin
        nonce_cur <= nonce_cur + 1'b1;
        sample_g_nonce_bumped_r <= 1'b1;
      end

      if ((pke_keygen_state == PKE_KEYGEN_WAIT_SAMPLE_F) &&
          sampler_done_i && sampler_vec_out_valid_i) begin
        f_vec <= sampler_vec_out_i;
      end

      if ((pke_keygen_state == PKE_KEYGEN_WAIT_NTT_F) &&
          ntt_done_i && ntt_vec_out_valid_i) begin
        f_nttmq_vec <= ntt_vec_out_i;
      end

      if (binary_row_valid_i && (binary_row_idx_i < KEYGEN_F2_ROW_COUNT)) begin
        f2_ready_coeffs_r <= keygen_ready_coeff_limit(active_n4, $unsigned(binary_row_idx_i));
        for (keygen_coeff_idx = 0; keygen_coeff_idx < KEYGEN_STREAM_ROW_COEFFS; keygen_coeff_idx++) begin
          int coeff_idx_local;
          coeff_idx_local = ($unsigned(binary_row_idx_i) * KEYGEN_STREAM_ROW_COEFFS) + keygen_coeff_idx;
          if (coeff_idx_local < active_n4) begin
            f2_vec[coeff_idx_local*COEFF_W +: COEFF_W] <=
              binary_row_data_i[keygen_coeff_idx*COEFF_W +: COEFF_W];
          end
        end
      end

      if (basemul_row_valid_i && (basemul_row_idx_i < KEYGEN_VEC_ROW_COUNT)) begin
        pkpoly_ready_coeffs_r <= keygen_ready_coeff_limit(active_n, $unsigned(basemul_row_idx_i));
        for (keygen_coeff_idx = 0; keygen_coeff_idx < KEYGEN_STREAM_ROW_COEFFS; keygen_coeff_idx++) begin
          int coeff_idx_local;
          coeff_idx_local = ($unsigned(basemul_row_idx_i) * KEYGEN_STREAM_ROW_COEFFS) + keygen_coeff_idx;
          if (coeff_idx_local < active_n) begin
            pkpoly_vec[coeff_idx_local*COEFF_W +: COEFF_W] <=
              basemul_row_data_i[keygen_coeff_idx*COEFF_W +: COEFF_W];
          end
        end
      end

      if (!baseinv_ready && baseinv_done_i && baseinv_vec_out_valid_i) begin
        f_inv_ntt_vec <= baseinv_vec_out_i;
        baseinv_ready <= 1'b1;
      end

      if (!fast_inv_ready && binary_done_i && binary_vec_out_valid_i) begin
        f2_vec <= binary_vec_out_i;
        fast_inv_ready <= 1'b1;
        f2_ready_coeffs_r <= active_n4;
      end

      if ((pke_keygen_state == PKE_KEYGEN_WAIT_NTT_G) &&
          ntt_done_i && ntt_vec_out_valid_i) begin
        g_nttmq_vec <= ntt_vec_out_i;
      end

      if ((pke_keygen_state == PKE_KEYGEN_WAIT_BASEMUL) &&
          basemul_done_i && basemul_vec_out_valid_i) begin
        pkpoly_vec <= basemul_vec_out_i;
        pk_poly_ready <= 1'b1;
        pkpoly_ready_coeffs_r <= active_n;
      end else if (pke_keygen_state == PKE_KEYGEN_WRITEBACK_PK) begin
        if (pk_wr_row + 1 < active_writeback_rows) begin
          pk_wr_row <= pk_wr_row + 1'b1;
          pk_packed_vec <= pk_packed_vec >> (BUF_BANKS * COEFF_W);
        end else begin
          pk_wr_row <= '0;
          pk_packed_vec <= '0;
        end
      end else if (pke_keygen_state == PKE_KEYGEN_WRITEBACK_SK_LO) begin
        if (sk_lo_wr_row + 1 < active_writeback_rows) begin
          sk_lo_wr_row <= sk_lo_wr_row + 1'b1;
          sk_lo_vec <= sk_lo_vec >> (BUF_BANKS * COEFF_W);
        end else begin
          sk_lo_wr_row <= '0;
          sk_lo_vec <= '0;
        end
      end else if (pke_keygen_state == PKE_KEYGEN_WRITEBACK_SK_HI) begin
        if (sk_hi_wr_row + 1 < active_writeback_rows) begin
          sk_hi_wr_row <= sk_hi_wr_row + 1'b1;
          sk_hi_vec <= sk_hi_vec >> (BUF_BANKS * COEFF_W);
        end else begin
          sk_hi_wr_row <= '0;
          sk_hi_vec <= '0;
        end
      end

      if ((pke_keygen_state != PKE_KEYGEN_CHECK_F_Z2) &&
          (pke_keygen_state_n == PKE_KEYGEN_CHECK_F_Z2)) begin
        z2_check_idx <= 32'd0;
        z2_acc <= 1'b0;
      end else if ((pke_keygen_state == PKE_KEYGEN_CHECK_F_Z2) &&
                   (z2_group_limit > 1) &&
                   !z2_scan_last) begin
        z2_acc <= z2_acc ^ z2_group_xor;
        z2_check_idx <= z2_check_idx + 1'b1;
      end

      if (((pke_keygen_state != PKE_KEYGEN_CHECK_F_ZQ) &&
           (pke_keygen_state_n == PKE_KEYGEN_CHECK_F_ZQ)) ||
          ((pke_keygen_state != PKE_KEYGEN_CHECK_G_ZQ) &&
           (pke_keygen_state_n == PKE_KEYGEN_CHECK_G_ZQ))) begin
        zq_check_idx <= 32'd0;
      end else if (((pke_keygen_state == PKE_KEYGEN_CHECK_F_ZQ) ||
                    (pke_keygen_state == PKE_KEYGEN_CHECK_G_ZQ)) &&
                   (zq_group_limit > 1) &&
                   !zq_group_is_zero &&
                   !zq_scan_last) begin
        zq_check_idx <= zq_check_idx + 1'b1;
      end

      if (((pke_keygen_state == PKE_KEYGEN_WAIT_NTT_F) ||
           (pke_keygen_state == PKE_KEYGEN_WAIT_BASEINV_F) ||
           (pke_keygen_state == PKE_KEYGEN_WAIT_FAST_INV_F) ||
           (pke_keygen_state == PKE_KEYGEN_WAIT_SAMPLE_G)) &&
          sampler_done_i && sampler_vec_out_valid_i) begin
        g_vec <= sampler_vec_out_i;
        sample_g_ready <= 1'b1;
      end

      if (keypair_pack_pk_ready && !pk_pack_ready) begin
        pk_packed_vec <= keypair_pack_pk_bytes_vec_out;
        pk_wr_row <= '0;
        pk_pack_ready <= 1'b1;
      end

      if (keypair_pack_sk_lo_ready && !sk_lo_pack_ready) begin
        sk_lo_vec <= keypair_pack_sk_lo_bytes_vec_out;
        sk_lo_wr_row <= '0;
        sk_lo_pack_ready <= 1'b1;
      end

      if (keypair_pack_sk_hi_ready && !sk_hi_pack_ready) begin
        sk_hi_vec <= keypair_pack_sk_hi_bytes_vec_out;
        sk_hi_wr_row <= '0;
        sk_hi_pack_ready <= 1'b1;
      end
    end
  end

  always_comb begin
    busy_o = (pke_keygen_state != PKE_KEYGEN_IDLE);
    done_o = 1'b0;
    error_o = 1'b0;
    errcode_o = 8'h00;
    sampler_seed_active_o = 1'b0;
    sampler_start_o = 1'b0;
    sample_cmd_o = CMD_NOP;
    sample_cfg_o = 32'd0;
    sample_len_o = 32'd0;
    sample_buf_r_sel_o = 3'd0;
    ntt_start_o = 1'b0;
    basemul_start_o = 1'b0;
    baseinv_start_o = 1'b0;
    binary_start_o = 1'b0;
    arith_cmd_o = CMD_NOP;
    vec_in_valid_o = 1'b0;
    vec_in_a_o = '0;
    vec_in_b_o = '0;
    keypair_pack_start = 1'b0;
    vec_wr_en_o = 1'b0;
    vec_wr_buf_sel_o = buf_r_sel_r;
    vec_wr_row_o = pk_wr_row;
    vec_wr_data_o = '0;
    pke_keygen_state_n = pke_keygen_state;

    unique case (pke_keygen_state)
      PKE_KEYGEN_IDLE: begin
        if (start_i) begin
          pke_keygen_state_n = PKE_KEYGEN_LAUNCH_SAMPLE_F;
        end
      end

      PKE_KEYGEN_LAUNCH_SAMPLE_F: begin
        sampler_seed_active_o = 1'b1;
        sampler_start_o = 1'b1;
        sample_cmd_o = CMD_SAMPLE_F;
        sample_cfg_o = sample_cfg_base_r | ({24'h0, nonce_cur} << 16);
        sample_len_o = len_r;
        sample_buf_r_sel_o = buf_b_sel_r;
        pke_keygen_state_n = PKE_KEYGEN_WAIT_SAMPLE_F;
      end

      PKE_KEYGEN_WAIT_SAMPLE_F: begin
        sampler_seed_active_o = 1'b1;
        sample_cmd_o = CMD_SAMPLE_F;
        sample_cfg_o = sample_cfg_base_r | ({24'h0, nonce_cur} << 16);
        sample_len_o = len_r;
        sample_buf_r_sel_o = buf_b_sel_r;
        if (sampler_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_SAMPLE_F;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (sampler_done_i && sampler_vec_out_valid_i) begin
          pke_keygen_state_n = PKE_KEYGEN_CHECK_F_Z2;
        end
      end

      PKE_KEYGEN_CHECK_F_Z2: begin
        if (z2_group_limit == 0) begin
          pke_keygen_state_n = PKE_KEYGEN_LAUNCH_SAMPLE_F;
        end else if (z2_scan_last) begin
          if (z2_scan_noninvertible) begin
            pke_keygen_state_n = PKE_KEYGEN_LAUNCH_SAMPLE_F;
          end else begin
            pke_keygen_state_n = PKE_KEYGEN_LAUNCH_NTT_F;
          end
        end
      end

      PKE_KEYGEN_LAUNCH_NTT_F: begin
        sampler_seed_active_o = 1'b1;
        sampler_start_o = 1'b1;
        sample_cmd_o = CMD_SAMPLE_G;
        sample_cfg_o = sample_cfg_base_r | ({24'h0, nonce_cur} << 16);
        sample_len_o = len_r;
        sample_buf_r_sel_o = buf_b_sel_r;
        vec_in_a_o = f_vec;
        vec_in_b_o = '0;
        arith_cmd_o = CMD_NTT_MQ;
        vec_in_valid_o = 1'b1;
        ntt_start_o = 1'b1;
        pke_keygen_state_n = PKE_KEYGEN_WAIT_NTT_F;
      end

      PKE_KEYGEN_WAIT_NTT_F: begin
        sampler_seed_active_o = 1'b1;
        sample_cmd_o = CMD_SAMPLE_G;
        sample_cfg_o = sample_cfg_base_r | ({24'h0, nonce_cur} << 16);
        sample_len_o = len_r;
        sample_buf_r_sel_o = buf_b_sel_r;
        arith_cmd_o = CMD_NTT_MQ;
        if (sample_g_started_early_r && sampler_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_SAMPLE_G;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (ntt_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_NTT_F;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (ntt_done_i && ntt_vec_out_valid_i) begin
          pke_keygen_state_n = PKE_KEYGEN_CHECK_F_ZQ;
        end
      end

      PKE_KEYGEN_CHECK_F_ZQ: begin
        if (zq_group_limit == 0) begin
          pke_keygen_state_n = PKE_KEYGEN_LAUNCH_BASEINV_F;
        end else if (zq_group_is_zero) begin
          pke_keygen_state_n = PKE_KEYGEN_LAUNCH_SAMPLE_F;
        end else if (zq_scan_last) begin
          pke_keygen_state_n = PKE_KEYGEN_LAUNCH_BASEINV_F;
        end
      end

      PKE_KEYGEN_LAUNCH_BASEINV_F: begin
        sampler_seed_active_o = 1'b1;
        if (!sample_g_started_early_r) begin
          sampler_start_o = 1'b1;
        end
        sample_cmd_o = CMD_SAMPLE_G;
        sample_cfg_o = sample_cfg_base_r | ({24'h0, nonce_cur} << 16);
        sample_len_o = len_r;
        sample_buf_r_sel_o = buf_b_sel_r;
        vec_in_a_o = f_nttmq_vec;
        vec_in_b_o = '0;
        arith_cmd_o = CMD_BASEINV;
        vec_in_valid_o = 1'b1;
        baseinv_start_o = 1'b1;
        keypair_pack_start = 1'b1;
        pke_keygen_state_n = PKE_KEYGEN_WAIT_BASEINV_F;
      end

      PKE_KEYGEN_WAIT_BASEINV_F: begin
        sampler_seed_active_o = 1'b1;
        sample_cmd_o = CMD_SAMPLE_G;
        sample_cfg_o = sample_cfg_base_r | ({24'h0, nonce_cur} << 16);
        sample_len_o = len_r;
        sample_buf_r_sel_o = buf_b_sel_r;
        arith_cmd_o = CMD_BASEINV;
        if (!baseinv_ready && baseinv_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_BASEINV;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (sampler_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_SAMPLE_G;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (sample_g_ready) begin
          vec_in_a_o = g_vec;
          vec_in_b_o = '0;
          arith_cmd_o = CMD_NTT_MQ;
          vec_in_valid_o = 1'b1;
          ntt_start_o = 1'b1;
          pke_keygen_state_n = PKE_KEYGEN_WAIT_NTT_G;
        end else if (!fast_inv_started_r &&
                     (baseinv_ready || (baseinv_done_i && baseinv_vec_out_valid_i))) begin
          vec_in_a_o = f_vec;
          vec_in_b_o = '0;
          arith_cmd_o = CMD_FAST_INV;
          vec_in_valid_o = 1'b1;
          binary_start_o = 1'b1;
          pke_keygen_state_n = PKE_KEYGEN_WAIT_FAST_INV_F;
        end
      end

      PKE_KEYGEN_LAUNCH_FAST_INV_F: begin
        sampler_seed_active_o = 1'b1;
        sample_cmd_o = CMD_SAMPLE_G;
        sample_cfg_o = sample_cfg_base_r | ({24'h0, nonce_cur} << 16);
        sample_len_o = len_r;
        sample_buf_r_sel_o = buf_b_sel_r;
        vec_in_a_o = f_vec;
        vec_in_b_o = '0;
        arith_cmd_o = CMD_FAST_INV;
        vec_in_valid_o = 1'b1;
        binary_start_o = 1'b1;
        pke_keygen_state_n = PKE_KEYGEN_WAIT_FAST_INV_F;
      end

      PKE_KEYGEN_WAIT_FAST_INV_F: begin
        sampler_seed_active_o = 1'b1;
        sample_cmd_o = CMD_SAMPLE_G;
        sample_cfg_o = sample_cfg_base_r | ({24'h0, nonce_cur} << 16);
        sample_len_o = len_r;
        sample_buf_r_sel_o = buf_b_sel_r;
        arith_cmd_o = CMD_FAST_INV;
        if (!baseinv_ready && baseinv_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_BASEINV;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (!fast_inv_ready && binary_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_FAST_INV;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (sampler_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_SAMPLE_G;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (sample_g_ready) begin
          pke_keygen_state_n = PKE_KEYGEN_LAUNCH_NTT_G;
        end
      end

      PKE_KEYGEN_LAUNCH_SAMPLE_G: begin
        sampler_seed_active_o = 1'b1;
        sampler_start_o = 1'b1;
        sample_cmd_o = CMD_SAMPLE_G;
        sample_cfg_o = sample_cfg_base_r | ({24'h0, nonce_cur} << 16);
        sample_len_o = len_r;
        sample_buf_r_sel_o = buf_b_sel_r;
        pke_keygen_state_n = PKE_KEYGEN_WAIT_SAMPLE_G;
      end

      PKE_KEYGEN_WAIT_SAMPLE_G: begin
        sampler_seed_active_o = 1'b1;
        sample_cmd_o = CMD_SAMPLE_G;
        sample_cfg_o = sample_cfg_base_r | ({24'h0, nonce_cur} << 16);
        sample_len_o = len_r;
        sample_buf_r_sel_o = buf_b_sel_r;
        if (!baseinv_ready && baseinv_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_BASEINV;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (!fast_inv_ready && binary_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_FAST_INV;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (sampler_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_SAMPLE_G;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (sampler_done_i && sampler_vec_out_valid_i) begin
          pke_keygen_state_n = PKE_KEYGEN_LAUNCH_NTT_G;
        end
      end

      PKE_KEYGEN_LAUNCH_NTT_G: begin
        vec_in_a_o = g_vec;
        vec_in_b_o = '0;
        arith_cmd_o = CMD_NTT_MQ;
        vec_in_valid_o = 1'b1;
        ntt_start_o = 1'b1;
        pke_keygen_state_n = PKE_KEYGEN_WAIT_NTT_G;
      end

      PKE_KEYGEN_WAIT_NTT_G: begin
        if (!fast_inv_started_r && baseinv_ready) begin
          vec_in_a_o = f_vec;
          vec_in_b_o = '0;
          arith_cmd_o = CMD_FAST_INV;
          vec_in_valid_o = 1'b1;
          binary_start_o = 1'b1;
        end else begin
          arith_cmd_o = CMD_NTT_MQ;
        end
        if (!baseinv_ready && baseinv_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_BASEINV;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (!fast_inv_ready && binary_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_FAST_INV;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (ntt_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_NTT_G;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (ntt_done_i && ntt_vec_out_valid_i) begin
          pke_keygen_state_n = PKE_KEYGEN_CHECK_G_ZQ;
        end
      end

      PKE_KEYGEN_CHECK_G_ZQ: begin
        if (!baseinv_ready && baseinv_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_BASEINV;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (!fast_inv_ready && binary_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_FAST_INV;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (zq_group_limit == 0) begin
          if (baseinv_ready) begin
            pke_keygen_state_n = PKE_KEYGEN_LAUNCH_BASEMUL;
          end
        end else if (zq_group_is_zero) begin
          pke_keygen_state_n = PKE_KEYGEN_LAUNCH_SAMPLE_G;
        end else if (zq_scan_last) begin
          if (baseinv_ready) begin
            pke_keygen_state_n = PKE_KEYGEN_LAUNCH_BASEMUL;
          end
        end
      end

      PKE_KEYGEN_LAUNCH_BASEMUL: begin
        vec_in_a_o = g_nttmq_vec;
        vec_in_b_o = f_inv_ntt_vec;
        arith_cmd_o = CMD_BASEMUL_MQ;
        vec_in_valid_o = 1'b1;
        basemul_start_o = 1'b1;
        pke_keygen_state_n = PKE_KEYGEN_WAIT_BASEMUL;
      end

      PKE_KEYGEN_WAIT_BASEMUL: begin
        if (!fast_inv_started_r && baseinv_ready) begin
          vec_in_a_o = f_vec;
          vec_in_b_o = '0;
          arith_cmd_o = CMD_FAST_INV;
          vec_in_valid_o = 1'b1;
          binary_start_o = 1'b1;
        end else begin
          arith_cmd_o = CMD_BASEMUL_MQ;
        end
        if (!fast_inv_ready && binary_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_FAST_INV;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (basemul_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_BASEMUL;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (basemul_done_i && basemul_vec_out_valid_i) begin
          pke_keygen_state_n = PKE_KEYGEN_PREP_OUT;
        end
      end

      PKE_KEYGEN_PREP_OUT: begin
        pke_keygen_state_n = PKE_KEYGEN_WAIT_PREP_OUT;
      end

      PKE_KEYGEN_WAIT_PREP_OUT: begin
        if (!fast_inv_ready && binary_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_FAST_INV;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end else if (pk_pack_ready) begin
          pke_keygen_state_n = PKE_KEYGEN_WRITEBACK_PK;
        end
      end

      PKE_KEYGEN_WRITEBACK_PK: begin
        vec_wr_en_o = 1'b1;
        vec_wr_buf_sel_o = buf_a_sel_r;
        vec_wr_row_o = pk_wr_row;
        vec_wr_data_o = pk_packed_vec[0 +: BUF_BANKS*COEFF_W];
        if (pk_wr_row + 1 >= active_writeback_rows) begin
          if (sk_lo_pack_ready) begin
            pke_keygen_state_n = PKE_KEYGEN_WRITEBACK_SK_LO;
          end else begin
            pke_keygen_state_n = PKE_KEYGEN_WAIT_SK_LO_READY;
          end
        end
      end

      PKE_KEYGEN_WAIT_SK_LO_READY: begin
        if (sk_lo_pack_ready) begin
          pke_keygen_state_n = PKE_KEYGEN_WRITEBACK_SK_LO;
        end
      end

      PKE_KEYGEN_WRITEBACK_SK_LO: begin
        vec_wr_en_o = 1'b1;
        vec_wr_buf_sel_o = buf_b_sel_r;
        vec_wr_row_o = sk_lo_wr_row;
        vec_wr_data_o = sk_lo_vec[0 +: BUF_BANKS*COEFF_W];
        if (sk_lo_wr_row + 1 >= active_writeback_rows) begin
          if (active_sk_pack_bytes > active_n) begin
            if (sk_hi_pack_ready) begin
              pke_keygen_state_n = PKE_KEYGEN_WRITEBACK_SK_HI;
            end else begin
              pke_keygen_state_n = PKE_KEYGEN_WAIT_SK_HI_READY;
            end
          end else begin
            busy_o = 1'b0;
            done_o = 1'b1;
            pke_keygen_state_n = PKE_KEYGEN_IDLE;
          end
        end
      end

      PKE_KEYGEN_WAIT_SK_HI_READY: begin
        if (sk_hi_pack_ready) begin
          pke_keygen_state_n = PKE_KEYGEN_WRITEBACK_SK_HI;
        end
      end

      PKE_KEYGEN_WRITEBACK_SK_HI: begin
        vec_wr_en_o = 1'b1;
        vec_wr_buf_sel_o = buf_r_sel_r;
        vec_wr_row_o = sk_hi_wr_row;
        vec_wr_data_o = sk_hi_vec[0 +: BUF_BANKS*COEFF_W];
        if (sk_hi_wr_row + 1 >= active_writeback_rows) begin
          busy_o = 1'b0;
          done_o = 1'b1;
          pke_keygen_state_n = PKE_KEYGEN_IDLE;
        end
      end

      default: begin
        pke_keygen_state_n = PKE_KEYGEN_IDLE;
      end
    endcase
  end

endmodule
