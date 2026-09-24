//======================================================================
//
// cuishen_core.v   (Cuishen-1024 v5, v2 parallel datapaths, shared schedule)
// --------------
// Verilog 2001 implementation of the Cuishen-1024 hash core, per
// CryptHash_Cuishen-1024v5.c. Modelled directly on the 512-bit design's
// latency-optimised v2 core (parallel upper/lower OCTARX datapaths
// sharing one key schedule, one round per clock, no pipelining, no loop
// unrolling), rescaled to the Cuishen-1024-v5 algorithm parameters:
//   - 512-bit datapath per side (8 x 64-bit words), 64 rounds.
//   - round-key is 8 x 64-bit words {rk0..rk7}.
//   - round constants are E_CONST[0..63] (fractional part of e).
//   - the message-counter is part of the key-schedule sliding window
//     (cnt[0..1], advanced by rotl-2 each round), exactly as in the
//     512-bit design -- NOT XORed into the cipher state.
//   - lsb_separate (XOR variant): the "top" pass input is t with word7's
//     LSB XORed with 0 (unchanged); the "bottom" pass input is t with
//     word7's LSB XORed with 1 (flipped).
//   - t is initialised from IV_1, b from IV_2 (two DISTINCT constants).
//   - finalization tail threshold is 512 bits.
//
// Compression  : t_next = OCTARX(lsb_separate(t,0), key=m||b_prev, cnt)
//                b_next = OCTARX(lsb_separate(t,1), key=m||b_prev, cnt)
// Finalization : y2 = OCTARX(C2, key=t||b||tail, cnt)
//                y3 = OCTARX(C3, key=t||b||tail, cnt)
//                digest = y2 || y3
//
//
//======================================================================

