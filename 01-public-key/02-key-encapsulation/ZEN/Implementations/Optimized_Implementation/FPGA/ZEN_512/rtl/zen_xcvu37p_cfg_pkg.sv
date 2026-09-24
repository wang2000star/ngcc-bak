package zen_xcvu37p_cfg_pkg;

  localparam int XCVU37P_BUF_BANKS = 32;
  localparam int XCVU37P_NTT_BFLY_LANES = 16;
  localparam int XCVU37P_MODMUL_LANES = 24;
  localparam int XCVU37P_BASEMUL_LANES = 2;
  localparam int XCVU37P_BASEINV_LANES = 4;
  localparam int XCVU37P_BINARY_LANES = 32;
  localparam int XCVU37P_BINARY_COL_FACTOR = ((zen_accel_pkg::ZEN_N >= 2048) ? 10 :
                                              ((zen_accel_pkg::ZEN_N > 512) ? 5 : 3));
  localparam int XCVU37P_SAMPLE_COEFF_LANES = 64;

endpackage
