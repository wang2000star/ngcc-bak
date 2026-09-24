package zen_swift_profile_pkg;

  // This workspace is intentionally specialized for the swift512 parameter set.
  localparam int SWIFT_SECURITY = 512;
  localparam int SWIFT_N = 2048;
  localparam int SWIFT_N4_LOG2 = 9;
  localparam int SWIFT_SYM_LEN_BYTES = 64;
  localparam int SWIFT_SHAREDKEY_LEN_BYTES = 64;
  localparam int SWIFT_F_NTT_PACK = 2560;
  localparam int SWIFT_F2_PACK = 64;
  localparam int SWIFT_INDCPA_MSG_LEN_BYTES = 64;
  localparam int SWIFT_INDCPA_PUBLICKEY_LEN_BYTES = 2458;
  localparam int SWIFT_INDCPA_CIPHERTEXT_LEN_BYTES = 2048;
  localparam int SWIFT_SAMPLE_MAX_BYTES = 1280;

  localparam int SWIFT_SEED_LEN_BYTES = 64;
  localparam int SWIFT_DRNG_SEEDLEN = 55;
  localparam int SWIFT_N2 = SWIFT_N / 2;
  localparam int SWIFT_N4 = SWIFT_N / 4;
  localparam int SWIFT_N_LEN_BYTES = SWIFT_N / 8;
  localparam int SWIFT_Q = 769;
  localparam int SWIFT_Q2 = 384;
  localparam int SWIFT_ADDR_W = $clog2(SWIFT_N);
  localparam int SWIFT_SEEDBUF_BYTES = 2048;
  localparam int SWIFT_SEEDBUF_ADDR_W = $clog2(SWIFT_SEEDBUF_BYTES);

endpackage