`default_nettype none

module cuishen_core(
                    input wire             clk,
                    input wire             reset_n,

                    input wire             init,  // load IV
                    input wire             next,  // process a message block
                    input wire             finalize, // run finalization

                    // 1024-bit message block (m[0]..m[15], big-endian word order)
                    input wire [1023 : 0]  block,

                    // counter value (bits processed) for this block / final
                    input wire [63 : 0]    counter_bits,

                    // 512-bit zero-padded tail for finalization
                    input wire [511 : 0]   tail_words,

                    output wire            ready,
                    output wire [1023 : 0] digest,
                    output wire            digest_valid
                   );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam OCTARX_ROUNDS = 64;

  // round-function rotation constants (per v5 source)
  localparam RA = 18;
  localparam RB = 33;
  localparam RC = 47;
  localparam RD = 60;
  localparam RE = 49;
  localparam RF = 20;
  localparam RG = 16;
  localparam RH = 21;

  localparam CTRL_IDLE   = 2'h0;
  localparam CTRL_START  = 2'h1;
  localparam CTRL_ROUNDS = 2'h2;
  localparam CTRL_DONE   = 2'h3;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  // 512-bit UPPER datapath state.
  reg [63 : 0] su0_reg, su0_new;
  reg [63 : 0] su1_reg, su1_new;
  reg [63 : 0] su2_reg, su2_new;
  reg [63 : 0] su3_reg, su3_new;
  reg [63 : 0] su4_reg, su4_new;
  reg [63 : 0] su5_reg, su5_new;
  reg [63 : 0] su6_reg, su6_new;
  reg [63 : 0] su7_reg, su7_new;

  // 512-bit LOWER datapath state.
  reg [63 : 0] sl0_reg, sl0_new;
  reg [63 : 0] sl1_reg, sl1_new;
  reg [63 : 0] sl2_reg, sl2_new;
  reg [63 : 0] sl3_reg, sl3_new;
  reg [63 : 0] sl4_reg, sl4_new;
  reg [63 : 0] sl5_reg, sl5_new;
  reg [63 : 0] sl6_reg, sl6_new;
  reg [63 : 0] sl7_reg, sl7_new;

  reg          s_we;  // shared write-enable for both datapaths

  // Feed-forward registers (anti-second-preimage hardening).
  // These latch the OCTARX *input* (top_input / bottom_input in the C
  // reference compress_one_block()) at the very same cycle it is loaded
  // into su/sl, so the value is still around 64 rounds later when the
  // cipher output is ready and needs to be XORed back in:
  //   t_next = OCTARX(top_input)    ; t_next ^= top_input
  //   b_next = OCTARX(bottom_input) ; b_next ^= bottom_input
  // Only meaningful for compression. Finalization does NOT feed forward
  // (C reference finalization() outputs y2/y3 directly, no XOR-back), so
  // these registers are simply not consulted when final_reg is set.
  reg [63 : 0] ffu0_reg, ffu0_new;
  reg [63 : 0] ffu1_reg, ffu1_new;
  reg [63 : 0] ffu2_reg, ffu2_new;
  reg [63 : 0] ffu3_reg, ffu3_new;
  reg [63 : 0] ffu4_reg, ffu4_new;
  reg [63 : 0] ffu5_reg, ffu5_new;
  reg [63 : 0] ffu6_reg, ffu6_new;
  reg [63 : 0] ffu7_reg, ffu7_new;

  reg [63 : 0] ffl0_reg, ffl0_new;
  reg [63 : 0] ffl1_reg, ffl1_new;
  reg [63 : 0] ffl2_reg, ffl2_new;
  reg [63 : 0] ffl3_reg, ffl3_new;
  reg [63 : 0] ffl4_reg, ffl4_new;
  reg [63 : 0] ffl5_reg, ffl5_new;
  reg [63 : 0] ffl6_reg, ffl6_new;
  reg [63 : 0] ffl7_reg, ffl7_new;

  reg          ff_we; // shared write-enable for the feed-forward registers

  // chaining values t (upper) and b (lower), 512-bit each.
  reg [63 : 0] T0_reg, T0_new;
  reg [63 : 0] T1_reg, T1_new;
  reg [63 : 0] T2_reg, T2_new;
  reg [63 : 0] T3_reg, T3_new;
  reg [63 : 0] T4_reg, T4_new;
  reg [63 : 0] T5_reg, T5_new;
  reg [63 : 0] T6_reg, T6_new;
  reg [63 : 0] T7_reg, T7_new;
  reg [63 : 0] B0_reg, B0_new;
  reg [63 : 0] B1_reg, B1_new;
  reg [63 : 0] B2_reg, B2_new;
  reg [63 : 0] B3_reg, B3_new;
  reg [63 : 0] B4_reg, B4_new;
  reg [63 : 0] B5_reg, B5_new;
  reg [63 : 0] B6_reg, B6_new;
  reg [63 : 0] B7_reg, B7_new;
  reg          chain_we;

  // digest holding register (y2 || y3), 1024-bit.
  reg [1023 : 0] digest_reg;
  reg [1023 : 0] digest_new;
  reg            digest_we;

  // remember whether the current cipher run belongs to a finalization
  reg          final_reg;
  reg          final_new;
  reg          final_we;

  reg [6 : 0]  round_ctr_reg;
  reg [6 : 0]  round_ctr_new;
  reg          round_ctr_we;
  reg          round_ctr_inc;
  reg          round_ctr_rst;

  reg          ready_reg;
  reg          ready_new;
  reg          ready_we;

  reg          digest_valid_reg;
  reg          digest_valid_new;
  reg          digest_valid_we;

  reg [1 : 0]  cuishen_ctrl_reg;
  reg [1 : 0]  cuishen_ctrl_new;
  reg          cuishen_ctrl_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg state_init;    // load both cipher inputs into the two datapaths
  reg state_update;  // run one round on both datapaths
  reg chain_init;    // load IV into t,b
  reg chain_update;  // store cipher outputs into t,b
  reg digest_update; // assemble final digest

  reg          key_init;
  reg          key_next;

  wire [63 : 0] e_data;
  wire [63 : 0] rk0, rk1, rk2, rk3, rk4, rk5, rk6, rk7;

  wire [63 : 0] IV_T0, IV_T1, IV_T2, IV_T3, IV_T4, IV_T5, IV_T6, IV_T7;
  wire [63 : 0] IV_B0, IV_B1, IV_B2, IV_B3, IV_B4, IV_B5, IV_B6, IV_B7;

  reg [1535 : 0] master_key;
  reg [127 : 0]  key_counter;

  // cipher inputs for the two parallel passes (lsb_separate already
  // applied combinationally below; no counter XOR here any more --
  // the counter is part of the key schedule, see cuishen_key_mem.v).
  reg [63 : 0] cu0, cu1, cu2, cu3, cu4, cu5, cu6, cu7;   // upper input
  reg [63 : 0] cl0, cl1, cl2, cl3, cl4, cl5, cl6, cl7;   // lower input


  //----------------------------------------------------------------
  // Module instantiations.
  //----------------------------------------------------------------
  cuishen_e_constants e_inst(
                            .addr(round_ctr_reg),
                            .E_CONST(e_data)
                           );

  cuishen_iv_constants iv_inst(
                               .T0(IV_T0), .T1(IV_T1), .T2(IV_T2), .T3(IV_T3),
                               .T4(IV_T4), .T5(IV_T5), .T6(IV_T6), .T7(IV_T7),
                               .B0(IV_B0), .B1(IV_B1), .B2(IV_B2), .B3(IV_B3),
                               .B4(IV_B4), .B5(IV_B5), .B6(IV_B6), .B7(IV_B7)
                              );

  cuishen_key_mem key_mem_inst(
                               .clk(clk),
                               .reset_n(reset_n),
                               .master_key(master_key),
                               .counter(key_counter),
                               .init(key_init),
                               .next(key_next),
                               .rk0(rk0), .rk1(rk1), .rk2(rk2), .rk3(rk3),
                               .rk4(rk4), .rk5(rk5), .rk6(rk6), .rk7(rk7)
                              );


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign ready        = ready_reg;
  assign digest       = digest_reg;
  assign digest_valid = digest_valid_reg;


  //----------------------------------------------------------------
  // master_key / counter selection.
  //
  // For finalization the 1536-bit key is t || b || tail. For compression
  // the key is the 1024-bit message block concatenated with the current
  // 512-bit lower chaining value b. Selection uses the latched final_reg.
  // The counter (bits processed) feeds the key schedule's cnt window,
  // per CryptHash_Cuishen-1024v5.c.
  //----------------------------------------------------------------
  always @*
    begin : key_select
      key_counter = {64'h0, counter_bits};

      if (final_reg)
        master_key = {T0_reg, T1_reg, T2_reg, T3_reg, T4_reg, T5_reg, T6_reg, T7_reg,
                      B0_reg, B1_reg, B2_reg, B3_reg, B4_reg, B5_reg, B6_reg, B7_reg,
                      tail_words};
      else
        master_key = {block, B0_reg, B1_reg, B2_reg, B3_reg, B4_reg, B5_reg, B6_reg, B7_reg};
    end // key_select


  //----------------------------------------------------------------
  // cipher_input_select
  //
  // Builds BOTH pass inputs:
  //   compression : upper = lsb_separate(t,0)  (clear word7 LSB via XOR 0)
  //                 lower = lsb_separate(t,1)  (flip  word7 LSB via XOR 1)
  //   finalization: upper = C2 = {0,0,0,0,0,0,0,2}
  //                 lower = C3 = {0,0,0,0,0,0,0,3}
  //----------------------------------------------------------------
  always @*
    begin : cipher_input_select
      if (final_reg)
        begin
          cu0 = 64'h0; cu1 = 64'h0; cu2 = 64'h0; cu3 = 64'h0;
          cu4 = 64'h0; cu5 = 64'h0; cu6 = 64'h0; cu7 = 64'h2;
          cl0 = 64'h0; cl1 = 64'h0; cl2 = 64'h0; cl3 = 64'h0;
          cl4 = 64'h0; cl5 = 64'h0; cl6 = 64'h0; cl7 = 64'h3;
        end
      else
        begin
          cu0 = T0_reg; cu1 = T1_reg; cu2 = T2_reg; cu3 = T3_reg;
          cu4 = T4_reg; cu5 = T5_reg; cu6 = T6_reg;
          cu7 = T7_reg ^ 64'h0;                  // lsb_separate, bit=0 (xor 0)

          cl0 = T0_reg; cl1 = T1_reg; cl2 = T2_reg; cl3 = T3_reg;
          cl4 = T4_reg; cl5 = T5_reg; cl6 = T6_reg;
          cl7 = T7_reg ^ 64'h0000000000000001;   // lsb_separate, bit=1 (xor 1)
        end
    end // cipher_input_select


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin : reg_update
      if (!reset_n)
        begin
          su0_reg <= 64'h0; su1_reg <= 64'h0; su2_reg <= 64'h0; su3_reg <= 64'h0;
          su4_reg <= 64'h0; su5_reg <= 64'h0; su6_reg <= 64'h0; su7_reg <= 64'h0;
          sl0_reg <= 64'h0; sl1_reg <= 64'h0; sl2_reg <= 64'h0; sl3_reg <= 64'h0;
          sl4_reg <= 64'h0; sl5_reg <= 64'h0; sl6_reg <= 64'h0; sl7_reg <= 64'h0;
          ffu0_reg <= 64'h0; ffu1_reg <= 64'h0; ffu2_reg <= 64'h0; ffu3_reg <= 64'h0;
          ffu4_reg <= 64'h0; ffu5_reg <= 64'h0; ffu6_reg <= 64'h0; ffu7_reg <= 64'h0;
          ffl0_reg <= 64'h0; ffl1_reg <= 64'h0; ffl2_reg <= 64'h0; ffl3_reg <= 64'h0;
          ffl4_reg <= 64'h0; ffl5_reg <= 64'h0; ffl6_reg <= 64'h0; ffl7_reg <= 64'h0;
          T0_reg  <= 64'h0; T1_reg  <= 64'h0; T2_reg  <= 64'h0; T3_reg  <= 64'h0;
          T4_reg  <= 64'h0; T5_reg  <= 64'h0; T6_reg  <= 64'h0; T7_reg  <= 64'h0;
          B0_reg  <= 64'h0; B1_reg  <= 64'h0; B2_reg  <= 64'h0; B3_reg  <= 64'h0;
          B4_reg  <= 64'h0; B5_reg  <= 64'h0; B6_reg  <= 64'h0; B7_reg  <= 64'h0;
          digest_reg       <= 1024'h0;
          final_reg        <= 1'b0;
          ready_reg        <= 1'b1;
          digest_valid_reg <= 1'b0;
          round_ctr_reg    <= 7'h0;
          cuishen_ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
          if (s_we)
            begin
              su0_reg <= su0_new; su1_reg <= su1_new;
              su2_reg <= su2_new; su3_reg <= su3_new;
              su4_reg <= su4_new; su5_reg <= su5_new;
              su6_reg <= su6_new; su7_reg <= su7_new;
              sl0_reg <= sl0_new; sl1_reg <= sl1_new;
              sl2_reg <= sl2_new; sl3_reg <= sl3_new;
              sl4_reg <= sl4_new; sl5_reg <= sl5_new;
              sl6_reg <= sl6_new; sl7_reg <= sl7_new;
            end

          if (ff_we)
            begin
              ffu0_reg <= ffu0_new; ffu1_reg <= ffu1_new;
              ffu2_reg <= ffu2_new; ffu3_reg <= ffu3_new;
              ffu4_reg <= ffu4_new; ffu5_reg <= ffu5_new;
              ffu6_reg <= ffu6_new; ffu7_reg <= ffu7_new;
              ffl0_reg <= ffl0_new; ffl1_reg <= ffl1_new;
              ffl2_reg <= ffl2_new; ffl3_reg <= ffl3_new;
              ffl4_reg <= ffl4_new; ffl5_reg <= ffl5_new;
              ffl6_reg <= ffl6_new; ffl7_reg <= ffl7_new;
            end

          if (chain_we)
            begin
              T0_reg <= T0_new; T1_reg <= T1_new; T2_reg <= T2_new; T3_reg <= T3_new;
              T4_reg <= T4_new; T5_reg <= T5_new; T6_reg <= T6_new; T7_reg <= T7_new;
              B0_reg <= B0_new; B1_reg <= B1_new; B2_reg <= B2_new; B3_reg <= B3_new;
              B4_reg <= B4_new; B5_reg <= B5_new; B6_reg <= B6_new; B7_reg <= B7_new;
            end

          if (digest_we)
            digest_reg <= digest_new;

          if (final_we)
            final_reg <= final_new;

          if (round_ctr_we)
            round_ctr_reg <= round_ctr_new;

          if (ready_we)
            ready_reg <= ready_new;

          if (digest_valid_we)
            digest_valid_reg <= digest_valid_new;

          if (cuishen_ctrl_we)
            cuishen_ctrl_reg <= cuishen_ctrl_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // round_logic
  //
  // Two parallel OCTARX round functions sharing one key {rk0..rk7} and
  // E_CONST[round]. Upper acts on su*_reg, lower on sl*_reg.
  //
  //   x0 = s0 ^ rk0 ^ E_CONST ; x1 = s1^rk1 ; x2 = s2^rk2 ; x3 = s3^rk3
  //   x4..x7 = s4..s7 (unchanged)
  //   t = x4 ^ x5 ^ x6 ^ x7
  //   s0' = x4 ; s1' = x5 ; s2' = x6 ; s3' = x7
  //   s4' = (x0 <<< A) + ((t ^ rk7) <<< H)
  //   s5' = (x1 <<< B) + ((t ^ rk6) <<< G)
  //   s6' = (x2 <<< C) + ((t ^ rk5) <<< F)
  //   s7' = (x3 <<< D) + ((t ^ rk4) <<< E)
  //
  // The counter is NOT applied here: it is folded into the round key
  // via the key schedule's cnt[0..1] window (see cuishen_key_mem.v),
  // matching the 512-bit design's structure.
  //----------------------------------------------------------------
  always @*
    begin : round_logic
      // upper intermediates
      reg [63 : 0] ux0, ux1, ux2, ux3, utt, ut7, ut6, ut5, ut4;
      reg [63 : 0] ux0r, ux1r, ux2r, ux3r, utd7, utd6, utd5, utd4;
      // lower intermediates
      reg [63 : 0] lx0, lx1, lx2, lx3, ltt, lt7, lt6, lt5, lt4;
      reg [63 : 0] lx0r, lx1r, lx2r, lx3r, ltd7, ltd6, ltd5, ltd4;

      su0_new = 64'h0; su1_new = 64'h0; su2_new = 64'h0; su3_new = 64'h0;
      su4_new = 64'h0; su5_new = 64'h0; su6_new = 64'h0; su7_new = 64'h0;
      sl0_new = 64'h0; sl1_new = 64'h0; sl2_new = 64'h0; sl3_new = 64'h0;
      sl4_new = 64'h0; sl5_new = 64'h0; sl6_new = 64'h0; sl7_new = 64'h0;
      s_we    = 1'b0;

      ffu0_new = 64'h0; ffu1_new = 64'h0; ffu2_new = 64'h0; ffu3_new = 64'h0;
      ffu4_new = 64'h0; ffu5_new = 64'h0; ffu6_new = 64'h0; ffu7_new = 64'h0;
      ffl0_new = 64'h0; ffl1_new = 64'h0; ffl2_new = 64'h0; ffl3_new = 64'h0;
      ffl4_new = 64'h0; ffl5_new = 64'h0; ffl6_new = 64'h0; ffl7_new = 64'h0;
      ff_we    = 1'b0;

      // ---- upper datapath combinational round ----
      ux0 = su0_reg ^ rk0 ^ e_data;
      ux1 = su1_reg ^ rk1;
      ux2 = su2_reg ^ rk2;
      ux3 = su3_reg ^ rk3;
      utt = su4_reg ^ su5_reg ^ su6_reg ^ su7_reg;
      ut7 = utt ^ rk7;
      ut6 = utt ^ rk6;
      ut5 = utt ^ rk5;
      ut4 = utt ^ rk4;

      ux0r = {ux0[63-RA:0], ux0[63:64-RA]};
      ux1r = {ux1[63-RB:0], ux1[63:64-RB]};
      ux2r = {ux2[63-RC:0], ux2[63:64-RC]};
      ux3r = {ux3[63-RD:0], ux3[63:64-RD]};
      utd7 = {ut7[63-RH:0], ut7[63:64-RH]};
      utd6 = {ut6[63-RG:0], ut6[63:64-RG]};
      utd5 = {ut5[63-RF:0], ut5[63:64-RF]};
      utd4 = {ut4[63-RE:0], ut4[63:64-RE]};

      // ---- lower datapath combinational round ----
      lx0 = sl0_reg ^ rk0 ^ e_data;
      lx1 = sl1_reg ^ rk1;
      lx2 = sl2_reg ^ rk2;
      lx3 = sl3_reg ^ rk3;
      ltt = sl4_reg ^ sl5_reg ^ sl6_reg ^ sl7_reg;
      lt7 = ltt ^ rk7;
      lt6 = ltt ^ rk6;
      lt5 = ltt ^ rk5;
      lt4 = ltt ^ rk4;

      lx0r = {lx0[63-RA:0], lx0[63:64-RA]};
      lx1r = {lx1[63-RB:0], lx1[63:64-RB]};
      lx2r = {lx2[63-RC:0], lx2[63:64-RC]};
      lx3r = {lx3[63-RD:0], lx3[63:64-RD]};
      ltd7 = {lt7[63-RH:0], lt7[63:64-RH]};
      ltd6 = {lt6[63-RG:0], lt6[63:64-RG]};
      ltd5 = {lt5[63-RF:0], lt5[63:64-RF]};
      ltd4 = {lt4[63-RE:0], lt4[63:64-RE]};

      if (state_init)
        begin
          su0_new = cu0; su1_new = cu1; su2_new = cu2; su3_new = cu3;
          su4_new = cu4; su5_new = cu5;
          su6_new = cu6;
          su7_new = cu7;

          sl0_new = cl0; sl1_new = cl1; sl2_new = cl2; sl3_new = cl3;
          sl4_new = cl4; sl5_new = cl5;
          sl6_new = cl6;
          sl7_new = cl7;

          s_we    = 1'b1;

          // Latch the OCTARX input itself (same cu/cl values) so it
          // survives the 64-round encryption and is available for the
          // feed-forward XOR-back in chain_logic. Harmless to also latch
          // during finalization runs since chain_logic simply never
          // reads ff*_reg in that case.
          ffu0_new = cu0; ffu1_new = cu1; ffu2_new = cu2; ffu3_new = cu3;
          ffu4_new = cu4; ffu5_new = cu5; ffu6_new = cu6; ffu7_new = cu7;
          ffl0_new = cl0; ffl1_new = cl1; ffl2_new = cl2; ffl3_new = cl3;
          ffl4_new = cl4; ffl5_new = cl5; ffl6_new = cl6; ffl7_new = cl7;
          ff_we    = 1'b1;
        end

      if (state_update)
        begin
          su0_new = su4_reg;
          su1_new = su5_reg;
          su2_new = su6_reg;
          su3_new = su7_reg;
          su4_new = ux0r + utd7;
          su5_new = ux1r + utd6;
          su6_new = ux2r + utd5;
          su7_new = ux3r + utd4;

          sl0_new = sl4_reg;
          sl1_new = sl5_reg;
          sl2_new = sl6_reg;
          sl3_new = sl7_reg;
          sl4_new = lx0r + ltd7;
          sl5_new = lx1r + ltd6;
          sl6_new = lx2r + ltd5;
          sl7_new = lx3r + ltd4;

          s_we    = 1'b1;
        end
    end // round_logic


  //----------------------------------------------------------------
  // chain_logic
  //
  // chain_init  : load IV -> t, IV -> b (both from the same constant).
  // chain_update: t <- upper result (su), b <- lower result (sl).
  //----------------------------------------------------------------
  always @*
    begin : chain_logic
      T0_new = 64'h0; T1_new = 64'h0; T2_new = 64'h0; T3_new = 64'h0;
      T4_new = 64'h0; T5_new = 64'h0; T6_new = 64'h0; T7_new = 64'h0;
      B0_new = 64'h0; B1_new = 64'h0; B2_new = 64'h0; B3_new = 64'h0;
      B4_new = 64'h0; B5_new = 64'h0; B6_new = 64'h0; B7_new = 64'h0;
      chain_we = 1'b0;

      if (chain_init)
        begin
          T0_new = IV_T0; T1_new = IV_T1; T2_new = IV_T2; T3_new = IV_T3;
          T4_new = IV_T4; T5_new = IV_T5; T6_new = IV_T6; T7_new = IV_T7;
          B0_new = IV_B0; B1_new = IV_B1; B2_new = IV_B2; B3_new = IV_B3;
          B4_new = IV_B4; B5_new = IV_B5; B6_new = IV_B6; B7_new = IV_B7;
          chain_we = 1'b1;
        end

      if (chain_update)
        begin
          // Anti-second-preimage feed-forward: XOR the OCTARX output with
          // the OCTARX input that was latched at state_init (ffu/ffl),
          // matching the C reference:
          //   t_next[i] = OCTARX(top_input)[i]    ^ top_input[i];
          //   b_next[i] = OCTARX(bottom_input)[i] ^ bottom_input[i];
          // chain_update is only ever asserted for compression runs
          // (see cuishen_ctrl_fsm / CTRL_DONE), so this path never fires
          // during finalization, which correctly has no feed-forward.
          T0_new = su0_reg ^ ffu0_reg; T1_new = su1_reg ^ ffu1_reg;
          T2_new = su2_reg ^ ffu2_reg; T3_new = su3_reg ^ ffu3_reg;
          T4_new = su4_reg ^ ffu4_reg; T5_new = su5_reg ^ ffu5_reg;
          T6_new = su6_reg ^ ffu6_reg; T7_new = su7_reg ^ ffu7_reg;
          B0_new = sl0_reg ^ ffl0_reg; B1_new = sl1_reg ^ ffl1_reg;
          B2_new = sl2_reg ^ ffl2_reg; B3_new = sl3_reg ^ ffl3_reg;
          B4_new = sl4_reg ^ ffl4_reg; B5_new = sl5_reg ^ ffl5_reg;
          B6_new = sl6_reg ^ ffl6_reg; B7_new = sl7_reg ^ ffl7_reg;
          chain_we = 1'b1;
        end
    end // chain_logic


  //----------------------------------------------------------------
  // digest_logic
  //
  // digest = y2 || y3 = upper state || lower state.
  //----------------------------------------------------------------
  always @*
    begin : digest_logic
      digest_new = {su0_reg, su1_reg, su2_reg, su3_reg, su4_reg, su5_reg, su6_reg, su7_reg,
                    sl0_reg, sl1_reg, sl2_reg, sl3_reg, sl4_reg, sl5_reg, sl6_reg, sl7_reg};
      digest_we  = digest_update;
    end // digest_logic


  //----------------------------------------------------------------
  // round_ctr
  //----------------------------------------------------------------
  always @*
    begin : round_ctr
      round_ctr_new = 7'h00;
      round_ctr_we  = 1'b0;

      if (round_ctr_rst)
        begin
          round_ctr_new = 7'h00;
          round_ctr_we  = 1'b1;
        end

      if (round_ctr_inc)
        begin
          round_ctr_new = round_ctr_reg + 1'b1;
          round_ctr_we  = 1'b1;
        end
    end // round_ctr


  //----------------------------------------------------------------
  // cuishen_ctrl_fsm
  //
  //   IDLE  : on init, preload IV (stay ready). On next/final, latch the
  //           request type and go to START.
  //   START : launch BOTH datapaths (key_init + state_init; the counter
  //           is XORed into su7/sl7 here too), go to ROUNDS.
  //   ROUNDS: run OCTARX_ROUNDS rounds, advancing the single key window
  //           each cycle; both datapaths step together.
  //   DONE  : finalization -> assemble digest; compression -> update
  //           chaining values. Return to IDLE, ready asserted.
  //----------------------------------------------------------------
  always @*
    begin : cuishen_ctrl_fsm
      chain_init       = 1'b0;
      chain_update     = 1'b0;
      state_init       = 1'b0;
      state_update     = 1'b0;
      digest_update    = 1'b0;
      key_init         = 1'b0;
      key_next         = 1'b0;
      round_ctr_inc    = 1'b0;
      round_ctr_rst    = 1'b0;
      final_new        = 1'b0;
      final_we         = 1'b0;
      digest_valid_new = 1'b0;
      digest_valid_we  = 1'b0;
      ready_new        = 1'b0;
      ready_we         = 1'b0;
      cuishen_ctrl_new = CTRL_IDLE;
      cuishen_ctrl_we  = 1'b0;

      case (cuishen_ctrl_reg)
        CTRL_IDLE:
          begin
            if (init)
              begin
                // Preload IV only; controller then issues next/final.
                chain_init       = 1'b1;
                digest_valid_new = 1'b0;
                digest_valid_we  = 1'b1;
                final_new        = 1'b0;
                final_we         = 1'b1;
                // stay IDLE, ready stays asserted
              end
            else if (next || finalize)
              begin
                ready_new        = 1'b0;
                ready_we         = 1'b1;
                digest_valid_new = 1'b0;
                digest_valid_we  = 1'b1;
                final_new        = finalize;
                final_we         = 1'b1;
                cuishen_ctrl_new = CTRL_START;
                cuishen_ctrl_we  = 1'b1;
              end
          end

        CTRL_START:
          begin
            // Launch both datapaths and the shared key schedule.
            key_init         = 1'b1;
            state_init       = 1'b1;
            round_ctr_rst    = 1'b1;
            cuishen_ctrl_new = CTRL_ROUNDS;
            cuishen_ctrl_we  = 1'b1;
          end

        CTRL_ROUNDS:
          begin
            state_update  = 1'b1;
            key_next      = 1'b1;
            round_ctr_inc = 1'b1;

            if (round_ctr_reg == (OCTARX_ROUNDS - 1))
              begin
                cuishen_ctrl_new = CTRL_DONE;
                cuishen_ctrl_we  = 1'b1;
              end
          end

        CTRL_DONE:
          begin
            if (final_reg)
              begin
                digest_update    = 1'b1;
                digest_valid_new = 1'b1;
                digest_valid_we  = 1'b1;
              end
            else
              begin
                chain_update = 1'b1;
              end
            ready_new        = 1'b1;
            ready_we         = 1'b1;
            cuishen_ctrl_new = CTRL_IDLE;
            cuishen_ctrl_we  = 1'b1;
          end

        default:
          begin
          end
      endcase // case (cuishen_ctrl_reg)
    end // cuishen_ctrl_fsm

endmodule // cuishen_core

//======================================================================
// EOF cuishen_core.v
//======================================================================
