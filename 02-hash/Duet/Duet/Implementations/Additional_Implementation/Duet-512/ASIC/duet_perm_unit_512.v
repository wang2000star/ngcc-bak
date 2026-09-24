//======================================================================
//
// duet_perm_unit_512.v
// -----------------
// One 960-bit permutation960 datapath for Duet-512: a 15-word (3
// columns x 5 rows) state register, advancing one round per clock
// (no unrolling), for ROUNDS=12 rounds. Two instances are used in
// duet_core_512.v: one for f1 (PI base 0), one for f2 (PI base 12). They
// are NOT run concurrently within the same absorbed message block
// (f2's input depends on f1's output), but using two separate,
// non-multiplexed instances avoids any control overhead for switching
// the same physical datapath between f1 and f2 roles.
//
// State word indexing follows the C reference's STATE960_INDEX(x,y) =
// x*5+y, x in [0,3), y in [0,5): words s00..s04 are column 0, s05..s09
// column 1, s10..s14 column 2.
//
// One round (permutation960_round), fully unrolled and statically
// indexed (no runtime loops, no dynamic array/case indexing -- every
// rotate amount below is a compile-time constant):
//   1. sb   : nonlinear S-box, applied independently to each column.
//   2. l15  : linear diffusion layer over all 15 words, fixed taps at
//             offsets +3,+4,+5,+7,+8,+13 (mod 15).
//   3. round-constant XOR into word 0 (state[0][0]) only.
//   4. l64  : per-word triple-rotate-XOR (rotl(w,i) ^ rotl(w,i+21) ^
//             rotl(w,i+43), i = word's flat index 0..14).
//
//======================================================================

