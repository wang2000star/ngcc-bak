`timescale 1ns/1ps

module zen_pke_dec_path_tb;

  localparam int NTT_N = 1024;
  localparam int NTT_N2 = 512;
  localparam int NTT_N4 = 256;
  localparam int COEFF_W = 16;
  localparam int MSG_BYTES = NTT_N4 / 8;
  localparam int SK_PACK_BYTES = (NTT_N * 5) / 4 + (NTT_N / 32);
  localparam int PKE_DEC_IDLE             = 0;
  localparam int PKE_DEC_PREFETCH_AB      = 1;
  localparam int PKE_DEC_PREFETCH_F2      = 2;
  localparam int PKE_DEC_PREP_SK          = 3;
  localparam int PKE_DEC_WAIT_PREP_SK     = 4;
  localparam int PKE_DEC_LAUNCH_CT_DECOMP = 5;
  localparam int PKE_DEC_WAIT_CT_DECOMP   = 6;
  localparam int PKE_DEC_LAUNCH_NTT       = 7;
  localparam int PKE_DEC_WAIT_NTT         = 8;
  localparam int PKE_DEC_LAUNCH_BASEMUL   = 9;
  localparam int PKE_DEC_WAIT_BASEMUL     = 10;
  localparam int PKE_DEC_LAUNCH_INTT      = 11;
  localparam int PKE_DEC_WAIT_INTT        = 12;
  localparam int PKE_DEC_LAUNCH_POST      = 13;
  localparam int PKE_DEC_WAIT_POST        = 14;
  localparam int PKE_DEC_LAUNCH_PACK      = 15;
  localparam int PKE_DEC_WAIT_PACK        = 16;
  localparam int PKE_DEC_WRITEBACK        = 17;
  localparam int BIN_ST_RUN_DEC_T0        = 12;
  localparam int BIN_ST_RUN_DEC_R2        = 13;
  localparam int BIN_ST_RUN_DEC_DECODE    = 14;
  localparam int BIN_ST_RUN_DEC_PACK      = 15;
  localparam int DEC_DBG_STAGE_PREP       = 0;
  localparam int DEC_DBG_STAGE_CT_DECOMP  = 1;
  localparam int DEC_DBG_STAGE_NTT        = 2;
  localparam int DEC_DBG_STAGE_BASEMUL    = 3;
  localparam int DEC_DBG_STAGE_INTT       = 4;
  localparam int DEC_DBG_STAGE_POSTPROC   = 5;
  localparam int DEC_DBG_STAGE_MSG_PACK   = 6;

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

  logic [7:0] ct_packed_mem [0:NTT_N-1];
  logic [7:0] sk_packed_mem [0:SK_PACK_BYTES-1];
  logic [15:0] ct_decomp_mem [0:NTT_N-1];
  logic [15:0] f_ntt_mem [0:NTT_N-1];
  logic [15:0] f2_vec_mem [0:NTT_N-1];
  logic [15:0] ct_ntt_mem [0:NTT_N-1];
  logic [15:0] cf_ntt_mem [0:NTT_N-1];
  logic [15:0] cf_intt_mem [0:NTT_N-1];
  logic [15:0] t0_transform_mem [0:NTT_N-1];
  logic [15:0] a_mod2_mem [0:NTT_N-1];
  logic [15:0] mp0_mem [0:NTT_N-1];
  logic [15:0] t2_mem [0:NTT_N-1];
  logic [15:0] mp1_bits_mem [0:NTT_N4-1];
  logic [7:0] msg_mem [0:31];
  logic [15:0] buf_read_mem [0:NTT_N-1];
  logic [15:0] r2_read_mem [0:NTT_N-1];
  logic [15:0] decode_read_mem [0:NTT_N-1];
  logic [15:0] mp1_read_mem [0:NTT_N-1];
  logic [15:0] host_t0_mem [0:NTT_N-1];
  logic [15:0] host_a_mod2_mem [0:NTT_N-1];
  integer total_cmd_cycles;
  integer last_cmd_cycles;
  integer i;
`ifdef DEBUG_PKE_DEC
  integer debug_wait_cycles;
  logic [4:0] debug_prev_pke_dec_state;
