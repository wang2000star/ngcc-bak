module zen_pke_dec_core (
  input  logic clk,
  input  logic rst_n,

  input  logic        start_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [2:0]  buf_a_sel_i,
  input  logic [2:0]  buf_b_sel_i,
  input  logic [2:0]  buf_r_sel_i,

  input  zen_accel_pkg::zen_buf_row_t vec_rd0_row_data_i,
  input  zen_accel_pkg::zen_buf_row_t vec_rd1_row_data_i,

  input  logic binary_done_i,
  input  logic binary_error_i,
  input  logic binary_vec_out_valid_i,
  input  zen_accel_pkg::zen_poly_vec_t binary_vec_out_i,

  input  logic ntt_done_i,
  input  logic ntt_error_i,
  input  logic ntt_vec_out_valid_i,
  input  zen_accel_pkg::zen_poly_vec_t ntt_vec_out_i,

  input  logic basemul_done_i,
  input  logic basemul_error_i,
  input  logic basemul_vec_out_valid_i,
  input  zen_accel_pkg::zen_poly_vec_t basemul_vec_out_i,

  output logic busy_o,
  output logic done_o,
  output logic error_o,
  output logic [7:0] errcode_o,
  output logic [31:0] out_bytes0_o,
  output logic [31:0] out_bytes1_o,

  output logic [2:0] vec_rd0_buf_sel_o,
  output logic [2:0] vec_rd1_buf_sel_o,
  output zen_accel_pkg::zen_row_addr_t vec_rd_row_o,

  output logic binary_start_o,
  output logic ntt_start_o,
  output logic basemul_start_o,
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

  localparam logic [7:0] ERR_CT_DECOMP = 8'h30;
  localparam logic [7:0] ERR_NTT       = 8'h31;
  localparam logic [7:0] ERR_BASEMUL   = 8'h32;
  localparam logic [7:0] ERR_INTT      = 8'h33;
  localparam logic [7:0] ERR_POSTPROC  = 8'h34;

  typedef enum logic [4:0] {
    PKE_DEC_IDLE,
    PKE_DEC_PREFETCH_AB,
    PKE_DEC_PREFETCH_F2,
    PKE_DEC_PREP_SK,
    PKE_DEC_WAIT_PREP_SK,
    PKE_DEC_LAUNCH_CT_DECOMP,
    PKE_DEC_WAIT_CT_DECOMP,
    PKE_DEC_LAUNCH_NTT,
    PKE_DEC_WAIT_NTT,
    PKE_DEC_LAUNCH_BASEMUL,
    PKE_DEC_WAIT_BASEMUL,
    PKE_DEC_LAUNCH_INTT,
    PKE_DEC_WAIT_INTT,
    PKE_DEC_LAUNCH_POST,
    PKE_DEC_WAIT_POST,
    PKE_DEC_LAUNCH_PACK,
    PKE_DEC_WAIT_PACK,
    PKE_DEC_WRITEBACK,
    PKE_DEC_WAIT_SK_READY
  } pke_dec_state_t;

  pke_dec_state_t pke_dec_state, pke_dec_state_n;

  logic raw_sk_mode;
  logic signed [NTT_N*COEFF_W-1:0] ct_packed_vec;
  logic signed [NTT_N*COEFF_W-1:0] sk_lo_vec;
  logic signed [NTT_N*COEFF_W-1:0] sk_hi_vec;
  logic signed [NTT_N*COEFF_W-1:0] f_ntt_vec;
  logic signed [NTT_N*COEFF_W-1:0] f2_vec;
  logic signed [NTT_N*COEFF_W-1:0] stage_vec;
  logic [ADDR_W-1:0] wr_row;

  logic [1:0] msg_codec_op;
  logic signed [NTT_N*COEFF_W-1:0] msg_codec_vec_out;
  logic signed [NTT_N*COEFF_W-1:0] sk_unpack_sk_f_ntt_poly_vec_out;
  logic signed [NTT_N*COEFF_W-1:0] sk_unpack_sk_f2_poly_vec_out;
  logic sk_unpack_busy;
  logic sk_unpack_done;
  logic sk_unpack_ready;
  logic [31:0] sk_unpack_bytes_consumed;
  logic [31:0] active_writeback_rows;
  logic dec_prefetch_ab_start;
  logic dec_prefetch_f2_start;
  logic dec_prefetch_active;
  logic dec_prefetch_load;
  logic dec_prefetch_done;
  logic [ADDR_W-1:0] dec_prefetch_row;
  logic [ADDR_W-1:0] dec_prefetch_load_row;
  integer prefetch_bank_idx;
  integer wr_bank_idx;
  localparam int ACTIVE_WRITEBACK_ROWS_CONST = NTT_N / BUF_BANKS;
  localparam int OUT_BYTES0_CONST = zen_swift_profile_pkg::SWIFT_INDCPA_MSG_LEN_BYTES;

  assign active_writeback_rows = ACTIVE_WRITEBACK_ROWS_CONST;

  zen_vec_prefetch_ctrl u_dec_prefetch_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .start_i(dec_prefetch_ab_start || dec_prefetch_f2_start),
    .rows_i(ADDR_W'(active_writeback_rows)),
    .active_o(dec_prefetch_active),
    .load_o(dec_prefetch_load),
    .done_o(dec_prefetch_done),
    .req_row_o(dec_prefetch_row),
    .load_row_o(dec_prefetch_load_row)
  );

  zen_msg_codec u_msg_codec (
    .op(msg_codec_op),
    .msg_bytes_vec_i('0),
    .msg_poly_vec_i(stage_vec),
    .vec_out_o(msg_codec_vec_out),
    .bytes_consumed_o(),
    .bytes_produced_o()
  );

  zen_sk_unpack_seq_core u_sk_unpack_seq_core (
    .clk(clk),
    .rst_n(rst_n),
    .start_i(pke_dec_state == PKE_DEC_PREP_SK),
    .sk_lo_bytes_vec_i(sk_lo_vec),
    .sk_hi_bytes_vec_i(sk_hi_vec),
    .busy_o(sk_unpack_busy),
    .done_o(sk_unpack_done),
    .sk_f_ntt_poly_vec_o(sk_unpack_sk_f_ntt_poly_vec_out),
    .sk_f2_poly_vec_o(sk_unpack_sk_f2_poly_vec_out),
    .bytes_consumed_o(sk_unpack_bytes_consumed)
  );

  assign raw_sk_mode = cfg_i[31];
  assign msg_codec_op = (pke_dec_state == PKE_DEC_LAUNCH_PACK) ? 2'd1 : 2'd0;
  assign out_bytes0_o = OUT_BYTES0_CONST;
  assign out_bytes1_o = 32'h0;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      pke_dec_state <= PKE_DEC_IDLE;
      ct_packed_vec <= '0;
      sk_lo_vec <= '0;
      sk_hi_vec <= '0;
      f_ntt_vec <= '0;
      f2_vec <= '0;
      sk_unpack_ready <= 1'b0;
      stage_vec <= '0;
      wr_row <= '0;
    end else begin
      pke_dec_state <= pke_dec_state_n;

      if (dec_prefetch_ab_start) begin
        ct_packed_vec <= '0;
        sk_unpack_ready <= 1'b0;
        if (raw_sk_mode) begin
          sk_lo_vec <= '0;
        end else begin
          f_ntt_vec <= '0;
        end
      end

      if (dec_prefetch_f2_start) begin
        if (raw_sk_mode) begin
          sk_hi_vec <= '0;
        end else begin
          f2_vec <= '0;
        end
      end

      if (dec_prefetch_load) begin
        for (prefetch_bank_idx = 0; prefetch_bank_idx < BUF_BANKS; prefetch_bank_idx++) begin
          if (pke_dec_state == PKE_DEC_PREFETCH_AB) begin
            ct_packed_vec[((dec_prefetch_load_row * BUF_BANKS) + prefetch_bank_idx) * COEFF_W +: COEFF_W]
              <= vec_rd0_row_data_i[prefetch_bank_idx*COEFF_W +: COEFF_W];
            if (raw_sk_mode) begin
              sk_lo_vec[((dec_prefetch_load_row * BUF_BANKS) + prefetch_bank_idx) * COEFF_W +: COEFF_W]
                <= vec_rd1_row_data_i[prefetch_bank_idx*COEFF_W +: COEFF_W];
            end else begin
              f_ntt_vec[((dec_prefetch_load_row * BUF_BANKS) + prefetch_bank_idx) * COEFF_W +: COEFF_W]
                <= vec_rd1_row_data_i[prefetch_bank_idx*COEFF_W +: COEFF_W];
            end
          end else if (pke_dec_state == PKE_DEC_PREFETCH_F2) begin
            if (raw_sk_mode) begin
              sk_hi_vec[((dec_prefetch_load_row * BUF_BANKS) + prefetch_bank_idx) * COEFF_W +: COEFF_W]
                <= vec_rd0_row_data_i[prefetch_bank_idx*COEFF_W +: COEFF_W];
            end else begin
              f2_vec[((dec_prefetch_load_row * BUF_BANKS) + prefetch_bank_idx) * COEFF_W +: COEFF_W]
                <= vec_rd0_row_data_i[prefetch_bank_idx*COEFF_W +: COEFF_W];
            end
          end
        end
      end else if (pke_dec_state == PKE_DEC_LAUNCH_PACK) begin
        stage_vec <= msg_codec_vec_out;
        wr_row <= '0;
      end

      if (sk_unpack_done) begin
        f_ntt_vec <= sk_unpack_sk_f_ntt_poly_vec_out;
        f2_vec <= sk_unpack_sk_f2_poly_vec_out;
        sk_unpack_ready <= 1'b1;
      end

      if ((pke_dec_state == PKE_DEC_WAIT_CT_DECOMP) && binary_done_i && binary_vec_out_valid_i) begin
        stage_vec <= binary_vec_out_i;
      end else if ((pke_dec_state == PKE_DEC_WAIT_NTT) && ntt_done_i && ntt_vec_out_valid_i) begin
        stage_vec <= ntt_vec_out_i;
      end else if ((pke_dec_state == PKE_DEC_WAIT_BASEMUL) && basemul_done_i && basemul_vec_out_valid_i) begin
        stage_vec <= basemul_vec_out_i;
      end else if ((pke_dec_state == PKE_DEC_WAIT_INTT) && ntt_done_i && ntt_vec_out_valid_i) begin
        stage_vec <= ntt_vec_out_i;
      end else if ((pke_dec_state == PKE_DEC_WAIT_POST) && binary_done_i && binary_vec_out_valid_i) begin
        stage_vec <= binary_vec_out_i;
      end else if (pke_dec_state == PKE_DEC_WRITEBACK) begin
        if (wr_row + 1 < active_writeback_rows) begin
          wr_row <= wr_row + 1'b1;
        end else begin
          wr_row <= '0;
        end
      end
    end
  end

  always_comb begin
    busy_o = (pke_dec_state != PKE_DEC_IDLE);
    done_o = 1'b0;
    error_o = 1'b0;
    errcode_o = 8'h00;
    vec_rd0_buf_sel_o = 3'd0;
    vec_rd1_buf_sel_o = 3'd0;
    vec_rd_row_o = '0;
    dec_prefetch_ab_start = 1'b0;
    dec_prefetch_f2_start = 1'b0;
    binary_start_o = 1'b0;
    ntt_start_o = 1'b0;
    basemul_start_o = 1'b0;
    arith_cmd_o = CMD_NOP;
    vec_in_valid_o = 1'b0;
    vec_in_a_o = '0;
    vec_in_b_o = '0;
    vec_wr_en_o = 1'b0;
    vec_wr_buf_sel_o = buf_r_sel_i;
    vec_wr_row_o = wr_row;
    vec_wr_data_o = '0;
    pke_dec_state_n = pke_dec_state;

    unique case (pke_dec_state)
      PKE_DEC_IDLE: begin
        if (start_i) begin
          dec_prefetch_ab_start = 1'b1;
          pke_dec_state_n = PKE_DEC_PREFETCH_AB;
        end
      end

      PKE_DEC_PREFETCH_AB: begin
        vec_rd0_buf_sel_o = buf_a_sel_i;
        vec_rd1_buf_sel_o = buf_b_sel_i;
        vec_rd_row_o = dec_prefetch_row;
        if (dec_prefetch_done) begin
          dec_prefetch_f2_start = 1'b1;
          pke_dec_state_n = PKE_DEC_PREFETCH_F2;
        end
      end

      PKE_DEC_PREFETCH_F2: begin
        vec_rd0_buf_sel_o = cfg_i[2:0];
        vec_rd1_buf_sel_o = 3'd0;
        vec_rd_row_o = dec_prefetch_row;
        if (dec_prefetch_done) begin
          if (raw_sk_mode) begin
            pke_dec_state_n = PKE_DEC_PREP_SK;
          end else begin
            pke_dec_state_n = PKE_DEC_LAUNCH_CT_DECOMP;
          end
        end
      end

      PKE_DEC_PREP_SK: begin
        pke_dec_state_n = PKE_DEC_WAIT_PREP_SK;
      end

      PKE_DEC_WAIT_PREP_SK: begin
        pke_dec_state_n = PKE_DEC_LAUNCH_CT_DECOMP;
      end

      PKE_DEC_LAUNCH_CT_DECOMP: begin
        vec_in_a_o = ct_packed_vec;
        vec_in_b_o = '0;
        arith_cmd_o = CMD_CT_DECOMP;
        vec_in_valid_o = 1'b1;
        binary_start_o = 1'b1;
        pke_dec_state_n = PKE_DEC_WAIT_CT_DECOMP;
      end

      PKE_DEC_WAIT_CT_DECOMP: begin
        arith_cmd_o = CMD_CT_DECOMP;
        if (binary_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_CT_DECOMP;
          pke_dec_state_n = PKE_DEC_IDLE;
        end else if (binary_done_i && binary_vec_out_valid_i) begin
          pke_dec_state_n = PKE_DEC_LAUNCH_NTT;
        end
      end

      PKE_DEC_LAUNCH_NTT: begin
        vec_in_a_o = stage_vec;
        vec_in_b_o = '0;
        arith_cmd_o = CMD_NTT;
        vec_in_valid_o = 1'b1;
        ntt_start_o = 1'b1;
        pke_dec_state_n = PKE_DEC_WAIT_NTT;
      end

      PKE_DEC_WAIT_NTT: begin
        arith_cmd_o = CMD_NTT;
        if (ntt_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_NTT;
          pke_dec_state_n = PKE_DEC_IDLE;
        end else if (ntt_done_i && ntt_vec_out_valid_i) begin
          if (raw_sk_mode && !sk_unpack_ready) begin
            pke_dec_state_n = PKE_DEC_WAIT_SK_READY;
          end else begin
            pke_dec_state_n = PKE_DEC_LAUNCH_BASEMUL;
          end
        end
      end

      PKE_DEC_WAIT_SK_READY: begin
        if (sk_unpack_ready) begin
          pke_dec_state_n = PKE_DEC_LAUNCH_BASEMUL;
        end
      end

      PKE_DEC_LAUNCH_BASEMUL: begin
        vec_in_a_o = stage_vec;
        vec_in_b_o = f_ntt_vec;
        arith_cmd_o = CMD_BASEMUL;
        vec_in_valid_o = 1'b1;
        basemul_start_o = 1'b1;
        pke_dec_state_n = PKE_DEC_WAIT_BASEMUL;
      end

      PKE_DEC_WAIT_BASEMUL: begin
        arith_cmd_o = CMD_BASEMUL;
        if (basemul_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_BASEMUL;
          pke_dec_state_n = PKE_DEC_IDLE;
        end else if (basemul_done_i && basemul_vec_out_valid_i) begin
          pke_dec_state_n = PKE_DEC_LAUNCH_INTT;
        end
      end

      PKE_DEC_LAUNCH_INTT: begin
        vec_in_a_o = stage_vec;
        vec_in_b_o = '0;
        arith_cmd_o = CMD_INTT;
        vec_in_valid_o = 1'b1;
        ntt_start_o = 1'b1;
        pke_dec_state_n = PKE_DEC_WAIT_INTT;
      end

      PKE_DEC_WAIT_INTT: begin
        arith_cmd_o = CMD_INTT;
        if (ntt_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_INTT;
          pke_dec_state_n = PKE_DEC_IDLE;
        end else if (ntt_done_i && ntt_vec_out_valid_i) begin
          pke_dec_state_n = PKE_DEC_LAUNCH_POST;
        end
      end

      PKE_DEC_LAUNCH_POST: begin
        vec_in_a_o = stage_vec;
        vec_in_b_o = f2_vec;
        arith_cmd_o = CMD_DEC_POSTPROC;
        vec_in_valid_o = 1'b1;
        binary_start_o = 1'b1;
        pke_dec_state_n = PKE_DEC_WAIT_POST;
      end

      PKE_DEC_WAIT_POST: begin
        arith_cmd_o = CMD_DEC_POSTPROC;
        if (binary_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_POSTPROC;
          pke_dec_state_n = PKE_DEC_IDLE;
        end else if (binary_done_i && binary_vec_out_valid_i) begin
          pke_dec_state_n = PKE_DEC_LAUNCH_PACK;
        end
      end

      PKE_DEC_LAUNCH_PACK: begin
        pke_dec_state_n = PKE_DEC_WAIT_PACK;
      end

      PKE_DEC_WAIT_PACK: begin
        pke_dec_state_n = PKE_DEC_WRITEBACK;
      end

      PKE_DEC_WRITEBACK: begin
        vec_wr_en_o = 1'b1;
        vec_wr_buf_sel_o = buf_r_sel_i;
        vec_wr_row_o = wr_row;
        for (wr_bank_idx = 0; wr_bank_idx < BUF_BANKS; wr_bank_idx++) begin
          vec_wr_data_o[wr_bank_idx*COEFF_W +: COEFF_W] =
            stage_vec[(wr_row * BUF_BANKS + wr_bank_idx) * COEFF_W +: COEFF_W];
        end
        if (wr_row + 1 >= active_writeback_rows) begin
          busy_o = 1'b0;
          done_o = 1'b1;
          pke_dec_state_n = PKE_DEC_IDLE;
        end
      end

      default: begin
        pke_dec_state_n = PKE_DEC_IDLE;
      end
    endcase
  end

endmodule
