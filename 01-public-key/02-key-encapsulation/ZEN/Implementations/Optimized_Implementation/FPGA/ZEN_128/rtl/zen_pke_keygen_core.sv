module zen_pke_keygen_core (
  input  logic clk,
  input  logic rst_n,

  input  logic        start_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [2:0]  buf_a_sel_i,
  input  logic [2:0]  buf_b_sel_i,
  input  logic [2:0]  buf_r_sel_i,

  input  logic sampler_done_i,
  input  logic sampler_error_i,
  input  logic sampler_vec_out_valid_i,
  input  zen_accel_pkg::zen_poly_vec_t sampler_vec_out_i,

  input  logic ntt_done_i,
  input  logic ntt_error_i,
  input  logic ntt_vec_out_valid_i,
  input  zen_accel_pkg::zen_poly_vec_t ntt_vec_out_i,

  input  logic basemul_done_i,
  input  logic basemul_error_i,
  input  logic basemul_vec_out_valid_i,
  input  zen_accel_pkg::zen_poly_vec_t basemul_vec_out_i,
  input  logic basemul_row_valid_i,
  input  zen_accel_pkg::zen_row_addr_t basemul_row_idx_i,
  input  zen_accel_pkg::zen_stream_row_t basemul_row_data_i,

  input  logic baseinv_done_i,
  input  logic baseinv_error_i,
  input  logic baseinv_vec_out_valid_i,
  input  zen_accel_pkg::zen_poly_vec_t baseinv_vec_out_i,
  input  logic baseinv_row_valid_i,
  input  zen_accel_pkg::zen_row_addr_t baseinv_row_idx_i,
  input  zen_accel_pkg::zen_stream_row_t baseinv_row_data_i,

  input  logic binary_done_i,
  input  logic binary_error_i,
  input  logic binary_vec_out_valid_i,
  input  zen_accel_pkg::zen_poly_vec_t binary_vec_out_i,
  input  logic binary_row_valid_i,
  input  zen_accel_pkg::zen_row_addr_t binary_row_idx_i,
  input  zen_accel_pkg::zen_stream_row_t binary_row_data_i,

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
  output zen_accel_pkg::zen_poly_vec_t vec_in_a_o,
  output zen_accel_pkg::zen_poly_vec_t vec_in_b_o,

  output logic vec_wr_en_o,
  output logic [2:0] vec_wr_buf_sel_o,
  output zen_accel_pkg::zen_row_addr_t vec_wr_row_o,
  output zen_accel_pkg::zen_buf_row_t vec_wr_data_o
);

  import zen_accel_pkg::*;
  localparam int NTT_N = ZEN_N;

  localparam logic [7:0] ERR_SAMPLE_F = 8'h10;
  localparam logic [7:0] ERR_NTT_F    = 8'h11;
  localparam logic [7:0] ERR_BASEINV  = 8'h12;
  localparam logic [7:0] ERR_FAST_INV = 8'h13;
  localparam logic [7:0] ERR_SAMPLE_G = 8'h14;
  localparam logic [7:0] ERR_NTT_G    = 8'h15;
  localparam logic [7:0] ERR_BASEMUL  = 8'h16;
  localparam int KEYGEN_STREAM_ROW_COEFFS = 16;
  localparam int KEYGEN_STREAM_ROW_BITS = KEYGEN_STREAM_ROW_COEFFS * COEFF_W;
  localparam int KEYGEN_VEC_ROW_COUNT =
      (NTT_N + KEYGEN_STREAM_ROW_COEFFS - 1) / KEYGEN_STREAM_ROW_COEFFS;
  localparam int KEYGEN_F2_ROW_COUNT =
      ((NTT_N / 4) + KEYGEN_STREAM_ROW_COEFFS - 1) / KEYGEN_STREAM_ROW_COEFFS;
  localparam int ACTIVE_WRITEBACK_ROWS_CONST = NTT_N / BUF_BANKS;
  localparam int ACTIVE_STREAM_ROWS_CONST = NTT_N / KEYGEN_STREAM_ROW_COEFFS;
  localparam int ACTIVE_F2_STREAM_ROWS_CONST = (NTT_N / 4) / KEYGEN_STREAM_ROW_COEFFS;
  localparam int ACTIVE_N_CONST = NTT_N;
  localparam int ACTIVE_N4_CONST = NTT_N / 4;
  localparam int ACTIVE_PK_PACK_BYTES_CONST = zen_swift_profile_pkg::SWIFT_INDCPA_PUBLICKEY_LEN_BYTES;
  localparam int ACTIVE_SK_PACK_BYTES_CONST =
      zen_swift_profile_pkg::SWIFT_F_NTT_PACK + zen_swift_profile_pkg::SWIFT_F2_PACK;

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
    PKE_KEYGEN_WRITEBACK_SK_HI
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
  logic keypair_pack_ready;
  logic f_z2_noninvertible_r;
  logic f_zq_noninvertible_r;
  logic g_zq_noninvertible_r;

  logic signed [NTT_N*COEFF_W-1:0] keypair_pack_pk_bytes_vec_out;
  logic signed [NTT_N*COEFF_W-1:0] keypair_pack_sk_lo_bytes_vec_out;
  logic signed [NTT_N*COEFF_W-1:0] keypair_pack_sk_hi_bytes_vec_out;
  logic keypair_pack_busy;
  logic keypair_pack_done;
  logic [31:0] keypair_pack_bytes_produced0;
  logic [31:0] keypair_pack_bytes_produced1;
  logic [31:0] active_writeback_rows_r;
  logic [31:0] active_stream_rows_r;
  logic [31:0] active_f2_stream_rows_r;
  logic [31:0] active_n_r;
  logic [31:0] active_n4_r;
  logic [31:0] active_pk_pack_bytes_r;
  logic [31:0] active_sk_pack_bytes_r;
  logic [31:0] f2_ready_coeffs_r;
  logic [31:0] pkpoly_ready_coeffs_r;
  logic [KEYGEN_VEC_ROW_COUNT-1:0] f_inv_ntt_row_ready_r;
  logic [KEYGEN_F2_ROW_COUNT-1:0] f2_row_ready_r;
  logic [KEYGEN_VEC_ROW_COUNT-1:0] g_nttmq_row_ready_r;
  logic [KEYGEN_VEC_ROW_COUNT-1:0] pkpoly_row_ready_r;
  integer wr_bank_idx;
  integer keygen_row_idx;
  integer keygen_coeff_idx;

  // Phase A keeps flat vectors as the synthesis storage backing while
  // introducing row-ready scoreboards for the later streaming steps.

  function automatic logic keygen_z2_noninvertible(
    input logic [31:0] active_n4_i,
    input logic signed [NTT_N*COEFF_W-1:0] poly_vec
  );
    logic acc;
    integer z2_idx;
    integer effective_n4;
    begin
      effective_n4 = active_n4_i;
      if (effective_n4 > (NTT_N / 4)) begin
        effective_n4 = NTT_N / 4;
      end
      acc = 1'b0;
      for (z2_idx = 0; z2_idx < (NTT_N / 4); z2_idx++) begin
        if (z2_idx < effective_n4) begin
          acc = acc ^
                poly_vec[(z2_idx + 0*effective_n4)*COEFF_W] ^
                poly_vec[(z2_idx + 1*effective_n4)*COEFF_W] ^
                poly_vec[(z2_idx + 2*effective_n4)*COEFF_W] ^
                poly_vec[(z2_idx + 3*effective_n4)*COEFF_W];
        end
      end
      keygen_z2_noninvertible = ~acc;
    end
  endfunction

  function automatic logic keygen_zq_noninvertible(
    input logic [31:0] active_n_i,
    input logic signed [NTT_N*COEFF_W-1:0] ntt_vec
  );
    integer zq_group_idx;
    integer zq_sum;
    integer effective_n;
    integer base_idx;
    begin
      effective_n = active_n_i;
      if (effective_n > NTT_N) begin
        effective_n = NTT_N;
      end
      keygen_zq_noninvertible = 1'b0;
      for (zq_group_idx = 0; zq_group_idx < (NTT_N / 4); zq_group_idx++) begin
        base_idx = zq_group_idx * 4;
        if (base_idx < effective_n) begin
          zq_sum =
            $signed(ntt_vec[(base_idx + 0)*COEFF_W +: COEFF_W]) +
            $signed(ntt_vec[(base_idx + 1)*COEFF_W +: COEFF_W]) +
            $signed(ntt_vec[(base_idx + 2)*COEFF_W +: COEFF_W]) +
            $signed(ntt_vec[(base_idx + 3)*COEFF_W +: COEFF_W]);
          if (zq_sum == 0) begin
            keygen_zq_noninvertible = 1'b1;
          end
        end
      end
    end
  endfunction

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

  zen_keypair_pack_seq_core u_keypair_pack_seq_core (
    .clk(clk),
    .rst_n(rst_n),
    .start_i(keypair_pack_start),
    .pk_poly_ready_i(pk_poly_ready),
    .pk_poly_ready_coeffs_i(pkpoly_ready_coeffs_r),
    .sk_f2_ready_coeffs_i(f2_ready_coeffs_r),
    .pk_poly_vec_i(pkpoly_vec),
    .sk_f_ntt_poly_vec_i(f_nttmq_vec),
    .sk_f2_poly_vec_i(f2_vec),
    .busy_o(keypair_pack_busy),
    .done_o(keypair_pack_done),
    .pk_bytes_vec_o(keypair_pack_pk_bytes_vec_out),
    .sk_lo_bytes_vec_o(keypair_pack_sk_lo_bytes_vec_out),
    .sk_hi_bytes_vec_o(keypair_pack_sk_hi_bytes_vec_out),
    .bytes_produced0_o(keypair_pack_bytes_produced0),
    .bytes_produced1_o(keypair_pack_bytes_produced1)
  );

  assign out_bytes0_o = active_pk_pack_bytes_r;
  assign out_bytes1_o = active_sk_pack_bytes_r;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      pke_keygen_state <= PKE_KEYGEN_IDLE;
      sample_cfg_base_r <= '0;
      len_r <= '0;
      buf_a_sel_r <= '0;
      buf_b_sel_r <= '0;
      buf_r_sel_r <= '0;
      active_writeback_rows_r <= ACTIVE_WRITEBACK_ROWS_CONST;
      active_stream_rows_r <= ACTIVE_STREAM_ROWS_CONST;
      active_f2_stream_rows_r <= ACTIVE_F2_STREAM_ROWS_CONST;
      active_n_r <= ACTIVE_N_CONST;
      active_n4_r <= ACTIVE_N4_CONST;
      active_pk_pack_bytes_r <= ACTIVE_PK_PACK_BYTES_CONST;
      active_sk_pack_bytes_r <= ACTIVE_SK_PACK_BYTES_CONST;
      f2_ready_coeffs_r <= 32'd0;
      pkpoly_ready_coeffs_r <= 32'd0;
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
      sample_g_ready <= 1'b0;
      sample_g_started_early_r <= 1'b0;
      sample_g_nonce_bumped_r <= 1'b0;
      baseinv_ready <= 1'b0;
      fast_inv_ready <= 1'b0;
      fast_inv_started_r <= 1'b0;
      pk_poly_ready <= 1'b0;
      keypair_pack_ready <= 1'b0;
      f_z2_noninvertible_r <= 1'b0;
      f_zq_noninvertible_r <= 1'b0;
      g_zq_noninvertible_r <= 1'b0;
      f_inv_ntt_row_ready_r <= '0;
      f2_row_ready_r <= '0;
      g_nttmq_row_ready_r <= '0;
      pkpoly_row_ready_r <= '0;
    end else begin
      pke_keygen_state <= pke_keygen_state_n;

      if ((pke_keygen_state == PKE_KEYGEN_IDLE) && start_i) begin
        sample_cfg_base_r <= 32'h8000_0000 | {16'h0, cfg_i[15:0]};
        len_r <= len_i;
        buf_a_sel_r <= buf_a_sel_i;
        buf_b_sel_r <= buf_b_sel_i;
        buf_r_sel_r <= buf_r_sel_i;
        active_writeback_rows_r <= ACTIVE_WRITEBACK_ROWS_CONST;
        active_stream_rows_r <= ACTIVE_STREAM_ROWS_CONST;
        active_f2_stream_rows_r <= ACTIVE_F2_STREAM_ROWS_CONST;
        active_n_r <= ACTIVE_N_CONST;
        active_n4_r <= ACTIVE_N4_CONST;
        active_pk_pack_bytes_r <= ACTIVE_PK_PACK_BYTES_CONST;
        active_sk_pack_bytes_r <= ACTIVE_SK_PACK_BYTES_CONST;
        f2_ready_coeffs_r <= 32'd0;
        pkpoly_ready_coeffs_r <= 32'd0;
        sample_g_ready <= 1'b0;
        sample_g_started_early_r <= 1'b0;
        sample_g_nonce_bumped_r <= 1'b0;
        baseinv_ready <= 1'b0;
        fast_inv_ready <= 1'b0;
        fast_inv_started_r <= 1'b0;
        pk_poly_ready <= 1'b0;
        keypair_pack_ready <= 1'b0;
        f_z2_noninvertible_r <= 1'b0;
        f_zq_noninvertible_r <= 1'b0;
        g_zq_noninvertible_r <= 1'b0;
        f_inv_ntt_row_ready_r <= '0;
        f2_row_ready_r <= '0;
        g_nttmq_row_ready_r <= '0;
        pkpoly_row_ready_r <= '0;
        f_inv_ntt_vec <= '0;
        f2_vec <= '0;
      end

      if ((pke_keygen_state == PKE_KEYGEN_IDLE) && start_i) begin
        nonce_cur <= 8'd0;
        fast_inv_started_r <= 1'b0;
        sample_g_started_early_r <= 1'b0;
        sample_g_nonce_bumped_r <= 1'b0;
      end else if (sampler_start_o && (sample_cmd_o == CMD_SAMPLE_F)) begin
        fast_inv_started_r <= 1'b0;
        sample_g_started_early_r <= 1'b0;
        sample_g_nonce_bumped_r <= 1'b0;
      end else if (sampler_start_o && (sample_cmd_o == CMD_SAMPLE_G)) begin
        sample_g_started_early_r <= (pke_keygen_state == PKE_KEYGEN_CHECK_F_Z2);
        sample_g_nonce_bumped_r <= 1'b0;
        sample_g_ready <= 1'b0;
        g_nttmq_row_ready_r <= '0;
      end else if (baseinv_start_o) begin
        baseinv_ready <= 1'b0;
        f_inv_ntt_row_ready_r <= '0;
      end else if (binary_start_o && (arith_cmd_o == CMD_FAST_INV)) begin
        fast_inv_ready <= 1'b0;
        fast_inv_started_r <= 1'b1;
        f2_row_ready_r <= '0;
        f2_ready_coeffs_r <= 32'd0;
      end else if (ntt_start_o &&
                   ((pke_keygen_state == PKE_KEYGEN_WAIT_FAST_INV_F) ||
                    (pke_keygen_state == PKE_KEYGEN_WAIT_SAMPLE_G) ||
                    (pke_keygen_state == PKE_KEYGEN_LAUNCH_NTT_G))) begin
        g_nttmq_row_ready_r <= '0;
      end else if (basemul_start_o) begin
        pk_poly_ready <= 1'b0;
        pkpoly_row_ready_r <= '0;
        pkpoly_ready_coeffs_r <= 32'd0;
      end else if ((pke_keygen_state == PKE_KEYGEN_WAIT_SAMPLE_F) &&
                   sampler_done_i && sampler_vec_out_valid_i) begin
        nonce_cur <= nonce_cur + 1'b1;
      end else if (((pke_keygen_state == PKE_KEYGEN_WAIT_BASEINV_F) ||
                    (pke_keygen_state == PKE_KEYGEN_WAIT_FAST_INV_F) ||
                    (pke_keygen_state == PKE_KEYGEN_WAIT_SAMPLE_G)) &&
                   sampler_done_i && sampler_vec_out_valid_i &&
                   !sample_g_started_early_r) begin
        nonce_cur <= nonce_cur + 1'b1;
      end else if ((pke_keygen_state == PKE_KEYGEN_CHECK_F_ZQ) &&
                   !f_zq_noninvertible_r &&
                   sample_g_started_early_r &&
                   !sample_g_nonce_bumped_r) begin
        nonce_cur <= nonce_cur + 1'b1;
        sample_g_nonce_bumped_r <= 1'b1;
      end

      if (baseinv_row_valid_i && (baseinv_row_idx_i < active_stream_rows_r)) begin
        f_inv_ntt_row_ready_r[baseinv_row_idx_i] <= 1'b1;
        for (keygen_coeff_idx = 0; keygen_coeff_idx < KEYGEN_STREAM_ROW_COEFFS; keygen_coeff_idx++) begin
          int coeff_idx_local;
          coeff_idx_local = ($unsigned(baseinv_row_idx_i) * KEYGEN_STREAM_ROW_COEFFS) + keygen_coeff_idx;
          if (coeff_idx_local < active_n_r) begin
            f_inv_ntt_vec[coeff_idx_local*COEFF_W +: COEFF_W] <=
              baseinv_row_data_i[keygen_coeff_idx*COEFF_W +: COEFF_W];
          end
        end
      end

      if (binary_row_valid_i && (binary_row_idx_i < active_f2_stream_rows_r)) begin
        f2_row_ready_r[binary_row_idx_i] <= 1'b1;
        f2_ready_coeffs_r <= keygen_ready_coeff_limit(active_n4_r, $unsigned(binary_row_idx_i));
        for (keygen_coeff_idx = 0; keygen_coeff_idx < KEYGEN_STREAM_ROW_COEFFS; keygen_coeff_idx++) begin
          int coeff_idx_local;
          coeff_idx_local = ($unsigned(binary_row_idx_i) * KEYGEN_STREAM_ROW_COEFFS) + keygen_coeff_idx;
          if (coeff_idx_local < active_n4_r) begin
            f2_vec[coeff_idx_local*COEFF_W +: COEFF_W] <=
              binary_row_data_i[keygen_coeff_idx*COEFF_W +: COEFF_W];
          end
        end
      end

      if (basemul_row_valid_i && (basemul_row_idx_i < active_stream_rows_r)) begin
        pkpoly_row_ready_r[basemul_row_idx_i] <= 1'b1;
        pkpoly_ready_coeffs_r <= keygen_ready_coeff_limit(active_n_r, $unsigned(basemul_row_idx_i));
        for (keygen_coeff_idx = 0; keygen_coeff_idx < KEYGEN_STREAM_ROW_COEFFS; keygen_coeff_idx++) begin
          int coeff_idx_local;
          coeff_idx_local = ($unsigned(basemul_row_idx_i) * KEYGEN_STREAM_ROW_COEFFS) + keygen_coeff_idx;
          if (coeff_idx_local < active_n_r) begin
            pkpoly_vec[coeff_idx_local*COEFF_W +: COEFF_W] <=
              basemul_row_data_i[keygen_coeff_idx*COEFF_W +: COEFF_W];
          end
        end
      end

      if ((pke_keygen_state == PKE_KEYGEN_WAIT_SAMPLE_F) &&
          sampler_done_i && sampler_vec_out_valid_i) begin
        f_vec <= sampler_vec_out_i;
        f_z2_noninvertible_r <= keygen_z2_noninvertible(active_n4_r, sampler_vec_out_i);
      end else if ((pke_keygen_state == PKE_KEYGEN_WAIT_NTT_F) &&
                   ntt_done_i && ntt_vec_out_valid_i) begin
        f_nttmq_vec <= ntt_vec_out_i;
        f_zq_noninvertible_r <= keygen_zq_noninvertible(active_n_r, ntt_vec_out_i);
      end

      if (!baseinv_ready && baseinv_done_i && baseinv_vec_out_valid_i) begin
        baseinv_ready <= 1'b1;
        for (keygen_row_idx = 0; keygen_row_idx < KEYGEN_VEC_ROW_COUNT; keygen_row_idx++) begin
          if (keygen_row_idx < active_stream_rows_r) begin
            f_inv_ntt_row_ready_r[keygen_row_idx] <= 1'b1;
          end
        end
      end

      if (!fast_inv_ready && binary_done_i && binary_vec_out_valid_i) begin
        fast_inv_ready <= 1'b1;
        f2_ready_coeffs_r <= active_n4_r;
        for (keygen_row_idx = 0; keygen_row_idx < KEYGEN_F2_ROW_COUNT; keygen_row_idx++) begin
          if (keygen_row_idx < active_f2_stream_rows_r) begin
            f2_row_ready_r[keygen_row_idx] <= 1'b1;
          end
        end
      end

      if ((pke_keygen_state == PKE_KEYGEN_WAIT_NTT_G) &&
          ntt_done_i && ntt_vec_out_valid_i) begin
        g_nttmq_vec <= ntt_vec_out_i;
        g_zq_noninvertible_r <= keygen_zq_noninvertible(active_n_r, ntt_vec_out_i);
        g_nttmq_row_ready_r <= '0;
        for (keygen_row_idx = 0; keygen_row_idx < KEYGEN_VEC_ROW_COUNT; keygen_row_idx++) begin
          if (keygen_row_idx < active_stream_rows_r) begin
            g_nttmq_row_ready_r[keygen_row_idx] <= 1'b1;
          end
        end
      end

      if ((pke_keygen_state == PKE_KEYGEN_WAIT_BASEMUL) &&
          basemul_done_i && basemul_vec_out_valid_i) begin
        pk_poly_ready <= 1'b1;
        for (keygen_row_idx = 0; keygen_row_idx < KEYGEN_VEC_ROW_COUNT; keygen_row_idx++) begin
          if (keygen_row_idx < active_stream_rows_r) begin
            pkpoly_row_ready_r[keygen_row_idx] <= 1'b1;
          end
        end
        pkpoly_ready_coeffs_r <= active_n_r;
      end

      if (keypair_pack_done) begin
        pk_packed_vec <= keypair_pack_pk_bytes_vec_out;
        sk_lo_vec <= keypair_pack_sk_lo_bytes_vec_out;
        sk_hi_vec <= keypair_pack_sk_hi_bytes_vec_out;
        pk_wr_row <= '0;
        sk_lo_wr_row <= '0;
        sk_hi_wr_row <= '0;
        keypair_pack_ready <= 1'b1;
      end else if (pke_keygen_state == PKE_KEYGEN_WRITEBACK_PK) begin
        if (pk_wr_row + 1 < active_writeback_rows_r) begin
          pk_wr_row <= pk_wr_row + 1'b1;
        end else begin
          pk_wr_row <= '0;
        end
      end else if (pke_keygen_state == PKE_KEYGEN_WRITEBACK_SK_LO) begin
        if (sk_lo_wr_row + 1 < active_writeback_rows_r) begin
          sk_lo_wr_row <= sk_lo_wr_row + 1'b1;
        end else begin
          sk_lo_wr_row <= '0;
        end
      end else if (pke_keygen_state == PKE_KEYGEN_WRITEBACK_SK_HI) begin
        if (sk_hi_wr_row + 1 < active_writeback_rows_r) begin
          sk_hi_wr_row <= sk_hi_wr_row + 1'b1;
        end else begin
          sk_hi_wr_row <= '0;
        end
      end

      if (sampler_done_i && sampler_vec_out_valid_i &&
          (((pke_keygen_state == PKE_KEYGEN_WAIT_NTT_F) &&
            sample_g_started_early_r) ||
           (pke_keygen_state == PKE_KEYGEN_WAIT_BASEINV_F) ||
           (pke_keygen_state == PKE_KEYGEN_WAIT_FAST_INV_F) ||
           (pke_keygen_state == PKE_KEYGEN_WAIT_SAMPLE_G))) begin
        g_vec <= sampler_vec_out_i;
        sample_g_ready <= 1'b1;
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
    vec_wr_en_o = 1'b0;
    vec_wr_buf_sel_o = buf_r_sel_i;
    vec_wr_row_o = pk_wr_row;
    vec_wr_data_o = '0;
    keypair_pack_start = 1'b0;
    pke_keygen_state_n = pke_keygen_state;

      unique case (pke_keygen_state)
      PKE_KEYGEN_IDLE: begin
        if (start_i) begin
          sampler_seed_active_o = 1'b1;
          sampler_start_o = 1'b1;
          sample_cmd_o = CMD_SAMPLE_F;
          sample_cfg_o = 32'h8000_0000 | {16'h0, cfg_i[15:0]};
          sample_len_o = len_i;
          sample_buf_r_sel_o = buf_b_sel_i;
          pke_keygen_state_n = PKE_KEYGEN_WAIT_SAMPLE_F;
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
        if (f_z2_noninvertible_r) begin
          sampler_seed_active_o = 1'b1;
          sampler_start_o = 1'b1;
          sample_cmd_o = CMD_SAMPLE_F;
          sample_cfg_o = sample_cfg_base_r | ({24'h0, nonce_cur} << 16);
          sample_len_o = len_r;
          sample_buf_r_sel_o = buf_b_sel_r;
          pke_keygen_state_n = PKE_KEYGEN_WAIT_SAMPLE_F;
        end else begin
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
      end

      PKE_KEYGEN_LAUNCH_NTT_F: begin
        vec_in_a_o = f_vec;
        vec_in_b_o = '0;
        arith_cmd_o = CMD_NTT_MQ;
        vec_in_valid_o = 1'b1;
        ntt_start_o = 1'b1;
        pke_keygen_state_n = PKE_KEYGEN_WAIT_NTT_F;
      end

      PKE_KEYGEN_WAIT_NTT_F: begin
        if (!sample_g_ready) begin
          sampler_seed_active_o = 1'b1;
          sample_cmd_o = CMD_SAMPLE_G;
          sample_cfg_o = sample_cfg_base_r | ({24'h0, nonce_cur} << 16);
          sample_len_o = len_r;
          sample_buf_r_sel_o = buf_b_sel_r;
        end
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
        if (f_zq_noninvertible_r) begin
          sampler_seed_active_o = 1'b1;
          sampler_start_o = 1'b1;
          sample_cmd_o = CMD_SAMPLE_F;
          sample_cfg_o = sample_cfg_base_r | ({24'h0, nonce_cur} << 16);
          sample_len_o = len_r;
          sample_buf_r_sel_o = buf_b_sel_r;
          pke_keygen_state_n = PKE_KEYGEN_WAIT_SAMPLE_F;
        end else begin
          if (!sample_g_started_early_r) begin
            sampler_seed_active_o = 1'b1;
            sampler_start_o = 1'b1;
            sample_cmd_o = CMD_SAMPLE_G;
            sample_cfg_o = sample_cfg_base_r | ({24'h0, nonce_cur} << 16);
            sample_len_o = len_r;
            sample_buf_r_sel_o = buf_b_sel_r;
          end
          vec_in_a_o = f_nttmq_vec;
          vec_in_b_o = '0;
          arith_cmd_o = CMD_BASEINV;
          vec_in_valid_o = 1'b1;
          baseinv_start_o = 1'b1;
          keypair_pack_start = 1'b1;
          pke_keygen_state_n = PKE_KEYGEN_WAIT_BASEINV_F;
        end
      end

      PKE_KEYGEN_LAUNCH_BASEINV_F: begin
        sampler_seed_active_o = 1'b1;
        sampler_start_o = 1'b1;
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
        pke_keygen_state_n = PKE_KEYGEN_LAUNCH_FAST_INV_F;
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
          vec_in_a_o = g_vec;
          vec_in_b_o = '0;
          arith_cmd_o = CMD_NTT_MQ;
          vec_in_valid_o = 1'b1;
          ntt_start_o = 1'b1;
          pke_keygen_state_n = PKE_KEYGEN_WAIT_NTT_G;
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
          vec_in_a_o = sampler_vec_out_i;
          vec_in_b_o = '0;
          arith_cmd_o = CMD_NTT_MQ;
          vec_in_valid_o = 1'b1;
          ntt_start_o = 1'b1;
          pke_keygen_state_n = PKE_KEYGEN_WAIT_NTT_G;
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
        end else if (g_zq_noninvertible_r) begin
          sampler_seed_active_o = 1'b1;
          sampler_start_o = 1'b1;
          sample_cmd_o = CMD_SAMPLE_G;
          sample_cfg_o = sample_cfg_base_r | ({24'h0, nonce_cur} << 16);
          sample_len_o = len_r;
          sample_buf_r_sel_o = buf_b_sel_r;
          pke_keygen_state_n = PKE_KEYGEN_WAIT_SAMPLE_G;
        end else if (baseinv_ready) begin
          vec_in_a_o = g_nttmq_vec;
          vec_in_b_o = f_inv_ntt_vec;
          arith_cmd_o = CMD_BASEMUL_MQ;
          vec_in_valid_o = 1'b1;
          basemul_start_o = 1'b1;
          pke_keygen_state_n = PKE_KEYGEN_WAIT_BASEMUL;
        end else begin
          pke_keygen_state_n = PKE_KEYGEN_CHECK_G_ZQ;
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
          pke_keygen_state_n = PKE_KEYGEN_WAIT_PREP_OUT;
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
        end else if (keypair_pack_ready) begin
          pke_keygen_state_n = PKE_KEYGEN_WRITEBACK_PK;
        end
      end

      PKE_KEYGEN_WRITEBACK_PK: begin
        vec_wr_en_o = 1'b1;
        vec_wr_buf_sel_o = buf_a_sel_r;
        vec_wr_row_o = pk_wr_row;
        for (wr_bank_idx = 0; wr_bank_idx < BUF_BANKS; wr_bank_idx++) begin
          vec_wr_data_o[wr_bank_idx*COEFF_W +: COEFF_W] =
            pk_packed_vec[(pk_wr_row * BUF_BANKS + wr_bank_idx) * COEFF_W +: COEFF_W];
        end
        if (pk_wr_row + 1 >= active_writeback_rows_r) begin
          pke_keygen_state_n = PKE_KEYGEN_WRITEBACK_SK_LO;
        end
      end

      PKE_KEYGEN_WRITEBACK_SK_LO: begin
        vec_wr_en_o = 1'b1;
        vec_wr_buf_sel_o = buf_b_sel_r;
        vec_wr_row_o = sk_lo_wr_row;
        for (wr_bank_idx = 0; wr_bank_idx < BUF_BANKS; wr_bank_idx++) begin
          vec_wr_data_o[wr_bank_idx*COEFF_W +: COEFF_W] =
            sk_lo_vec[(sk_lo_wr_row * BUF_BANKS + wr_bank_idx) * COEFF_W +: COEFF_W];
        end
        if (sk_lo_wr_row + 1 >= active_writeback_rows_r) begin
          if (active_sk_pack_bytes_r > active_n_r) begin
            pke_keygen_state_n = PKE_KEYGEN_WRITEBACK_SK_HI;
          end else begin
            busy_o = 1'b0;
            done_o = 1'b1;
            pke_keygen_state_n = PKE_KEYGEN_IDLE;
          end
        end
      end

      PKE_KEYGEN_WRITEBACK_SK_HI: begin
        vec_wr_en_o = 1'b1;
        vec_wr_buf_sel_o = buf_r_sel_r;
        vec_wr_row_o = sk_hi_wr_row;
        for (wr_bank_idx = 0; wr_bank_idx < BUF_BANKS; wr_bank_idx++) begin
          vec_wr_data_o[wr_bank_idx*COEFF_W +: COEFF_W] =
            sk_hi_vec[(sk_hi_wr_row * BUF_BANKS + wr_bank_idx) * COEFF_W +: COEFF_W];
        end
        if (sk_hi_wr_row + 1 >= active_writeback_rows_r) begin
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
