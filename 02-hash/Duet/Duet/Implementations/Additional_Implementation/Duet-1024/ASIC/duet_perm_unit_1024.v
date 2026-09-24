//======================================================================
//
// duet_perm_unit_768.v
// ----------------------
// One 1920-bit permutation1920 datapath for Duet-768/1024: a 30-word (6
// columns x 5 rows) state register, advancing one round per clock
// (no unrolling), for ROUNDS=18 rounds. A single instance is shared
// between f1 (PI base 0) and f2 (PI base 18) by duet_core_768.v, exactly
// as in the Duet-512 core: f1 and f2 are multiplexed onto the same
// physical datapath since they run strictly sequentially.
//
// State word indexing follows the C reference's STATE1920_INDEX(x,y) =
// x*5+y, x in [0,6), y in [0,5): words s00..s04 are column 0, s05..s09
// column 1, ..., s25..s29 column 5.
//
// One round (permutation1920_round), fully unrolled and statically
// indexed (no runtime loops, no dynamic array/case indexing -- every
// rotate amount below is a compile-time constant):
//   1. sb   : nonlinear S-box, applied independently to each of the 6
//             columns.
//   2. l30  : linear diffusion layer over all 30 words, fixed taps at
//             offsets +3,+10,+13,+14,+15,+16,+18,+21,+26,+28 (mod 30).
//   3. round-constant XOR into word 0 (state[0][0]) only.
//   4. l64  : per-word triple-rotate-XOR (rotl(w,i) ^ rotl(w,i+21) ^
//             rotl(w,i+43), i = word's flat index 0..29).
//
//======================================================================

