module zen_cmd_dispatch (
  input  logic                      start,
  input  logic [7:0]                cmd,
  output zen_accel_pkg::core_sel_t  active_core,
  output logic                      ntt_start,
  output logic                      basemul_start,
  output logic                      baseinv_start,
  output logic                      binary_start,
  output logic                      sampler_start
);

  import zen_accel_pkg::*;

  always_comb begin
    active_core = CORE_NONE;
    ntt_start = 1'b0;
    basemul_start = 1'b0;
    baseinv_start = 1'b0;
    binary_start = 1'b0;
    sampler_start = 1'b0;

    unique case (cmd)
      CMD_NTT, CMD_NTT_MQ, CMD_INTT: begin
        active_core = CORE_NTT;
        ntt_start = start;
      end
      CMD_BASEMUL, CMD_BASEMUL_MQ: begin
        active_core = CORE_BASEMUL;
        basemul_start = start;
      end
      CMD_BASEINV: begin
        active_core = CORE_BASEINV;
        baseinv_start = start;
      end
      CMD_R2_MUL, CMD_FAST_INV, CMD_DECODE_HELPER, CMD_T0_TRANSFORM, CMD_A_MOD2,
      CMD_POLY_ADD, CMD_ENC_POSTPROC, CMD_DEC_POSTPROC, CMD_CT_DECOMP,
      CMD_MSG_UNPACK, CMD_MSG_PACK: begin
        active_core = CORE_BINARY;
        binary_start = start;
      end
      CMD_SAMPLE_F, CMD_SAMPLE_G, CMD_SAMPLE_S, CMD_SAMPLE_E,
      CMD_SAMPLE_GF, CMD_SAMPLE_SE: begin
        active_core = CORE_SAMPLER;
        sampler_start = start;
      end
      default: begin
        active_core = CORE_NONE;
      end
    endcase
  end

endmodule
