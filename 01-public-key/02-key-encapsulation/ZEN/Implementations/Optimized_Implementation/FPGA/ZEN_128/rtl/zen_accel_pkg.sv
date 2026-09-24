package zen_accel_pkg;

  localparam int ZEN_N = zen_swift_profile_pkg::SWIFT_N;
  localparam int ZEN_N2 = zen_swift_profile_pkg::SWIFT_N2;
  localparam int ZEN_N4 = zen_swift_profile_pkg::SWIFT_N4;
  localparam int ZEN_Q = zen_swift_profile_pkg::SWIFT_Q;
  localparam int COEFF_W = 16;
  localparam int PROD_W = 32;
  localparam int HOST_ADDR_W = 32;
  localparam int AXIL_ADDR_W = 16;
  localparam int STREAM_ROW_COEFFS = 16;
  localparam int ADDR_W = $clog2(ZEN_N);
  localparam int SAMPLE_MAX_BYTES = zen_swift_profile_pkg::SWIFT_SAMPLE_MAX_BYTES;
  localparam int SEEDBUF_BYTES = zen_swift_profile_pkg::SWIFT_SEEDBUF_BYTES;
  localparam int SEEDBUF_ADDR_W = $clog2(SEEDBUF_BYTES);
  localparam int MSG_BYTES = zen_swift_profile_pkg::SWIFT_INDCPA_MSG_LEN_BYTES;
  localparam int PK_PACK_BYTES = zen_swift_profile_pkg::SWIFT_INDCPA_PUBLICKEY_LEN_BYTES;
  localparam int CT_PACK_BYTES = zen_swift_profile_pkg::SWIFT_INDCPA_CIPHERTEXT_LEN_BYTES;
  localparam int SK_FNTT_PACK_BYTES = zen_swift_profile_pkg::SWIFT_F_NTT_PACK;
  localparam int SK_F2_PACK_BYTES = zen_swift_profile_pkg::SWIFT_F2_PACK;
  localparam int SK_PACK_BYTES = SK_FNTT_PACK_BYTES + SK_F2_PACK_BYTES;
  localparam int SK_HI_BYTES = SK_PACK_BYTES - ZEN_N;
  localparam int KEM_SK_BYTES = PK_PACK_BYTES + SK_PACK_BYTES + MSG_BYTES;

  localparam int BUF_COUNT = 6;
`ifdef USE_XCV80
  `ifdef USE_SAFE
  localparam int BUF_BANKS = zen_xcv80_profiles_pkg::XCV80_SAFE_BUF_BANKS;
  localparam int MODMUL_LANES = zen_xcv80_profiles_pkg::XCV80_SAFE_MODMUL_LANES;
  localparam int NTT_BFLY_LANES = zen_xcv80_profiles_pkg::XCV80_SAFE_NTT_BFLY_LANES;
  localparam int BASEMUL_LANES = zen_xcv80_profiles_pkg::XCV80_SAFE_BASEMUL_LANES;
  localparam int BASEINV_LANES = zen_xcv80_profiles_pkg::XCV80_SAFE_BASEINV_LANES;
  localparam int BINARY_LANES = zen_xcv80_profiles_pkg::XCV80_SAFE_BINARY_LANES;
  localparam int SAMPLE_COEFF_LANES = zen_xcv80_profiles_pkg::XCV80_SAFE_SAMPLE_COEFF_LANES;
  `elsif USE_TIMING
  localparam int BUF_BANKS = zen_xcv80_profiles_pkg::XCV80_TIMING_BUF_BANKS;
  localparam int MODMUL_LANES = zen_xcv80_profiles_pkg::XCV80_TIMING_MODMUL_LANES;
  localparam int NTT_BFLY_LANES = zen_xcv80_profiles_pkg::XCV80_TIMING_NTT_BFLY_LANES;
  localparam int BASEMUL_LANES = zen_xcv80_profiles_pkg::XCV80_TIMING_BASEMUL_LANES;
  localparam int BASEINV_LANES = zen_xcv80_profiles_pkg::XCV80_TIMING_BASEINV_LANES;
  localparam int BINARY_LANES = zen_xcv80_profiles_pkg::XCV80_TIMING_BINARY_LANES;
  localparam int SAMPLE_COEFF_LANES = zen_xcv80_profiles_pkg::XCV80_TIMING_SAMPLE_COEFF_LANES;
  `elsif USE_AGGR
  localparam int BUF_BANKS = zen_xcv80_profiles_pkg::XCV80_AGGR_BUF_BANKS;
  localparam int MODMUL_LANES = zen_xcv80_profiles_pkg::XCV80_AGGR_MODMUL_LANES;
  localparam int NTT_BFLY_LANES = zen_xcv80_profiles_pkg::XCV80_AGGR_NTT_BFLY_LANES;
  localparam int BASEMUL_LANES = zen_xcv80_profiles_pkg::XCV80_AGGR_BASEMUL_LANES;
  localparam int BASEINV_LANES = zen_xcv80_profiles_pkg::XCV80_AGGR_BASEINV_LANES;
  localparam int BINARY_LANES = zen_xcv80_profiles_pkg::XCV80_AGGR_BINARY_LANES;
  localparam int SAMPLE_COEFF_LANES = zen_xcv80_profiles_pkg::XCV80_AGGR_SAMPLE_COEFF_LANES;
  `else
  localparam int BUF_BANKS = zen_xcv80_cfg_pkg::XCV80_BUF_BANKS;
  localparam int MODMUL_LANES = zen_xcv80_cfg_pkg::XCV80_MODMUL_LANES;
  localparam int NTT_BFLY_LANES = zen_xcv80_cfg_pkg::XCV80_NTT_BFLY_LANES;
  localparam int BASEMUL_LANES = zen_xcv80_cfg_pkg::XCV80_BASEMUL_LANES;
  localparam int BASEINV_LANES = zen_xcv80_cfg_pkg::XCV80_BASEINV_LANES;
  localparam int BINARY_LANES = zen_xcv80_cfg_pkg::XCV80_BINARY_LANES;
  localparam int SAMPLE_COEFF_LANES = zen_xcv80_cfg_pkg::XCV80_SAMPLE_COEFF_LANES;
  `endif
