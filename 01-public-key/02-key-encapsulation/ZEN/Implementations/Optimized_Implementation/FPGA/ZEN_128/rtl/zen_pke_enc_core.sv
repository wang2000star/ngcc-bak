module zen_pke_enc_core (
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

  output logic busy_o,
  output logic done_o,
  output logic error_o,
  output logic [7:0] errcode_o,
  output logic [31:0] out_bytes0_o,
  output logic [31:0] out_bytes1_o,
  output logic sampler_seed_active_o,

  output logic prefetch_active_o,
  output logic [2:0] vec_rd0_buf_sel_o,
  output logic [2:0] vec_rd1_buf_sel_o,
  output zen_accel_pkg::zen_row_addr_t vec_rd_row_o,

  output logic sampler_start_o,
  output logic [7:0] sample_cmd_o,
  output logic [31:0] sample_cfg_o,
  output logic [31:0] sample_len_o,
  output logic [2:0] sample_buf_r_sel_o,

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

  localparam logic [7:0] ERR_SAMPLE_S = 8'h20;
  localparam logic [7:0] ERR_SAMPLE_E = 8'h21;
  localparam logic [7:0] ERR_NTT      = 8'h22;
  localparam logic [7:0] ERR_BASEMUL  = 8'h23;
  localparam logic [7:0] ERR_INTT     = 8'h24;

  typedef enum logic [3:0] {
    PKE_ENC_IDLE,
    PKE_ENC_PREFETCH_AB,
    PKE_ENC_PREP,
    PKE_ENC_WAIT_PREP,
    PKE_ENC_LAUNCH_SAMPLE_S,
    PKE_ENC_WAIT_SAMPLE_S,
    PKE_ENC_LAUNCH_SAMPLE_E,
    PKE_ENC_WAIT_SAMPLE_E,
    PKE_ENC_LAUNCH_NTT,
    PKE_ENC_WAIT_NTT,
    PKE_ENC_LAUNCH_BASEMUL,
    PKE_ENC_WAIT_BASEMUL,
    PKE_ENC_LAUNCH_INTT,
    PKE_ENC_WAIT_INTT,
    PKE_ENC_PREP_CT,
    PKE_ENC_WRITEBACK
  } pke_enc_state_t;

  pke_enc_state_t pke_enc_state, pke_enc_state_n;

  logic signed [NTT_N*COEFF_W-1:0] pk_packed_vec;
  logic signed [NTT_N*COEFF_W-1:0] msg_bytes_vec;
  logic signed [NTT_N*COEFF_W-1:0] h_vec;
  logic signed [NTT_N*COEFF_W-1:0] msg_poly_vec;
  logic signed [NTT_N*COEFF_W-1:0] s_vec;
  logic signed [NTT_N*COEFF_W-1:0] e_vec;
  logic signed [NTT_N*COEFF_W-1:0] stage_vec;
  logic [ADDR_W-1:0] wr_row;
  logic sample_s_ready;
  logic sample_e_ready;
  logic s_ntt_ready;

  logic [1:0] msg_codec_op;
  logic signed [NTT_N*COEFF_W-1:0] msg_codec_vec_out;
  logic signed [BUF_BANKS*COEFF_W-1:0] ct_pack_row_vec_out;
  logic signed [NTT_N*COEFF_W-1:0] pk_unpack_pk_poly_vec_out;
  logic pk_unpack_busy;
  logic pk_unpack_done;
  logic [31:0] active_writeback_rows;
  logic enc_prefetch_start;
  logic enc_prefetch_active;
  logic enc_prefetch_load;
  logic enc_prefetch_done;
  logic [ADDR_W-1:0] enc_prefetch_row;
  logic [ADDR_W-1:0] enc_prefetch_load_row;
  logic [31:0] pk_unpack_bytes_consumed;
  localparam int ACTIVE_WRITEBACK_ROWS_CONST = NTT_N / BUF_BANKS;
  localparam int OUT_BYTES0_CONST = zen_swift_profile_pkg::SWIFT_INDCPA_CIPHERTEXT_LEN_BYTES;
  assign active_writeback_rows = ACTIVE_WRITEBACK_ROWS_CONST;

  zen_vec_prefetch_ctrl u_enc_prefetch_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .start_i(enc_prefetch_start),
    .rows_i(ADDR_W'(active_writeback_rows)),
    .active_o(enc_prefetch_active),
    .load_o(enc_prefetch_load),
    .done_o(enc_prefetch_done),
    .req_row_o(enc_prefetch_row),
    .load_row_o(enc_prefetch_load_row)
  );

  zen_vec_row_loader u_pk_packed_loader (
    .clk(clk),
    .rst_n(rst_n),
    .clear_i(enc_prefetch_start),
    .load_i(enc_prefetch_load),
    .row_i(enc_prefetch_load_row),
    .row_vec_i(vec_rd0_row_data_i),
    .vec_o(pk_packed_vec)
  );

  zen_vec_row_loader u_msg_bytes_loader (
    .clk(clk),
    .rst_n(rst_n),
    .clear_i(enc_prefetch_start),
    .load_i(enc_prefetch_load),
    .row_i(enc_prefetch_load_row),
    .row_vec_i(vec_rd1_row_data_i),
    .vec_o(msg_bytes_vec)
  );

  zen_msg_codec u_msg_codec (
    .op(msg_codec_op),
    .msg_bytes_vec_i(msg_bytes_vec),
    .msg_poly_vec_i('0),
    .vec_out_o(msg_codec_vec_out),
    .bytes_consumed_o(),
    .bytes_produced_o()
  );

  zen_ct_pack_row_core u_ct_pack_row_core (
    .row_i(wr_row),
    .hs_poly_vec_i(stage_vec),
    .e_poly_vec_i(e_vec),
    .msg_poly_vec_i(msg_poly_vec),
    .row_vec_o(ct_pack_row_vec_out)
  );

  zen_pk_unpack_seq_core u_pk_unpack_seq_core (
    .clk(clk),
    .rst_n(rst_n),
    .start_i(pke_enc_state == PKE_ENC_PREP),
    .pk_bytes_vec_i(pk_packed_vec),
    .busy_o(pk_unpack_busy),
    .done_o(pk_unpack_done),
    .pk_poly_vec_o(pk_unpack_pk_poly_vec_out),
    .bytes_consumed_o(pk_unpack_bytes_consumed)
  );

  assign msg_codec_op = 2'd0;
  assign out_bytes0_o = OUT_BYTES0_CONST;
  assign out_bytes1_o = 32'h0;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      pke_enc_state <= PKE_ENC_IDLE;
      h_vec <= '0;
      msg_poly_vec <= '0;
      s_vec <= '0;
      e_vec <= '0;
      stage_vec <= '0;
      wr_row <= '0;
      sample_s_ready <= 1'b0;
      sample_e_ready <= 1'b0;
      s_ntt_ready <= 1'b0;
    end else begin
      pke_enc_state <= pke_enc_state_n;

      if (enc_prefetch_start) begin
        sample_s_ready <= 1'b0;
        sample_e_ready <= 1'b0;
        s_ntt_ready <= 1'b0;
      end

      if ((pke_enc_state == PKE_ENC_WAIT_PREP) && pk_unpack_done) begin
        h_vec <= pk_unpack_pk_poly_vec_out;
        msg_poly_vec <= msg_codec_vec_out;
      end

      if (((pke_enc_state == PKE_ENC_WAIT_PREP) ||
           (pke_enc_state == PKE_ENC_LAUNCH_SAMPLE_S) ||
           (pke_enc_state == PKE_ENC_WAIT_SAMPLE_S)) &&
          sampler_done_i && sampler_vec_out_valid_i) begin
        s_vec <= sampler_vec_out_i;
        sample_s_ready <= 1'b1;
      end

      if ((pke_enc_state == PKE_ENC_WAIT_SAMPLE_E) && sampler_done_i && sampler_vec_out_valid_i) begin
        e_vec <= sampler_vec_out_i;
        sample_e_ready <= 1'b1;
      end

      if (((pke_enc_state == PKE_ENC_WAIT_SAMPLE_E) ||
           (pke_enc_state == PKE_ENC_WAIT_NTT)) &&
          ntt_done_i && ntt_vec_out_valid_i) begin
        stage_vec <= ntt_vec_out_i;
        if (pke_enc_state == PKE_ENC_WAIT_SAMPLE_E) begin
          s_ntt_ready <= 1'b1;
        end
      end else if ((pke_enc_state == PKE_ENC_WAIT_BASEMUL) && basemul_done_i && basemul_vec_out_valid_i) begin
        stage_vec <= basemul_vec_out_i;
      end else if ((pke_enc_state == PKE_ENC_WAIT_INTT) && ntt_done_i && ntt_vec_out_valid_i) begin
        stage_vec <= ntt_vec_out_i;
      end else if (pke_enc_state == PKE_ENC_PREP_CT) begin
        wr_row <= '0;
      end else if (pke_enc_state == PKE_ENC_WRITEBACK) begin
        if (wr_row + 1 < active_writeback_rows) begin
          wr_row <= wr_row + 1'b1;
        end else begin
          wr_row <= '0;
        end
      end
    end
  end

  always_comb begin
    busy_o = (pke_enc_state != PKE_ENC_IDLE);
    done_o = 1'b0;
    error_o = 1'b0;
    errcode_o = 8'h00;
    sampler_seed_active_o = 1'b0;
    prefetch_active_o = 1'b0;
    vec_rd0_buf_sel_o = '0;
    vec_rd1_buf_sel_o = '0;
    vec_rd_row_o = '0;
    enc_prefetch_start = 1'b0;
    sampler_start_o = 1'b0;
    sample_cmd_o = CMD_NOP;
    sample_cfg_o = 32'd0;
    sample_len_o = 32'd0;
    sample_buf_r_sel_o = 3'd0;
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
    pke_enc_state_n = pke_enc_state;

    unique case (pke_enc_state)
      PKE_ENC_IDLE: begin
        if (start_i) begin
          enc_prefetch_start = 1'b1;
          pke_enc_state_n = PKE_ENC_PREFETCH_AB;
        end
      end

      PKE_ENC_PREFETCH_AB: begin
        prefetch_active_o = enc_prefetch_active;
        vec_rd0_buf_sel_o = buf_a_sel_i;
        vec_rd1_buf_sel_o = buf_b_sel_i;
        vec_rd_row_o = enc_prefetch_row;
        if (enc_prefetch_done) begin
          pke_enc_state_n = PKE_ENC_PREP;
        end
      end

      PKE_ENC_PREP: begin
        sampler_seed_active_o = 1'b1;
        sampler_start_o = 1'b1;
        sample_cmd_o = CMD_SAMPLE_S;
        sample_cfg_o = cfg_i & 32'hFF00_FFFF;
        sample_len_o = len_i;
        sample_buf_r_sel_o = buf_r_sel_i;
        pke_enc_state_n = PKE_ENC_WAIT_PREP;
      end

      PKE_ENC_WAIT_PREP: begin
        sampler_seed_active_o = 1'b1;
        sample_cmd_o = CMD_SAMPLE_S;
        sample_cfg_o = cfg_i & 32'hFF00_FFFF;
        sample_len_o = len_i;
        sample_buf_r_sel_o = buf_r_sel_i;
        if (sampler_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_SAMPLE_S;
          pke_enc_state_n = PKE_ENC_IDLE;
        end else if (pk_unpack_done) begin
          pke_enc_state_n = PKE_ENC_LAUNCH_SAMPLE_S;
        end
      end

      PKE_ENC_LAUNCH_SAMPLE_S: begin
        sampler_seed_active_o = 1'b1;
        sample_cmd_o = CMD_SAMPLE_S;
        sample_cfg_o = cfg_i & 32'hFF00_FFFF;
        sample_len_o = len_i;
        sample_buf_r_sel_o = buf_r_sel_i;
        pke_enc_state_n = PKE_ENC_WAIT_SAMPLE_S;
      end

      PKE_ENC_WAIT_SAMPLE_S: begin
        sampler_seed_active_o = 1'b1;
        sample_cmd_o = CMD_SAMPLE_S;
        sample_cfg_o = cfg_i & 32'hFF00_FFFF;
        sample_len_o = len_i;
        if (sampler_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_SAMPLE_S;
          pke_enc_state_n = PKE_ENC_IDLE;
        end else if (sample_s_ready) begin
          pke_enc_state_n = PKE_ENC_LAUNCH_SAMPLE_E;
        end
      end

      PKE_ENC_LAUNCH_SAMPLE_E: begin
        sampler_seed_active_o = 1'b1;
        sampler_start_o = 1'b1;
        sample_cmd_o = CMD_SAMPLE_E;
        sample_cfg_o = (cfg_i & 32'hFF00_FFFF) | 32'h0001_0000;
        sample_len_o = len_i;
        sample_buf_r_sel_o = buf_r_sel_i;
        vec_in_a_o = s_vec;
        vec_in_b_o = '0;
        arith_cmd_o = CMD_NTT;
        vec_in_valid_o = 1'b1;
        ntt_start_o = 1'b1;
        pke_enc_state_n = PKE_ENC_WAIT_SAMPLE_E;
      end

      PKE_ENC_WAIT_SAMPLE_E: begin
        sampler_seed_active_o = 1'b1;
        sample_cmd_o = CMD_SAMPLE_E;
        sample_cfg_o = (cfg_i & 32'hFF00_FFFF) | 32'h0001_0000;
        sample_len_o = len_i;
        if (sampler_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_SAMPLE_E;
          pke_enc_state_n = PKE_ENC_IDLE;
        end else if (ntt_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_NTT;
          pke_enc_state_n = PKE_ENC_IDLE;
        end else if (sample_e_ready && s_ntt_ready) begin
          pke_enc_state_n = PKE_ENC_LAUNCH_BASEMUL;
        end
      end

      PKE_ENC_LAUNCH_NTT: begin
        vec_in_a_o = s_vec;
        vec_in_b_o = '0;
        arith_cmd_o = CMD_NTT;
        vec_in_valid_o = 1'b1;
        ntt_start_o = 1'b1;
        pke_enc_state_n = PKE_ENC_WAIT_NTT;
      end

      PKE_ENC_WAIT_NTT: begin
        arith_cmd_o = CMD_NTT;
        if (ntt_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_NTT;
          pke_enc_state_n = PKE_ENC_IDLE;
        end else if (ntt_done_i && ntt_vec_out_valid_i) begin
          pke_enc_state_n = PKE_ENC_LAUNCH_BASEMUL;
        end
      end

      PKE_ENC_LAUNCH_BASEMUL: begin
        vec_in_a_o = h_vec;
        vec_in_b_o = stage_vec;
        arith_cmd_o = CMD_BASEMUL;
        vec_in_valid_o = 1'b1;
        basemul_start_o = 1'b1;
        pke_enc_state_n = PKE_ENC_WAIT_BASEMUL;
      end

      PKE_ENC_WAIT_BASEMUL: begin
        arith_cmd_o = CMD_BASEMUL;
        if (basemul_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_BASEMUL;
          pke_enc_state_n = PKE_ENC_IDLE;
        end else if (basemul_done_i && basemul_vec_out_valid_i) begin
          pke_enc_state_n = PKE_ENC_LAUNCH_INTT;
        end
      end

      PKE_ENC_LAUNCH_INTT: begin
        vec_in_a_o = stage_vec;
        vec_in_b_o = '0;
        arith_cmd_o = CMD_INTT;
        vec_in_valid_o = 1'b1;
        ntt_start_o = 1'b1;
        pke_enc_state_n = PKE_ENC_WAIT_INTT;
      end

      PKE_ENC_WAIT_INTT: begin
        arith_cmd_o = CMD_INTT;
        if (ntt_error_i) begin
          busy_o = 1'b0;
          error_o = 1'b1;
          errcode_o = ERR_INTT;
          pke_enc_state_n = PKE_ENC_IDLE;
        end else if (ntt_done_i && ntt_vec_out_valid_i) begin
          pke_enc_state_n = PKE_ENC_PREP_CT;
        end
      end

      PKE_ENC_PREP_CT: begin
        pke_enc_state_n = PKE_ENC_WRITEBACK;
      end

      PKE_ENC_WRITEBACK: begin
        vec_wr_en_o = 1'b1;
        vec_wr_buf_sel_o = buf_r_sel_i;
        vec_wr_row_o = wr_row;
        vec_wr_data_o = ct_pack_row_vec_out;
        if (wr_row + 1 >= active_writeback_rows) begin
          busy_o = 1'b0;
          done_o = 1'b1;
          pke_enc_state_n = PKE_ENC_IDLE;
        end
      end

      default: begin
        pke_enc_state_n = PKE_ENC_IDLE;
      end
    endcase
  end

endmodule
