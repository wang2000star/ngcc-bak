//======================================================================
//
// tb_cuishen.v
// ------------
// Self-checking testbench for the Cuishen-512 hash, driving the public
// 32-bit memory-mapped interface of the cuishen wrapper exactly as a
// host CPU would. Structured after the secworks SHA-512 testbench style.
//
// Scope: the three short KAT_2_12 vectors (msg_len 0, 1, 2 bits). These
// exercise the complete OCTARX datapath, the key schedule, the dual
// upper/lower cipher passes and the finalization, all without any
// multi-block streaming, so the simulation completes in microseconds.
//
//   KAT_2_12 #1 : msg_len = 0
//   KAT_2_12 #2 : msg_len = 1, msg = 0x80
//   KAT_2_12 #3 : msg_len = 2, msg = 0x40
//
// Flow for a short message (0 full blocks, tail <= 768 bit):
//   - pulse INIT  : load IV_1 -> t, IV_2 -> b
//   - write COUNTER = msg_len_bits
//   - write the 768-bit zero-padded tail message
//   - pulse FINAL : run finalization, then read the 512-bit digest
//
//======================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_cuishen;

  //----------------------------------------------------------------
  // Parameters.
  //----------------------------------------------------------------
  localparam CLK_HALF = 5;

  // Register map (mirrors cuishen.v).
  localparam ADDR_NAME0    = 8'h00;
  localparam ADDR_NAME1    = 8'h01;
  localparam ADDR_VERSION  = 8'h02;
  localparam ADDR_CTRL     = 8'h08;
  localparam ADDR_STATUS   = 8'h09;
  localparam ADDR_COUNTER0 = 8'h0a;
  localparam ADDR_COUNTER1 = 8'h0b;
  localparam ADDR_BLOCK0   = 8'h10;
  localparam ADDR_TAIL0    = 8'h30;
  localparam ADDR_DIGEST0  = 8'h60;

  localparam CTRL_INIT  = 32'h1;
  localparam CTRL_NEXT  = 32'h2;
  localparam CTRL_FINAL = 32'h4;


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
  cuishen dut(
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
  // wait_ready / wait_valid : poll the status register.
  //----------------------------------------------------------------
  task wait_ready;
    reg [31:0] s;
    begin
      s = 32'h0;
      while (s[0] == 1'b0)
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
  // set_counter : write the 64-bit bits-processed counter.
  //----------------------------------------------------------------
  task set_counter(input [63:0] c);
    begin
      write_word(ADDR_COUNTER0, c[31 : 0]);
      write_word(ADDR_COUNTER1, c[63 : 32]);
    end
  endtask


  //----------------------------------------------------------------
  // pulse_init : preload IV (single cycle, core stays ready).
  //----------------------------------------------------------------
  task pulse_init;
    begin
      write_word(ADDR_CTRL, CTRL_INIT);
      @(negedge tb_clk);
      wait_ready;
    end
  endtask


  //----------------------------------------------------------------
  // load_tail : write a 768-bit tail (24 x 32-bit words) into
  // TAIL0..TAIL23, MSB word first.
  //----------------------------------------------------------------
  task load_tail(input [767:0] tail);
    integer i;
    begin
      for (i = 0; i < 24; i = i + 1)
        write_word(ADDR_TAIL0 + i[7:0], tail[(23 - i)*32 +: 32]);
    end
  endtask


  //----------------------------------------------------------------
  // run_final : run the finalization and capture the digest.
  //----------------------------------------------------------------
  task run_final(input [767:0] tail, input [63:0] counter_bits);
    integer i;
    reg [31:0] w;
    begin
      set_counter(counter_bits);
      load_tail(tail);
      write_word(ADDR_CTRL, CTRL_FINAL);
      @(negedge tb_clk);
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
  // hash_short : hash a message that fits entirely in the 768-bit
  // tail (0 full blocks). tail is already zero-padded.
  //----------------------------------------------------------------
  task hash_short(input [767:0] tail, input [63:0] msg_len_bits);
    begin
      pulse_init;
      run_final(tail, msg_len_bits);
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
      $display(" Cuishen-512 testbench (KAT_2_12 short vectors)");
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
      // KAT_2_12 #1 : msg_len = 0
      //--------------------------------------------------------
      hash_short(768'h0, 64'd0);
      check("KAT_2_12 #1 (len=0)",
            512'hBABCF10A17748EF651C8FFD57A60991B62436BF4E6506F149AB121598CB5606455308A67ED58194937E0F0ADE39CC16E401EE7E0F158E9146C74F1A60A1D837B);

      //--------------------------------------------------------
      // KAT_2_12 #2 : msg_len = 1, msg = 0x80
      //--------------------------------------------------------
      hash_short({8'h80, 760'h0}, 64'd1);
      check("KAT_2_12 #2 (len=1)",
            512'h1A1004D193BBF94DC39A8BBB5471F75431F43FBDBC10BD16CB777F167AB2E9DF1288CF2F63EF579DB20D3F9154B847BAC0BFB67CEEE2617FE534A6C8C2DE9CDB);

      //--------------------------------------------------------
      // KAT_2_12 #3 : msg_len = 2, msg = 0x40
      //--------------------------------------------------------
      hash_short({8'h40, 760'h0}, 64'd2);
      check("KAT_2_12 #3 (len=2)",
            512'h3F3FCC5C0C68E92001A77755AB0733D8AC7EE4A43A2B73F0F8131335C2A1C16957AD7721A449C8A265D04D110581601321A35C3824D523174DE4B910BE08CBC2);

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

endmodule // tb_cuishen

//======================================================================
// EOF tb_cuishen.v
//======================================================================