`else
  `ifdef USE_SAFE
  localparam int BUF_BANKS = zen_xcvu37p_profiles_pkg::XCVU37P_SAFE_BUF_BANKS;
  localparam int MODMUL_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_SAFE_MODMUL_LANES;
  localparam int NTT_BFLY_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_SAFE_NTT_BFLY_LANES;
  localparam int BASEMUL_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_SAFE_BASEMUL_LANES;
  localparam int BASEINV_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_SAFE_BASEINV_LANES;
  localparam int BINARY_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_SAFE_BINARY_LANES;
  localparam int SAMPLE_COEFF_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_SAFE_SAMPLE_COEFF_LANES;
  `elsif USE_TIMING
  localparam int BUF_BANKS = zen_xcvu37p_profiles_pkg::XCVU37P_TIMING_BUF_BANKS;
  localparam int MODMUL_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_TIMING_MODMUL_LANES;
  localparam int NTT_BFLY_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_TIMING_NTT_BFLY_LANES;
  localparam int BASEMUL_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_TIMING_BASEMUL_LANES;
  localparam int BASEINV_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_TIMING_BASEINV_LANES;
  localparam int BINARY_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_TIMING_BINARY_LANES;
  localparam int SAMPLE_COEFF_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_TIMING_SAMPLE_COEFF_LANES;
  `elsif USE_AGGR
  localparam int BUF_BANKS = zen_xcvu37p_profiles_pkg::XCVU37P_AGGR_BUF_BANKS;
  localparam int MODMUL_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_AGGR_MODMUL_LANES;
  localparam int NTT_BFLY_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_AGGR_NTT_BFLY_LANES;
  localparam int BASEMUL_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_AGGR_BASEMUL_LANES;
  localparam int BASEINV_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_AGGR_BASEINV_LANES;
  localparam int BINARY_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_AGGR_BINARY_LANES;
  localparam int SAMPLE_COEFF_LANES = zen_xcvu37p_profiles_pkg::XCVU37P_AGGR_SAMPLE_COEFF_LANES;
  `else
  localparam int BUF_BANKS = zen_xcvu37p_cfg_pkg::XCVU37P_BUF_BANKS;
  localparam int MODMUL_LANES = zen_xcvu37p_cfg_pkg::XCVU37P_MODMUL_LANES;
  localparam int NTT_BFLY_LANES = zen_xcvu37p_cfg_pkg::XCVU37P_NTT_BFLY_LANES;
  localparam int BASEMUL_LANES = zen_xcvu37p_cfg_pkg::XCVU37P_BASEMUL_LANES;
  localparam int BASEINV_LANES = zen_xcvu37p_cfg_pkg::XCVU37P_BASEINV_LANES;
  localparam int BINARY_LANES = zen_xcvu37p_cfg_pkg::XCVU37P_BINARY_LANES;
  localparam int SAMPLE_COEFF_LANES = zen_xcvu37p_cfg_pkg::XCVU37P_SAMPLE_COEFF_LANES;
  `endif
`endif
  localparam int BANK_DEPTH = ZEN_N / BUF_BANKS;

  localparam int STREAM_ROW_BITS = STREAM_ROW_COEFFS * COEFF_W;

  typedef logic signed [COEFF_W-1:0] zen_coeff_t;
  typedef logic signed [ZEN_N*COEFF_W-1:0] zen_poly_vec_t;
  typedef logic [BUF_BANKS*COEFF_W-1:0] zen_buf_row_t;
  typedef logic signed [STREAM_ROW_BITS-1:0] zen_stream_row_t;
  typedef logic [ADDR_W-1:0] zen_row_addr_t;
  typedef logic [SEEDBUF_ADDR_W-1:0] zen_seed_addr_t;
  typedef logic [AXIL_ADDR_W-1:0] zen_axil_addr_t;

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
