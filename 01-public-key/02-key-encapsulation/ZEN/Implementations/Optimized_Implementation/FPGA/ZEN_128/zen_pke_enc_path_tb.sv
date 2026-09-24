`timescale 1ns/1ps

module zen_pke_enc_path_tb;

  localparam int NTT_N = 512;
  localparam int COEFF_W = 16;
  localparam int RAW_SEED_BASE = 0;
  localparam bit ENC_ENABLE_TRACE = 1'b0;
  localparam int ENC_TRACE_HEARTBEAT_CYCLES = 200;
  localparam int ENC_STALL_GUARD_CYCLES = 5000;
  localparam int PKE_ENC_IDLE            = 0;
  localparam int PKE_ENC_PREFETCH_AB     = 1;
  localparam int PKE_ENC_PREP            = 2;
  localparam int PKE_ENC_WAIT_PREP       = 3;
  localparam int PKE_ENC_LAUNCH_SAMPLE_S = 4;
  localparam int PKE_ENC_WAIT_SAMPLE_S   = 5;
  localparam int PKE_ENC_LAUNCH_SAMPLE_E = 6;
  localparam int PKE_ENC_WAIT_SAMPLE_E   = 7;
  localparam int PKE_ENC_LAUNCH_NTT      = 8;
  localparam int PKE_ENC_WAIT_NTT        = 9;
  localparam int PKE_ENC_LAUNCH_BASEMUL  = 10;
  localparam int PKE_ENC_WAIT_BASEMUL    = 11;
  localparam int PKE_ENC_LAUNCH_INTT     = 12;
  localparam int PKE_ENC_WAIT_INTT       = 13;
  localparam int PKE_ENC_PREP_CT         = 14;
  localparam int PKE_ENC_WRITEBACK       = 15;
  localparam int ENC_DBG_STAGE_PREP      = 0;
  localparam int ENC_DBG_STAGE_SAMPLE_S  = 1;
  localparam int ENC_DBG_STAGE_SAMPLE_E  = 2;
  localparam int ENC_DBG_STAGE_NTT       = 3;
  localparam int ENC_DBG_STAGE_BASEMUL   = 4;
  localparam int ENC_DBG_STAGE_INTT      = 5;
  localparam int ENC_DBG_STAGE_CT_PACK   = 6;

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

  logic [15:0] h_mem [0:NTT_N-1];
  logic [7:0] pk_packed_mem [0:614];
  logic [7:0] seed_mem [0:63];
  logic [15:0] s_mem [0:NTT_N-1];
  logic [15:0] e_mem [0:NTT_N-1];
  logic [15:0] s_ntt_mem [0:NTT_N-1];
  logic [15:0] hs_basemul_mem [0:NTT_N-1];
  logic [15:0] hs_intt_mem [0:NTT_N-1];
  logic [7:0] msg_mem [0:15];
  logic [15:0] msg_poly_mem [0:NTT_N-1];
  logic [15:0] final_poly_mem [0:NTT_N-1];
  logic [7:0] ct_packed_mem [0:NTT_N-1];
  logic [15:0] buf_read_mem [0:NTT_N-1];
  integer total_cmd_cycles;
  integer last_cmd_cycles;
  integer fused_cmd_cycles;
  integer i;

`ifdef USE_XCV80
  `ifdef USE_SAFE
  zen_accel_xcv80_safe_top dut (
  `elsif USE_AGGR
  zen_accel_xcv80_aggr_top dut (
  `elsif USE_TIMING
  zen_accel_xcv80_timing_top dut (
  `else
  zen_accel_xcv80_top dut (
  `endif
`else
`ifdef USE_SAFE
  zen_accel_xcvu37p_safe_top dut (
`elsif USE_AGGR
  zen_accel_xcvu37p_aggr_top dut (
`elsif USE_TIMING
  zen_accel_xcvu37p_timing_top dut (
`else
  zen_accel_xcvu37p_top dut (
`endif
`endif
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
      wr_en = 1'b1;
      wr_addr = addr;
      wr_data = data;
      @(negedge clk);
      wr_en = 1'b0;
      wr_addr = 16'h0000;
      wr_data = 32'h0;
    end
  endtask

  task automatic read_reg(input [15:0] addr, output [31:0] data);
    begin
      @(negedge clk);
      rd_en = 1'b1;
      rd_addr = addr;
      @(posedge clk);
      data = rd_data;
      @(negedge clk);
      rd_en = 1'b0;
      rd_addr = 16'h0000;
    end
  endtask

  task automatic host_buf_write(
    input [2:0] buf_sel,
    input [8:0] addr,
    input [15:0] data
  );
    begin
      write_reg(16'h0100, {29'h0, buf_sel});
      write_reg(16'h0104, {23'h0, addr});
      write_reg(16'h0108, {16'h0, data});
      write_reg(16'h010C, 32'h1);
    end
  endtask

  task automatic host_buf_read(
    input [2:0] buf_sel,
    input [8:0] addr,
    output [15:0] data
  );
    reg [31:0] rd_word;
    begin
      write_reg(16'h0100, {29'h0, buf_sel});
      write_reg(16'h0104, {23'h0, addr});
      @(negedge clk);
      @(negedge clk);
      read_reg(16'h0110, rd_word);
      data = rd_word[15:0];
    end
  endtask

  task automatic host_seed_write(
    input [9:0] addr,
    input [7:0] data
  );
    begin
      write_reg(16'h0120, {22'h0, addr});
      write_reg(16'h0124, {24'h0, data});
      write_reg(16'h0128, 32'h1);
    end
  endtask

  task automatic poll_done;
    reg [31:0] status_word;
    integer tries;
    begin : wait_done_block
      for (tries = 0; tries < 600; tries++) begin
        read_reg(16'h0004, status_word);
        if (status_word[2]) begin
          $display("TB ERROR: STATUS error bit asserted");
          $fatal(1);
        end
        if (status_word[1]) begin
          disable wait_done_block;
        end
      end
      $display("TB ERROR: poll_done timeout");
      $display("TB DEBUG: cmd=%0h active_core=%0d sample_state=%0d sampler_state=%0d sample_cmd_cur=%0h seed_ptr=%0d sample_bytes=%0d done=%0b vec_valid=%0b",
               dut.u_dut.cmd,
               dut.u_dut.active_core,
               dut.u_dut.sample_state,
               dut.u_dut.u_sampler_core.state,
               dut.u_dut.sample_cmd_cur,
               dut.u_dut.u_sampler_core.seed_ptr,
               dut.u_dut.u_sampler_core.sample_bytes,
               dut.u_dut.sampler_done,
               dut.u_dut.sampler_vec_out_valid);
      $fatal(1);
    end
  endtask

  task automatic print_enc_progress(
    input [255:0] tag,
    input integer cmd_cycles,
    input integer wait_cycles
  );
    begin
      if (ENC_ENABLE_TRACE) begin
        $display("TB TRACE: %0s t=%0t cmd_cycles=%0d wait=%0d active_core=%0d arith_core=%0d arith_state=%0d enc_state=%0d sample_state=%0d sampler_state=%0d ntt_state=%0d arith_cmd=%0h vec_in_valid=%0b ntt_start=%0b xof_state=%0d wr_row=%0d seed_ptr=%0d sample_bytes=%0d s_done=%0b s_valid=%0b ntt_done=%0b ntt_valid=%0b mul_done=%0b mul_valid=%0b",
                 tag,
                 $time,
                 cmd_cycles,
                 wait_cycles,
                 dut.u_dut.active_core,
                 dut.u_dut.arith_core,
                 dut.u_dut.arith_state,
                 dut.u_dut.u_pke_enc_core.pke_enc_state,
                 dut.u_dut.sample_state,
                 dut.u_dut.u_sampler_core.state,
                 dut.u_dut.u_ntt_core.state,
                 dut.u_dut.arith_cmd,
                 dut.u_dut.vec_in_valid,
                 dut.u_dut.ntt_core_start,
                 dut.u_dut.u_sampler_core.u_seed_xof_core.state,
                 dut.u_dut.u_pke_enc_core.wr_row,
                 dut.u_dut.u_sampler_core.seed_ptr,
                 dut.u_dut.u_sampler_core.sample_bytes,
                 dut.u_dut.sampler_done,
                 dut.u_dut.sampler_vec_out_valid,
                 dut.u_dut.ntt_done,
                 dut.u_dut.ntt_vec_out_valid,
                 dut.u_dut.basemul_done,
                 dut.u_dut.basemul_vec_out_valid);
      end
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
    integer start_wait;
    integer done_wait;
    integer last_active_core;
    integer last_enc_state;
    integer last_sample_state;
    integer last_sampler_state;
    integer last_arith_state;
    integer last_arith_core;
    integer prev_enc_state;
    integer cur_enc_state;
    integer last_checked_wr_row;
    bit prep_checked;
    bit sample_s_checked;
    bit sample_e_checked;
    bit ntt_checked;
    bit basemul_checked;
    bit intt_checked;
    bit final_poly_checked;
    begin
      write_reg(16'h0020, {29'h0, buf_a});
      write_reg(16'h0024, {29'h0, buf_b});
      write_reg(16'h0028, {29'h0, buf_r});
      write_reg(16'h000c, cfg_word);
      write_reg(16'h0010, len_word);
      write_reg(16'h0008, {24'h0, cmd_word});
      write_reg(16'h0000, 32'h1);
      cmd_cycles = 0;
      start_wait = 0;
      done_wait = 0;
      last_active_core = -1;
      last_enc_state = -1;
      last_sample_state = -1;
      last_sampler_state = -1;
      last_arith_state = -1;
      last_arith_core = -1;
      prev_enc_state = PKE_ENC_IDLE;
      cur_enc_state = PKE_ENC_IDLE;
      last_checked_wr_row = -1;
      prep_checked = 1'b0;
      sample_s_checked = 1'b0;
      sample_e_checked = 1'b0;
      ntt_checked = 1'b0;
      basemul_checked = 1'b0;
      intt_checked = 1'b0;
      final_poly_checked = 1'b0;
      @(posedge clk);
      while (!(busy || done || error) && (start_wait < 2000)) begin
        @(posedge clk);
        start_wait = start_wait + 1;
      end
      if (!(busy || done || error)) begin
        $display("TB ERROR: %0s did not start cmd=%0h active_core=%0d pke_enc_state=%0d",
                 name, cmd_word, dut.u_dut.active_core, dut.u_dut.u_pke_enc_core.pke_enc_state);
        $fatal(1);
      end
      print_enc_progress({name, " start"}, cmd_cycles, done_wait);
      last_active_core = dut.u_dut.active_core;
      last_enc_state = dut.u_dut.u_pke_enc_core.pke_enc_state;
      last_sample_state = dut.u_dut.sample_state;
      last_sampler_state = dut.u_dut.u_sampler_core.state;
      last_arith_state = dut.u_dut.arith_state;
      last_arith_core = dut.u_dut.arith_core;
      prev_enc_state = dut.u_dut.u_pke_enc_core.pke_enc_state;
      while (!(done || error) && (done_wait < 200000)) begin
        @(posedge clk);
        cmd_cycles = cmd_cycles + 1;
        done_wait = done_wait + 1;
        #1;
        cur_enc_state = dut.u_dut.u_pke_enc_core.pke_enc_state;
        if ((prev_enc_state == PKE_ENC_WAIT_PREP) &&
            (cur_enc_state == PKE_ENC_LAUNCH_SAMPLE_S) &&
            !prep_checked) begin
          compare_core_vec16("PKE_ENC_H", dut.u_dut.u_pke_enc_core.h_vec, 0);
          compare_core_vec16("PKE_ENC_MSGPOLY", dut.u_dut.u_pke_enc_core.msg_poly_vec, 1);
          prep_checked = 1'b1;
        end
        if ((prev_enc_state == PKE_ENC_WAIT_SAMPLE_S) &&
            (cur_enc_state == PKE_ENC_LAUNCH_SAMPLE_E) &&
            !sample_s_checked) begin
          compare_core_vec16("PKE_ENC_S", dut.u_dut.u_pke_enc_core.s_vec, 2);
          sample_s_checked = 1'b1;
        end
        if ((cur_enc_state == PKE_ENC_LAUNCH_BASEMUL) &&
            !sample_e_checked) begin
          compare_core_vec16("PKE_ENC_E", dut.u_dut.u_pke_enc_core.e_vec, 3);
          sample_e_checked = 1'b1;
        end
        if ((cur_enc_state == PKE_ENC_LAUNCH_BASEMUL) &&
            !ntt_checked) begin
          compare_core_vec16("PKE_ENC_S_NTT", dut.u_dut.u_pke_enc_core.stage_vec, 4);
          ntt_checked = 1'b1;
        end
        if ((prev_enc_state == PKE_ENC_WAIT_BASEMUL) &&
            (cur_enc_state == PKE_ENC_LAUNCH_INTT) &&
            !basemul_checked) begin
          compare_core_vec16("PKE_ENC_HS_BASEMUL", dut.u_dut.u_pke_enc_core.stage_vec, 5);
          basemul_checked = 1'b1;
        end
        if ((prev_enc_state == PKE_ENC_WAIT_INTT) &&
            (cur_enc_state == PKE_ENC_PREP_CT) &&
            !intt_checked) begin
          compare_core_vec16("PKE_ENC_HS_INTT", dut.u_dut.u_pke_enc_core.stage_vec, 6);
          compare_enc_final_poly("PKE_ENC_FINAL_POLY");
          intt_checked = 1'b1;
          final_poly_checked = 1'b1;
        end
        if ((cur_enc_state == PKE_ENC_WRITEBACK) &&
            dut.u_dut.vec_wr_en &&
            (dut.u_dut.vec_wr_row !== last_checked_wr_row)) begin
          compare_ct_pack_row("PKE_ENC_CT_PACK_ROW", dut.u_dut.vec_wr_row);
          last_checked_wr_row = dut.u_dut.vec_wr_row;
        end
        if ((dut.u_dut.active_core != last_active_core) ||
            (dut.u_dut.u_pke_enc_core.pke_enc_state != last_enc_state) ||
            (dut.u_dut.sample_state != last_sample_state) ||
            (dut.u_dut.u_sampler_core.state != last_sampler_state) ||
            (dut.u_dut.arith_state != last_arith_state) ||
            (dut.u_dut.arith_core != last_arith_core)) begin
          print_enc_progress({name, " state"}, cmd_cycles, done_wait);
          last_active_core = dut.u_dut.active_core;
          last_enc_state = dut.u_dut.u_pke_enc_core.pke_enc_state;
          last_sample_state = dut.u_dut.sample_state;
          last_sampler_state = dut.u_dut.u_sampler_core.state;
          last_arith_state = dut.u_dut.arith_state;
          last_arith_core = dut.u_dut.arith_core;
        end else if ((done_wait % ENC_TRACE_HEARTBEAT_CYCLES) == 0) begin
          print_enc_progress({name, " heartbeat"}, cmd_cycles, done_wait);
        end
        if (done_wait >= ENC_STALL_GUARD_CYCLES) begin
          $display("TB ERROR: %0s stall guard tripped at %0d cycles", name, done_wait);
          print_enc_progress({name, " stall"}, cmd_cycles, done_wait);
          $fatal(1);
        end
        prev_enc_state = cur_enc_state;
      end
      if (!(done || error)) begin
        $display("TB ERROR: %0s timeout cmd=%0h active_core=%0d pke_enc_state=%0d sample_state=%0d sampler_state=%0d",
                 name,
                 cmd_word,
                 dut.u_dut.active_core,
                 dut.u_dut.u_pke_enc_core.pke_enc_state,
                 dut.u_dut.sample_state,
                 dut.u_dut.u_sampler_core.state);
        print_enc_progress({name, " timeout"}, cmd_cycles, done_wait);
        $fatal(1);
      end
      last_cmd_cycles = cmd_cycles;
      total_cmd_cycles = total_cmd_cycles + cmd_cycles;
      poll_done();
      if (!prep_checked || !sample_s_checked || !sample_e_checked ||
          !ntt_checked || !basemul_checked || !intt_checked ||
          !final_poly_checked) begin
        $display("TB ERROR: %0s stage checks incomplete prep=%0b s=%0b e=%0b ntt=%0b basemul=%0b intt=%0b final=%0b",
                 name, prep_checked, sample_s_checked, sample_e_checked,
                 ntt_checked, basemul_checked, intt_checked, final_poly_checked);
        $fatal(1);
      end
      check_enc_stage_counters();
      $display("TB INFO: %0s top-level command completed in %0d cycles", name, cmd_cycles);
    end
  endtask

  task automatic read_buffer_to_mem(input [2:0] buf_sel);
    logic [15:0] got;
    begin
      for (i = 0; i < NTT_N; i++) begin
        host_buf_read(buf_sel, i[8:0], got);
        buf_read_mem[i] = got;
      end
    end
  endtask

  task automatic compare_mem16(
    input [255:0] name,
    input integer mode
  );
    integer mismatch_count;
    logic [15:0] exp;
    begin
      mismatch_count = 0;
      for (i = 0; i < NTT_N; i++) begin
        case (mode)
          0: exp = s_mem[i];
          1: exp = e_mem[i];
          2: exp = hs_intt_mem[i];
          3: exp = final_poly_mem[i];
          4: exp = msg_poly_mem[i];
          default: exp = h_mem[i];
        endcase
        if (buf_read_mem[i] !== exp) begin
          if (mismatch_count < 8) begin
            $display("TB ERROR: %0s mismatch idx=%0d got=%0d exp=%0d", name, i, $signed(buf_read_mem[i]), $signed(exp));
          end
          mismatch_count = mismatch_count + 1;
        end
      end
      if (mismatch_count != 0) begin
        $display("TB DEBUG: ct_pack_row_vec_out[0]=%04x vec_wr_data[0]=%04x stage_vec[0]=%0d e_vec[0]=%0d msg_poly_vec[0]=%0d",
                 dut.u_dut.u_pke_enc_core.ct_pack_row_vec_out[0 +: 16],
                 dut.u_dut.vec_wr_data[0 +: 16],
                 $signed(dut.u_dut.u_pke_enc_core.stage_vec[0 +: 16]),
                 $signed(dut.u_dut.u_pke_enc_core.e_vec[0 +: 16]),
                 $signed(dut.u_dut.u_pke_enc_core.msg_poly_vec[0 +: 16]));
        $display("TB DEBUG: ct_pack_row_vec_out[1]=%04x vec_wr_data[1]=%04x buf_row0_bank0=%04x buf_row0_bank1=%04x",
                 dut.u_dut.u_pke_enc_core.ct_pack_row_vec_out[16 +: 16],
                 dut.u_dut.vec_wr_data[16 +: 16],
                 dut.u_dut.u_buf_mgr.mem[3'd5][0][0],
                 dut.u_dut.u_buf_mgr.mem[3'd5][1][0]);
        $display("TB ERROR: %0s mismatch count=%0d", name, mismatch_count);
        $fatal(1);
      end
    end
  endtask

  task automatic compare_core_vec16(
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
          0: exp_coeff = $signed(h_mem[i]);
          1: exp_coeff = $signed(msg_poly_mem[i]);
          2: exp_coeff = $signed(s_mem[i]);
          3: exp_coeff = $signed(e_mem[i]);
          4: exp_coeff = $signed(s_ntt_mem[i]);
          5: exp_coeff = $signed(hs_basemul_mem[i]);
          default: exp_coeff = $signed(hs_intt_mem[i]);
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
        $fatal(1);
      end
    end
  endtask

  task automatic compare_enc_final_poly(input [255:0] name);
    integer mismatch_count;
    logic signed [15:0] hs_coeff;
    logic signed [15:0] e_coeff;
    logic signed [15:0] msg_coeff;
    logic signed [16:0] accum;
    logic signed [15:0] reduced;
    logic signed [15:0] got_coeff;
    begin
      mismatch_count = 0;
      for (i = 0; i < NTT_N; i++) begin
        hs_coeff = dut.u_dut.u_pke_enc_core.stage_vec[i*COEFF_W +: COEFF_W];
        e_coeff = dut.u_dut.u_pke_enc_core.e_vec[i*COEFF_W +: COEFF_W];
        msg_coeff = dut.u_dut.u_pke_enc_core.msg_poly_vec[i*COEFF_W +: COEFF_W];
        accum = hs_coeff + e_coeff + msg_coeff;
        reduced = montgomery_reduce(accum * 16'sd171);
        got_coeff = reduced + ((reduced >>> 15) & 16'sd769);
        if (got_coeff !== $signed(final_poly_mem[i])) begin
          if (mismatch_count < 8) begin
            $display("TB ERROR: %0s mismatch idx=%0d got=%0d exp=%0d",
                     name, i, got_coeff, $signed(final_poly_mem[i]));
          end
          mismatch_count = mismatch_count + 1;
        end
      end
      if (mismatch_count != 0) begin
        $display("TB ERROR: %0s mismatch count=%0d", name, mismatch_count);
        $fatal(1);
      end
    end
  endtask

  task automatic compare_ct_pack_row(
    input [255:0] name,
    input integer row_idx
  );
    integer mismatch_count;
    integer lane_idx;
    integer coeff_idx;
    logic [15:0] got_word;
    logic [15:0] exp_word;
    begin
      mismatch_count = 0;
      for (lane_idx = 0; lane_idx < dut.u_dut.BUF_BANKS; lane_idx++) begin
        coeff_idx = row_idx * dut.u_dut.BUF_BANKS + lane_idx;
        got_word = dut.u_dut.vec_wr_data[lane_idx*COEFF_W +: COEFF_W];
        if (coeff_idx < NTT_N) begin
          exp_word = {8'h00, ct_packed_mem[coeff_idx]};
        end else begin
          exp_word = 16'd0;
        end
        if (got_word !== exp_word) begin
          if (mismatch_count < 8) begin
            $display("TB ERROR: %0s row=%0d lane=%0d got=%04x exp=%04x",
                     name, row_idx, lane_idx, got_word, exp_word);
          end
          mismatch_count = mismatch_count + 1;
        end
      end
      if (mismatch_count != 0) begin
        $display("TB ERROR: %0s mismatch count=%0d", name, mismatch_count);
        $fatal(1);
      end
    end
  endtask

  task automatic check_enc_stage_counters;
    begin
      // Synced mainline RTL no longer exposes legacy dbg_stage_enter/exit counters.
    end
  endtask

  task automatic compare_ct_packed(
    input [255:0] name
  );
    integer mismatch_count;
    begin
      mismatch_count = 0;
      for (i = 0; i < NTT_N; i++) begin
        if (buf_read_mem[i][7:0] !== ct_packed_mem[i]) begin
          if (mismatch_count < 8) begin
            $display("TB ERROR: %0s mismatch idx=%0d got=%02x exp=%02x",
                     name, i, buf_read_mem[i][7:0], ct_packed_mem[i]);
          end
          mismatch_count = mismatch_count + 1;
        end
      end
      if (mismatch_count != 0) begin
        $display("TB DEBUG: pke_enc_vec_wr_en=%0b vec_wr_en=%0b pke_enc_vec_wr_row=%0d vec_wr_row=%0d",
                 dut.u_dut.pke_enc_vec_wr_en,
                 dut.u_dut.vec_wr_en,
                 dut.u_dut.pke_enc_vec_wr_row,
                 dut.u_dut.vec_wr_row);
        $display("TB DEBUG: launch_bufs a=%0d b=%0d r=%0d",
                 dut.u_dut.launch_buf_a_sel,
                 dut.u_dut.launch_buf_b_sel,
                 dut.u_dut.launch_buf_r_sel);
        $display("TB DEBUG: pke_enc_vec_wr_data[0]=%04x vec_wr_data[0]=%04x ct_pack_row_vec_out[0]=%04x wr_row=%0d",
                 dut.u_dut.pke_enc_vec_wr_data[0 +: 16],
                 dut.u_dut.vec_wr_data[0 +: 16],
                 dut.u_dut.u_pke_enc_core.ct_pack_row_vec_out[0 +: 16],
                 dut.u_dut.u_pke_enc_core.wr_row);
        $display("TB DEBUG: pk_packed_vec[0]=%04x msg_bytes_vec[0]=%04x h_vec[0]=%0d msg_poly_vec[0]=%0d",
                 dut.u_dut.u_pke_enc_core.pk_packed_vec[0 +: 16],
                 dut.u_dut.u_pke_enc_core.msg_bytes_vec[0 +: 16],
                 $signed(dut.u_dut.u_pke_enc_core.h_vec[0 +: 16]),
                 $signed(dut.u_dut.u_pke_enc_core.msg_poly_vec[0 +: 16]));
        $display("TB DEBUG: s_vec[0]=%0d e_vec[0]=%0d stage_vec[0]=%0d ct_pack_row_vec_out[1]=%04x",
                 $signed(dut.u_dut.u_pke_enc_core.s_vec[0 +: 16]),
                 $signed(dut.u_dut.u_pke_enc_core.e_vec[0 +: 16]),
                 $signed(dut.u_dut.u_pke_enc_core.stage_vec[0 +: 16]),
                 dut.u_dut.u_pke_enc_core.ct_pack_row_vec_out[16 +: 16]);
        $display("TB DEBUG: buf5_row0_bank0=%04x buf5_row0_bank1=%04x buf5_row0_bank2=%04x buf5_row0_bank3=%04x",
                 dut.u_dut.u_buf_mgr.mem[3'd5][0][0],
                 dut.u_dut.u_buf_mgr.mem[3'd5][1][0],
                 dut.u_dut.u_buf_mgr.mem[3'd5][2][0],
                 dut.u_dut.u_buf_mgr.mem[3'd5][3][0]);
        $display("TB ERROR: %0s mismatch count=%0d", name, mismatch_count);
        $fatal(1);
      end
    end
  endtask

  initial begin
    $readmemh("testdata/enc_h.mem", h_mem);
    $readmemh("testdata/enc_pk_packed.mem", pk_packed_mem);
    $readmemh("testdata/enc_seed.mem", seed_mem);
    $readmemh("testdata/enc_s.mem", s_mem);
    $readmemh("testdata/enc_e.mem", e_mem);
    $readmemh("testdata/enc_s_ntt.mem", s_ntt_mem);
    $readmemh("testdata/enc_hs_basemul.mem", hs_basemul_mem);
    $readmemh("testdata/enc_hs_intt.mem", hs_intt_mem);
    $readmemh("testdata/enc_msg.mem", msg_mem);
    $readmemh("testdata/enc_msg_poly.mem", msg_poly_mem);
    $readmemh("testdata/enc_final_poly.mem", final_poly_mem);
    $readmemh("testdata/enc_ct_packed.mem", ct_packed_mem);

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
      if ((2*i + 1) < 615) begin
        dut.u_dut.u_buf_mgr.mem[3'd0][i % dut.u_dut.BUF_BANKS][i / dut.u_dut.BUF_BANKS] =
          {pk_packed_mem[2*i + 1], pk_packed_mem[2*i]};
      end else if ((2*i) < 615) begin
        dut.u_dut.u_buf_mgr.mem[3'd0][i % dut.u_dut.BUF_BANKS][i / dut.u_dut.BUF_BANKS] =
          {8'h00, pk_packed_mem[2*i]};
      end else begin
        dut.u_dut.u_buf_mgr.mem[3'd0][i % dut.u_dut.BUF_BANKS][i / dut.u_dut.BUF_BANKS] = 16'd0;
      end
      dut.u_dut.u_buf_mgr.mem[3'd4][i % dut.u_dut.BUF_BANKS][i / dut.u_dut.BUF_BANKS] =
        (i < 16) ? {8'h00, msg_mem[i]} : 16'd0;
      dut.u_dut.u_buf_mgr.mem[3'd5][i % dut.u_dut.BUF_BANKS][i / dut.u_dut.BUF_BANKS] = 16'd0;
    end

    for (i = 0; i < 64; i++) begin
      dut.u_dut.u_seedbuf_mgr.mem[RAW_SEED_BASE + i] = seed_mem[i];
    end

    launch_cmd("PKE_ENC", 8'h91, 32'h8000_0000 | RAW_SEED_BASE, 32'd512, 3'd0, 3'd4, 3'd5);
    fused_cmd_cycles = last_cmd_cycles;
    @(posedge clk);
    #1;
    read_buffer_to_mem(3'd5);
    compare_ct_packed("PKE_ENC_CTPACK");
    $display("TB INFO: PKE_ENC fused command matched packed ciphertext reference");
    $display("TB INFO: PKE_ENC fused command cycles = %0d", fused_cmd_cycles);
    $display("TB PASS: zen_accel_top PKE enc path passed");
    $finish(0);
  end

endmodule
