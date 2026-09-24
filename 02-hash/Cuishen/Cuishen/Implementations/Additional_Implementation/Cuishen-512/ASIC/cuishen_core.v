//======================================================================
//
// cuishen_core.v   (LATENCY version - parallel datapaths, shortest path)
// --------------
// Verilog 2001 implementation of the Cuishen-512 hash core. Still
// modelled on sha512_core.v (same {x_reg,x_new,x_we} register style,
// same round-counter FSM, every round is one clock, no loop unrolling),
// but the dual OCTARX passes that v1 ran serially are now executed in
// PARALLEL over a single shared key schedule.
//
// Compression  : t_next = OCTARX(lsb_separate(t,0), key=m||b_prev, cnt)
//                b_next = OCTARX(lsb_separate(t,1), key=m||b_prev, cnt)
// Finalization : y2 = OCTARX(C2, key=t||b||tail, cnt)
//                y3 = OCTARX(C3, key=t||b||tail, cnt)
//                digest = y2 || y3
//
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

                    // 768-bit zero-padded tail for finalization
                    input wire [767 : 0]   tail_words,

                    output wire            ready,
                    output wire [511 : 0]  digest,
                    output wire            digest_valid
                   );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam OCTARX_ROUNDS = 64;

  // round-function rotation constants
  localparam RA = 7;
  localparam RB = 31;
  localparam RC = 56;
  localparam RD = 20;

  localparam CTRL_IDLE   = 2'h0;
  localparam CTRL_START  = 2'h1;
  localparam CTRL_ROUNDS = 2'h2;
  localparam CTRL_DONE   = 2'h3;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  // 256-bit UPPER datapath state.
  reg [63 : 0] su0_reg, su0_new;
  reg [63 : 0] su1_reg, su1_new;
  reg [63 : 0] su2_reg, su2_new;
  reg [63 : 0] su3_reg, su3_new;

  // 256-bit LOWER datapath state.
  reg [63 : 0] sl0_reg, sl0_new;
  reg [63 : 0] sl1_reg, sl1_new;
  reg [63 : 0] sl2_reg, sl2_new;
  reg [63 : 0] sl3_reg, sl3_new;

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

  reg [63 : 0] ffl0_reg, ffl0_new;
  reg [63 : 0] ffl1_reg, ffl1_new;
  reg [63 : 0] ffl2_reg, ffl2_new;
  reg [63 : 0] ffl3_reg, ffl3_new;

  reg          ff_we; // shared write-enable for the feed-forward registers

  // chaining values t (upper) and b (lower), 256-bit each.
  reg [63 : 0] T0_reg, T0_new;
  reg [63 : 0] T1_reg, T1_new;
  reg [63 : 0] T2_reg, T2_new;
  reg [63 : 0] T3_reg, T3_new;
  reg [63 : 0] B0_reg, B0_new;
  reg [63 : 0] B1_reg, B1_new;
  reg [63 : 0] B2_reg, B2_new;
  reg [63 : 0] B3_reg, B3_new;
  reg          chain_we;

  // digest holding register (y2 || y3)
  reg [511 : 0] digest_reg;
  reg [511 : 0] digest_new;
  reg           digest_we;

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

  wire [63 : 0] pi_data;
  wire [63 : 0] ka, kb, kc, kd;

  wire [63 : 0] IV_T0, IV_T1, IV_T2, IV_T3;
  wire [63 : 0] IV_B0, IV_B1, IV_B2, IV_B3;

  reg [1279 : 0] master_key;
  reg [127 : 0]  key_counter;

  // cipher inputs for the two parallel passes.
  reg [63 : 0] cu0, cu1, cu2, cu3;   // upper input
  reg [63 : 0] cl0, cl1, cl2, cl3;   // lower input


  //----------------------------------------------------------------
  // Module instantiations.
  //----------------------------------------------------------------
  cuishen_pi_constants pi_inst(
                               .addr(round_ctr_reg),
                               .PI(pi_data)
                              );

  cuishen_iv_constants iv_inst(
                               .T0(IV_T0), .T1(IV_T1), .T2(IV_T2), .T3(IV_T3),
                               .B0(IV_B0), .B1(IV_B1), .B2(IV_B2), .B3(IV_B3)
                              );

  cuishen_key_mem key_mem_inst(
                               .clk(clk),
                               .reset_n(reset_n),
                               .master_key(master_key),
                               .counter(key_counter),
                               .init(key_init),
                               .next(key_next),
                               .ka(ka), .kb(kb), .kc(kc), .kd(kd)
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
  // For finalization the 1280-bit key is t || b || tail. For compression
  // the key is the 1024-bit message block concatenated with the current
  // 256-bit lower chaining value b. Selection uses the latched final_reg.
  //----------------------------------------------------------------
  always @*
    begin : key_select
      key_counter = {64'h0, counter_bits};

      if (final_reg)
        master_key = {T0_reg, T1_reg, T2_reg, T3_reg,
                      B0_reg, B1_reg, B2_reg, B3_reg,
                      tail_words};
      else
        master_key = {block, B0_reg, B1_reg, B2_reg, B3_reg};
    end // key_select


  //----------------------------------------------------------------
  // cipher_input_select
  //
  // Builds BOTH pass inputs at once (no load_lower phase needed any more
  // since the passes are concurrent):
  //   compression : upper = lsb_separate(t,0), lower = lsb_separate(t,1)
  //   finalization: upper = C2 = {0,0,0,2},    lower = C3 = {0,0,0,3}
  //----------------------------------------------------------------
  always @*
    begin : cipher_input_select
      if (final_reg)
        begin
          cu0 = 64'h0; cu1 = 64'h0; cu2 = 64'h0; cu3 = 64'h2;
          cl0 = 64'h0; cl1 = 64'h0; cl2 = 64'h0; cl3 = 64'h3;
        end
      else
        begin
          cu0 = T0_reg; cu1 = T1_reg; cu2 = T2_reg; cu3 = T3_reg;                    // XOR 0 == no-op
          cl0 = T0_reg; cl1 = T1_reg; cl2 = T2_reg; cl3 = {T3_reg[63:1], ~T3_reg[0]}; // XOR 1 == flip LSB
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
          sl0_reg <= 64'h0; sl1_reg <= 64'h0; sl2_reg <= 64'h0; sl3_reg <= 64'h0;
          ffu0_reg <= 64'h0; ffu1_reg <= 64'h0; ffu2_reg <= 64'h0; ffu3_reg <= 64'h0;
          ffl0_reg <= 64'h0; ffl1_reg <= 64'h0; ffl2_reg <= 64'h0; ffl3_reg <= 64'h0;
          T0_reg  <= 64'h0; T1_reg  <= 64'h0; T2_reg  <= 64'h0; T3_reg  <= 64'h0;
          B0_reg  <= 64'h0; B1_reg  <= 64'h0; B2_reg  <= 64'h0; B3_reg  <= 64'h0;
          digest_reg       <= 512'h0;
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
              sl0_reg <= sl0_new; sl1_reg <= sl1_new;
              sl2_reg <= sl2_new; sl3_reg <= sl3_new;
            end

          if (ff_we)
            begin
              ffu0_reg <= ffu0_new; ffu1_reg <= ffu1_new;
              ffu2_reg <= ffu2_new; ffu3_reg <= ffu3_new;
              ffl0_reg <= ffl0_new; ffl1_reg <= ffl1_new;
              ffl2_reg <= ffl2_new; ffl3_reg <= ffl3_new;
            end

          if (chain_we)
            begin
              T0_reg <= T0_new; T1_reg <= T1_new;
              T2_reg <= T2_new; T3_reg <= T3_new;
              B0_reg <= B0_new; B1_reg <= B1_new;
              B2_reg <= B2_new; B3_reg <= B3_new;
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
  // round_logic  (LATENCY-optimised)
  //
  // Two parallel OCTARX round functions sharing one key {ka,kb,kc,kd}
  // and PI[round]. To shorten the datapath critical path, the key-side
  // XOR term  kap = ka ^ PI[round]  is factored out ONCE (it is identical
  // for both datapaths and depends only on the key window + ROM, both
  // register/ROM outputs). Each datapath's pre-rotation term then needs
  // only a single 2-input XOR ( s0 ^ kap ) instead of a 3-input reduction
  // ( s0 ^ ka ^ PI ), so the per-round critical path is
  //     reg -> XOR(1 level) -> rotate(wires) -> ADD -> reg
  // This is a pure combinational re-association: no pipeline registers,
  // no extra cycles, identical results to the v2 core.
  //----------------------------------------------------------------
  always @*
    begin : round_logic
      // shared key-side term (computed once for both datapaths)
      reg [63 : 0] kap;
      // upper intermediates
      reg [63 : 0] ux0, ux1, utt, utkd, utkc;
      reg [63 : 0] ux0r, utd_r, ux1r, utc_r;
      // lower intermediates
      reg [63 : 0] lx0, lx1, ltt, ltkd, ltkc;
      reg [63 : 0] lx0r, ltd_r, lx1r, ltc_r;

      su0_new = 64'h0; su1_new = 64'h0; su2_new = 64'h0; su3_new = 64'h0;
      sl0_new = 64'h0; sl1_new = 64'h0; sl2_new = 64'h0; sl3_new = 64'h0;
      s_we    = 1'b0;

      ffu0_new = 64'h0; ffu1_new = 64'h0; ffu2_new = 64'h0; ffu3_new = 64'h0;
      ffl0_new = 64'h0; ffl1_new = 64'h0; ffl2_new = 64'h0; ffl3_new = 64'h0;
      ff_we    = 1'b0;

      // ---- shared term ----
      kap = ka ^ pi_data;

      // ---- upper datapath combinational round ----
      ux0  = su0_reg ^ kap;          // single 2-input XOR
      ux1  = su1_reg ^ kb;
      utt  = su2_reg ^ su3_reg;
      utkd = utt ^ kd;
      utkc = utt ^ kc;
      ux0r  = {ux0[63-RA:0],  ux0[63:64-RA]};
      utd_r = {utkd[63-RD:0], utkd[63:64-RD]};
      ux1r  = {ux1[63-RB:0],  ux1[63:64-RB]};
      utc_r = {utkc[63-RC:0], utkc[63:64-RC]};

      // ---- lower datapath combinational round ----
      lx0  = sl0_reg ^ kap;          // single 2-input XOR (shares kap)
      lx1  = sl1_reg ^ kb;
      ltt  = sl2_reg ^ sl3_reg;
      ltkd = ltt ^ kd;
      ltkc = ltt ^ kc;
      lx0r  = {lx0[63-RA:0],  lx0[63:64-RA]};
      ltd_r = {ltkd[63-RD:0], ltkd[63:64-RD]};
      lx1r  = {lx1[63-RB:0],  lx1[63:64-RB]};
      ltc_r = {ltkc[63-RC:0], ltkc[63:64-RC]};

      if (state_init)
        begin
          su0_new = cu0; su1_new = cu1; su2_new = cu2; su3_new = cu3;
          sl0_new = cl0; sl1_new = cl1; sl2_new = cl2; sl3_new = cl3;
          s_we    = 1'b1;

          // Latch the OCTARX input itself (same cu/cl values) so it
          // survives the 64-round encryption and is available for the
          // feed-forward XOR-back in chain_logic. Harmless to also latch
          // during finalization runs since chain_logic simply never
          // reads ff*_reg in that case.
          ffu0_new = cu0; ffu1_new = cu1; ffu2_new = cu2; ffu3_new = cu3;
          ffl0_new = cl0; ffl1_new = cl1; ffl2_new = cl2; ffl3_new = cl3;
          ff_we    = 1'b1;
        end

      if (state_update)
        begin
          su0_new = su2_reg;
          su1_new = su3_reg;
          su2_new = ux0r + utd_r;
          su3_new = ux1r + utc_r;

          sl0_new = sl2_reg;
          sl1_new = sl3_reg;
          sl2_new = lx0r + ltd_r;
          sl3_new = lx1r + ltc_r;

          s_we    = 1'b1;
        end
    end // round_logic


  //----------------------------------------------------------------
  // chain_logic
  //
  // chain_init  : load IV_1 -> t, IV_2 -> b.
  // chain_update: t <- upper result (su), b <- lower result (sl).
  //----------------------------------------------------------------
  always @*
    begin : chain_logic
      T0_new = 64'h0; T1_new = 64'h0; T2_new = 64'h0; T3_new = 64'h0;
      B0_new = 64'h0; B1_new = 64'h0; B2_new = 64'h0; B3_new = 64'h0;
      chain_we = 1'b0;

      if (chain_init)
        begin
          T0_new = IV_T0; T1_new = IV_T1; T2_new = IV_T2; T3_new = IV_T3;
          B0_new = IV_B0; B1_new = IV_B1; B2_new = IV_B2; B3_new = IV_B3;
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
          B0_new = sl0_reg ^ ffl0_reg; B1_new = sl1_reg ^ ffl1_reg;
          B2_new = sl2_reg ^ ffl2_reg; B3_new = sl3_reg ^ ffl3_reg;
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
      digest_new = {su0_reg, su1_reg, su2_reg, su3_reg,
                    sl0_reg, sl1_reg, sl2_reg, sl3_reg};
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
  //   START : launch BOTH datapaths (key_init + state_init), go to ROUNDS.
  //   ROUNDS: run 64 rounds, advancing the single key window each cycle;
  //           both datapaths step together.
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
