//======================================================================
//
// tb_duet_2_23.v
// ---------------
// Self-checking testbench for the Duet-512 hash, covering all-zero and
// all-one 8388608-bit messages. Unlike tb_duet.v (short vectors, which
// absorb a single padded block with no full blocks), these vectors
// drive 21845 full 384-bit blocks plus one final padded block (128-bit
// remainder + 1 || 0^k padding), exercising the multi-block chaining of
// A, B, and C across many absorb_block() calls.
//
//   #1 : msg_len = 8388608, msg = all-zero
//   #2 : msg_len = 8388608, msg = all-one
//
// Each vector absorbs 21846 blocks total (21845 full + 1 padded), at 29
// cycles/block, for roughly 633,500 simulated clock cycles. This
// completes in well under a minute under a standard event simulator
// (iverilog/vvp); it is not a synthesis-time concern.
//
//======================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_duet_2_23;

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

  localparam NUM_FULL_BLOCKS = 21845; // 8388608 / 384
  // remainder = 8388608 mod 384 = 128 bits -> one extra padded block


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
  // write_word / read_word.
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
  // pulse_init.
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
  // run_absorb_block : absorb one block (no digest read; used for the
  // full blocks in a multi-block message).
  //----------------------------------------------------------------
  task run_absorb_block(input [383:0] blk);
    begin
      load_block(blk);
      write_word(ADDR_CTRL, CTRL_ABSORB);
      wait_busy;
      wait_ready;
    end
  endtask


  //----------------------------------------------------------------
  // run_absorb_final : absorb the final (padded) block and capture
  // the digest.
  //----------------------------------------------------------------
  task run_absorb_final(input [383:0] blk);
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
  // hash_long : absorb NUM_FULL_BLOCKS repeats of fill_block, then the
  // final padded block.
  //----------------------------------------------------------------
  task hash_long(input [383:0] fill_block, input [383:0] final_padded_block);
    integer blk;
    begin
      pulse_init;
      for (blk = 0; blk < NUM_FULL_BLOCKS; blk = blk + 1)
        run_absorb_block(fill_block);
      run_absorb_final(final_padded_block);
    end
  endtask


  //----------------------------------------------------------------
  // check.
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
      $display(" Duet-512 testbench (all-zero / all-one, 21846 blocks)");
      $display(" msg_len = 8388608 bit (21845 full blocks + 1 padded block)");
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
      // #1 : msg_len = 8388608, msg = all-zero.
      // Final 128-bit remainder (all-zero) padded -> 0^128 || 1 || 0^255
      //--------------------------------------------------------
      $display(" running #1 (all-zero, %0d full blocks + 1 padded)...", NUM_FULL_BLOCKS);
      hash_long(384'h0,
                384'h000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000);
      check("all-zero (8388608 bit)",
            512'h22DF266E5A8EE72CA2D798D067FC6C0F458A3BDCB47F4F6A1694DF8BA8714A4340B79F6C145FA3807EC895AA9D4B4EE8678E24C9F124CCEDA0ED48946FA40CB5);

      //--------------------------------------------------------
      // #2 : msg_len = 8388608, msg = all-one.
      // Final 128-bit remainder (all-one) padded -> 1^128 || 1 || 0^255
      //--------------------------------------------------------
      $display(" running #2 (all-one, %0d full blocks + 1 padded)...", NUM_FULL_BLOCKS);
      hash_long({384{1'b1}},
                384'hffffffffffffffffffffffffffffffff8000000000000000000000000000000000000000000000000000000000000000);
      check("all-one (8388608 bit)",
            512'h130B3CC456182243E1EFB30E6733A0CE3D5EFF9FF53AB436E1F1CF9CE92F7C94D7A288C389553BCA7D7A13F2AE7F6F544453BFAE39C5E18878A20C0C266DD096);

      //--------------------------------------------------------
      // #3 (DRNG-seeded message) -- SKIPPED, same reason as the
      // Cuishen testbenches: the plaintext is generated by a DRNG
      // from Msg_Seed and is not reconstructable here.
      //--------------------------------------------------------
      $display("  [SKIP] #3 (DRNG-seeded msg; plaintext not reconstructable here)");

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

endmodule // tb_duet_2_23

//======================================================================
// EOF tb_duet_2_23.v
//======================================================================
