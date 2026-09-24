//======================================================================
//
// tb_duet_768.v
// --------------
// Self-checking testbench for the Duet-768 hash, driving the public
// 32-bit memory-mapped interface of the duet_768 wrapper exactly as a
// host CPU would. Modelled directly on tb_duet.v (Duet-512).
//
// Scope: the three short KAT_2_12 vectors (msg_len 0, 1, 2 bits). Each
// is padded by the host into a single 1088-bit block (M || 1 || 0^k) per
// pad_message_block() in the C reference, then absorbed in one shot
// (0 full blocks + 1 padding block).
//
//   KAT_2_12 #1 : msg_len = 0
//   KAT_2_12 #2 : msg_len = 1, msg = 0x80
//   KAT_2_12 #3 : msg_len = 2, msg = 0x40
//
// Flow:
//   - pulse INIT   : clear A, B, C to zero
//   - write the padded 1088-bit block (34 x 32-bit words, MSB word first)
//   - pulse ABSORB : run f1 (18 rounds) then f2 (18 rounds) sequentially
//   - read the 768-bit digest (the high 768 bits of the 832-bit C
//     register; no extra squeeze calls are needed since 768 <= 832)
//
//======================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_duet_768;

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

  localparam NUM_BLOCK_WORDS  = 34;
  localparam NUM_DIGEST_WORDS = 24;


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
  reg [767:0]  digest_result;


  //----------------------------------------------------------------
  // DUT.
  //----------------------------------------------------------------
  duet_768 dut(
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
  // load_block : write a 1088-bit block (34 x 32-bit words, MSB word
  // first) into BLOCK0..BLOCK33.
  //----------------------------------------------------------------
  task load_block(input [1087:0] blk);
    integer i;
    begin
      for (i = 0; i < NUM_BLOCK_WORDS; i = i + 1)
        write_word(ADDR_BLOCK0 + i[7:0], blk[(NUM_BLOCK_WORDS - 1 - i)*32 +: 32]);
    end
  endtask


  //----------------------------------------------------------------
  // run_absorb : absorb one padded 1088-bit block and capture the digest.
  //----------------------------------------------------------------
  task run_absorb(input [1087:0] blk);
    integer i;
    reg [31:0] w;
    begin
      load_block(blk);
      write_word(ADDR_CTRL, CTRL_ABSORB);
      wait_busy;
      wait_valid;
      digest_result = 768'h0;
      for (i = 0; i < NUM_DIGEST_WORDS; i = i + 1)
        begin
          read_word(ADDR_DIGEST0 + i[7:0], w);
          digest_result[(NUM_DIGEST_WORDS - 1 - i)*32 +: 32] = w;
        end
      wait_ready;
    end
  endtask


  //----------------------------------------------------------------
  // hash_short : init + absorb the single padded block.
  //----------------------------------------------------------------
  task hash_short(input [1087:0] padded_block);
    begin
      pulse_init;
      run_absorb(padded_block);
    end
  endtask


  //----------------------------------------------------------------
  // check : compare digest against expected, report.
  //----------------------------------------------------------------
  task check(input [8*32-1:0] name, input [767:0] expected);
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
      $display(" Duet-768 testbench (KAT_2_12 short vectors)");
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
      // KAT_2_12 #1 : msg_len = 0  -> padded block = 0x80 || 0^1080
      //--------------------------------------------------------
      hash_short(1088'h80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000);
      check("KAT_2_12 #1 (len=0)",
            768'h1D00E353387AC2227D58A58EF2E40A625282A7F53B07E2502254055E9E6E3E73ACC58DA77823F77D8F7BB9E2247576E58B85A61D31DF399D5BB240656A7CF7347B5E7DFDE9C9ABF9F5099CA697399B9FD6CAFF601BCD5C690B819AF9E5557F69);

      //--------------------------------------------------------
      // KAT_2_12 #2 : msg_len = 1, msg = 0x80 -> padded block = 0xC0 || 0^1080
      //--------------------------------------------------------
      hash_short(1088'hC0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000);
      check("KAT_2_12 #2 (len=1)",
            768'h5591D94D834DEA6AE3381B0B0C0206A37BA0A650A26DB4C9918D44EF9ECA008910E6B45E12968831C0813CCDB97161DFE3B23E2EDA1ACE43E62B747BE5E567620D641DF74B57E1B0666B76AE162D612B9F3DB83A97C100D42FD54A40067401EA);

      //--------------------------------------------------------
      // KAT_2_12 #3 : msg_len = 2, msg = 0x40 -> padded block = 0x60 || 0^1080
      //--------------------------------------------------------
      hash_short(1088'h60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000);
      check("KAT_2_12 #3 (len=2)",
            768'h0272B58B8F104A4B7093BB71F703962651A97DC72D87279B2D0803AA452C3FE0C67E326D86095CD821DCB83C4600BC9FEA84687152E38AFC4D064CCF16B4648901BE18F8DED0C4F7222C14E4CFE278387C6D82BAE9E7C426BA440A3D9238D771);

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

endmodule // tb_duet_768

//======================================================================
// EOF tb_duet_768.v
//======================================================================
