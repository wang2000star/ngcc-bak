//======================================================================
//
// tb_duet.v
// ---------
// Self-checking testbench for the Duet-512 hash, driving the public
// 32-bit memory-mapped interface of the duet wrapper exactly as a host
// CPU would. Mirrors the SHA512/Cuishen style testbenches (tb_cuishen.v).
//
// Scope: the three short KAT_2_12 vectors (msg_len 0, 1, 2 bits). Each
// is padded by the host into a single 384-bit block (M || 1 || 0^k) per
// pad_message_block() in the C reference, then absorbed in one shot
// (0 full blocks + 1 padding block).
//
//   KAT_2_12 #1 : msg_len = 0
//   KAT_2_12 #2 : msg_len = 1, msg = 0x80
//   KAT_2_12 #3 : msg_len = 2, msg = 0x40
//
// Flow:
//   - pulse INIT   : clear A, B, C to zero
//   - write the padded 384-bit block (12 x 32-bit words, MSB word first)
//   - pulse ABSORB : run f1 (12 rounds) then f2 (12 rounds) sequentially
//   - read the 512-bit digest (the high 512 bits of the 576-bit C
//     register; no extra squeeze calls are needed since 512 <= 576)
//
//======================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_duet;

  //----------------------------------------------------------------
  // Parameters.
  //----------------------------------------------------------------
  localparam CLK_HALF = 5;

  localparam ADDR_CTRL    = 8'h08;
  localparam ADDR_STATUS  = 8'h09;
  localparam ADDR_BLOCK0  = 8'h10;
  localparam ADDR_DIGEST0 = 8'h40;

  localparam CTRL_INIT   = 32'h1;
  localparam CTRL_ABSORB = 32'h2;


  //----------------------------------------------------------------
  // DUT connections.
  //----------------------------------------------------------------
  reg          tb_clk;
  reg          tb_reset_n;
  reg          tb_cs;
  reg          tb_we;
  reg  [7 : 0] tb_address;
  reg  [31: 0] tb_write_data;
  wire [31: 0] tb_read_data;
  wire         tb_error;

  integer      errors;
  integer      tests;
  reg [511:0]  digest_result;


  //----------------------------------------------------------------
  // DUT.
  //----------------------------------------------------------------
  duet dut(
           .clk(tb_clk),
           .reset_n(tb_reset_n),
           .cs(tb_cs),
           .we(tb_we),
           .address(tb_address),
           .write_data(tb_write_data),
           .read_data(tb_read_data),
           .error(tb_error)
          );


  //----------------------------------------------------------------
  // Clock.
  //----------------------------------------------------------------
  always
    begin : clk_gen
      #CLK_HALF tb_clk = !tb_clk;
    end


  //----------------------------------------------------------------
  // write_word / read_word : single-cycle bus transactions.
  //----------------------------------------------------------------
  task write_word(input [7:0] addr, input [31:0] data);
    begin
      @(negedge tb_clk);
      tb_cs         = 1'b1;
      tb_we         = 1'b1;
      tb_address    = addr;
      tb_write_data = data;
      @(negedge tb_clk);
      tb_cs         = 1'b0;
      tb_we         = 1'b0;
    end
  endtask

  task read_word(input [7:0] addr, output [31:0] data);
    begin
      @(negedge tb_clk);
      tb_cs      = 1'b1;
      tb_we      = 1'b0;
      tb_address = addr;
      @(negedge tb_clk);
      data       = tb_read_data;
      tb_cs      = 1'b0;
    end
  endtask


  //----------------------------------------------------------------
  // wait_ready / wait_busy / wait_valid.
  //----------------------------------------------------------------
  task wait_ready;
    reg [31:0] s;
    begin
      s = 32'h0;
      while (s[0] == 1'b0)
        read_word(ADDR_STATUS, s);
    end
  endtask

  task wait_busy;
    reg [31:0] s;
    begin
      s = 32'hffffffff;
      while (s[0] == 1'b1)
        read_word(ADDR_STATUS, s);
    end
  endtask

  task wait_valid;
    reg [31:0] s;
    begin
      s = 32'h0;
      while (s[1] == 1'b0)
        read_word(ADDR_STATUS, s);
    end
  endtask


  //----------------------------------------------------------------
  // pulse_init : clear A,B,C (single cycle, core stays ready).
  //----------------------------------------------------------------
  task pulse_init;
    begin
      write_word(ADDR_CTRL, CTRL_INIT);
      @(negedge tb_clk);
      wait_ready;
    end
  endtask


  //----------------------------------------------------------------
  // load_block : write a 384-bit block (12 x 32-bit words, MSB word
  // first) into BLOCK0..BLOCK11.
  //----------------------------------------------------------------
  task load_block(input [383:0] blk);
    integer i;
    begin
      for (i = 0; i < 12; i = i + 1)
        write_word(ADDR_BLOCK0 + i[7:0], blk[(11 - i)*32 +: 32]);
    end
  endtask


  //----------------------------------------------------------------
  // run_absorb : absorb one padded 384-bit block and capture the digest.
  //----------------------------------------------------------------
  task run_absorb(input [383:0] blk);
    integer i;
    reg [31:0] w;
    begin
      load_block(blk);
      write_word(ADDR_CTRL, CTRL_ABSORB);
      wait_busy;
      wait_valid;
      digest_result = 512'h0;
      for (i = 0; i < 16; i = i + 1)
        begin
          read_word(ADDR_DIGEST0 + i[7:0], w);
          digest_result[(15 - i)*32 +: 32] = w;
        end
      wait_ready;
    end
  endtask


  //----------------------------------------------------------------
  // hash_short : init + absorb the single padded block.
  //----------------------------------------------------------------
  task hash_short(input [383:0] padded_block);
    begin
      pulse_init;
      run_absorb(padded_block);
    end
  endtask


  //----------------------------------------------------------------
  // check : compare digest against expected, report.
  //----------------------------------------------------------------
  task check(input [8*32-1:0] name, input [511:0] expected);
    begin
      tests = tests + 1;
      if (digest_result === expected)
        $display("  [PASS] %0s", name);
      else
        begin
          errors = errors + 1;
          $display("  [FAIL] %0s", name);
          $display("         got = %h", digest_result);
          $display("         exp = %h", expected);
        end
    end
  endtask


  //----------------------------------------------------------------
  // Test sequence.
  //----------------------------------------------------------------
  initial
    begin : main
      $display("==================================================");
      $display(" Duet-512 testbench (KAT_2_12 short vectors)");
      $display("==================================================");

      tb_clk        = 1'b0;
      tb_reset_n    = 1'b0;
      tb_cs         = 1'b0;
      tb_we         = 1'b0;
      tb_address    = 8'h0;
      tb_write_data = 32'h0;
      errors        = 0;
      tests         = 0;

      // reset
      repeat (4) @(negedge tb_clk);
      tb_reset_n = 1'b1;
      repeat (2) @(negedge tb_clk);
      wait_ready;

      //--------------------------------------------------------
      // KAT_2_12 #1 : msg_len = 0  -> padded block = 0x80 || 0^376
      //--------------------------------------------------------
      hash_short(384'h800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000);
      check("KAT_2_12 #1 (len=0)",
            512'hCE271865915E2EF5D56A1D142218718A039C8C287DABCB305CD912ECFF2BA671C072CD867017AA52088565582A2281F200445BE350280D6B0BE96C4C71829CA7);

      //--------------------------------------------------------
      // KAT_2_12 #2 : msg_len = 1, msg = 0x80 -> padded block = 0xC0 || 0^376
      //--------------------------------------------------------
      hash_short(384'hC00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000);
      check("KAT_2_12 #2 (len=1)",
            512'hE3E59BF6979563D69EFEC3218D8FF23885655F5C8390FCCDBC7D6E1D25E7EF3D98BD251AC9F817FEB75C6AC3C51902D4EE5A1663C4DEDFECB9F648D2BA4B0B2E);

      //--------------------------------------------------------
      // KAT_2_12 #3 : msg_len = 2, msg = 0x40 -> padded block = 0x60 || 0^376
      //--------------------------------------------------------
      hash_short(384'h600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000);
      check("KAT_2_12 #3 (len=2)",
            512'h63BFD322F6AA3FF0FD3F4066F6DEA15B0E43F9E827DC1D5A1A0C35D164EC27F1F5F36BB05BD1F9F04B74C112D4B532B81B20D1EF1530A965DBBD094917A3F05B);

      //--------------------------------------------------------
      // Summary.
      //--------------------------------------------------------
      $display("--------------------------------------------------");
      $display(" Tests run : %0d", tests);
      $display(" Failures  : %0d", errors);
      if (errors == 0)
        $display(" RESULT    : ALL TESTS PASSED");
      else
        $display(" RESULT    : %0d TEST(S) FAILED", errors);
      $display("==================================================");
      $finish;
    end

endmodule // tb_duet

//======================================================================
// EOF tb_duet.v
//======================================================================
