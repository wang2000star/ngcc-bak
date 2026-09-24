//======================================================================
//
// cuishen_key_mem.v
// -----------------
// The round-key schedule memory for the Cuishen-1024 block cipher
// (OCTARX), per CryptHash_Cuishen-1024v5.c. Direct analogue of the
// 512-bit design's cuishen_key_mem.v: a sliding window of registers
// loaded from the 1536-bit master key on "init" and advanced one round
// per "next", emitting one 512-bit round key {rk0..rk7} each cycle.
//
// Unlike the earlier 1024-bit revision, the counter IS part of this
// sliding window again (matching the 512-bit design's structure): a
// separate 2-word cnt[0..1] window is loaded from the 128-bit counter
// input and advanced (rotl by 2) every round, exactly as in the
// 512-bit cuishen_key_mem.v.
//
// Master key layout (1536 bit) : m[0..15] (1024 bit) || b[0..7] (512 bit)
// Counter (128 bit)            : cnt[0], cnt[1]
//
// Round key (per round i):
//   rk0 = m[0] ^ b[0] ^ cnt[0]
//   rk1 = m[1] ^ b[1] ^ cnt[1]
//   rk2 = m[8] ^ b[2]
//   rk3 = m[9] ^ b[3]
//   rk4 = b[4]
//   rk5 = b[5]
//   rk6 = b[6]
//   rk7 = b[7]
//
// State update (m, b, cnt) follows the C reference key_schedule().
//
//======================================================================

