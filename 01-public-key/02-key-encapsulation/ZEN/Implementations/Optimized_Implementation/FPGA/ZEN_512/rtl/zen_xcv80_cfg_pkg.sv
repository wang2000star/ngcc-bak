package zen_xcv80_cfg_pkg;

  localparam int XCV80_BUF_BANKS = 32;
  localparam int XCV80_NTT_BFLY_LANES = 16;
  localparam int XCV80_MODMUL_LANES = 24;
  localparam int XCV80_BASEMUL_LANES = 2;
  localparam int XCV80_BASEINV_LANES = 4;
  localparam int XCV80_BINARY_LANES = 32;
  localparam int XCV80_BINARY_COL_FACTOR = ((zen_accel_pkg::ZEN_N >= 2048) ? 10 :
                                              ((zen_accel_pkg::ZEN_N > 512) ? 5 : 3));
  localparam int XCV80_SAMPLE_COEFF_LANES = 64;

endpackage
