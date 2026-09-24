`timescale 1ns/1ps

module zen_pke_keygen_path_tb;

  localparam int NTT_N = 1024;
  localparam int COEFF_W = 16;
  localparam int RAW_SEED_BASE = 0;
  localparam int PK_PACK_BYTES = 1229;
  localparam int SK_PACK_BYTES = 1312;
`ifdef USE_XCV80
  localparam int BUF_BANKS = zen_xcv80_cfg_pkg::XCV80_BUF_BANKS;
`else
  localparam int BUF_BANKS = zen_xcvu37p_cfg_pkg::XCVU37P_BUF_BANKS;
`endif

  localparam int PKE_KEYGEN_IDLE              = 0;
  localparam int PKE_KEYGEN_LAUNCH_SAMPLE_F   = 1;
  localparam int PKE_KEYGEN_WAIT_SAMPLE_F     = 2;
  localparam int PKE_KEYGEN_CHECK_F_Z2        = 3;
  localparam int PKE_KEYGEN_LAUNCH_NTT_F      = 4;
  localparam int PKE_KEYGEN_WAIT_NTT_F        = 5;
  localparam int PKE_KEYGEN_CHECK_F_ZQ        = 6;
  localparam int PKE_KEYGEN_LAUNCH_BASEINV_F  = 7;
  localparam int PKE_KEYGEN_WAIT_BASEINV_F    = 8;
  localparam int PKE_KEYGEN_LAUNCH_FAST_INV_F = 9;
  localparam int PKE_KEYGEN_WAIT_FAST_INV_F   = 10;
  localparam int PKE_KEYGEN_LAUNCH_SAMPLE_G   = 11;
  localparam int PKE_KEYGEN_WAIT_SAMPLE_G     = 12;
  localparam int PKE_KEYGEN_LAUNCH_NTT_G      = 13;
  localparam int PKE_KEYGEN_WAIT_NTT_G        = 14;
  localparam int PKE_KEYGEN_CHECK_G_ZQ        = 15;
  localparam int PKE_KEYGEN_LAUNCH_BASEMUL    = 16;
  localparam int PKE_KEYGEN_WAIT_BASEMUL      = 17;
  localparam int PKE_KEYGEN_PREP_OUT          = 18;
  localparam int PKE_KEYGEN_WAIT_PREP_OUT     = 19;
  localparam int PKE_KEYGEN_WRITEBACK_PK      = 20;
  localparam int PKE_KEYGEN_WRITEBACK_SK_LO   = 21;
  localparam int PKE_KEYGEN_WRITEBACK_SK_HI   = 22;
  localparam int KEYGEN_DBG_STAGE_SAMPLE_F    = 0;
  localparam int KEYGEN_DBG_STAGE_CHECK_F_Z2  = 1;
  localparam int KEYGEN_DBG_STAGE_NTT_F       = 2;
  localparam int KEYGEN_DBG_STAGE_CHECK_F_ZQ  = 3;
  localparam int KEYGEN_DBG_STAGE_BASEINV_F   = 4;
  localparam int KEYGEN_DBG_STAGE_FAST_INV_F  = 5;
  localparam int KEYGEN_DBG_STAGE_SAMPLE_G    = 6;
  localparam int KEYGEN_DBG_STAGE_NTT_G       = 7;
  localparam int KEYGEN_DBG_STAGE_CHECK_G_ZQ  = 8;
  localparam int KEYGEN_DBG_STAGE_BASEMUL     = 9;
  localparam int KEYGEN_DBG_STAGE_PACK_OUT    = 10;
  localparam int KEYGEN_DBG_STAGE_WRITEBACK_PK = 11;
  localparam int KEYGEN_DBG_STAGE_WRITEBACK_SK = 12;

  logic clk;
  logic rst_n;
  logic wr_en;
  logic [15:0] wr_addr;
  logic [31:0] wr_data;
  logic rd_en;
  logic [15:0] rd_addr;
  logic [31:0] rd_data;
  logic busy;
  logic done;
  logic error;
  logic irq;

  logic [7:0] keygen_seed_mem [0:63];
  logic [7:0] keygen_f_nonce_mem [0:0];
  logic [7:0] keygen_g_nonce_mem [0:0];
  logic [7:0] pk_packed_mem [0:PK_PACK_BYTES-1];
  logic [7:0] sk_packed_mem [0:SK_PACK_BYTES-1];
  logic [15:0] f_mem [0:NTT_N-1];
  logic [15:0] f_nttmq_mem [0:NTT_N-1];
  logic [15:0] f_inv_ntt_mem [0:NTT_N-1];
  logic [15:0] f2_vec_mem [0:NTT_N-1];
  logic [15:0] g_mem [0:NTT_N-1];
  logic [15:0] g_nttmq_mem [0:NTT_N-1];
  logic [15:0] pkpoly_mem [0:NTT_N-1];
  integer total_cmd_cycles;
  integer last_cmd_cycles;
  integer fused_cmd_cycles;
  integer i;

