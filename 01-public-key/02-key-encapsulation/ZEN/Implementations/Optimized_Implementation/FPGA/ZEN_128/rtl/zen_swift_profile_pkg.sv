package zen_swift_profile_pkg;

  // This workspace is intentionally specialized for the swift128 parameter set.
  localparam int SWIFT_SECURITY = 128;
  localparam int SWIFT_N = 512;
  localparam int SWIFT_N4_LOG2 = 7;
  localparam int SWIFT_SYM_LEN_BYTES = 16;
  localparam int SWIFT_SHAREDKEY_LEN_BYTES = 16;
  localparam int SWIFT_F_NTT_PACK = 640;
  localparam int SWIFT_F2_PACK = 16;
  localparam int SWIFT_INDCPA_MSG_LEN_BYTES = 16;
  localparam int SWIFT_INDCPA_PUBLICKEY_LEN_BYTES = 615;
  localparam int SWIFT_INDCPA_CIPHERTEXT_LEN_BYTES = 512;
  localparam int SWIFT_SAMPLE_MAX_BYTES = 448;

  localparam int SWIFT_SEED_LEN_BYTES = 64;
  localparam int SWIFT_DRNG_SEEDLEN = 55;
  localparam int SWIFT_N2 = SWIFT_N / 2;
  localparam int SWIFT_N4 = SWIFT_N / 4;
  localparam int SWIFT_N_LEN_BYTES = SWIFT_N / 8;
  localparam int SWIFT_Q = 769;
  localparam int SWIFT_Q2 = 384;
  localparam int SWIFT_ADDR_W = $clog2(SWIFT_N);
  localparam int SWIFT_SEEDBUF_BYTES = 1024;
  localparam int SWIFT_SEEDBUF_ADDR_W = $clog2(SWIFT_SEEDBUF_BYTES);

endpackage
