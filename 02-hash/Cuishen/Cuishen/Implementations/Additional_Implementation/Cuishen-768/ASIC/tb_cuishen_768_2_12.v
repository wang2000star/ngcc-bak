//======================================================================
//
// tb_cuishen.v
// ------------
// Self-checking testbench for the Cuishen-768 hash, driving the public
// 32-bit memory-mapped interface of the cuishen wrapper exactly as a
// host CPU would.
//
//======================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_cuishen;

  //----------------------------------------------------------------
  // Parameters.
  //----------------------------------------------------------------
  localparam CLK_HALF = 5;

  localparam ADDR_CTRL     = 8'h08;
  localparam ADDR_STATUS   = 8'h09;
  localparam ADDR_COUNTER0 = 8'h0a;
  localparam ADDR_COUNTER1 = 8'h0b;
  localparam ADDR_TAIL0    = 8'h30;
  localparam ADDR_DIGEST0  = 8'h60;

  localparam CTRL_INIT  = 32'h1;
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

  // 修改为 768 位
  reg [767:0]  digest_result;

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

      digest_result = 768'h0;
      // 修改为只读取前 24 个 word (24 * 32 = 768 bits)
      for (i = 0; i < 24; i = i + 1)
        begin
          read_word(ADDR_DIGEST0 + i[7:0], w);
          digest_result[(23 - i)*32 +: 32] = w;
        end
      wait_ready;
    end
  endtask

  //----------------------------------------------------------------
  // hash_short : hash a message that fits entirely in the 512-bit
  // tail (0 full blocks). tail is already zero-padded.
  //----------------------------------------------------------------
  task hash_short(input [511:0] tail, input [63:0] msg_len_bits);
    begin
      pulse_init;
      run_final(tail, msg_len_bits);
    end
  endtask

  //----------------------------------------------------------------
  // check : compare digest against expected, report.
  // 修改为接收 768 位的期望值
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
      $display(" Cuishen-768 testbench (KAT_2_12 short vectors)");
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
      hash_short(512'h0, 64'd0);
      check("KAT_2_12 #1 (len=0)",
            768'hDA2CA2F19708FBE9A5146DCC93DE7D80E69918008779D0F48AC3EC81018477A79AF8D334C3A964F03C3CB9EB3C63F1DEA875806FA5282D7221CF979C218F339154678AA0F52D7E386EE83D90AA611549E545066848C809B0E12033C2AEFA7DAA);

      //--------------------------------------------------------
      // KAT_2_12 #2 : msg_len = 1, msg = 0x80
      //--------------------------------------------------------
      hash_short({8'h80, 504'h0}, 64'd1);
      check("KAT_2_12 #2 (len=1)",
            768'hC66D7B1B6F7E79A8AD89F72843720CBC24516B2F3CC6ACB32382F35AF4461CE8AA464693B810EB181B71B8D5FAEBED320229CAC4BFEE477D9E992641D1E1FE17120160D6637D45E09DE2B104742B2124E32C6CBC5991ACDC808EA8BB7BCD6861);

      //--------------------------------------------------------
      // KAT_2_12 #3 : msg_len = 2, msg = 0x40
      //--------------------------------------------------------
      hash_short({8'h40, 504'h0}, 64'd2);
      check("KAT_2_12 #3 (len=2)",
            768'h364C93F0D7040E439EBF65202DBCB04B6575F2E5F33FA9BB7CDA0C7749C3D75F4B206C5B4B46156AB4A1083E183FD749717F034EECC22816A5A90184373854F18C5D2306F989B5BCAF8DF79BDAA8A7287C28A3889AAA341A1263452C4E5DAD9C);

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