`default_nettype none

module duet_perm_unit_768(
                          input wire             clk,
                          input wire             reset_n,

                          input wire             start,      // load + begin
                          input wire [1919 : 0]  load_state, // s00..s29, MSB word first

                          input wire [63 : 0]    pi_data,    // round constant for current round

                          output wire            busy,
                          output wire            done,       // pulses for 1 cycle when finished
                          output wire [1919 : 0] result_state
                         );

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam ROUNDS = 18;

  localparam CTRL_IDLE   = 1'h0;
  localparam CTRL_ROUNDS = 1'h1;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [63 : 0] s00_reg, s01_reg, s02_reg, s03_reg, s04_reg;
  reg [63 : 0] s05_reg, s06_reg, s07_reg, s08_reg, s09_reg;
  reg [63 : 0] s10_reg, s11_reg, s12_reg, s13_reg, s14_reg;
  reg [63 : 0] s15_reg, s16_reg, s17_reg, s18_reg, s19_reg;
  reg [63 : 0] s20_reg, s21_reg, s22_reg, s23_reg, s24_reg;
  reg [63 : 0] s25_reg, s26_reg, s27_reg, s28_reg, s29_reg;

  reg [63 : 0] s00_new, s01_new, s02_new, s03_new, s04_new;
  reg [63 : 0] s05_new, s06_new, s07_new, s08_new, s09_new;
  reg [63 : 0] s10_new, s11_new, s12_new, s13_new, s14_new;
  reg [63 : 0] s15_new, s16_new, s17_new, s18_new, s19_new;
  reg [63 : 0] s20_new, s21_new, s22_new, s23_new, s24_new;
  reg [63 : 0] s25_new, s26_new, s27_new, s28_new, s29_new;
  reg          s_we;


  reg [4 : 0]  round_ctr_reg;
  reg [4 : 0]  round_ctr_new;
  reg          round_ctr_we;
  reg          round_ctr_inc;
  reg          round_ctr_rst;

  reg [0 : 0]  ctrl_reg;
  reg [0 : 0]  ctrl_new;
  reg          ctrl_we;

  reg          busy_reg, busy_new, busy_we;
  reg          done_reg, done_new, done_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg state_init;
  reg state_update;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign busy = busy_reg;
  assign done = done_reg;
  assign result_state = {s00_reg, s01_reg, s02_reg, s03_reg, s04_reg,
                         s05_reg, s06_reg, s07_reg, s08_reg, s09_reg,
                         s10_reg, s11_reg, s12_reg, s13_reg, s14_reg,
                         s15_reg, s16_reg, s17_reg, s18_reg, s19_reg,
                         s20_reg, s21_reg, s22_reg, s23_reg, s24_reg,
                         s25_reg, s26_reg, s27_reg, s28_reg, s29_reg};


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin : reg_update
      if (!reset_n)
        begin
          s00_reg <= 64'h0; s01_reg <= 64'h0; s02_reg <= 64'h0; s03_reg <= 64'h0; s04_reg <= 64'h0;
          s05_reg <= 64'h0; s06_reg <= 64'h0; s07_reg <= 64'h0; s08_reg <= 64'h0; s09_reg <= 64'h0;
          s10_reg <= 64'h0; s11_reg <= 64'h0; s12_reg <= 64'h0; s13_reg <= 64'h0; s14_reg <= 64'h0;
          s15_reg <= 64'h0; s16_reg <= 64'h0; s17_reg <= 64'h0; s18_reg <= 64'h0; s19_reg <= 64'h0;
          s20_reg <= 64'h0; s21_reg <= 64'h0; s22_reg <= 64'h0; s23_reg <= 64'h0; s24_reg <= 64'h0;
          s25_reg <= 64'h0; s26_reg <= 64'h0; s27_reg <= 64'h0; s28_reg <= 64'h0; s29_reg <= 64'h0;
          round_ctr_reg <= 5'h0;
          ctrl_reg      <= CTRL_IDLE;
          busy_reg      <= 1'b0;
          done_reg      <= 1'b0;
        end
      else
        begin
          if (s_we)
            begin
              s00_reg <= s00_new; s01_reg <= s01_new; s02_reg <= s02_new; s03_reg <= s03_new; s04_reg <= s04_new;
              s05_reg <= s05_new; s06_reg <= s06_new; s07_reg <= s07_new; s08_reg <= s08_new; s09_reg <= s09_new;
              s10_reg <= s10_new; s11_reg <= s11_new; s12_reg <= s12_new; s13_reg <= s13_new; s14_reg <= s14_new;
              s15_reg <= s15_new; s16_reg <= s16_new; s17_reg <= s17_new; s18_reg <= s18_new; s19_reg <= s19_new;
              s20_reg <= s20_new; s21_reg <= s21_new; s22_reg <= s22_new; s23_reg <= s23_new; s24_reg <= s24_new;
              s25_reg <= s25_new; s26_reg <= s26_new; s27_reg <= s27_new; s28_reg <= s28_new; s29_reg <= s29_new;
            end

          if (round_ctr_we)
            round_ctr_reg <= round_ctr_new;

          if (ctrl_we)
            ctrl_reg <= ctrl_new;

          if (busy_we)
            busy_reg <= busy_new;

          if (done_we)
            done_reg <= done_new;
        end
    end // reg_update

  //----------------------------------------------------------------
  // round_logic
  //
  // Fully unrolled, statically-indexed implementation of one
  // permutation1920 round: sb (6 columns), l30 (30 static taps),
  // round-constant XOR (word 0 only), l64 (30 static triple
  // rotate-XOR expressions; every shift amount below is a compile-time
  // constant 0..29, 21..50, or 43..72 (mod 64).
  //----------------------------------------------------------------
  always @*
    begin : round_logic
      reg [63:0] c0_t0;
      reg [63:0] c0_t1;
      reg [63:0] c0_t2;
      reg [63:0] c0_t3;
      reg [63:0] c0_t4;
      reg [63:0] c0_t5;
      reg [63:0] c0_t6;
      reg [63:0] c0_t7;
      reg [63:0] c0_t8;
      reg [63:0] c0_t9;
      reg [63:0] c0_t10;
      reg [63:0] c0_t11;
      reg [63:0] c0_t12;
      reg [63:0] c0_t13;
      reg [63:0] c0_t14;
      reg [63:0] c0_t15;
      reg [63:0] c0_t16;
      reg [63:0] c0_t17;
      reg [63:0] c0_t18;
      reg [63:0] c0_t19;
      reg [63:0] c0_t20;
      reg [63:0] c0_t21;
      reg [63:0] c0_t22;
      reg [63:0] c0_t23;
      reg [63:0] c0_t24;
      reg [63:0] c0_t25;
      reg [63:0] c0_t26;
      reg [63:0] c0_t27;
      reg [63:0] c0_t28;
      reg [63:0] c0_t29;
      reg [63:0] c0_t30;
      reg [63:0] c0_t31;
      reg [63:0] c0_t32;
      reg [63:0] c0_t33;
      reg [63:0] c0_t34;
      reg [63:0] c0_t35;
      reg [63:0] c0_t36;
      reg [63:0] c0_t37;
      reg [63:0] c0_t38;
      reg [63:0] c0_t39;
      reg [63:0] c0_t40;
      reg [63:0] c0_t41;
      reg [63:0] c0_t42;
      reg [63:0] c0_t43;
      reg [63:0] c0_t44;
      reg [63:0] c0_t45;
      reg [63:0] c0_t46;
      reg [63:0] c0_t47;
      reg [63:0] c0_t48;
      reg [63:0] c0_t49;
      reg [63:0] c0_t50;
      reg [63:0] c0_t51;
      reg [63:0] c1_t0;
      reg [63:0] c1_t1;
      reg [63:0] c1_t2;
      reg [63:0] c1_t3;
      reg [63:0] c1_t4;
      reg [63:0] c1_t5;
      reg [63:0] c1_t6;
      reg [63:0] c1_t7;
      reg [63:0] c1_t8;
      reg [63:0] c1_t9;
      reg [63:0] c1_t10;
      reg [63:0] c1_t11;
      reg [63:0] c1_t12;
      reg [63:0] c1_t13;
      reg [63:0] c1_t14;
      reg [63:0] c1_t15;
      reg [63:0] c1_t16;
      reg [63:0] c1_t17;
      reg [63:0] c1_t18;
      reg [63:0] c1_t19;
      reg [63:0] c1_t20;
      reg [63:0] c1_t21;
      reg [63:0] c1_t22;
      reg [63:0] c1_t23;
      reg [63:0] c1_t24;
      reg [63:0] c1_t25;
      reg [63:0] c1_t26;
      reg [63:0] c1_t27;
      reg [63:0] c1_t28;
      reg [63:0] c1_t29;
      reg [63:0] c1_t30;
      reg [63:0] c1_t31;
      reg [63:0] c1_t32;
      reg [63:0] c1_t33;
      reg [63:0] c1_t34;
      reg [63:0] c1_t35;
      reg [63:0] c1_t36;
      reg [63:0] c1_t37;
      reg [63:0] c1_t38;
      reg [63:0] c1_t39;
      reg [63:0] c1_t40;
      reg [63:0] c1_t41;
      reg [63:0] c1_t42;
      reg [63:0] c1_t43;
      reg [63:0] c1_t44;
      reg [63:0] c1_t45;
      reg [63:0] c1_t46;
      reg [63:0] c1_t47;
      reg [63:0] c1_t48;
      reg [63:0] c1_t49;
      reg [63:0] c1_t50;
      reg [63:0] c1_t51;
      reg [63:0] c2_t0;
      reg [63:0] c2_t1;
      reg [63:0] c2_t2;
      reg [63:0] c2_t3;
      reg [63:0] c2_t4;
      reg [63:0] c2_t5;
      reg [63:0] c2_t6;
      reg [63:0] c2_t7;
      reg [63:0] c2_t8;
      reg [63:0] c2_t9;
      reg [63:0] c2_t10;
      reg [63:0] c2_t11;
      reg [63:0] c2_t12;
      reg [63:0] c2_t13;
      reg [63:0] c2_t14;
      reg [63:0] c2_t15;
      reg [63:0] c2_t16;
      reg [63:0] c2_t17;
      reg [63:0] c2_t18;
      reg [63:0] c2_t19;
      reg [63:0] c2_t20;
      reg [63:0] c2_t21;
      reg [63:0] c2_t22;
      reg [63:0] c2_t23;
      reg [63:0] c2_t24;
      reg [63:0] c2_t25;
      reg [63:0] c2_t26;
      reg [63:0] c2_t27;
      reg [63:0] c2_t28;
      reg [63:0] c2_t29;
      reg [63:0] c2_t30;
      reg [63:0] c2_t31;
      reg [63:0] c2_t32;
      reg [63:0] c2_t33;
      reg [63:0] c2_t34;
      reg [63:0] c2_t35;
      reg [63:0] c2_t36;
      reg [63:0] c2_t37;
      reg [63:0] c2_t38;
      reg [63:0] c2_t39;
      reg [63:0] c2_t40;
      reg [63:0] c2_t41;
      reg [63:0] c2_t42;
      reg [63:0] c2_t43;
      reg [63:0] c2_t44;
      reg [63:0] c2_t45;
      reg [63:0] c2_t46;
      reg [63:0] c2_t47;
      reg [63:0] c2_t48;
      reg [63:0] c2_t49;
      reg [63:0] c2_t50;
      reg [63:0] c2_t51;
      reg [63:0] c3_t0;
      reg [63:0] c3_t1;
      reg [63:0] c3_t2;
      reg [63:0] c3_t3;
      reg [63:0] c3_t4;
      reg [63:0] c3_t5;
      reg [63:0] c3_t6;
      reg [63:0] c3_t7;
      reg [63:0] c3_t8;
      reg [63:0] c3_t9;
      reg [63:0] c3_t10;
      reg [63:0] c3_t11;
      reg [63:0] c3_t12;
      reg [63:0] c3_t13;
      reg [63:0] c3_t14;
      reg [63:0] c3_t15;
      reg [63:0] c3_t16;
      reg [63:0] c3_t17;
      reg [63:0] c3_t18;
      reg [63:0] c3_t19;
      reg [63:0] c3_t20;
      reg [63:0] c3_t21;
      reg [63:0] c3_t22;
      reg [63:0] c3_t23;
      reg [63:0] c3_t24;
      reg [63:0] c3_t25;
      reg [63:0] c3_t26;
      reg [63:0] c3_t27;
      reg [63:0] c3_t28;
      reg [63:0] c3_t29;
      reg [63:0] c3_t30;
      reg [63:0] c3_t31;
      reg [63:0] c3_t32;
      reg [63:0] c3_t33;
      reg [63:0] c3_t34;
      reg [63:0] c3_t35;
      reg [63:0] c3_t36;
      reg [63:0] c3_t37;
      reg [63:0] c3_t38;
      reg [63:0] c3_t39;
      reg [63:0] c3_t40;
      reg [63:0] c3_t41;
      reg [63:0] c3_t42;
      reg [63:0] c3_t43;
      reg [63:0] c3_t44;
      reg [63:0] c3_t45;
      reg [63:0] c3_t46;
      reg [63:0] c3_t47;
      reg [63:0] c3_t48;
      reg [63:0] c3_t49;
      reg [63:0] c3_t50;
      reg [63:0] c3_t51;
      reg [63:0] c4_t0;
      reg [63:0] c4_t1;
      reg [63:0] c4_t2;
      reg [63:0] c4_t3;
      reg [63:0] c4_t4;
      reg [63:0] c4_t5;
      reg [63:0] c4_t6;
      reg [63:0] c4_t7;
      reg [63:0] c4_t8;
      reg [63:0] c4_t9;
      reg [63:0] c4_t10;
      reg [63:0] c4_t11;
      reg [63:0] c4_t12;
      reg [63:0] c4_t13;
      reg [63:0] c4_t14;
      reg [63:0] c4_t15;
      reg [63:0] c4_t16;
      reg [63:0] c4_t17;
      reg [63:0] c4_t18;
      reg [63:0] c4_t19;
      reg [63:0] c4_t20;
      reg [63:0] c4_t21;
      reg [63:0] c4_t22;
      reg [63:0] c4_t23;
      reg [63:0] c4_t24;
      reg [63:0] c4_t25;
      reg [63:0] c4_t26;
      reg [63:0] c4_t27;
      reg [63:0] c4_t28;
      reg [63:0] c4_t29;
      reg [63:0] c4_t30;
      reg [63:0] c4_t31;
      reg [63:0] c4_t32;
      reg [63:0] c4_t33;
      reg [63:0] c4_t34;
      reg [63:0] c4_t35;
      reg [63:0] c4_t36;
      reg [63:0] c4_t37;
      reg [63:0] c4_t38;
      reg [63:0] c4_t39;
      reg [63:0] c4_t40;
      reg [63:0] c4_t41;
      reg [63:0] c4_t42;
      reg [63:0] c4_t43;
      reg [63:0] c4_t44;
      reg [63:0] c4_t45;
      reg [63:0] c4_t46;
      reg [63:0] c4_t47;
      reg [63:0] c4_t48;
      reg [63:0] c4_t49;
      reg [63:0] c4_t50;
      reg [63:0] c4_t51;
      reg [63:0] c5_t0;
      reg [63:0] c5_t1;
      reg [63:0] c5_t2;
      reg [63:0] c5_t3;
      reg [63:0] c5_t4;
      reg [63:0] c5_t5;
      reg [63:0] c5_t6;
      reg [63:0] c5_t7;
      reg [63:0] c5_t8;
      reg [63:0] c5_t9;
      reg [63:0] c5_t10;
      reg [63:0] c5_t11;
      reg [63:0] c5_t12;
      reg [63:0] c5_t13;
      reg [63:0] c5_t14;
      reg [63:0] c5_t15;
      reg [63:0] c5_t16;
      reg [63:0] c5_t17;
      reg [63:0] c5_t18;
      reg [63:0] c5_t19;
      reg [63:0] c5_t20;
      reg [63:0] c5_t21;
      reg [63:0] c5_t22;
      reg [63:0] c5_t23;
      reg [63:0] c5_t24;
      reg [63:0] c5_t25;
      reg [63:0] c5_t26;
      reg [63:0] c5_t27;
      reg [63:0] c5_t28;
      reg [63:0] c5_t29;
      reg [63:0] c5_t30;
      reg [63:0] c5_t31;
      reg [63:0] c5_t32;
      reg [63:0] c5_t33;
      reg [63:0] c5_t34;
      reg [63:0] c5_t35;
      reg [63:0] c5_t36;
      reg [63:0] c5_t37;
      reg [63:0] c5_t38;
      reg [63:0] c5_t39;
      reg [63:0] c5_t40;
      reg [63:0] c5_t41;
      reg [63:0] c5_t42;
      reg [63:0] c5_t43;
      reg [63:0] c5_t44;
      reg [63:0] c5_t45;
      reg [63:0] c5_t46;
      reg [63:0] c5_t47;
      reg [63:0] c5_t48;
      reg [63:0] c5_t49;
      reg [63:0] c5_t50;
      reg [63:0] c5_t51;
      reg [63:0] l30_0;
      reg [63:0] l30_1;
      reg [63:0] l30_2;
      reg [63:0] l30_3;
      reg [63:0] l30_4;
      reg [63:0] l30_5;
      reg [63:0] l30_6;
      reg [63:0] l30_7;
      reg [63:0] l30_8;
      reg [63:0] l30_9;
      reg [63:0] l30_10;
      reg [63:0] l30_11;
      reg [63:0] l30_12;
      reg [63:0] l30_13;
      reg [63:0] l30_14;
      reg [63:0] l30_15;
      reg [63:0] l30_16;
      reg [63:0] l30_17;
      reg [63:0] l30_18;
      reg [63:0] l30_19;
      reg [63:0] l30_20;
      reg [63:0] l30_21;
      reg [63:0] l30_22;
      reg [63:0] l30_23;
      reg [63:0] l30_24;
      reg [63:0] l30_25;
      reg [63:0] l30_26;
      reg [63:0] l30_27;
      reg [63:0] l30_28;
      reg [63:0] l30_29;
      reg [63:0] rc_0;
      reg [63:0] rc_1;
      reg [63:0] rc_2;
      reg [63:0] rc_3;
      reg [63:0] rc_4;
      reg [63:0] rc_5;
      reg [63:0] rc_6;
      reg [63:0] rc_7;
      reg [63:0] rc_8;
      reg [63:0] rc_9;
      reg [63:0] rc_10;
      reg [63:0] rc_11;
      reg [63:0] rc_12;
      reg [63:0] rc_13;
      reg [63:0] rc_14;
      reg [63:0] rc_15;
      reg [63:0] rc_16;
      reg [63:0] rc_17;
      reg [63:0] rc_18;
      reg [63:0] rc_19;
      reg [63:0] rc_20;
      reg [63:0] rc_21;
      reg [63:0] rc_22;
      reg [63:0] rc_23;
      reg [63:0] rc_24;
      reg [63:0] rc_25;
      reg [63:0] rc_26;
      reg [63:0] rc_27;
      reg [63:0] rc_28;
      reg [63:0] rc_29;

      c0_t0 = s03_reg & s04_reg;
      c0_t1 = s02_reg & s04_reg;
      c0_t2 = s02_reg & s03_reg;
      c0_t3 = s01_reg & s04_reg;
      c0_t4 = s01_reg & s02_reg;
      c0_t5 = s00_reg & s01_reg;
      c0_t6 = s04_reg ^ s02_reg;
      c0_t7 = s00_reg ^ c0_t0;
      c0_t8 = c0_t1 ^ c0_t2;
      c0_t9 = c0_t3 ^ c0_t4;
      c0_t10 = c0_t5 ^ c0_t6;
      c0_t11 = c0_t7 ^ c0_t8;
      c0_t12 = c0_t9 ^ c0_t10;
      c0_t13 = c0_t11 ^ c0_t12;
      c0_t14 = ~c0_t13;
      c0_t15 = s01_reg & s03_reg;
      c0_t16 = s00_reg & s02_reg;
      c0_t17 = s03_reg ^ s02_reg;
      c0_t18 = s00_reg ^ c0_t1;
      c0_t19 = c0_t2 ^ c0_t15;
      c0_t20 = c0_t4 ^ c0_t16;
      c0_t21 = c0_t17 ^ c0_t18;
      c0_t22 = c0_t19 ^ c0_t20;
      c0_t23 = c0_t21 ^ c0_t22;
      c0_t24 = ~c0_t23;
      c0_t25 = s00_reg & s04_reg;
      c0_t26 = s02_reg ^ s00_reg;
      c0_t27 = c0_t0 ^ c0_t1;
      c0_t28 = c0_t3 ^ c0_t15;
      c0_t29 = c0_t4 ^ c0_t25;
      c0_t30 = c0_t16 ^ c0_t5;
      c0_t31 = c0_t26 ^ c0_t27;
      c0_t32 = c0_t28 ^ c0_t29;
      c0_t33 = c0_t30 ^ c0_t31;
      c0_t34 = c0_t32 ^ c0_t33;
      c0_t35 = s00_reg & s03_reg;
      c0_t36 = s04_reg ^ s03_reg;
      c0_t37 = s01_reg ^ s00_reg;
      c0_t38 = c0_t4 ^ c0_t35;
      c0_t39 = c0_t16 ^ c0_t5;
      c0_t40 = c0_t36 ^ c0_t37;
      c0_t41 = c0_t38 ^ c0_t39;
      c0_t42 = c0_t40 ^ c0_t41;
      c0_t43 = ~c0_t42;
      c0_t44 = s04_reg ^ s02_reg;
      c0_t45 = s01_reg ^ s00_reg;
      c0_t46 = c0_t3 ^ c0_t15;
      c0_t47 = c0_t4 ^ c0_t25;
      c0_t48 = c0_t5 ^ c0_t44;
      c0_t49 = c0_t45 ^ c0_t46;
      c0_t50 = c0_t47 ^ c0_t48;
      c0_t51 = c0_t49 ^ c0_t50;
      c1_t0 = s08_reg & s09_reg;
      c1_t1 = s07_reg & s09_reg;
      c1_t2 = s07_reg & s08_reg;
      c1_t3 = s06_reg & s09_reg;
      c1_t4 = s06_reg & s07_reg;
      c1_t5 = s05_reg & s06_reg;
      c1_t6 = s09_reg ^ s07_reg;
      c1_t7 = s05_reg ^ c1_t0;
      c1_t8 = c1_t1 ^ c1_t2;
      c1_t9 = c1_t3 ^ c1_t4;
      c1_t10 = c1_t5 ^ c1_t6;
      c1_t11 = c1_t7 ^ c1_t8;
      c1_t12 = c1_t9 ^ c1_t10;
      c1_t13 = c1_t11 ^ c1_t12;
      c1_t14 = ~c1_t13;
      c1_t15 = s06_reg & s08_reg;
      c1_t16 = s05_reg & s07_reg;
      c1_t17 = s08_reg ^ s07_reg;
      c1_t18 = s05_reg ^ c1_t1;
      c1_t19 = c1_t2 ^ c1_t15;
      c1_t20 = c1_t4 ^ c1_t16;
      c1_t21 = c1_t17 ^ c1_t18;
      c1_t22 = c1_t19 ^ c1_t20;
      c1_t23 = c1_t21 ^ c1_t22;
      c1_t24 = ~c1_t23;
      c1_t25 = s05_reg & s09_reg;
      c1_t26 = s07_reg ^ s05_reg;
      c1_t27 = c1_t0 ^ c1_t1;
      c1_t28 = c1_t3 ^ c1_t15;
      c1_t29 = c1_t4 ^ c1_t25;
      c1_t30 = c1_t16 ^ c1_t5;
      c1_t31 = c1_t26 ^ c1_t27;
      c1_t32 = c1_t28 ^ c1_t29;
      c1_t33 = c1_t30 ^ c1_t31;
      c1_t34 = c1_t32 ^ c1_t33;
      c1_t35 = s05_reg & s08_reg;
      c1_t36 = s09_reg ^ s08_reg;
      c1_t37 = s06_reg ^ s05_reg;
      c1_t38 = c1_t4 ^ c1_t35;
      c1_t39 = c1_t16 ^ c1_t5;
      c1_t40 = c1_t36 ^ c1_t37;
      c1_t41 = c1_t38 ^ c1_t39;
      c1_t42 = c1_t40 ^ c1_t41;
      c1_t43 = ~c1_t42;
      c1_t44 = s09_reg ^ s07_reg;
      c1_t45 = s06_reg ^ s05_reg;
      c1_t46 = c1_t3 ^ c1_t15;
      c1_t47 = c1_t4 ^ c1_t25;
      c1_t48 = c1_t5 ^ c1_t44;
      c1_t49 = c1_t45 ^ c1_t46;
      c1_t50 = c1_t47 ^ c1_t48;
      c1_t51 = c1_t49 ^ c1_t50;
      c2_t0 = s13_reg & s14_reg;
      c2_t1 = s12_reg & s14_reg;
      c2_t2 = s12_reg & s13_reg;
      c2_t3 = s11_reg & s14_reg;
      c2_t4 = s11_reg & s12_reg;
      c2_t5 = s10_reg & s11_reg;
      c2_t6 = s14_reg ^ s12_reg;
      c2_t7 = s10_reg ^ c2_t0;
      c2_t8 = c2_t1 ^ c2_t2;
      c2_t9 = c2_t3 ^ c2_t4;
      c2_t10 = c2_t5 ^ c2_t6;
      c2_t11 = c2_t7 ^ c2_t8;
      c2_t12 = c2_t9 ^ c2_t10;
      c2_t13 = c2_t11 ^ c2_t12;
      c2_t14 = ~c2_t13;
      c2_t15 = s11_reg & s13_reg;
      c2_t16 = s10_reg & s12_reg;
      c2_t17 = s13_reg ^ s12_reg;
      c2_t18 = s10_reg ^ c2_t1;
      c2_t19 = c2_t2 ^ c2_t15;
      c2_t20 = c2_t4 ^ c2_t16;
      c2_t21 = c2_t17 ^ c2_t18;
      c2_t22 = c2_t19 ^ c2_t20;
      c2_t23 = c2_t21 ^ c2_t22;
      c2_t24 = ~c2_t23;
      c2_t25 = s10_reg & s14_reg;
      c2_t26 = s12_reg ^ s10_reg;
      c2_t27 = c2_t0 ^ c2_t1;
      c2_t28 = c2_t3 ^ c2_t15;
      c2_t29 = c2_t4 ^ c2_t25;
      c2_t30 = c2_t16 ^ c2_t5;
      c2_t31 = c2_t26 ^ c2_t27;
      c2_t32 = c2_t28 ^ c2_t29;
      c2_t33 = c2_t30 ^ c2_t31;
      c2_t34 = c2_t32 ^ c2_t33;
      c2_t35 = s10_reg & s13_reg;
      c2_t36 = s14_reg ^ s13_reg;
      c2_t37 = s11_reg ^ s10_reg;
      c2_t38 = c2_t4 ^ c2_t35;
      c2_t39 = c2_t16 ^ c2_t5;
      c2_t40 = c2_t36 ^ c2_t37;
      c2_t41 = c2_t38 ^ c2_t39;
      c2_t42 = c2_t40 ^ c2_t41;
      c2_t43 = ~c2_t42;
      c2_t44 = s14_reg ^ s12_reg;
      c2_t45 = s11_reg ^ s10_reg;
      c2_t46 = c2_t3 ^ c2_t15;
      c2_t47 = c2_t4 ^ c2_t25;
      c2_t48 = c2_t5 ^ c2_t44;
      c2_t49 = c2_t45 ^ c2_t46;
      c2_t50 = c2_t47 ^ c2_t48;
      c2_t51 = c2_t49 ^ c2_t50;
      c3_t0 = s18_reg & s19_reg;
      c3_t1 = s17_reg & s19_reg;
      c3_t2 = s17_reg & s18_reg;
      c3_t3 = s16_reg & s19_reg;
      c3_t4 = s16_reg & s17_reg;
      c3_t5 = s15_reg & s16_reg;
      c3_t6 = s19_reg ^ s17_reg;
      c3_t7 = s15_reg ^ c3_t0;
      c3_t8 = c3_t1 ^ c3_t2;
      c3_t9 = c3_t3 ^ c3_t4;
      c3_t10 = c3_t5 ^ c3_t6;
      c3_t11 = c3_t7 ^ c3_t8;
      c3_t12 = c3_t9 ^ c3_t10;
      c3_t13 = c3_t11 ^ c3_t12;
      c3_t14 = ~c3_t13;
      c3_t15 = s16_reg & s18_reg;
      c3_t16 = s15_reg & s17_reg;
      c3_t17 = s18_reg ^ s17_reg;
      c3_t18 = s15_reg ^ c3_t1;
      c3_t19 = c3_t2 ^ c3_t15;
      c3_t20 = c3_t4 ^ c3_t16;
      c3_t21 = c3_t17 ^ c3_t18;
      c3_t22 = c3_t19 ^ c3_t20;
      c3_t23 = c3_t21 ^ c3_t22;
      c3_t24 = ~c3_t23;
      c3_t25 = s15_reg & s19_reg;
      c3_t26 = s17_reg ^ s15_reg;
      c3_t27 = c3_t0 ^ c3_t1;
      c3_t28 = c3_t3 ^ c3_t15;
      c3_t29 = c3_t4 ^ c3_t25;
      c3_t30 = c3_t16 ^ c3_t5;
      c3_t31 = c3_t26 ^ c3_t27;
      c3_t32 = c3_t28 ^ c3_t29;
      c3_t33 = c3_t30 ^ c3_t31;
      c3_t34 = c3_t32 ^ c3_t33;
      c3_t35 = s15_reg & s18_reg;
      c3_t36 = s19_reg ^ s18_reg;
      c3_t37 = s16_reg ^ s15_reg;
      c3_t38 = c3_t4 ^ c3_t35;
      c3_t39 = c3_t16 ^ c3_t5;
      c3_t40 = c3_t36 ^ c3_t37;
      c3_t41 = c3_t38 ^ c3_t39;
      c3_t42 = c3_t40 ^ c3_t41;
      c3_t43 = ~c3_t42;
      c3_t44 = s19_reg ^ s17_reg;
      c3_t45 = s16_reg ^ s15_reg;
      c3_t46 = c3_t3 ^ c3_t15;
      c3_t47 = c3_t4 ^ c3_t25;
      c3_t48 = c3_t5 ^ c3_t44;
      c3_t49 = c3_t45 ^ c3_t46;
      c3_t50 = c3_t47 ^ c3_t48;
      c3_t51 = c3_t49 ^ c3_t50;
      c4_t0 = s23_reg & s24_reg;
      c4_t1 = s22_reg & s24_reg;
      c4_t2 = s22_reg & s23_reg;
      c4_t3 = s21_reg & s24_reg;
      c4_t4 = s21_reg & s22_reg;
      c4_t5 = s20_reg & s21_reg;
      c4_t6 = s24_reg ^ s22_reg;
      c4_t7 = s20_reg ^ c4_t0;
      c4_t8 = c4_t1 ^ c4_t2;
      c4_t9 = c4_t3 ^ c4_t4;
      c4_t10 = c4_t5 ^ c4_t6;
      c4_t11 = c4_t7 ^ c4_t8;
      c4_t12 = c4_t9 ^ c4_t10;
      c4_t13 = c4_t11 ^ c4_t12;
      c4_t14 = ~c4_t13;
      c4_t15 = s21_reg & s23_reg;
      c4_t16 = s20_reg & s22_reg;
      c4_t17 = s23_reg ^ s22_reg;
      c4_t18 = s20_reg ^ c4_t1;
      c4_t19 = c4_t2 ^ c4_t15;
      c4_t20 = c4_t4 ^ c4_t16;
      c4_t21 = c4_t17 ^ c4_t18;
      c4_t22 = c4_t19 ^ c4_t20;
      c4_t23 = c4_t21 ^ c4_t22;
      c4_t24 = ~c4_t23;
      c4_t25 = s20_reg & s24_reg;
      c4_t26 = s22_reg ^ s20_reg;
      c4_t27 = c4_t0 ^ c4_t1;
      c4_t28 = c4_t3 ^ c4_t15;
      c4_t29 = c4_t4 ^ c4_t25;
      c4_t30 = c4_t16 ^ c4_t5;
      c4_t31 = c4_t26 ^ c4_t27;
      c4_t32 = c4_t28 ^ c4_t29;
      c4_t33 = c4_t30 ^ c4_t31;
      c4_t34 = c4_t32 ^ c4_t33;
      c4_t35 = s20_reg & s23_reg;
      c4_t36 = s24_reg ^ s23_reg;
      c4_t37 = s21_reg ^ s20_reg;
      c4_t38 = c4_t4 ^ c4_t35;
      c4_t39 = c4_t16 ^ c4_t5;
      c4_t40 = c4_t36 ^ c4_t37;
      c4_t41 = c4_t38 ^ c4_t39;
      c4_t42 = c4_t40 ^ c4_t41;
      c4_t43 = ~c4_t42;
      c4_t44 = s24_reg ^ s22_reg;
      c4_t45 = s21_reg ^ s20_reg;
      c4_t46 = c4_t3 ^ c4_t15;
      c4_t47 = c4_t4 ^ c4_t25;
      c4_t48 = c4_t5 ^ c4_t44;
      c4_t49 = c4_t45 ^ c4_t46;
      c4_t50 = c4_t47 ^ c4_t48;
      c4_t51 = c4_t49 ^ c4_t50;
      c5_t0 = s28_reg & s29_reg;
      c5_t1 = s27_reg & s29_reg;
      c5_t2 = s27_reg & s28_reg;
      c5_t3 = s26_reg & s29_reg;
      c5_t4 = s26_reg & s27_reg;
      c5_t5 = s25_reg & s26_reg;
      c5_t6 = s29_reg ^ s27_reg;
      c5_t7 = s25_reg ^ c5_t0;
      c5_t8 = c5_t1 ^ c5_t2;
      c5_t9 = c5_t3 ^ c5_t4;
      c5_t10 = c5_t5 ^ c5_t6;
      c5_t11 = c5_t7 ^ c5_t8;
      c5_t12 = c5_t9 ^ c5_t10;
      c5_t13 = c5_t11 ^ c5_t12;
      c5_t14 = ~c5_t13;
      c5_t15 = s26_reg & s28_reg;
      c5_t16 = s25_reg & s27_reg;
      c5_t17 = s28_reg ^ s27_reg;
      c5_t18 = s25_reg ^ c5_t1;
      c5_t19 = c5_t2 ^ c5_t15;
      c5_t20 = c5_t4 ^ c5_t16;
      c5_t21 = c5_t17 ^ c5_t18;
      c5_t22 = c5_t19 ^ c5_t20;
      c5_t23 = c5_t21 ^ c5_t22;
      c5_t24 = ~c5_t23;
      c5_t25 = s25_reg & s29_reg;
      c5_t26 = s27_reg ^ s25_reg;
      c5_t27 = c5_t0 ^ c5_t1;
      c5_t28 = c5_t3 ^ c5_t15;
      c5_t29 = c5_t4 ^ c5_t25;
      c5_t30 = c5_t16 ^ c5_t5;
      c5_t31 = c5_t26 ^ c5_t27;
      c5_t32 = c5_t28 ^ c5_t29;
      c5_t33 = c5_t30 ^ c5_t31;
      c5_t34 = c5_t32 ^ c5_t33;
      c5_t35 = s25_reg & s28_reg;
      c5_t36 = s29_reg ^ s28_reg;
      c5_t37 = s26_reg ^ s25_reg;
      c5_t38 = c5_t4 ^ c5_t35;
      c5_t39 = c5_t16 ^ c5_t5;
      c5_t40 = c5_t36 ^ c5_t37;
      c5_t41 = c5_t38 ^ c5_t39;
      c5_t42 = c5_t40 ^ c5_t41;
      c5_t43 = ~c5_t42;
      c5_t44 = s29_reg ^ s27_reg;
      c5_t45 = s26_reg ^ s25_reg;
      c5_t46 = c5_t3 ^ c5_t15;
      c5_t47 = c5_t4 ^ c5_t25;
      c5_t48 = c5_t5 ^ c5_t44;
      c5_t49 = c5_t45 ^ c5_t46;
      c5_t50 = c5_t47 ^ c5_t48;
      c5_t51 = c5_t49 ^ c5_t50;
      l30_0 = (c0_t14 ^ c0_t43) ^ (c2_t14 ^ c2_t43) ^ ((c2_t51 ^ c3_t14) ^ (c3_t24 ^ c3_t43)) ^ ((c4_t24 ^ c5_t24) ^ c5_t43);
      l30_1 = (c0_t24 ^ c0_t51) ^ (c2_t24 ^ c2_t51) ^ ((c3_t14 ^ c3_t24) ^ (c3_t34 ^ c3_t51)) ^ ((c4_t34 ^ c5_t34) ^ c5_t51);
      l30_2 = (c0_t34 ^ c1_t14) ^ (c2_t34 ^ c3_t14) ^ ((c3_t24 ^ c3_t34) ^ (c3_t43 ^ c4_t14)) ^ ((c4_t43 ^ c5_t43) ^ c0_t14);
      l30_3 = (c0_t43 ^ c1_t24) ^ (c2_t43 ^ c3_t24) ^ ((c3_t34 ^ c3_t43) ^ (c3_t51 ^ c4_t24)) ^ ((c4_t51 ^ c5_t51) ^ c0_t24);
      l30_4 = (c0_t51 ^ c1_t34) ^ (c2_t51 ^ c3_t34) ^ ((c3_t43 ^ c3_t51) ^ (c4_t14 ^ c4_t34)) ^ ((c5_t14 ^ c0_t14) ^ c0_t34);
      l30_5 = (c1_t14 ^ c1_t43) ^ (c3_t14 ^ c3_t43) ^ ((c3_t51 ^ c4_t14) ^ (c4_t24 ^ c4_t43)) ^ ((c5_t24 ^ c0_t24) ^ c0_t43);
      l30_6 = (c1_t24 ^ c1_t51) ^ (c3_t24 ^ c3_t51) ^ ((c4_t14 ^ c4_t24) ^ (c4_t34 ^ c4_t51)) ^ ((c5_t34 ^ c0_t34) ^ c0_t51);
      l30_7 = (c1_t34 ^ c2_t14) ^ (c3_t34 ^ c4_t14) ^ ((c4_t24 ^ c4_t34) ^ (c4_t43 ^ c5_t14)) ^ ((c5_t43 ^ c0_t43) ^ c1_t14);
      l30_8 = (c1_t43 ^ c2_t24) ^ (c3_t43 ^ c4_t24) ^ ((c4_t34 ^ c4_t43) ^ (c4_t51 ^ c5_t24)) ^ ((c5_t51 ^ c0_t51) ^ c1_t24);
      l30_9 = (c1_t51 ^ c2_t34) ^ (c3_t51 ^ c4_t34) ^ ((c4_t43 ^ c4_t51) ^ (c5_t14 ^ c5_t34)) ^ ((c0_t14 ^ c1_t14) ^ c1_t34);
      l30_10 = (c2_t14 ^ c2_t43) ^ (c4_t14 ^ c4_t43) ^ ((c4_t51 ^ c5_t14) ^ (c5_t24 ^ c5_t43)) ^ ((c0_t24 ^ c1_t24) ^ c1_t43);
      l30_11 = (c2_t24 ^ c2_t51) ^ (c4_t24 ^ c4_t51) ^ ((c5_t14 ^ c5_t24) ^ (c5_t34 ^ c5_t51)) ^ ((c0_t34 ^ c1_t34) ^ c1_t51);
      l30_12 = (c2_t34 ^ c3_t14) ^ (c4_t34 ^ c5_t14) ^ ((c5_t24 ^ c5_t34) ^ (c5_t43 ^ c0_t14)) ^ ((c0_t43 ^ c1_t43) ^ c2_t14);
      l30_13 = (c2_t43 ^ c3_t24) ^ (c4_t43 ^ c5_t24) ^ ((c5_t34 ^ c5_t43) ^ (c5_t51 ^ c0_t24)) ^ ((c0_t51 ^ c1_t51) ^ c2_t24);
      l30_14 = (c2_t51 ^ c3_t34) ^ (c4_t51 ^ c5_t34) ^ ((c5_t43 ^ c5_t51) ^ (c0_t14 ^ c0_t34)) ^ ((c1_t14 ^ c2_t14) ^ c2_t34);
      l30_15 = (c3_t14 ^ c3_t43) ^ (c5_t14 ^ c5_t43) ^ ((c5_t51 ^ c0_t14) ^ (c0_t24 ^ c0_t43)) ^ ((c1_t24 ^ c2_t24) ^ c2_t43);
      l30_16 = (c3_t24 ^ c3_t51) ^ (c5_t24 ^ c5_t51) ^ ((c0_t14 ^ c0_t24) ^ (c0_t34 ^ c0_t51)) ^ ((c1_t34 ^ c2_t34) ^ c2_t51);
      l30_17 = (c3_t34 ^ c4_t14) ^ (c5_t34 ^ c0_t14) ^ ((c0_t24 ^ c0_t34) ^ (c0_t43 ^ c1_t14)) ^ ((c1_t43 ^ c2_t43) ^ c3_t14);
      l30_18 = (c3_t43 ^ c4_t24) ^ (c5_t43 ^ c0_t24) ^ ((c0_t34 ^ c0_t43) ^ (c0_t51 ^ c1_t24)) ^ ((c1_t51 ^ c2_t51) ^ c3_t24);
      l30_19 = (c3_t51 ^ c4_t34) ^ (c5_t51 ^ c0_t34) ^ ((c0_t43 ^ c0_t51) ^ (c1_t14 ^ c1_t34)) ^ ((c2_t14 ^ c3_t14) ^ c3_t34);
      l30_20 = (c4_t14 ^ c4_t43) ^ (c0_t14 ^ c0_t43) ^ ((c0_t51 ^ c1_t14) ^ (c1_t24 ^ c1_t43)) ^ ((c2_t24 ^ c3_t24) ^ c3_t43);
      l30_21 = (c4_t24 ^ c4_t51) ^ (c0_t24 ^ c0_t51) ^ ((c1_t14 ^ c1_t24) ^ (c1_t34 ^ c1_t51)) ^ ((c2_t34 ^ c3_t34) ^ c3_t51);
      l30_22 = (c4_t34 ^ c5_t14) ^ (c0_t34 ^ c1_t14) ^ ((c1_t24 ^ c1_t34) ^ (c1_t43 ^ c2_t14)) ^ ((c2_t43 ^ c3_t43) ^ c4_t14);
      l30_23 = (c4_t43 ^ c5_t24) ^ (c0_t43 ^ c1_t24) ^ ((c1_t34 ^ c1_t43) ^ (c1_t51 ^ c2_t24)) ^ ((c2_t51 ^ c3_t51) ^ c4_t24);
      l30_24 = (c4_t51 ^ c5_t34) ^ (c0_t51 ^ c1_t34) ^ ((c1_t43 ^ c1_t51) ^ (c2_t14 ^ c2_t34)) ^ ((c3_t14 ^ c4_t14) ^ c4_t34);
      l30_25 = (c5_t14 ^ c5_t43) ^ (c1_t14 ^ c1_t43) ^ ((c1_t51 ^ c2_t14) ^ (c2_t24 ^ c2_t43)) ^ ((c3_t24 ^ c4_t24) ^ c4_t43);
      l30_26 = (c5_t24 ^ c5_t51) ^ (c1_t24 ^ c1_t51) ^ ((c2_t14 ^ c2_t24) ^ (c2_t34 ^ c2_t51)) ^ ((c3_t34 ^ c4_t34) ^ c4_t51);
      l30_27 = (c5_t34 ^ c0_t14) ^ (c1_t34 ^ c2_t14) ^ ((c2_t24 ^ c2_t34) ^ (c2_t43 ^ c3_t14)) ^ ((c3_t43 ^ c4_t43) ^ c5_t14);
      l30_28 = (c5_t43 ^ c0_t24) ^ (c1_t43 ^ c2_t24) ^ ((c2_t34 ^ c2_t43) ^ (c2_t51 ^ c3_t24)) ^ ((c3_t51 ^ c4_t51) ^ c5_t24);
      l30_29 = (c5_t51 ^ c0_t34) ^ (c1_t51 ^ c2_t34) ^ ((c2_t43 ^ c2_t51) ^ (c3_t14 ^ c3_t34)) ^ ((c4_t14 ^ c5_t14) ^ c5_t34);
      rc_0 = l30_0 ^ pi_data;
      rc_1 = l30_1;
      rc_2 = l30_2;
      rc_3 = l30_3;
      rc_4 = l30_4;
      rc_5 = l30_5;
      rc_6 = l30_6;
      rc_7 = l30_7;
      rc_8 = l30_8;
      rc_9 = l30_9;
      rc_10 = l30_10;
      rc_11 = l30_11;
      rc_12 = l30_12;
      rc_13 = l30_13;
      rc_14 = l30_14;
      rc_15 = l30_15;
      rc_16 = l30_16;
      rc_17 = l30_17;
      rc_18 = l30_18;
      rc_19 = l30_19;
      rc_20 = l30_20;
      rc_21 = l30_21;
      rc_22 = l30_22;
      rc_23 = l30_23;
      rc_24 = l30_24;
      rc_25 = l30_25;
      rc_26 = l30_26;
      rc_27 = l30_27;
      rc_28 = l30_28;
      rc_29 = l30_29;

      s00_new = rc_0 ^ {rc_0[42:0], rc_0[63:43]} ^ {rc_0[20:0], rc_0[63:21]};
      s01_new = {rc_1[62:0], rc_1[63:63]} ^ {rc_1[41:0], rc_1[63:42]} ^ {rc_1[19:0], rc_1[63:20]};
      s02_new = {rc_2[61:0], rc_2[63:62]} ^ {rc_2[40:0], rc_2[63:41]} ^ {rc_2[18:0], rc_2[63:19]};
      s03_new = {rc_3[60:0], rc_3[63:61]} ^ {rc_3[39:0], rc_3[63:40]} ^ {rc_3[17:0], rc_3[63:18]};
      s04_new = {rc_4[59:0], rc_4[63:60]} ^ {rc_4[38:0], rc_4[63:39]} ^ {rc_4[16:0], rc_4[63:17]};
      s05_new = {rc_5[58:0], rc_5[63:59]} ^ {rc_5[37:0], rc_5[63:38]} ^ {rc_5[15:0], rc_5[63:16]};
      s06_new = {rc_6[57:0], rc_6[63:58]} ^ {rc_6[36:0], rc_6[63:37]} ^ {rc_6[14:0], rc_6[63:15]};
      s07_new = {rc_7[56:0], rc_7[63:57]} ^ {rc_7[35:0], rc_7[63:36]} ^ {rc_7[13:0], rc_7[63:14]};
      s08_new = {rc_8[55:0], rc_8[63:56]} ^ {rc_8[34:0], rc_8[63:35]} ^ {rc_8[12:0], rc_8[63:13]};
      s09_new = {rc_9[54:0], rc_9[63:55]} ^ {rc_9[33:0], rc_9[63:34]} ^ {rc_9[11:0], rc_9[63:12]};
      s10_new = {rc_10[53:0], rc_10[63:54]} ^ {rc_10[32:0], rc_10[63:33]} ^ {rc_10[10:0], rc_10[63:11]};
      s11_new = {rc_11[52:0], rc_11[63:53]} ^ {rc_11[31:0], rc_11[63:32]} ^ {rc_11[9:0], rc_11[63:10]};
      s12_new = {rc_12[51:0], rc_12[63:52]} ^ {rc_12[30:0], rc_12[63:31]} ^ {rc_12[8:0], rc_12[63:9]};
      s13_new = {rc_13[50:0], rc_13[63:51]} ^ {rc_13[29:0], rc_13[63:30]} ^ {rc_13[7:0], rc_13[63:8]};
      s14_new = {rc_14[49:0], rc_14[63:50]} ^ {rc_14[28:0], rc_14[63:29]} ^ {rc_14[6:0], rc_14[63:7]};
      s15_new = {rc_15[48:0], rc_15[63:49]} ^ {rc_15[27:0], rc_15[63:28]} ^ {rc_15[5:0], rc_15[63:6]};
      s16_new = {rc_16[47:0], rc_16[63:48]} ^ {rc_16[26:0], rc_16[63:27]} ^ {rc_16[4:0], rc_16[63:5]};
      s17_new = {rc_17[46:0], rc_17[63:47]} ^ {rc_17[25:0], rc_17[63:26]} ^ {rc_17[3:0], rc_17[63:4]};
      s18_new = {rc_18[45:0], rc_18[63:46]} ^ {rc_18[24:0], rc_18[63:25]} ^ {rc_18[2:0], rc_18[63:3]};
      s19_new = {rc_19[44:0], rc_19[63:45]} ^ {rc_19[23:0], rc_19[63:24]} ^ {rc_19[1:0], rc_19[63:2]};
      s20_new = {rc_20[43:0], rc_20[63:44]} ^ {rc_20[22:0], rc_20[63:23]} ^ {rc_20[0:0], rc_20[63:1]};
      s21_new = {rc_21[42:0], rc_21[63:43]} ^ {rc_21[21:0], rc_21[63:22]} ^ rc_21;
      s22_new = {rc_22[41:0], rc_22[63:42]} ^ {rc_22[20:0], rc_22[63:21]} ^ {rc_22[62:0], rc_22[63:63]};
      s23_new = {rc_23[40:0], rc_23[63:41]} ^ {rc_23[19:0], rc_23[63:20]} ^ {rc_23[61:0], rc_23[63:62]};
      s24_new = {rc_24[39:0], rc_24[63:40]} ^ {rc_24[18:0], rc_24[63:19]} ^ {rc_24[60:0], rc_24[63:61]};
      s25_new = {rc_25[38:0], rc_25[63:39]} ^ {rc_25[17:0], rc_25[63:18]} ^ {rc_25[59:0], rc_25[63:60]};
      s26_new = {rc_26[37:0], rc_26[63:38]} ^ {rc_26[16:0], rc_26[63:17]} ^ {rc_26[58:0], rc_26[63:59]};
      s27_new = {rc_27[36:0], rc_27[63:37]} ^ {rc_27[15:0], rc_27[63:16]} ^ {rc_27[57:0], rc_27[63:58]};
      s28_new = {rc_28[35:0], rc_28[63:36]} ^ {rc_28[14:0], rc_28[63:15]} ^ {rc_28[56:0], rc_28[63:57]};
      s29_new = {rc_29[34:0], rc_29[63:35]} ^ {rc_29[13:0], rc_29[63:14]} ^ {rc_29[55:0], rc_29[63:56]};

      if (state_init)
        begin
          s00_new = load_state[1919:1856]; s01_new = load_state[1855:1792];
          s02_new = load_state[1791:1728]; s03_new = load_state[1727:1664];
          s04_new = load_state[1663:1600]; s05_new = load_state[1599:1536];
          s06_new = load_state[1535:1472]; s07_new = load_state[1471:1408];
          s08_new = load_state[1407:1344]; s09_new = load_state[1343:1280];
          s10_new = load_state[1279:1216]; s11_new = load_state[1215:1152];
          s12_new = load_state[1151:1088]; s13_new = load_state[1087:1024];
          s14_new = load_state[1023:960]; s15_new = load_state[959:896];
          s16_new = load_state[895:832]; s17_new = load_state[831:768];
          s18_new = load_state[767:704]; s19_new = load_state[703:640];
          s20_new = load_state[639:576]; s21_new = load_state[575:512];
          s22_new = load_state[511:448]; s23_new = load_state[447:384];
          s24_new = load_state[383:320]; s25_new = load_state[319:256];
          s26_new = load_state[255:192]; s27_new = load_state[191:128];
          s28_new = load_state[127:64]; s29_new = load_state[63:0];
          s_we = 1'b1;
        end
      else if (state_update)
        begin
          s_we = 1'b1;
        end
      else
        begin
          s_we = 1'b0;
        end
    end // round_logic

  //----------------------------------------------------------------
  // round_ctr
  //----------------------------------------------------------------
  always @*
    begin : round_ctr
      round_ctr_new = 5'h0;
      round_ctr_we  = 1'b0;

      if (round_ctr_rst)
        begin
          round_ctr_new = 5'h0;
          round_ctr_we  = 1'b1;
        end

      if (round_ctr_inc)
        begin
          round_ctr_new = round_ctr_reg + 1'b1;
          round_ctr_we  = 1'b1;
        end
    end // round_ctr


  //----------------------------------------------------------------
  // ctrl_fsm
  //
  //   IDLE  : on start, load state, reset round counter, go to ROUNDS.
  //   ROUNDS: run ROUNDS rounds (1/cycle); on the last round, go DONE.
  //   DONE  : pulse done for one cycle, go back to IDLE.
  //----------------------------------------------------------------
  always @*
    begin : ctrl_fsm
      state_init    = 1'b0;
      state_update  = 1'b0;
      round_ctr_inc = 1'b0;
      round_ctr_rst = 1'b0;
      busy_new = 1'b0; busy_we = 1'b0;
      done_new = 1'b0; done_we = 1'b0;
      ctrl_new = CTRL_IDLE; ctrl_we = 1'b0;

      case (ctrl_reg)
        CTRL_IDLE:
          begin
            done_new = 1'b0; done_we = 1'b1;
            if (start)
              begin
                state_init    = 1'b1;
                round_ctr_rst = 1'b1;
                busy_new = 1'b1; busy_we = 1'b1;
                ctrl_new = CTRL_ROUNDS; ctrl_we = 1'b1;
              end
          end

        CTRL_ROUNDS:
          begin
            state_update  = 1'b1;
            round_ctr_inc = 1'b1;
            if (round_ctr_reg == (ROUNDS - 1))
              begin
                // The last round's result becomes valid in s*_reg at the
                // end of THIS cycle (state_update writes it). Assert
                // done in this SAME cycle (not one cycle later) so a
                // consumer FSM sees done=1 exactly when the result is
                // first stable, and transition straight to IDLE.
                done_new = 1'b1; done_we = 1'b1;
                busy_new = 1'b0; busy_we = 1'b1;
                ctrl_new = CTRL_IDLE; ctrl_we = 1'b1;
              end
          end

        default: ;
      endcase
    end // ctrl_fsm

endmodule // duet_perm_unit_768

//======================================================================
// EOF duet_perm_unit_768.v
//======================================================================