`default_nettype none

module duet_perm_unit(
                      input wire             clk,
                      input wire             reset_n,

                      input wire             start,      // load + begin
                      input wire [959 : 0]   load_state, // s00..s14, MSB word first

                      input wire [63 : 0]    pi_data,    // round constant for current round

                      output wire            busy,
                      output wire            done,       // pulses for 1 cycle when finished
                      output wire [959 : 0]  result_state
                     );

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam ROUNDS = 12;

  localparam CTRL_IDLE   = 1'h0;
  localparam CTRL_ROUNDS = 1'h1;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [63 : 0] s00_reg, s01_reg, s02_reg, s03_reg, s04_reg;
  reg [63 : 0] s05_reg, s06_reg, s07_reg, s08_reg, s09_reg;
  reg [63 : 0] s10_reg, s11_reg, s12_reg, s13_reg, s14_reg;

  reg [63 : 0] s00_new, s01_new, s02_new, s03_new, s04_new;
  reg [63 : 0] s05_new, s06_new, s07_new, s08_new, s09_new;
  reg [63 : 0] s10_new, s11_new, s12_new, s13_new, s14_new;
  reg          s_we;

  reg [3 : 0]  round_ctr_reg;
  reg [3 : 0]  round_ctr_new;
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
                         s10_reg, s11_reg, s12_reg, s13_reg, s14_reg};


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
          round_ctr_reg <= 4'h0;
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
  // permutation960 round: sb (3 columns), l15 (15 static taps),
  // round-constant XOR (word 0 only), l64 (15 static triple
  // rotate-XOR expressions; every shift amount below is a compile-time
  // constant 0..14, 21..35, or 43..57).
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
      reg [63:0] l15_0;
      reg [63:0] l15_1;
      reg [63:0] l15_2;
      reg [63:0] l15_3;
      reg [63:0] l15_4;
      reg [63:0] l15_5;
      reg [63:0] l15_6;
      reg [63:0] l15_7;
      reg [63:0] l15_8;
      reg [63:0] l15_9;
      reg [63:0] l15_10;
      reg [63:0] l15_11;
      reg [63:0] l15_12;
      reg [63:0] l15_13;
      reg [63:0] l15_14;
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
      l15_0 = (c0_t14 ^ c0_t43) ^ (c0_t51 ^ c1_t14) ^ ((c1_t34 ^ c1_t43) ^ c2_t43);
      l15_1 = (c0_t24 ^ c0_t51) ^ (c1_t14 ^ c1_t24) ^ ((c1_t43 ^ c1_t51) ^ c2_t51);
      l15_2 = (c0_t34 ^ c1_t14) ^ (c1_t24 ^ c1_t34) ^ ((c1_t51 ^ c2_t14) ^ c0_t14);
      l15_3 = (c0_t43 ^ c1_t24) ^ (c1_t34 ^ c1_t43) ^ ((c2_t14 ^ c2_t24) ^ c0_t24);
      l15_4 = (c0_t51 ^ c1_t34) ^ (c1_t43 ^ c1_t51) ^ ((c2_t24 ^ c2_t34) ^ c0_t34);
      l15_5 = (c1_t14 ^ c1_t43) ^ (c1_t51 ^ c2_t14) ^ ((c2_t34 ^ c2_t43) ^ c0_t43);
      l15_6 = (c1_t24 ^ c1_t51) ^ (c2_t14 ^ c2_t24) ^ ((c2_t43 ^ c2_t51) ^ c0_t51);
      l15_7 = (c1_t34 ^ c2_t14) ^ (c2_t24 ^ c2_t34) ^ ((c2_t51 ^ c0_t14) ^ c1_t14);
      l15_8 = (c1_t43 ^ c2_t24) ^ (c2_t34 ^ c2_t43) ^ ((c0_t14 ^ c0_t24) ^ c1_t24);
      l15_9 = (c1_t51 ^ c2_t34) ^ (c2_t43 ^ c2_t51) ^ ((c0_t24 ^ c0_t34) ^ c1_t34);
      l15_10 = (c2_t14 ^ c2_t43) ^ (c2_t51 ^ c0_t14) ^ ((c0_t34 ^ c0_t43) ^ c1_t43);
      l15_11 = (c2_t24 ^ c2_t51) ^ (c0_t14 ^ c0_t24) ^ ((c0_t43 ^ c0_t51) ^ c1_t51);
      l15_12 = (c2_t34 ^ c0_t14) ^ (c0_t24 ^ c0_t34) ^ ((c0_t51 ^ c1_t14) ^ c2_t14);
      l15_13 = (c2_t43 ^ c0_t24) ^ (c0_t34 ^ c0_t43) ^ ((c1_t14 ^ c1_t24) ^ c2_t24);
      l15_14 = (c2_t51 ^ c0_t34) ^ (c0_t43 ^ c0_t51) ^ ((c1_t24 ^ c1_t34) ^ c2_t34);
      rc_0 = l15_0 ^ pi_data;
      rc_1 = l15_1;
      rc_2 = l15_2;
      rc_3 = l15_3;
      rc_4 = l15_4;
      rc_5 = l15_5;
      rc_6 = l15_6;
      rc_7 = l15_7;
      rc_8 = l15_8;
      rc_9 = l15_9;
      rc_10 = l15_10;
      rc_11 = l15_11;
      rc_12 = l15_12;
      rc_13 = l15_13;
      rc_14 = l15_14;

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

      if (state_init)
        begin
          s00_new = load_state[959:896]; s01_new = load_state[895:832];
          s02_new = load_state[831:768]; s03_new = load_state[767:704];
          s04_new = load_state[703:640]; s05_new = load_state[639:576];
          s06_new = load_state[575:512]; s07_new = load_state[511:448];
          s08_new = load_state[447:384]; s09_new = load_state[383:320];
          s10_new = load_state[319:256]; s11_new = load_state[255:192];
          s12_new = load_state[191:128]; s13_new = load_state[127:64];
          s14_new = load_state[63:0];
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
      round_ctr_new = 4'h0;
      round_ctr_we  = 1'b0;

      if (round_ctr_rst)
        begin
          round_ctr_new = 4'h0;
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

endmodule // duet_perm_unit

//======================================================================
// EOF duet_perm_unit.v
//======================================================================
