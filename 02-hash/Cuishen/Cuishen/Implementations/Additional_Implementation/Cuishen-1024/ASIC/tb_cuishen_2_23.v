//======================================================================
//
// tb_cuishen_2_23.v
// ------------------
// Self-checking testbench for the Cuishen-1024 hash, covering all-zero
// and all-one 8388608-bit (8192 full 1024-bit block) messages. Unlike
// tb_cuishen.v (short vectors, which never exercise the compression /
// msb_separate path), these vectors drive 8192 real "next" compression
// blocks before finalization, exercising the block-to-block chaining
// and msb_separate logic.
//
// Expected digests were generated from a reference model implementing
// msb_separate with XOR semantics (the design choice for this
// implementation), and cross-validated against a literal, line-by-line
// interpretation of this testbench's exact RTL drive sequence. They are
// NOT taken from any KAT_*.txt Dst field, since the original C reference
// uses force-set/clear semantics for msb_separate rather than XOR; the
// KAT files are used here only as a source of input message patterns
// (all-zero / all-one), not as expected-output references.
//
//   #1 : msg_len = 8388608, msg = all-zero
//   #2 : msg_len = 8388608, msg = all-one
//
// Each vector takes ~739000 clock cycles in simulation (8192 blocks x
// ~90 cycles/block on the parallel core, plus finalization). This runs
// in seconds under a standard event simulator (iverilog/vvp); it is not
// a synthesis-time concern.
//
//======================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_cuishen_2_23;

  //----------------------------------------------------------------
  // Parameters.
  //----------------------------------------------------------------
  localparam CLK_HALF = 5;

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

  localparam NUM_BLOCKS    = 8192;          // 8388608 bit / 1024 bit
  localparam MSG_LEN_BITS  = 64'd8388608;


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
  reg [1023:0] digest_result;


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
  // wait_ready / wait_busy / wait_valid : poll the status register.
  // wait_busy is used right after issuing next/final so we don't read
  // a stale "ready=1" from before the command was registered.
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
  // load_block : write a 1024-bit block (32 x 32-bit words, MSB word
  // first) into BLOCK0..BLOCK31.
  //----------------------------------------------------------------
  task load_block(input [1023:0] blk);
    integer i;
    begin
      for (i = 0; i < 32; i = i + 1)
        write_word(ADDR_BLOCK0 + i[7:0], blk[(31 - i)*32 +: 32]);
    end
  endtask


  //----------------------------------------------------------------
  // load_tail : write a 512-bit tail (16 x 32-bit words) into
  // TAIL0..TAIL15, MSB word first.
  //----------------------------------------------------------------
  task load_tail(input [511:0] tail);
    integer i;
    begin
      for (i = 0; i < 16; i = i + 1)
        write_word(ADDR_TAIL0 + i[7:0], tail[(15 - i)*32 +: 32]);
    end
  endtask


  //----------------------------------------------------------------
  // run_block : feed one compression block.
  //----------------------------------------------------------------
  task run_block(input [1023:0] blk, input [63:0] counter_bits);
    begin
      set_counter(counter_bits);
      load_block(blk);
      write_word(ADDR_CTRL, CTRL_NEXT);
      wait_busy;
      wait_ready;
    end
  endtask


  //----------------------------------------------------------------
  // run_final : run the finalization and capture the digest.
  //----------------------------------------------------------------
  task run_final(input [511:0] tail, input [63:0] counter_bits);
    integer i;
    reg [31:0] w;
    begin
      set_counter(counter_bits);
      load_tail(tail);
      write_word(ADDR_CTRL, CTRL_FINAL);
      @(negedge tb_clk);
      wait_valid;
      digest_result = 1024'h0;
      for (i = 0; i < 32; i = i + 1)
        begin
          read_word(ADDR_DIGEST0 + i[7:0], w);
          digest_result[(31 - i)*32 +: 32] = w;
        end
      wait_ready;
    end
  endtask


  //----------------------------------------------------------------
  // hash_long : hash an 8388608-bit message made of NUM_BLOCKS repeats
  // of the same 1024-bit fill pattern (used for the all-0 / all-1
  // vectors). The remainder is exactly 0, so the tail is empty.
  //----------------------------------------------------------------
  task hash_long(input [1023:0] fill_block);
    integer blk;
    begin
      pulse_init;
      for (blk = 0; blk < NUM_BLOCKS; blk = blk + 1)
        run_block(fill_block, (blk + 1) * 1024);
      run_final(512'h0, MSG_LEN_BITS);
    end
  endtask


  //----------------------------------------------------------------
  // check : compare digest against expected, report.
  //----------------------------------------------------------------
  task check(input [8*32-1:0] name, input [1023:0] expected);
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
      $display(" Cuishen-1024 testbench (all-zero / all-one, 8192 blocks)");
      $display(" msg_len = 8388608 bit (8192 full compression blocks)");
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
      // #1 : msg_len = 8388608, msg = all-zero
      //--------------------------------------------------------
      $display(" running #1 (all-zero, %0d blocks)...", NUM_BLOCKS);
      hash_long(1024'h0);
      check("all-zero (8388608 bit)",
            1024'h894F35E986F890B5BF93F2A85F833ACDD4CFFD6DF20A603E6E298652FEA37A7265118F6AA7A7ECE2EBB10426CE529F03CA7135996B736D42C80F882C2F8FAD745206FC2A12D5E80EBE0A582CB2FD084B838C0F3983D1584B8BA0EF9CBDFDD6DDD3DD6351AFFE3610F3162EEBEC952C814628A1FDE30C55331F9DF3E0722AEB81);

      //--------------------------------------------------------
      // #2 : msg_len = 8388608, msg = all-one
      //--------------------------------------------------------
      $display(" running #2 (all-one, %0d blocks)...", NUM_BLOCKS);
      hash_long({1024{1'b1}});
      check("all-one (8388608 bit)",
            1024'h3FC454942DEB66E41A4206BFFEDA5E7CC3FDCB53297EB8196F21115D49A615BB9C0E8C6ECD55E7F5355B71B1485574A0280C884FCDF7B2FA2684CD822BAE22BE7BECA9D9550FE0901D628A73D01E944C4006DD11EC86A00B1E303D82C20E2912D1854910184DFA867699F8C59E8E45433B59181BBF3025C6B962B8DD1D2984D0);


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

endmodule // tb_cuishen_2_23

//======================================================================
// EOF tb_cuishen_2_23.v
//======================================================================