`ifdef USE_XCV80
  `ifdef USE_SAFE
    `define ZEN_ACCEL_BOARD_TOP zen_accel_xcv80_safe_top
  `elsif USE_AGGR
    `define ZEN_ACCEL_BOARD_TOP zen_accel_xcv80_aggr_top
  `elsif USE_TIMING
    `define ZEN_ACCEL_BOARD_TOP zen_accel_xcv80_timing_top
  `else
    `define ZEN_ACCEL_BOARD_TOP zen_accel_xcv80_top
  `endif
`else
  `ifdef USE_SAFE
    `define ZEN_ACCEL_BOARD_TOP zen_accel_xcvu37p_safe_top
  `elsif USE_AGGR
    `define ZEN_ACCEL_BOARD_TOP zen_accel_xcvu37p_aggr_top
  `elsif USE_TIMING
    `define ZEN_ACCEL_BOARD_TOP zen_accel_xcvu37p_timing_top
  `else
    `define ZEN_ACCEL_BOARD_TOP zen_accel_xcvu37p_top
  `endif
`endif

  `ZEN_ACCEL_BOARD_TOP dut (
    .clk    (clk),
    .rst_n  (rst_n),
    .wr_en  (wr_en),
    .wr_addr(wr_addr),
    .wr_data(wr_data),
    .rd_en  (rd_en),
    .rd_addr(rd_addr),
    .rd_data(rd_data),
    .busy   (busy),
    .done   (done),
    .error  (error),
    .irq    (irq)
  );

  `undef ZEN_ACCEL_BOARD_TOP

  always #5 clk = ~clk;

  task automatic write_reg(input [15:0] addr, input [31:0] data);
    begin
      @(negedge clk);
      wr_en <= 1'b1;
      wr_addr <= addr;
      wr_data <= data;
      @(negedge clk);
      wr_en <= 1'b0;
      wr_addr <= 16'h0000;
      wr_data <= 32'h0;
    end
  endtask

  task automatic read_reg(input [15:0] addr, output [31:0] data);
    begin
      @(negedge clk);
      rd_en <= 1'b1;
      rd_addr <= addr;
      @(posedge clk);
      data = rd_data;
      @(negedge clk);
      rd_en <= 1'b0;
      rd_addr <= 16'h0000;
    end
  endtask

  task automatic poll_done;
    reg [31:0] status_word;
    integer tries;
    begin : wait_done_block
      for (tries = 0; tries < 30000; tries++) begin
        read_reg(16'h0004, status_word);
        if (status_word[2]) begin
          $display("TB ERROR: STATUS error bit asserted");
          $finish(1);
        end
        if (status_word[1]) begin
          disable wait_done_block;
        end
      end
      $display("TB ERROR: poll_done timeout");
      $finish(1);
    end
  endtask

  task automatic launch_cmd(
    input [255:0] name,
    input [7:0] cmd_word,
    input [31:0] cfg_word,
    input [31:0] len_word,
    input [2:0] buf_a,
    input [2:0] buf_b,
    input [2:0] buf_r
  );
    integer cmd_cycles;
    integer wait_cycles;
    integer prev_keygen_state;
    integer cur_keygen_state;
    bit f_checked;
    bit f_ntt_checked;
    bit f_inv_checked;
    bit f2_checked;
    bit g_checked;
    bit g_ntt_checked;
    bit pkpoly_checked;
    begin
      write_reg(16'h0020, {29'h0, buf_a});
      write_reg(16'h0024, {29'h0, buf_b});
      write_reg(16'h0028, {29'h0, buf_r});
      write_reg(16'h000c, cfg_word);
      write_reg(16'h0010, len_word);
      write_reg(16'h0008, {24'h0, cmd_word});
      write_reg(16'h0000, 32'h1);
      cmd_cycles = 0;
      wait_cycles = 0;
      prev_keygen_state = PKE_KEYGEN_IDLE;
      cur_keygen_state = PKE_KEYGEN_IDLE;
      f_checked = 1'b0;
      f_ntt_checked = 1'b0;
      f_inv_checked = 1'b0;
      f2_checked = 1'b0;
      g_checked = 1'b0;
      g_ntt_checked = 1'b0;
      pkpoly_checked = 1'b0;
      @(posedge clk);
      while (!(busy || done || error)) begin
        @(posedge clk);
        wait_cycles = wait_cycles + 1;
        if (wait_cycles > 300000) begin
          $display("TB ERROR: %0s launch timeout keygen_state=%0d sampler_state=%0d xof_state=%0d nonce_cur=%0d",
                   name,
                   dut.u_dut.u_pke_keygen_core.pke_keygen_state,
                   dut.u_dut.u_sampler_core.state,
                   dut.u_dut.u_sampler_core.u_seed_xof_core.state,
                   dut.u_dut.u_pke_keygen_core.nonce_cur);
          $finish(1);
        end
      end
      prev_keygen_state = dut.u_dut.u_pke_keygen_core.pke_keygen_state;
      while (!(done || error)) begin
        @(posedge clk);
        cmd_cycles = cmd_cycles + 1;
        #1;
        cur_keygen_state = dut.u_dut.u_pke_keygen_core.pke_keygen_state;
        if ((cur_keygen_state == PKE_KEYGEN_WAIT_NTT_F) &&
            !f_checked) begin
          compare_keygen_vec16("PKE_KEYGEN_F", dut.u_dut.u_pke_keygen_core.f_vec, 0);
          f_checked = 1'b1;
        end
        if ((cur_keygen_state == PKE_KEYGEN_WAIT_BASEINV_F) &&
            !f_ntt_checked) begin
          compare_keygen_vec16("PKE_KEYGEN_F_NTTMQ", dut.u_dut.u_pke_keygen_core.f_nttmq_vec, 1);
          f_ntt_checked = 1'b1;
        end
        if (dut.u_dut.u_pke_keygen_core.baseinv_ready &&
            !f_inv_checked) begin
          compare_keygen_vec16("PKE_KEYGEN_F_INV", dut.u_dut.u_pke_keygen_core.f_inv_ntt_vec, 2);
          f_inv_checked = 1'b1;
        end
        if (dut.u_dut.u_pke_keygen_core.fast_inv_ready &&
            !f2_checked) begin
          compare_keygen_vec16("PKE_KEYGEN_F2", dut.u_dut.u_pke_keygen_core.f2_vec, 3);
          f2_checked = 1'b1;
        end
        if ((cur_keygen_state == PKE_KEYGEN_WAIT_BASEMUL) &&
            !g_checked) begin
          compare_keygen_vec16("PKE_KEYGEN_G", dut.u_dut.u_pke_keygen_core.g_vec, 4);
          compare_keygen_vec16("PKE_KEYGEN_G_NTTMQ", dut.u_dut.u_pke_keygen_core.g_nttmq_vec, 5);
          g_checked = 1'b1;
          g_ntt_checked = 1'b1;
        end
        if (dut.u_dut.u_pke_keygen_core.pk_poly_ready &&
            !pkpoly_checked) begin
          compare_keygen_vec16("PKE_KEYGEN_PKPOLY", dut.u_dut.u_pke_keygen_core.pkpoly_vec, 6);
          pkpoly_checked = 1'b1;
        end
        if (cmd_cycles > 300000) begin
          $display("TB ERROR: %0s completion timeout keygen_state=%0d sampler_state=%0d xof_state=%0d nonce_cur=%0d",
                   name,
                   dut.u_dut.u_pke_keygen_core.pke_keygen_state,
                   dut.u_dut.u_sampler_core.state,
                   dut.u_dut.u_sampler_core.u_seed_xof_core.state,
                   dut.u_dut.u_pke_keygen_core.nonce_cur);
          $finish(1);
        end
        prev_keygen_state = cur_keygen_state;
      end
      last_cmd_cycles = cmd_cycles;
      total_cmd_cycles = total_cmd_cycles + cmd_cycles;
      poll_done();
      if (!f_checked || !f_ntt_checked || !f_inv_checked || !f2_checked ||
          !g_checked || !g_ntt_checked || !pkpoly_checked) begin
        $display("TB ERROR: %0s stage checks incomplete f=%0b f_ntt=%0b f_inv=%0b f2=%0b g=%0b g_ntt=%0b pkpoly=%0b",
                 name, f_checked, f_ntt_checked, f_inv_checked, f2_checked,
                 g_checked, g_ntt_checked, pkpoly_checked);
        $finish(1);
      end
      check_keygen_stage_counters();
      $display("TB INFO: %0s top-level command completed in %0d cycles", name, cmd_cycles);
    end
  endtask

  task automatic compare_keygen_vec16(
    input [255:0] name,
    input logic signed [NTT_N*COEFF_W-1:0] got_vec,
    input integer mode
  );
    integer mismatch_count;
    logic signed [15:0] got_coeff;
    logic signed [15:0] exp_coeff;
    begin
      mismatch_count = 0;
      for (i = 0; i < NTT_N; i++) begin
        got_coeff = got_vec[i*COEFF_W +: COEFF_W];
        case (mode)
          0: exp_coeff = $signed(f_mem[i]);
          1: exp_coeff = $signed(f_nttmq_mem[i]);
          2: exp_coeff = $signed(f_inv_ntt_mem[i]);
          3: exp_coeff = $signed(f2_vec_mem[i]);
          4: exp_coeff = $signed(g_mem[i]);
          5: exp_coeff = $signed(g_nttmq_mem[i]);
          default: exp_coeff = $signed(pkpoly_mem[i]);
        endcase
        if (got_coeff !== exp_coeff) begin
          if (mismatch_count < 8) begin
            $display("TB ERROR: %0s mismatch idx=%0d got=%0d exp=%0d",
                     name, i, got_coeff, exp_coeff);
          end
          mismatch_count = mismatch_count + 1;
        end
      end
      if (mismatch_count != 0) begin
        $display("TB ERROR: %0s mismatch count=%0d", name, mismatch_count);
        $finish(1);
      end
    end
  endtask

  task automatic check_keygen_stage_counters;
    begin
      // Synced mainline RTL no longer exposes legacy dbg_stage_enter/exit counters.
    end
  endtask

  task automatic compare_pk_packed(input [255:0] name, input [2:0] buf_sel);
    integer mismatch_count;
    logic [15:0] got_word;
    begin
      mismatch_count = 0;
      for (i = 0; i < NTT_N; i++) begin
        got_word = dut.u_dut.u_buf_mgr.mem[buf_sel][i % BUF_BANKS][i / BUF_BANKS];
        if ((2*i) < PK_PACK_BYTES) begin
          if (got_word[7:0] !== pk_packed_mem[2*i]) begin
            if (mismatch_count < 8) begin
              $display("TB ERROR: %0s low mismatch idx=%0d got=%02x exp=%02x",
                       name, 2*i, got_word[7:0], pk_packed_mem[2*i]);
            end
            mismatch_count = mismatch_count + 1;
          end
        end else if (got_word[7:0] !== 8'h00) begin
          if (mismatch_count < 8) begin
            $display("TB ERROR: %0s low tail mismatch idx=%0d got=%02x exp=00",
                     name, 2*i, got_word[7:0]);
          end
          mismatch_count = mismatch_count + 1;
        end

        if ((2*i + 1) < PK_PACK_BYTES) begin
          if (got_word[15:8] !== pk_packed_mem[2*i + 1]) begin
            if (mismatch_count < 8) begin
              $display("TB ERROR: %0s high mismatch idx=%0d got=%02x exp=%02x",
                       name, 2*i + 1, got_word[15:8], pk_packed_mem[2*i + 1]);
            end
            mismatch_count = mismatch_count + 1;
          end
        end else if (got_word[15:8] !== 8'h00) begin
          if (mismatch_count < 8) begin
            $display("TB ERROR: %0s high tail mismatch idx=%0d got=%02x exp=00",
                     name, 2*i + 1, got_word[15:8]);
          end
          mismatch_count = mismatch_count + 1;
        end
      end
      if (mismatch_count != 0) begin
        $display("TB ERROR: %0s mismatch count=%0d", name, mismatch_count);
        $finish(1);
      end
    end
  endtask

  task automatic compare_sk_packed(
    input [255:0] name,
    input [2:0] lo_buf_sel,
    input [2:0] hi_buf_sel
  );
    integer mismatch_count;
    logic [15:0] got_word;
    integer sk_hi_bytes;
    begin
      mismatch_count = 0;
      sk_hi_bytes = SK_PACK_BYTES - NTT_N;
      for (i = 0; i < NTT_N; i++) begin
        got_word = dut.u_dut.u_buf_mgr.mem[lo_buf_sel][i % BUF_BANKS][i / BUF_BANKS];
        if (i < SK_PACK_BYTES) begin
          if (got_word[7:0] !== sk_packed_mem[i]) begin
            if (mismatch_count < 8) begin
              $display("TB ERROR: %0s lo mismatch idx=%0d got=%02x exp=%02x",
                       name, i, got_word[7:0], sk_packed_mem[i]);
            end
            mismatch_count = mismatch_count + 1;
          end
        end else if (got_word[7:0] !== 8'h00) begin
          if (mismatch_count < 8) begin
            $display("TB ERROR: %0s lo tail mismatch idx=%0d got=%02x exp=00",
                     name, i, got_word[7:0]);
          end
          mismatch_count = mismatch_count + 1;
        end
        if (got_word[15:8] !== 8'h00) begin
          if (mismatch_count < 8) begin
            $display("TB ERROR: %0s lo upper-byte mismatch idx=%0d got=%02x exp=00",
                     name, i, got_word[15:8]);
          end
          mismatch_count = mismatch_count + 1;
        end
      end

      for (i = 0; i < NTT_N; i++) begin
        got_word = dut.u_dut.u_buf_mgr.mem[hi_buf_sel][i % BUF_BANKS][i / BUF_BANKS];
        if (i < sk_hi_bytes) begin
          if (got_word[7:0] !== sk_packed_mem[NTT_N + i]) begin
            if (mismatch_count < 8) begin
              $display("TB ERROR: %0s hi mismatch idx=%0d got=%02x exp=%02x",
                       name, NTT_N + i, got_word[7:0], sk_packed_mem[NTT_N + i]);
            end
            mismatch_count = mismatch_count + 1;
          end
        end else if (got_word[7:0] !== 8'h00) begin
          if (mismatch_count < 8) begin
            $display("TB ERROR: %0s hi tail mismatch idx=%0d got=%02x exp=00",
                     name, NTT_N + i, got_word[7:0]);
          end
          mismatch_count = mismatch_count + 1;
        end
        if (got_word[15:8] !== 8'h00) begin
          if (mismatch_count < 8) begin
            $display("TB ERROR: %0s hi upper-byte mismatch idx=%0d got=%02x exp=00",
                     name, NTT_N + i, got_word[15:8]);
          end
          mismatch_count = mismatch_count + 1;
        end
      end

      if (mismatch_count != 0) begin
        $display("TB ERROR: %0s mismatch count=%0d", name, mismatch_count);
        $finish(1);
      end
    end
  endtask

  initial begin
    $readmemh("testdata/keygen_seed.mem", keygen_seed_mem);
    $readmemh("testdata/keygen_f_nonce.mem", keygen_f_nonce_mem);
    $readmemh("testdata/keygen_g_nonce.mem", keygen_g_nonce_mem);
    $readmemh("testdata/keygen_f.mem", f_mem);
    $readmemh("testdata/keygen_f_nttmq.mem", f_nttmq_mem);
    $readmemh("testdata/keygen_f_inv_ntt.mem", f_inv_ntt_mem);
    $readmemh("testdata/keygen_f2_vec.mem", f2_vec_mem);
    $readmemh("testdata/keygen_g.mem", g_mem);
    $readmemh("testdata/keygen_g_nttmq.mem", g_nttmq_mem);
    $readmemh("testdata/keygen_pkpoly.mem", pkpoly_mem);
    $readmemh("testdata/keygen_pk_packed.mem", pk_packed_mem);
    $readmemh("testdata/keygen_sk_packed.mem", sk_packed_mem);

    clk = 1'b0;
    rst_n = 1'b0;
    wr_en = 1'b0;
    wr_addr = 16'h0000;
    wr_data = 32'h0;
    rd_en = 1'b0;
    rd_addr = 16'h0000;
    total_cmd_cycles = 0;
    last_cmd_cycles = 0;
    fused_cmd_cycles = 0;

    repeat (4) @(negedge clk);
    rst_n = 1'b1;

    for (i = 0; i < NTT_N; i++) begin
      dut.u_dut.u_buf_mgr.mem[3'd0][i % BUF_BANKS][i / BUF_BANKS] = 16'd0;
      dut.u_dut.u_buf_mgr.mem[3'd1][i % BUF_BANKS][i / BUF_BANKS] = 16'd0;
      dut.u_dut.u_buf_mgr.mem[3'd5][i % BUF_BANKS][i / BUF_BANKS] = 16'd0;
    end

    for (i = 0; i < 64; i++) begin
      dut.u_dut.u_seedbuf_mgr.mem[RAW_SEED_BASE + i] = keygen_seed_mem[i];
    end

    launch_cmd("PKE_KEYGEN", 8'h92, 32'h8000_0000 | RAW_SEED_BASE, 32'd1024, 3'd0, 3'd1, 3'd5);
    fused_cmd_cycles = last_cmd_cycles;
    compare_pk_packed("PKE_KEYGEN_PK", 3'd0);
    compare_sk_packed("PKE_KEYGEN_SK", 3'd1, 3'd5);
    $display("TB INFO: PKE_KEYGEN fused command matched packed pk/sk references");
    $display("TB INFO: PKE_KEYGEN fused command cycles = %0d", fused_cmd_cycles);
    $display("TB PASS: zen_accel_top PKE keygen path passed");
    $finish(0);
  end

endmodule
