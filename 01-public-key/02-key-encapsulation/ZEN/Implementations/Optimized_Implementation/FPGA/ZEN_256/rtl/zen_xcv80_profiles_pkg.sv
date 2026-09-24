package zen_xcv80_profiles_pkg;

  localparam int XCV80_SAFE_BUF_BANKS = 16;
  localparam int XCV80_SAFE_NTT_BFLY_LANES = 8;
  localparam int XCV80_SAFE_MODMUL_LANES = 16;
  localparam int XCV80_SAFE_BASEMUL_LANES = 2;
  localparam int XCV80_SAFE_BASEINV_LANES = 4;
  localparam int XCV80_SAFE_BINARY_LANES = 16;
  localparam int XCV80_SAFE_BINARY_COL_FACTOR = ((zen_accel_pkg::ZEN_N >= 2048) ? 8 :
                                                   ((zen_accel_pkg::ZEN_N > 512) ? 4 : 2));
  localparam int XCV80_SAFE_SAMPLE_COEFF_LANES = 32;

  localparam int XCV80_BAL_BUF_BANKS = 32;
  localparam int XCV80_BAL_NTT_BFLY_LANES = 16;
  localparam int XCV80_BAL_MODMUL_LANES = 24;
  localparam int XCV80_BAL_BASEMUL_LANES = 12;
  localparam int XCV80_BAL_BASEINV_LANES = 4;
  localparam int XCV80_BAL_BINARY_LANES = 32;
  localparam int XCV80_BAL_BINARY_COL_FACTOR = ((zen_accel_pkg::ZEN_N >= 2048) ? 10 :
                                                  ((zen_accel_pkg::ZEN_N > 512) ? 5 : 3));
  localparam int XCV80_BAL_SAMPLE_COEFF_LANES = 64;

  localparam int XCV80_TIMING_BUF_BANKS = 32;
  localparam int XCV80_TIMING_NTT_BFLY_LANES = 12;
  localparam int XCV80_TIMING_MODMUL_LANES = 20;
  localparam int XCV80_TIMING_BASEMUL_LANES = 10;
  localparam int XCV80_TIMING_BASEINV_LANES = 5;
  localparam int XCV80_TIMING_BINARY_LANES = 24;
  localparam int XCV80_TIMING_BINARY_COL_FACTOR = ((zen_accel_pkg::ZEN_N >= 2048) ? 10 :
                                                     ((zen_accel_pkg::ZEN_N > 512) ? 5 : 3));
  localparam int XCV80_TIMING_SAMPLE_COEFF_LANES = 48;

  localparam int XCV80_AGGR_BUF_BANKS = 64;
  localparam int XCV80_AGGR_NTT_BFLY_LANES = 32;
  localparam int XCV80_AGGR_MODMUL_LANES = 32;
  localparam int XCV80_AGGR_BASEMUL_LANES = 16;
  localparam int XCV80_AGGR_BASEINV_LANES = 8;
  localparam int XCV80_AGGR_BINARY_LANES = 96;
  localparam int XCV80_AGGR_BINARY_COL_FACTOR = ((zen_accel_pkg::ZEN_N >= 2048) ? 10 :
                                                   ((zen_accel_pkg::ZEN_N > 512) ? 5 : 3));
  localparam int XCV80_AGGR_SAMPLE_COEFF_LANES = 128;

endpackage