`endif

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

  function automatic logic signed [15:0] montgomery_reduce(input logic signed [31:0] a);
    logic signed [15:0] u;
    logic signed [31:0] t;
    begin
      u = a * (-16'sd767);
      t = a - (u * 16'sd769);
      montgomery_reduce = t >>> 16;
    end
  endfunction

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

  task automatic host_buf_write(
    input [2:0] buf_sel,
    input [9:0] addr,
    input [15:0] data
  );
    begin
      write_reg(16'h0100, {29'h0, buf_sel});
      write_reg(16'h0104, {22'h0, addr});
      write_reg(16'h0108, {16'h0, data});
      write_reg(16'h010C, 32'h1);
    end
  endtask

  task automatic host_buf_read(
    input [2:0] buf_sel,
    input [9:0] addr,
    output [15:0] data
  );
    reg [31:0] rd_word;
    begin
      write_reg(16'h0100, {29'h0, buf_sel});
      write_reg(16'h0104, {22'h0, addr});
      @(negedge clk);
      @(negedge clk);
      read_reg(16'h0110, rd_word);
      data = rd_word[15:0];
    end
  endtask

  task automatic poll_done;
    reg [31:0] status_word;
    integer tries;
    begin : wait_done_block
      for (tries = 0; tries < 2400; tries++) begin
        read_reg(16'h0004, status_word);
`ifdef DEBUG_PKE_DEC
        if ((tries % 100) == 0) begin
          $display("TB DEBUG: poll_done try=%0d status=%08x raw_status=%08x busy=%0b done=%0b error=%0b pke_dec_state=%0d",
                   tries, status_word, dut.u_dut.u_ctrl_if.status_reg, busy, done, error, dut.u_dut.u_pke_dec_core.pke_dec_state);
        end
