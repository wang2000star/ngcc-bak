// reference_only:
// - Full-vector ct egress/reference codec retained for TB compare and historical debug semantics.
// - Excluded from filelist_xcvu37p.f and not part of the mainline synthesis/OOC sweep.
module zen_ct_codec #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic [2:0] op,
  input  logic [1:0] profile_id_i,
  input  logic signed [NTT_N*COEFF_W-1:0] hs_poly_vec_i,
  input  logic signed [NTT_N*COEFF_W-1:0] e_poly_vec_i,
  input  logic signed [NTT_N*COEFF_W-1:0] msg_poly_vec_i,
  output logic signed [NTT_N*COEFF_W-1:0] vec_out_o,
  output logic [31:0] bytes_consumed_o,
  output logic [31:0] bytes_produced_o
);

  import zen_accel_pkg::*;

  localparam logic [2:0] OP_CT_EGRESS = 3'd1;
  localparam int COEFF_LOOP_CHUNK = 8;
  localparam int COEFF_LOOP_BLOCKS = (NTT_N + COEFF_LOOP_CHUNK - 1) / COEFF_LOOP_CHUNK;

  logic [31:0] active_n;
  logic [31:0] active_ct_bytes;
  integer idx;
  integer idx_outer;
  integer idx_inner;

  function automatic int limited_profile_n(input logic [1:0] profile_id);
    int profile_n_raw;
    begin
      profile_n_raw = profile_n(profile_id);
      if (profile_n_raw > NTT_N) begin
        limited_profile_n = NTT_N;
      end else begin
        limited_profile_n = profile_n_raw;
      end
    end
  endfunction

  assign active_n = limited_profile_n(profile_id_i);
  assign active_ct_bytes = profile_ct_pack_bytes(profile_id_i);

  function automatic logic signed [15:0] montgomery_reduce(
    input logic signed [31:0] a
  );
    logic signed [15:0] u;
    logic signed [31:0] t;
    begin
      u = a * (-16'sd767);
      t = a - (u * 16'sd769);
      montgomery_reduce = t >>> 16;
    end
  endfunction

  function automatic logic [15:0] ct_pack_coeff(
    input logic signed [15:0] hs_coeff,
    input logic signed [15:0] e_coeff,
    input logic signed [15:0] msg_coeff
  );
    logic signed [16:0] accum;
    logic signed [15:0] reduced;
    logic [31:0] d;
    begin
      accum = hs_coeff + e_coeff + msg_coeff;
      reduced = montgomery_reduce(accum * 16'sd171);
      reduced = reduced + ((reduced >>> 15) & 16'sd769);
      d = $unsigned(reduced) << 8;
      d = d + 32'd384;
      if (active_n == 1024) begin
        d = d * 32'd2727;
        d = d >> 21;
      end else begin
        d = d * 32'd10908;
        d = d >> 23;
      end
      ct_pack_coeff = {8'd0, d[7:0]};
    end
  endfunction

  always_comb begin
    vec_out_o = '0;
    bytes_consumed_o = 32'd0;
    bytes_produced_o = 32'd0;

    unique case (op)
      OP_CT_EGRESS: begin
        bytes_produced_o = active_ct_bytes;
        // Chunk large profile loops so Vivado elaboration stays below its 2000-iteration cap.
        for (idx_outer = 0; idx_outer < COEFF_LOOP_BLOCKS; idx_outer++) begin
          for (idx_inner = 0; idx_inner < COEFF_LOOP_CHUNK; idx_inner++) begin
            idx = (idx_outer * COEFF_LOOP_CHUNK) + idx_inner;
            if (idx < active_n) begin
              vec_out_o[idx*COEFF_W +: COEFF_W] = ct_pack_coeff(
                hs_poly_vec_i[idx*COEFF_W +: COEFF_W],
                e_poly_vec_i[idx*COEFF_W +: COEFF_W],
                msg_poly_vec_i[idx*COEFF_W +: COEFF_W]
              );
            end
          end
        end
      end
      default: begin
        vec_out_o = '0;
        bytes_consumed_o = 32'd0;
        bytes_produced_o = 32'd0;
      end
    endcase
  end

endmodule