`default_nettype none

module cuishen_key_mem(
                       input wire             clk,
                       input wire             reset_n,

                       input wire [1535 : 0]  master_key, // m[0..15] || b[0..7]
                       input wire [127 : 0]   counter,     // {cnt0, cnt1}

                       input wire             init,
                       input wire             next,

                       output wire [63 : 0]   rk0,
                       output wire [63 : 0]   rk1,
                       output wire [63 : 0]   rk2,
                       output wire [63 : 0]   rk3,
                       output wire [63 : 0]   rk4,
                       output wire [63 : 0]   rk5,
                       output wire [63 : 0]   rk6,
                       output wire [63 : 0]   rk7
                      );


  //----------------------------------------------------------------
  // Block-cipher key-generation rotation constants (per v5 source).
  //----------------------------------------------------------------
  localparam MA = 14;
  localparam MB = 43;
  localparam MC = 28;
  localparam MD = 19;
  localparam ME = 29;
  localparam MF = 63;
  localparam MG = 12;
  localparam MH = 6;
  localparam BA = 47;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [63 : 0] m_mem [0 : 15];
  reg [63 : 0] b_mem [0 : 7];
  reg [63 : 0] cnt_mem [0 : 1];

  reg [63 : 0] m_new [0 : 15];
  reg [63 : 0] b_new [0 : 7];
  reg [63 : 0] cnt_new [0 : 1];
  reg          key_mem_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [63 : 0] tmp_rk0;
  reg [63 : 0] tmp_rk1;
  reg [63 : 0] tmp_rk2;
  reg [63 : 0] tmp_rk3;
  reg [63 : 0] tmp_rk4;
  reg [63 : 0] tmp_rk5;
  reg [63 : 0] tmp_rk6;
  reg [63 : 0] tmp_rk7;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign rk0 = tmp_rk0;
  assign rk1 = tmp_rk1;
  assign rk2 = tmp_rk2;
  assign rk3 = tmp_rk3;
  assign rk4 = tmp_rk4;
  assign rk5 = tmp_rk5;
  assign rk6 = tmp_rk6;
  assign rk7 = tmp_rk7;


  //----------------------------------------------------------------
  // reg_update
  // Positive edge triggered with asynchronous active low reset.
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin : reg_update
      integer i;

      if (!reset_n)
        begin
          for (i = 0; i < 16; i = i + 1)
            m_mem[i] <= 64'h0;
          for (i = 0; i < 8; i = i + 1)
            b_mem[i] <= 64'h0;
          cnt_mem[0] <= 64'h0;
          cnt_mem[1] <= 64'h0;
        end
      else
        begin
          if (key_mem_we)
            begin
              for (i = 0; i < 16; i = i + 1)
                m_mem[i] <= m_new[i];
              for (i = 0; i < 8; i = i + 1)
                b_mem[i] <= b_new[i];
              cnt_mem[0] <= cnt_new[0];
              cnt_mem[1] <= cnt_new[1];
            end
        end
    end // reg_update


  //----------------------------------------------------------------
  // round_key_logic
  //
  // Combinationally emit the current round key from the live window.
  //----------------------------------------------------------------
  always @*
    begin : round_key_logic
      tmp_rk0 = m_mem[0] ^ b_mem[0] ^ cnt_mem[0];
      tmp_rk1 = m_mem[1] ^ b_mem[1] ^ cnt_mem[1];
      tmp_rk2 = m_mem[8] ^ b_mem[2];
      tmp_rk3 = m_mem[9] ^ b_mem[3];
      tmp_rk4 = b_mem[4];
      tmp_rk5 = b_mem[5];
      tmp_rk6 = b_mem[6];
      tmp_rk7 = b_mem[7];
    end // round_key_logic


  //----------------------------------------------------------------
  // key_mem_update_logic
  //
  // Computes the next window. On "init" the window is loaded from the
  // master key and counter. On "next" the window slides one round.
  //----------------------------------------------------------------
  always @*
    begin : key_mem_update_logic
      reg [63 : 0] mx2_3;   // m[2] ^ m[3]
      reg [63 : 0] mx10_11; // m[10] ^ m[11]
      integer i;

      for (i = 0; i < 16; i = i + 1)
        m_new[i] = 64'h0;
      for (i = 0; i < 8; i = i + 1)
        b_new[i] = 64'h0;
      cnt_new[0] = 64'h0;
      cnt_new[1] = 64'h0;
      key_mem_we = 1'b0;

      // ---- advance computation (uses current window) ----
      mx2_3   = m_mem[2]  ^ m_mem[3];
      mx10_11 = m_mem[10] ^ m_mem[11];

      if (init)
        begin
          // master_key[1535:1472] = m[0], descending to b[7] = [63:0]
          m_new[0]  = master_key[1535 : 1472];
          m_new[1]  = master_key[1471 : 1408];
          m_new[2]  = master_key[1407 : 1344];
          m_new[3]  = master_key[1343 : 1280];
          m_new[4]  = master_key[1279 : 1216];
          m_new[5]  = master_key[1215 : 1152];
          m_new[6]  = master_key[1151 : 1088];
          m_new[7]  = master_key[1087 : 1024];
          m_new[8]  = master_key[1023 :  960];
          m_new[9]  = master_key[ 959 :  896];
          m_new[10] = master_key[ 895 :  832];
          m_new[11] = master_key[ 831 :  768];
          m_new[12] = master_key[ 767 :  704];
          m_new[13] = master_key[ 703 :  640];
          m_new[14] = master_key[ 639 :  576];
          m_new[15] = master_key[ 575 :  512];
          b_new[0]  = master_key[ 511 :  448];
          b_new[1]  = master_key[ 447 :  384];
          b_new[2]  = master_key[ 383 :  320];
          b_new[3]  = master_key[ 319 :  256];
          b_new[4]  = master_key[ 255 :  192];
          b_new[5]  = master_key[ 191 :  128];
          b_new[6]  = master_key[ 127 :   64];
          b_new[7]  = master_key[  63 :    0];
          cnt_new[0] = counter[127 : 64];
          cnt_new[1] = counter[63  :  0];
          key_mem_we = 1'b1;
        end

      if (next)
        begin
          // ---- m advance ----
          m_new[0]  = m_mem[6];
          m_new[1]  = m_mem[7];
          m_new[2]  = ({m_mem[8][64-ME-1:0],  m_mem[8][63:64-ME]}) +
                      ({mx10_11[64-MH-1:0],    mx10_11[63:64-MH]});
          m_new[3]  = ({m_mem[9][64-MF-1:0],  m_mem[9][63:64-MF]}) +
                      ({mx10_11[64-MG-1:0],    mx10_11[63:64-MG]});
          m_new[4]  = m_mem[10];
          m_new[5]  = m_mem[11];
          m_new[6]  = m_mem[12];
          m_new[7]  = m_mem[13];
          m_new[8]  = m_mem[14];
          m_new[9]  = m_mem[15];
          m_new[10] = ({m_mem[0][64-MA-1:0],  m_mem[0][63:64-MA]}) +
                      ({mx2_3[64-MD-1:0],      mx2_3[63:64-MD]});
          m_new[11] = ({m_mem[1][64-MB-1:0],  m_mem[1][63:64-MB]}) +
                      ({mx2_3[64-MC-1:0],      mx2_3[63:64-MC]});
          m_new[12] = m_mem[2];
          m_new[13] = m_mem[3];
          m_new[14] = m_mem[4];
          m_new[15] = m_mem[5];

          // ---- b advance ----
          b_new[0] = b_mem[1];
          b_new[1] = b_mem[2];
          b_new[2] = b_mem[3];
          b_new[3] = b_mem[4];
          b_new[4] = b_mem[5];
          b_new[5] = b_mem[6];
          b_new[6] = b_mem[7];
          b_new[7] = ({b_mem[0][64-BA-1:0], b_mem[0][63:64-BA]}) ^ b_mem[1];

          // ---- counter advance ----
          cnt_new[0] = cnt_mem[1];
          cnt_new[1] = {cnt_mem[0][61:0], cnt_mem[0][63:62]}; // rotl 2

          key_mem_we = 1'b1;
        end
    end // key_mem_update_logic

endmodule // cuishen_key_mem

//======================================================================
// EOF cuishen_key_mem.v
//======================================================================