`endif
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
    integer prev_dec_state;
    integer cur_dec_state;
    integer prev_bin_state;
    integer cur_bin_state;
    bit prep_checked;
    bit f2_checked;
    bit ct_decomp_checked;
    bit ntt_checked;
    bit basemul_checked;
    bit intt_checked;
    bit t0_checked;
    bit a_mod2_checked;
    bit mp0_checked;
    bit t2_checked;
    bit mp1_checked;
    begin
      write_reg(16'h0020, {29'h0, buf_a});
      write_reg(16'h0024, {29'h0, buf_b});
      write_reg(16'h0028, {29'h0, buf_r});
      write_reg(16'h000c, cfg_word);
      write_reg(16'h0010, len_word);
      write_reg(16'h0008, {24'h0, cmd_word});
      write_reg(16'h0000, 32'h1);
      cmd_cycles = 0;
      prev_dec_state = PKE_DEC_IDLE;
      cur_dec_state = PKE_DEC_IDLE;
      prev_bin_state = 0;
      cur_bin_state = 0;
      prep_checked = 1'b0;
      f2_checked = 1'b0;
      ct_decomp_checked = 1'b0;
      ntt_checked = 1'b0;
      basemul_checked = 1'b0;
      intt_checked = 1'b0;
      t0_checked = 1'b0;
      a_mod2_checked = 1'b0;
      mp0_checked = 1'b0;
      t2_checked = 1'b0;
      mp1_checked = 1'b0;
      @(posedge clk);
      while (!(busy || done || error)) begin
        @(posedge clk);
      end
      prev_dec_state = dut.u_dut.u_pke_dec_core.pke_dec_state;
      prev_bin_state = dut.u_dut.u_binary_core.state;
      while (!(done || error)) begin
        @(posedge clk);
        cmd_cycles = cmd_cycles + 1;
        #1;
        cur_dec_state = dut.u_dut.u_pke_dec_core.pke_dec_state;
        cur_bin_state = dut.u_dut.u_binary_core.state;
        if ((cur_dec_state == PKE_DEC_LAUNCH_BASEMUL) &&
            !prep_checked) begin
          compare_dec_vec16("PKE_DEC_F_NTT", dut.u_dut.u_pke_dec_core.f_ntt_vec, 0);
          prep_checked = 1'b1;
        end
        if ((cur_dec_state == PKE_DEC_LAUNCH_POST) &&
            !f2_checked) begin
          compare_dec_vec16("PKE_DEC_F2", dut.u_dut.u_pke_dec_core.f2_vec, 1);
          f2_checked = 1'b1;
        end
        if ((prev_dec_state == PKE_DEC_WAIT_CT_DECOMP) &&
            (cur_dec_state == PKE_DEC_LAUNCH_NTT) &&
            !ct_decomp_checked) begin
          compare_dec_vec16("PKE_DEC_CT_DECOMP", dut.u_dut.u_pke_dec_core.stage_vec, 2);
          ct_decomp_checked = 1'b1;
        end
        if ((cur_dec_state == PKE_DEC_LAUNCH_BASEMUL) &&
            !ntt_checked) begin
          compare_dec_vec16("PKE_DEC_CT_NTT", dut.u_dut.u_pke_dec_core.stage_vec, 3);
          ntt_checked = 1'b1;
        end
        if ((prev_dec_state == PKE_DEC_WAIT_BASEMUL) &&
            (cur_dec_state == PKE_DEC_LAUNCH_INTT) &&
            !basemul_checked) begin
          compare_dec_vec16("PKE_DEC_CF_NTT", dut.u_dut.u_pke_dec_core.stage_vec, 4);
          basemul_checked = 1'b1;
        end
        if ((prev_dec_state == PKE_DEC_WAIT_INTT) &&
            (cur_dec_state == PKE_DEC_LAUNCH_POST) &&
            !intt_checked) begin
          compare_dec_vec16("PKE_DEC_CF_INTT", dut.u_dut.u_pke_dec_core.stage_vec, 5);
          intt_checked = 1'b1;
        end
        if ((prev_bin_state == BIN_ST_RUN_DEC_T0) &&
            (cur_bin_state == BIN_ST_RUN_DEC_R2) &&
            !t0_checked) begin
          compare_dec_t0_transform("PKE_DEC_T0");
          compare_dec_a_mod2("PKE_DEC_A_MOD2");
          t0_checked = 1'b1;
          a_mod2_checked = 1'b1;
        end
        if ((prev_bin_state == BIN_ST_RUN_DEC_R2) &&
            (cur_bin_state == BIN_ST_RUN_DEC_DECODE) &&
            !mp0_checked) begin
          compare_dec_mp0("PKE_DEC_MP0");
          mp0_checked = 1'b1;
        end
        if ((prev_bin_state == BIN_ST_RUN_DEC_DECODE) &&
            (cur_bin_state == BIN_ST_RUN_DEC_PACK) &&
            !t2_checked) begin
          compare_dec_t2("PKE_DEC_T2");
          t2_checked = 1'b1;
        end
        if ((prev_dec_state == PKE_DEC_WAIT_POST) &&
            (cur_dec_state == PKE_DEC_LAUNCH_PACK) &&
            !mp1_checked) begin
          compare_dec_mp1_bits("PKE_DEC_MP1");
          mp1_checked = 1'b1;
        end
`ifdef DEBUG_PKE_DEC
        if ((cmd_cycles % 250) == 0) begin
          $display("TB DEBUG: cmd=%0s cycles=%0d busy=%0b done=%0b error=%0b pke_dec_state=%0d ntt_state=%0d ntt_busy=%0b ntt_done=%0b ntt_vld=%0b len_cur=%0d block_base=%0d group_offset=%0d twiddle_idx=%0d",
                   name, cmd_cycles, busy, done, error, dut.u_dut.u_pke_dec_core.pke_dec_state,
                   dut.u_dut.u_ntt_core.state, dut.u_dut.ntt_busy, dut.u_dut.ntt_done, dut.u_dut.ntt_vec_out_valid,
                   dut.u_dut.u_ntt_core.len_cur, dut.u_dut.u_ntt_core.block_base,
                   dut.u_dut.u_ntt_core.group_offset, dut.u_dut.u_ntt_core.twiddle_idx);
        end
        if (cmd_cycles >= 10000) begin
          $display("TB ERROR: %0s exceeded debug cycle guard, busy=%0b done=%0b error=%0b pke_dec_state=%0d ntt_state=%0d ntt_busy=%0b ntt_done=%0b ntt_vld=%0b len_cur=%0d block_base=%0d group_offset=%0d twiddle_idx=%0d",
                   name, busy, done, error, dut.u_dut.u_pke_dec_core.pke_dec_state,
                   dut.u_dut.u_ntt_core.state, dut.u_dut.ntt_busy, dut.u_dut.ntt_done, dut.u_dut.ntt_vec_out_valid,
                   dut.u_dut.u_ntt_core.len_cur, dut.u_dut.u_ntt_core.block_base,
                   dut.u_dut.u_ntt_core.group_offset, dut.u_dut.u_ntt_core.twiddle_idx);
          $finish(1);
        end
