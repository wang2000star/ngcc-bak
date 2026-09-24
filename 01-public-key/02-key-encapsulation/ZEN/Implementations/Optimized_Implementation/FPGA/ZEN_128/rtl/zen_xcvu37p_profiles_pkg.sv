package zen_xcvu37p_profiles_pkg;

  localparam int XCVU37P_SAFE_BUF_BANKS = 16;
  localparam int XCVU37P_SAFE_NTT_BFLY_LANES = 8;
  localparam int XCVU37P_SAFE_MODMUL_LANES = 16;
  localparam int XCVU37P_SAFE_BASEMUL_LANES = 2;
  localparam int XCVU37P_SAFE_BASEINV_LANES = 4;
  localparam int XCVU37P_SAFE_BINARY_LANES = 16;
  localparam int XCVU37P_SAFE_SAMPLE_COEFF_LANES = 32;

  localparam int XCVU37P_BAL_BUF_BANKS = 32;
  localparam int XCVU37P_BAL_NTT_BFLY_LANES = 16;
  localparam int XCVU37P_BAL_MODMUL_LANES = 24;
  localparam int XCVU37P_BAL_BASEMUL_LANES = 12;
  localparam int XCVU37P_BAL_BASEINV_LANES = 4;
  localparam int XCVU37P_BAL_BINARY_LANES = 32;
  localparam int XCVU37P_BAL_SAMPLE_COEFF_LANES = 64;

  localparam int XCVU37P_TIMING_BUF_BANKS = 32;
  localparam int XCVU37P_TIMING_NTT_BFLY_LANES = 12;
  localparam int XCVU37P_TIMING_MODMUL_LANES = 20;
  localparam int XCVU37P_TIMING_BASEMUL_LANES = 10;
  localparam int XCVU37P_TIMING_BASEINV_LANES = 5;
  localparam int XCVU37P_TIMING_BINARY_LANES = 24;
  localparam int XCVU37P_TIMING_SAMPLE_COEFF_LANES = 48;

  localparam int XCVU37P_AGGR_BUF_BANKS = 64;
  localparam int XCVU37P_AGGR_NTT_BFLY_LANES = 32;
  localparam int XCVU37P_AGGR_MODMUL_LANES = 32;
  localparam int XCVU37P_AGGR_BASEMUL_LANES = 16;
  localparam int XCVU37P_AGGR_BASEINV_LANES = 8;
  localparam int XCVU37P_AGGR_BINARY_LANES = 96;
  localparam int XCVU37P_AGGR_SAMPLE_COEFF_LANES = 128;

endpackage
