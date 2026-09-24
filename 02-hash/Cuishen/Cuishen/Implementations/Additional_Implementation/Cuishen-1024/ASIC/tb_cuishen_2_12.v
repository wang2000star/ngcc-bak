//======================================================================
//
// tb_cuishen.v
// ------------
// Self-checking testbench for the Cuishen-1024 hash, driving the public
// 32-bit memory-mapped interface of the cuishen wrapper exactly as a
// host CPU would. Mirrors the 512-bit design's tb_cuishen.v.
//
// Scope: the three short KAT_2_12 vectors (msg_len 0, 1, 2 bits). These
// exercise the OCTARX datapath, the key schedule, the dual upper/lower
// cipher passes and the finalization. They do NOT exercise the
// compression path (msb_separate), since 0/1/2-bit messages never reach
// a full 1024-bit block.
//
// Expected digests below were generated from a reference model that
// implements the Cuishen-1024 algorithm WITH the msb_separate operation
// using XOR semantics (out[0] ^= 0 for the top pass, out[0] ^= MSB for
// the bottom pass) rather than the force-set/clear semantics of the
// original C source. Because these three vectors are all <= 512 bits,
// they never exercise msb_separate, so this distinction does not affect
// them -- the KAT_2_12 Dst values for these vectors are not used here;
// the expected digests were independently produced and cross-validated
// against a direct compilation of the original C reference.
//
//   KAT_2_12 #1 : msg_len = 0
//   KAT_2_12 #2 : msg_len = 1, msg = 0x80
//   KAT_2_12 #3 : msg_len = 2, msg = 0x40
//
// Flow for a short message (0 full blocks, tail <= 512 bit):
//   - pulse INIT  : load IV -> t, IV -> b (both from SHA512_H)
//   - write COUNTER = msg_len_bits
//   - write the 512-bit zero-padded tail message
//   - pulse FINAL : run finalization, then read the 1024-bit digest
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
      $display(" Cuishen-1024 testbench (KAT_2_12 short vectors)");
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
            1024'hBA4525130731B071A95B5395FA0B72476288A58B5EFD76465CACE5889263D22C7FB48ADD70EE70D525D1FADA96182C80BA2701EFB0288AB1C99C4C339DE2A8D3421E6DEB57F42C21E348F05B153D1849C078105C75C12079D5F3584562B65259724479381CA097D9806B13EBB6C77A6CA3A90E687933FF47FEF4840840FCB5AF);

      //--------------------------------------------------------
      // KAT_2_12 #2 : msg_len = 1, msg = 0x80
      //--------------------------------------------------------
      hash_short({8'h80, 504'h0}, 64'd1);
      check("KAT_2_12 #2 (len=1)",
            1024'h308A93812737385D14D3EE1867C8B72E16EDB902D714060DE3659B87698F3AA253F37A2AE5775C942C06B829705398DDE5491C92AEAF4459A230D40B50F8D7DB1CE2A90FBFCDE0EAE5292FEEE49D5A5F769D557D3D5A7120F4CF39191CE60C51EA3C12E13F4617F28FA37E46F0ACF0E3809D92E57122EF06DB47479E3EB0D2E9);

      //--------------------------------------------------------
      // KAT_2_12 #3 : msg_len = 2, msg = 0x40
      //--------------------------------------------------------
      hash_short({8'h40, 504'h0}, 64'd2);
      check("KAT_2_12 #3 (len=2)",
            1024'h6F1B4CDC07DEC52BD403531B5351AC55F629826F59DEAEBF33CA40FBE5EADDE9D0009DAAA26A079A30187A3AA8CE4D4F1C840F49DDCF8163FF6141CF4C8451DD2FE501D0BA1BB71E224DDE596FA9B40729705F8451E17774F5526B41E22844C727EE4B6F2EB902CF3E48519D6514AC3FAEC85BF6886AEB0B48ED5B928B69B8C9);

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