`endif
        prev_dec_state = cur_dec_state;
        prev_bin_state = cur_bin_state;
      end
      last_cmd_cycles = cmd_cycles;
      total_cmd_cycles = total_cmd_cycles + cmd_cycles;
`ifdef DEBUG_PKE_DEC
      $display("TB DEBUG: command loop exit cycles=%0d busy=%0b done=%0b error=%0b raw_status=%08x pke_dec_state=%0d",
               cmd_cycles, busy, done, error, dut.u_dut.u_ctrl_if.status_reg, dut.u_dut.u_pke_dec_core.pke_dec_state);
`endif
      poll_done();
      if (!prep_checked || !f2_checked || !ct_decomp_checked || !ntt_checked ||
          !basemul_checked || !intt_checked || !t0_checked ||
          !a_mod2_checked || !mp0_checked || !t2_checked ||
          !mp1_checked) begin
        $display("TB ERROR: %0s stage checks incomplete prep=%0b f2=%0b ct_decomp=%0b ntt=%0b basemul=%0b intt=%0b t0=%0b a_mod2=%0b mp0=%0b t2=%0b mp1=%0b",
                 name, prep_checked, f2_checked, ct_decomp_checked, ntt_checked,
                 basemul_checked, intt_checked, t0_checked,
                 a_mod2_checked, mp0_checked, t2_checked, mp1_checked);
        $finish(1);
      end
      check_dec_stage_counters();
      $display("TB INFO: %0s top-level command completed in %0d cycles", name, cmd_cycles);
    end
  endtask

  task automatic read_buffer_to_mem(input [2:0] buf_sel);
    logic [15:0] got;
    begin
      for (i = 0; i < NTT_N; i++) begin
        host_buf_read(buf_sel, i[9:0], got);
        buf_read_mem[i] = got;
      end
    end
  endtask

  task automatic compare_buf_with_mode(
    input [255:0] name,
    input integer mode
  );
    integer mismatch_count;
    logic [15:0] exp;
    begin
      mismatch_count = 0;
      for (i = 0; i < NTT_N; i++) begin
        case (mode)
          0: exp = ct_ntt_mem[i];
          1: exp = cf_ntt_mem[i];
          2: exp = cf_intt_mem[i];
          3: exp = t0_transform_mem[i];
          4: exp = a_mod2_mem[i];
          5: exp = mp0_mem[i];
          default: exp = t2_mem[i];
        endcase
        if (buf_read_mem[i] !== exp) begin
          if (mismatch_count < 8) begin
            $display("TB ERROR: %0s mismatch idx=%0d got=%0d exp=%0d", name, i, $signed(buf_read_mem[i]), $signed(exp));
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

  task automatic compare_dec_vec16(
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
          0: exp_coeff = $signed(f_ntt_mem[i]);
          1: exp_coeff = $signed(f2_vec_mem[i]);
          2: exp_coeff = $signed(ct_decomp_mem[i]);
          3: exp_coeff = $signed(ct_ntt_mem[i]);
          4: exp_coeff = $signed(cf_ntt_mem[i]);
          default: exp_coeff = $signed(cf_intt_mem[i]);
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

  task automatic compare_dec_t0_transform(input [255:0] name);
    integer mismatch_count;
    logic signed [15:0] got_coeff;
    begin
      mismatch_count = 0;
      for (i = 0; i < NTT_N; i++) begin
        got_coeff = dut.u_dut.u_binary_core.dec_t0_vec[i*COEFF_W +: COEFF_W];
        if (got_coeff !== $signed(t0_transform_mem[i])) begin
          if (mismatch_count < 8) begin
            $display("TB ERROR: %0s mismatch idx=%0d got=%0d exp=%0d",
                     name, i, got_coeff, $signed(t0_transform_mem[i]));
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

  task automatic compare_dec_a_mod2(input [255:0] name);
    integer mismatch_count;
    logic signed [15:0] lhs;
    logic signed [15:0] rhs;
    logic signed [15:0] got_coeff;
    begin
      mismatch_count = 0;
      for (i = 0; i < NTT_N; i++) begin
        if (i < NTT_N2) begin
          lhs = dut.u_dut.u_binary_core.dec_t0_vec[i*COEFF_W +: COEFF_W] & 16'sd1;
          rhs = dut.u_dut.u_binary_core.dec_t0_vec[(i + NTT_N2)*COEFF_W +: COEFF_W] & 16'sd1;
          got_coeff = lhs ^ rhs;
        end else begin
          got_coeff = 16'sd0;
        end
        if (got_coeff !== $signed(a_mod2_mem[i])) begin
          if (mismatch_count < 8) begin
            $display("TB ERROR: %0s mismatch idx=%0d got=%0d exp=%0d",
                     name, i, got_coeff, $signed(a_mod2_mem[i]));
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

  task automatic compare_dec_mp0(input [255:0] name);
    integer mismatch_count;
    logic signed [15:0] got_coeff;
    begin
      mismatch_count = 0;
      for (i = 0; i < NTT_N4; i++) begin
        got_coeff = dut.u_dut.u_binary_core.dec_r2_vec[i*COEFF_W +: COEFF_W];
        if (got_coeff !== $signed(mp0_mem[i])) begin
          if (mismatch_count < 8) begin
            $display("TB ERROR: %0s mismatch idx=%0d got=%0d exp=%0d",
                     name, i, got_coeff, $signed(mp0_mem[i]));
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

  task automatic compare_dec_t2(input [255:0] name);
    integer mismatch_count;
    logic signed [15:0] got_coeff;
    begin
      mismatch_count = 0;
      for (i = 0; i < NTT_N; i++) begin
        got_coeff = dut.u_dut.u_binary_core.vec_r_data[i*COEFF_W +: COEFF_W];
        if (got_coeff !== $signed(t2_mem[i])) begin
          if (mismatch_count < 8) begin
            $display("TB ERROR: %0s mismatch idx=%0d got=%0d exp=%0d",
                     name, i, got_coeff, $signed(t2_mem[i]));
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

  task automatic compare_dec_mp1_bits(input [255:0] name);
    integer mismatch_count;
    logic signed [15:0] got_coeff;
    logic signed [15:0] exp_coeff;
    begin
      mismatch_count = 0;
      for (i = 0; i < NTT_N; i++) begin
        got_coeff = dut.u_dut.u_pke_dec_core.stage_vec[i*COEFF_W +: COEFF_W];
        if (i < NTT_N4) begin
          exp_coeff = $signed(mp1_bits_mem[i]);
        end else begin
          exp_coeff = 16'sd0;
        end
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

  task automatic check_dec_stage_counters;
    begin
      // Synced mainline RTL no longer exposes legacy dbg_stage_enter/exit counters.
    end
  endtask

  task automatic compare_hw_msg_buffer(input [2:0] buf_sel);
    integer msg_mismatch_count;
    begin
      msg_mismatch_count = 0;
`ifdef FAST_PKE_DEC
      for (i = 0; i < MSG_BYTES; i++) begin
        buf_read_mem[i] = dut.u_dut.u_buf_mgr.mem[buf_sel][i % dut.u_dut.BUF_BANKS][i / dut.u_dut.BUF_BANKS];
        if (buf_read_mem[i] !== {8'h00, msg_mem[i]}) begin
          if (msg_mismatch_count < 8) begin
            $display("TB ERROR: DEC_MSG_PACK mismatch idx=%0d got=%02x exp=%02x", i, buf_read_mem[i][7:0], msg_mem[i]);
          end
          msg_mismatch_count = msg_mismatch_count + 1;
        end
      end
      for (i = MSG_BYTES; i < NTT_N; i++) begin
        buf_read_mem[i] = dut.u_dut.u_buf_mgr.mem[buf_sel][i % dut.u_dut.BUF_BANKS][i / dut.u_dut.BUF_BANKS];
        if (buf_read_mem[i] !== 16'd0) begin
          if (msg_mismatch_count < 8) begin
            $display("TB ERROR: DEC_MSG_PACK tail mismatch idx=%0d got=%0d exp=0", i, buf_read_mem[i]);
          end
          msg_mismatch_count = msg_mismatch_count + 1;
        end
      end
`else
      read_buffer_to_mem(buf_sel);
      for (i = 0; i < MSG_BYTES; i++) begin
        if (buf_read_mem[i] !== {8'h00, msg_mem[i]}) begin
          if (msg_mismatch_count < 8) begin
            $display("TB ERROR: DEC_MSG_PACK mismatch idx=%0d got=%02x exp=%02x", i, buf_read_mem[i][7:0], msg_mem[i]);
          end
          msg_mismatch_count = msg_mismatch_count + 1;
        end
      end
      for (i = MSG_BYTES; i < NTT_N; i++) begin
        if (buf_read_mem[i] !== 16'd0) begin
          if (msg_mismatch_count < 8) begin
            $display("TB ERROR: DEC_MSG_PACK tail mismatch idx=%0d got=%0d exp=0", i, buf_read_mem[i]);
          end
          msg_mismatch_count = msg_mismatch_count + 1;
        end
      end
`endif
      if (msg_mismatch_count != 0) begin
        $display("TB ERROR: DEC_MSG_PACK mismatch count=%0d", msg_mismatch_count);
        $finish(1);
      end
    end
  endtask

  initial begin
    $readmemh("testdata/dec_ct_packed.mem", ct_packed_mem);
    $readmemh("testdata/dec_sk_packed.mem", sk_packed_mem);
    $readmemh("testdata/dec_ct_decomp.mem", ct_decomp_mem);
    $readmemh("testdata/dec_f_ntt.mem", f_ntt_mem);
    $readmemh("testdata/dec_f2_vec.mem", f2_vec_mem);
    $readmemh("testdata/dec_ct_ntt.mem", ct_ntt_mem);
    $readmemh("testdata/dec_cf_ntt.mem", cf_ntt_mem);
    $readmemh("testdata/dec_cf_intt.mem", cf_intt_mem);
    $readmemh("testdata/dec_t0_transform.mem", t0_transform_mem);
    $readmemh("testdata/dec_a_mod2_vec.mem", a_mod2_mem);
    $readmemh("testdata/dec_mp0.mem", mp0_mem);
    $readmemh("testdata/dec_t2.mem", t2_mem);
    $readmemh("testdata/dec_mp1_bits.mem", mp1_bits_mem);
    $readmemh("testdata/dec_msg.mem", msg_mem);

    clk = 1'b0;
    rst_n = 1'b0;
    wr_en = 1'b0;
    wr_addr = 16'h0000;
    wr_data = 32'h0;
    rd_en = 1'b0;
    rd_addr = 16'h0000;
    total_cmd_cycles = 0;
    last_cmd_cycles = 0;
`ifdef DEBUG_PKE_DEC
    debug_wait_cycles = 0;
    debug_prev_pke_dec_state = 5'h1f;
`endif

    repeat (4) @(negedge clk);
    rst_n = 1'b1;

`ifdef FAST_PKE_DEC
    for (i = 0; i < NTT_N; i++) begin
      dut.u_dut.u_buf_mgr.mem[0][i % dut.u_dut.BUF_BANKS][i / dut.u_dut.BUF_BANKS] = {8'h00, ct_packed_mem[i]};
      dut.u_dut.u_buf_mgr.mem[1][i % dut.u_dut.BUF_BANKS][i / dut.u_dut.BUF_BANKS] = 16'd0;
      dut.u_dut.u_buf_mgr.mem[5][i % dut.u_dut.BUF_BANKS][i / dut.u_dut.BUF_BANKS] = 16'd0;
    end
    for (i = 0; i < SK_PACK_BYTES; i++) begin
      if (i < NTT_N) begin
        dut.u_dut.u_buf_mgr.mem[1][i % dut.u_dut.BUF_BANKS][i / dut.u_dut.BUF_BANKS] = {8'h00, sk_packed_mem[i]};
      end else begin
        dut.u_dut.u_buf_mgr.mem[5][(i - NTT_N) % dut.u_dut.BUF_BANKS][(i - NTT_N) / dut.u_dut.BUF_BANKS] = {8'h00, sk_packed_mem[i]};
      end
    end
`else
    for (i = 0; i < NTT_N; i++) begin
      host_buf_write(3'd0, i[9:0], {8'h00, ct_packed_mem[i]});
      host_buf_write(3'd1, i[9:0], 16'd0);
      host_buf_write(3'd5, i[9:0], 16'd0);
    end
    for (i = 0; i < SK_PACK_BYTES; i++) begin
      if (i < NTT_N) begin
        host_buf_write(3'd1, i[9:0], {8'h00, sk_packed_mem[i]});
      end else begin
        host_buf_write(3'd5, i - NTT_N, {8'h00, sk_packed_mem[i]});
      end
    end
