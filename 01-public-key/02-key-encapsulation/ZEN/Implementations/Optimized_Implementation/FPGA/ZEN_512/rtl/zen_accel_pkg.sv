package zen_accel_pkg;

  parameter int ZEN_N = zen_swift_profile_pkg::SWIFT_N;
  parameter int ZEN_N2 = zen_swift_profile_pkg::SWIFT_N2;
  parameter int ZEN_N4 = zen_swift_profile_pkg::SWIFT_N4;
  parameter int ZEN_Q = zen_swift_profile_pkg::SWIFT_Q;
  parameter int COEFF_W = 16;
  parameter int PROD_W = 32;
  parameter int HOST_ADDR_W = 32;
  // Single-bitstream groundwork: reserve seed/sample storage for the largest profile.
  parameter int MAX_ZEN_N = 2048;
  parameter int MAX_ADDR_W = $clog2(MAX_ZEN_N);
  parameter int ADDR_W = MAX_ADDR_W;
  parameter int MAX_SAMPLE_MAX_BYTES = 1280;
  parameter int MAX_SEEDBUF_BYTES = 2048;
  parameter int MAX_SEEDBUF_ADDR_W = $clog2(MAX_SEEDBUF_BYTES);
  parameter int MAX_MSG_BYTES = 64;
  parameter int MAX_PK_PACK_BYTES = 2458;
  parameter int MAX_CT_PACK_BYTES = 2048;
  parameter int MAX_SK_FNTT_PACK_BYTES = (MAX_ZEN_N * 5) / 4;
  parameter int MAX_SK_F2_PACK_BYTES = MAX_ZEN_N / 32;
  parameter int MAX_SK_PACK_BYTES = MAX_SK_FNTT_PACK_BYTES + MAX_SK_F2_PACK_BYTES;
  parameter int MAX_SK_HI_BYTES = MAX_SK_PACK_BYTES - MAX_ZEN_N;
  parameter int MAX_KEM_SK_BYTES = 5210;
  parameter int SEEDBUF_BYTES = MAX_SEEDBUF_BYTES;
  parameter int SEEDBUF_ADDR_W = MAX_SEEDBUF_ADDR_W;
  parameter int SAMPLE_MAX_BYTES = MAX_SAMPLE_MAX_BYTES;

  parameter int BUF_COUNT = 6;
  parameter int BUF_BANKS = 8;
  parameter int MAX_BANK_DEPTH = MAX_ZEN_N / BUF_BANKS;
  parameter int BANK_DEPTH = MAX_BANK_DEPTH;
  parameter int STREAM_ROW_COEFFS = 16;
  parameter int STREAM_ROW_BITS = STREAM_ROW_COEFFS * COEFF_W;

  parameter int NTT_BFLY_LANES = 8;
  parameter int MODMUL_LANES = 16;
  parameter int BASEMUL_LANES = 2;
  parameter int BASEINV_LANES = 4;
  parameter int BINARY_LANES = 16;
  parameter int SAMPLE_COEFF_LANES = 32;

  localparam logic [1:0] PROFILE_SWIFT128 = 2'd0;
  localparam logic [1:0] PROFILE_SWIFT256 = 2'd1;
  localparam logic [1:0] PROFILE_SWIFT512 = 2'd2;

  localparam logic [1:0] CURRENT_PROFILE_ID =
      (zen_swift_profile_pkg::SWIFT_SECURITY == 512) ? PROFILE_SWIFT512 :
      ((zen_swift_profile_pkg::SWIFT_SECURITY == 256) ? PROFILE_SWIFT256 : PROFILE_SWIFT128);

  localparam logic [7:0] CMD_NOP           = 8'h00;
  localparam logic [7:0] CMD_LOAD_A        = 8'h01;
  localparam logic [7:0] CMD_LOAD_B        = 8'h02;
  localparam logic [7:0] CMD_STORE_R       = 8'h03;
  localparam logic [7:0] CMD_NTT           = 8'h10;
  localparam logic [7:0] CMD_NTT_MQ        = 8'h11;
  localparam logic [7:0] CMD_INTT          = 8'h12;
  localparam logic [7:0] CMD_BASEMUL       = 8'h20;
  localparam logic [7:0] CMD_BASEMUL_MQ    = 8'h21;
  localparam logic [7:0] CMD_BASEINV       = 8'h22;
  localparam logic [7:0] CMD_R2_MUL        = 8'h30;
  localparam logic [7:0] CMD_FAST_INV      = 8'h31;
  localparam logic [7:0] CMD_SAMPLE_F      = 8'h40;
  localparam logic [7:0] CMD_SAMPLE_G      = 8'h41;
  localparam logic [7:0] CMD_SAMPLE_S      = 8'h42;
  localparam logic [7:0] CMD_SAMPLE_E      = 8'h43;
  localparam logic [7:0] CMD_SAMPLE_GF     = 8'h44;
  localparam logic [7:0] CMD_SAMPLE_SE     = 8'h45;
  localparam logic [7:0] CMD_DECODE_HELPER = 8'h50;
  localparam logic [7:0] CMD_T0_TRANSFORM  = 8'h51;
  localparam logic [7:0] CMD_A_MOD2        = 8'h52;
  localparam logic [7:0] CMD_POLY_ADD      = 8'h53;
  localparam logic [7:0] CMD_ENC_POSTPROC  = 8'h54;
  localparam logic [7:0] CMD_DEC_POSTPROC  = 8'h55;
  localparam logic [7:0] CMD_CT_DECOMP     = 8'h56;
  localparam logic [7:0] CMD_MSG_UNPACK    = 8'h57;
  localparam logic [7:0] CMD_MSG_PACK      = 8'h58;
  localparam logic [7:0] CMD_PK_UNPACK     = 8'h59;
  localparam logic [7:0] CMD_RUN_PKE_KEYGEN = 8'hA0;
  localparam logic [7:0] CMD_RUN_PKE_ENC    = 8'hA1;
  localparam logic [7:0] CMD_RUN_PKE_DEC    = 8'hA2;
  localparam logic [7:0] CMD_PKE_DEC       = 8'h90;
  localparam logic [7:0] CMD_PKE_ENC       = 8'h91;
  localparam logic [7:0] CMD_PKE_KEYGEN    = 8'h92;

  localparam logic [3:0] SLOT_NONE     = 4'd0;
  localparam logic [3:0] SLOT_PK_IN    = 4'd1;
  localparam logic [3:0] SLOT_SK_IN    = 4'd2;
  localparam logic [3:0] SLOT_CT_IN    = 4'd3;
  localparam logic [3:0] SLOT_MSG_IN   = 4'd4;
  localparam logic [3:0] SLOT_SEED_IN  = 4'd5;
  localparam logic [3:0] SLOT_PK_OUT   = 4'd6;
  localparam logic [3:0] SLOT_SK_OUT   = 4'd7;
  localparam logic [3:0] SLOT_CT_OUT   = 4'd8;
  localparam logic [3:0] SLOT_MSG_OUT  = 4'd9;
  localparam logic [3:0] SLOT_DEBUG    = 4'd15;

  typedef logic signed [COEFF_W-1:0] zen_coeff_t;
  typedef logic signed [ZEN_N*COEFF_W-1:0] zen_poly_vec_t;
  typedef logic signed [STREAM_ROW_BITS-1:0] zen_stream_row_t;
  typedef logic [ADDR_W-1:0] zen_row_addr_t;

  function automatic logic profile_valid(input logic [1:0] profile_id);
    begin
      profile_valid = (profile_id == PROFILE_SWIFT128) ||
                      (profile_id == PROFILE_SWIFT256) ||
                      (profile_id == PROFILE_SWIFT512);
    end
  endfunction

  function automatic int profile_n(input logic [1:0] profile_id);
    begin
      unique case (profile_id)
        PROFILE_SWIFT128: profile_n = 512;
        PROFILE_SWIFT256: profile_n = 1024;
        default:          profile_n = 2048;
      endcase
    end
  endfunction

  function automatic int profile_n2(input logic [1:0] profile_id);
    begin
      profile_n2 = profile_n(profile_id) / 2;
    end
  endfunction

  function automatic int profile_n4(input logic [1:0] profile_id);
    begin
      profile_n4 = profile_n(profile_id) / 4;
    end
  endfunction

  function automatic int profile_addr_w(input logic [1:0] profile_id);
    begin
      unique case (profile_id)
        PROFILE_SWIFT128: profile_addr_w = 9;
        PROFILE_SWIFT256: profile_addr_w = 10;
        default:          profile_addr_w = 11;
      endcase
    end
  endfunction

  function automatic int profile_writeback_rows(input logic [1:0] profile_id);
    begin
      profile_writeback_rows = profile_n(profile_id) / BUF_BANKS;
    end
  endfunction

  function automatic int profile_writeback_rows_for_banks(
    input logic [1:0] profile_id,
    input int bank_count
  );
    int effective_bank_count;
    begin
      effective_bank_count = (bank_count > 0) ? bank_count : 1;
      profile_writeback_rows_for_banks = profile_n(profile_id) / effective_bank_count;
    end
  endfunction

  function automatic int profile_writeback_last_row_for_banks(
    input logic [1:0] profile_id,
    input int bank_count
  );
    int rows;
    begin
      rows = profile_writeback_rows_for_banks(profile_id, bank_count);
      if (rows <= 0) begin
        profile_writeback_last_row_for_banks = 0;
      end else begin
        profile_writeback_last_row_for_banks = rows - 1;
      end
    end
  endfunction

  function automatic int profile_msg_bytes(input logic [1:0] profile_id);
    begin
      unique case (profile_id)
        PROFILE_SWIFT128: profile_msg_bytes = 16;
        PROFILE_SWIFT256: profile_msg_bytes = 32;
        default:          profile_msg_bytes = 64;
      endcase
    end
  endfunction

  function automatic int profile_sym_bytes(input logic [1:0] profile_id);
    begin
      unique case (profile_id)
        PROFILE_SWIFT128: profile_sym_bytes = 16;
        PROFILE_SWIFT256: profile_sym_bytes = 32;
        default:          profile_sym_bytes = 64;
      endcase
    end
  endfunction

  function automatic int profile_pk_pack_bytes(input logic [1:0] profile_id);
    begin
      unique case (profile_id)
        PROFILE_SWIFT128: profile_pk_pack_bytes = 615;
        PROFILE_SWIFT256: profile_pk_pack_bytes = 1229;
        default:          profile_pk_pack_bytes = 2458;
      endcase
    end
  endfunction

  function automatic int profile_ct_pack_bytes(input logic [1:0] profile_id);
    begin
      profile_ct_pack_bytes = profile_n(profile_id);
    end
  endfunction

  function automatic int profile_sk_fntt_pack_bytes(input logic [1:0] profile_id);
    begin
      profile_sk_fntt_pack_bytes = (profile_n(profile_id) * 5) / 4;
    end
  endfunction

  function automatic int profile_sk_f2_pack_bytes(input logic [1:0] profile_id);
    begin
      profile_sk_f2_pack_bytes = profile_n(profile_id) / 32;
    end
  endfunction

  function automatic int profile_sk_pack_bytes(input logic [1:0] profile_id);
    begin
      profile_sk_pack_bytes =
          profile_sk_fntt_pack_bytes(profile_id) +
          profile_sk_f2_pack_bytes(profile_id);
    end
  endfunction

  function automatic int profile_sample_max_bytes(input logic [1:0] profile_id);
    begin
      unique case (profile_id)
        PROFILE_SWIFT128: profile_sample_max_bytes = 448;
        PROFILE_SWIFT256: profile_sample_max_bytes = 512;
        default:          profile_sample_max_bytes = 1280;
      endcase
    end
  endfunction

  function automatic int profile_seedbuf_bytes(input logic [1:0] profile_id);
    begin
      if (profile_sample_max_bytes(profile_id) > 1024) begin
        profile_seedbuf_bytes = 2048;
      end else begin
        profile_seedbuf_bytes = 1024;
      end
    end
  endfunction

  function automatic logic sample_cmd_valid(
    input logic [1:0] profile_id,
    input logic [7:0] cmd
  );
    begin
      sample_cmd_valid = 1'b1;
      unique case (cmd)
        CMD_SAMPLE_F,
        CMD_SAMPLE_G,
        CMD_SAMPLE_S,
        CMD_SAMPLE_E: sample_cmd_valid = 1'b1;
        CMD_SAMPLE_GF: sample_cmd_valid = (profile_id == PROFILE_SWIFT512);
        CMD_SAMPLE_SE: sample_cmd_valid = (profile_id != PROFILE_SWIFT128);
        default: sample_cmd_valid = 1'b0;
      endcase
    end
  endfunction

  function automatic logic [7:0] canonical_sample_cmd(
    input logic [1:0] profile_id,
    input logic [7:0] cmd
  );
    begin
      canonical_sample_cmd = cmd;
      if (cmd == CMD_SAMPLE_GF) begin
        if (profile_id == PROFILE_SWIFT512) begin
          canonical_sample_cmd = CMD_SAMPLE_F;
        end else begin
          canonical_sample_cmd = CMD_NOP;
        end
      end else if (cmd == CMD_SAMPLE_SE) begin
        if (profile_id != PROFILE_SWIFT128) begin
          canonical_sample_cmd = CMD_SAMPLE_S;
        end else begin
          canonical_sample_cmd = CMD_NOP;
        end
      end
    end
  endfunction

  typedef enum logic [2:0] {
    CORE_NONE    = 3'd0,
    CORE_NTT     = 3'd1,
    CORE_BASEMUL = 3'd2,
    CORE_BASEINV = 3'd3,
    CORE_BINARY  = 3'd4,
    CORE_SAMPLER = 3'd5
  } core_sel_t;

  typedef struct packed {
    logic [7:0]  cmd;
    logic [31:0] cfg;
    logic [31:0] len;
    logic [2:0]  buf_a_sel;
    logic [2:0]  buf_b_sel;
    logic [2:0]  buf_r_sel;
  } zen_job_t;

  typedef struct packed {
    logic        busy;
    logic        done;
    logic        error;
  } zen_status_t;

  typedef struct packed {
    logic                  valid;
    logic [2:0]            buf_sel;
    logic [ADDR_W-1:0]     addr;
  } zen_buf_rd_req_t;

  typedef struct packed {
    logic                  valid;
    logic [COEFF_W-1:0]    data;
  } zen_buf_rd_rsp_t;

  typedef struct packed {
    logic                  valid;
    logic [2:0]            buf_sel;
    logic [ADDR_W-1:0]     addr;
    logic [COEFF_W-1:0]    data;
    logic [(COEFF_W/8)-1:0] strb;
  } zen_buf_wr_req_t;

endpackage