`endif

    launch_cmd("PKE_DEC", 8'h90, 32'h8000_0005, 32'd1024, 3'd0, 3'd1, 3'd2);
    compare_hw_msg_buffer(3'd2);
    $display("TB INFO: PKE_DEC matched software reference");

    $display("TB INFO: PKE_DEC top-level command total cycles = %0d", total_cmd_cycles);
    $display("TB PASS: zen_accel_top PKE dec path passed");
    $finish(0);
  end

`ifdef DEBUG_PKE_DEC
  always @(posedge clk) begin
    if (rst_n && (dut.u_dut.u_pke_dec_core.pke_dec_state != debug_prev_pke_dec_state)) begin
      $display("TB DEBUG: pke_dec_state %0d -> %0d busy=%0b done=%0b error=%0b ntt_state=%0d ntt_busy=%0b ntt_done=%0b ntt_vld=%0b",
               debug_prev_pke_dec_state, dut.u_dut.u_pke_dec_core.pke_dec_state, busy, done, error,
               dut.u_dut.u_ntt_core.state, dut.u_dut.ntt_busy, dut.u_dut.ntt_done, dut.u_dut.ntt_vec_out_valid);
      debug_prev_pke_dec_state <= dut.u_dut.u_pke_dec_core.pke_dec_state;
    end
  end
`endif

endmodule
