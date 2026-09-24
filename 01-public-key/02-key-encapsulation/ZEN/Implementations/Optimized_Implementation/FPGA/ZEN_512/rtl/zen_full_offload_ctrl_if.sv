module zen_full_offload_ctrl_if (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        wr_en,
  input  logic [15:0] wr_addr,
  input  logic [31:0] wr_data,
  input  logic        rd_en,
  input  logic [15:0] rd_addr,
  output logic [31:0] rd_data,

  output logic        start_pulse,
  output logic [7:0]  cmd,
  output logic [31:0] cfg,
  output logic [31:0] len,
  output logic [2:0]  buf_a_sel,
  output logic [2:0]  buf_b_sel,
  output logic [2:0]  buf_r_sel,
  output logic        host_buf_wr_en,
  output logic [2:0]  host_buf_sel,
  output logic [zen_accel_pkg::ADDR_W-1:0] host_buf_addr,
  output logic [15:0] host_buf_wdata,
  output logic [2:0]  host_buf_rd_sel,
  output logic [zen_accel_pkg::ADDR_W-1:0] host_buf_rd_addr,
  input  logic [15:0] host_buf_rdata,
  output logic        host_seed_wr_en,
  output logic [zen_accel_pkg::SEEDBUF_ADDR_W-1:0] host_seed_addr,
  output logic [7:0]  host_seed_wdata,
  output logic [zen_accel_pkg::SEEDBUF_ADDR_W-1:0] host_seed_rd_addr,
  input  logic [7:0]  host_seed_rdata,

  input  logic        core_busy,
  input  logic        core_done,
  input  logic        core_error,
  input  logic        host_access_lock,
  input  logic        terminal_slots_ok_i,

  input  logic [7:0]  job_errcode_i,
  input  logic [31:0] out_bytes0_i,
  input  logic [31:0] out_bytes1_i,

  output logic [7:0]  job_cmd_raw_o,
  output logic [1:0]  param_set_o,
  output logic [3:0]  input0_slot_o,
  output logic [3:0]  input1_slot_o,
  output logic [3:0]  input2_slot_o,
  output logic [3:0]  output0_slot_o,
  output logic [3:0]  output1_slot_o,
  output logic [31:0] job_cfg_o
);

  import zen_accel_pkg::*;

  localparam logic [7:0] ERR_NONE               = 8'h00;
  localparam logic [7:0] ERR_PARAM_SET_MISMATCH = 8'h01;
  localparam logic [7:0] ERR_SLOT_SET_MISMATCH  = 8'h02;
  localparam logic [7:0] ERR_INVALID_PROFILE    = 8'h03;
  localparam logic [7:0] ERR_UNSUPPORTED_PROFILE = 8'h04;

  localparam logic [1:0] CURRENT_PARAM_SET =
      (zen_swift_profile_pkg::SWIFT_SECURITY == 512) ? 2'd2 :
      ((zen_swift_profile_pkg::SWIFT_SECURITY == 256) ? 2'd1 : 2'd0);

  logic ctrl_start_d;
  logic [31:0] ctrl_reg;
  logic [31:0] status_reg;
  logic [7:0]  cmd_raw_reg;
  logic [31:0] cfg_raw_reg;
  logic [31:0] len_raw_reg;
  logic [2:0]  buf_a_sel_raw_reg;
  logic [2:0]  buf_b_sel_raw_reg;
  logic [2:0]  buf_r_sel_raw_reg;
  logic [1:0]  param_set_reg;
  logic [3:0]  input0_slot_reg;
  logic [3:0]  input1_slot_reg;
  logic [3:0]  input2_slot_reg;
  logic [3:0]  output0_slot_reg;
  logic [3:0]  output1_slot_reg;
  logic [31:0] task_job_cfg_reg;
  logic [7:0]  task_errcode_reg;
  logic [31:0] task_out_bytes0_reg;
  logic [31:0] task_out_bytes1_reg;
  logic [2:0]  host_buf_sel_reg;
  logic [ADDR_W-1:0] host_buf_addr_reg;
  logic [15:0] host_buf_wdata_reg;
  logic [15:0] host_buf_rdata_reg;
  logic [SEEDBUF_ADDR_W-1:0] host_seed_addr_reg;
  logic [7:0]  host_seed_wdata_reg;
  logic [7:0]  host_seed_rdata_reg;
  logic blocked_host_buf_write;
  logic blocked_host_buf_read;
  logic blocked_host_seed_write;
  logic blocked_host_seed_read;
  logic blocked_profile_write;
  logic [1:0] host_profile_id;
  logic [31:0] host_buf_limit;
  logic [31:0] host_seed_limit;
  logic host_buf_sel_valid;
  logic host_buf_addr_valid;
  logic host_seed_addr_valid;
  logic task_param_mismatch;
  logic task_profile_invalid;
  logic task_profile_unsupported;
  logic start_req;
  logic terminal_task_cmd;

  function automatic logic is_terminal_task_cmd(input logic [7:0] cmd_word);
    begin
      is_terminal_task_cmd = (cmd_word == CMD_RUN_PKE_KEYGEN) ||
                             (cmd_word == CMD_RUN_PKE_ENC) ||
                             (cmd_word == CMD_RUN_PKE_DEC);
    end
  endfunction

  function automatic logic [7:0] map_terminal_cmd(input logic [7:0] cmd_word);
    begin
      unique case (cmd_word)
        CMD_RUN_PKE_KEYGEN: map_terminal_cmd = CMD_PKE_KEYGEN;
        CMD_RUN_PKE_ENC:    map_terminal_cmd = CMD_PKE_ENC;
        CMD_RUN_PKE_DEC:    map_terminal_cmd = CMD_PKE_DEC;
        default:            map_terminal_cmd = cmd_word;
      endcase
    end
  endfunction

  function automatic logic [31:0] task_cfg_default(input logic [7:0] cmd_word);
    begin
      unique case (cmd_word)
        CMD_RUN_PKE_KEYGEN,
        CMD_RUN_PKE_ENC: task_cfg_default = 32'h8000_0000;
        CMD_RUN_PKE_DEC: task_cfg_default = 32'h8000_0005;
        default:         task_cfg_default = 32'h0;
      endcase
    end
  endfunction

  function automatic logic [31:0] task_cfg_effective(
    input logic [7:0]  cmd_word,
    input logic [31:0] task_cfg_word
  );
    begin
      if (task_cfg_word != 32'h0) begin
        task_cfg_effective = task_cfg_word;
      end else begin
        task_cfg_effective = task_cfg_default(cmd_word);
      end
    end
  endfunction

  function automatic logic [31:0] task_len_default(
    input logic [7:0] cmd_word,
    input logic [1:0] profile_id
  );
    begin
      if (is_terminal_task_cmd(cmd_word)) begin
        task_len_default = profile_n(profile_id);
      end else begin
        task_len_default = 32'h0;
      end
    end
  endfunction

  function automatic logic [2:0] task_buf_a_default(input logic [7:0] cmd_word);
    begin
      unique case (cmd_word)
        CMD_RUN_PKE_KEYGEN: task_buf_a_default = 3'd0;
        CMD_RUN_PKE_ENC:    task_buf_a_default = 3'd0;
        CMD_RUN_PKE_DEC:    task_buf_a_default = 3'd0;
        default:            task_buf_a_default = 3'd0;
      endcase
    end
  endfunction

  function automatic logic [2:0] task_buf_b_default(input logic [7:0] cmd_word);
    begin
      unique case (cmd_word)
        CMD_RUN_PKE_KEYGEN: task_buf_b_default = 3'd1;
        CMD_RUN_PKE_ENC:    task_buf_b_default = 3'd4;
        CMD_RUN_PKE_DEC:    task_buf_b_default = 3'd1;
        default:            task_buf_b_default = 3'd0;
      endcase
    end
  endfunction

  function automatic logic [2:0] task_buf_r_default(input logic [7:0] cmd_word);
    begin
      unique case (cmd_word)
        CMD_RUN_PKE_KEYGEN: task_buf_r_default = 3'd5;
        CMD_RUN_PKE_ENC:    task_buf_r_default = 3'd5;
        CMD_RUN_PKE_DEC:    task_buf_r_default = 3'd2;
        default:            task_buf_r_default = 3'd0;
      endcase
    end
  endfunction

  function automatic logic [31:0] task_out_bytes0_default(
    input logic [7:0] cmd_word,
    input logic [1:0] profile_id
  );
    begin
      unique case (cmd_word)
        CMD_RUN_PKE_KEYGEN: task_out_bytes0_default = profile_pk_pack_bytes(profile_id);
        CMD_RUN_PKE_ENC:    task_out_bytes0_default = profile_ct_pack_bytes(profile_id);
        CMD_RUN_PKE_DEC:    task_out_bytes0_default = profile_msg_bytes(profile_id);
        default:            task_out_bytes0_default = 32'h0;
      endcase
    end
  endfunction

  function automatic logic [31:0] task_out_bytes1_default(
    input logic [7:0] cmd_word,
    input logic [1:0] profile_id
  );
    begin
      unique case (cmd_word)
        CMD_RUN_PKE_KEYGEN: task_out_bytes1_default = profile_sk_pack_bytes(profile_id);
        default: task_out_bytes1_default = 32'h0;
      endcase
    end
  endfunction

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      ctrl_reg <= '0;
      status_reg <= '0;
      cmd_raw_reg <= '0;
      cfg_raw_reg <= '0;
      len_raw_reg <= '0;
      buf_a_sel_raw_reg <= '0;
      buf_b_sel_raw_reg <= '0;
      buf_r_sel_raw_reg <= '0;
      param_set_reg <= CURRENT_PARAM_SET;
      input0_slot_reg <= '0;
      input1_slot_reg <= '0;
      input2_slot_reg <= '0;
      output0_slot_reg <= '0;
      output1_slot_reg <= '0;
      task_job_cfg_reg <= '0;
      task_errcode_reg <= '0;
      task_out_bytes0_reg <= '0;
      task_out_bytes1_reg <= '0;
      host_buf_sel_reg <= '0;
      host_buf_addr_reg <= '0;
      host_buf_wdata_reg <= '0;
      host_buf_rdata_reg <= '0;
      host_seed_addr_reg <= '0;
      host_seed_wdata_reg <= '0;
      host_seed_rdata_reg <= '0;
      ctrl_start_d <= 1'b0;
    end else begin
      ctrl_start_d <= ctrl_reg[0];

      status_reg[0] <= core_busy;
      if (core_done) begin
        status_reg[1] <= 1'b1;
        if (out_bytes0_i != 32'h0) begin
          task_out_bytes0_reg <= out_bytes0_i;
        end
        if (out_bytes1_i != 32'h0) begin
          task_out_bytes1_reg <= out_bytes1_i;
        end
      end
      if (core_error) begin
        status_reg[2] <= 1'b1;
        if (job_errcode_i != ERR_NONE) begin
          task_errcode_reg <= job_errcode_i;
        end
      end
      if (blocked_host_buf_write || blocked_host_buf_read ||
          blocked_host_seed_write || blocked_host_seed_read ||
          blocked_profile_write) begin
        status_reg[3] <= 1'b1;
      end
      host_buf_rdata_reg <= host_buf_rdata;
      host_seed_rdata_reg <= host_seed_rdata;

      if (wr_en) begin
        unique case (wr_addr)
          16'h0000: begin
            ctrl_reg <= wr_data;
            if (wr_data[0]) begin
              status_reg[1] <= 1'b0;
              status_reg[2] <= 1'b0;
              status_reg[3] <= 1'b0;
              task_errcode_reg <= ERR_NONE;
              if (is_terminal_task_cmd(cmd_raw_reg)) begin
                if (task_profile_invalid) begin
                  status_reg[2] <= 1'b1;
                  task_errcode_reg <= ERR_INVALID_PROFILE;
                  task_out_bytes0_reg <= 32'h0;
                  task_out_bytes1_reg <= 32'h0;
                end else if (task_profile_unsupported || task_param_mismatch) begin
                  status_reg[2] <= 1'b1;
                  task_errcode_reg <= ERR_UNSUPPORTED_PROFILE;
                  task_out_bytes0_reg <= 32'h0;
                  task_out_bytes1_reg <= 32'h0;
                end else if (!terminal_slots_ok_i) begin
                  status_reg[2] <= 1'b1;
                  task_errcode_reg <= ERR_SLOT_SET_MISMATCH;
                  task_out_bytes0_reg <= 32'h0;
                  task_out_bytes1_reg <= 32'h0;
                end else begin
                  task_out_bytes0_reg <= task_out_bytes0_default(cmd_raw_reg, param_set_reg);
                  task_out_bytes1_reg <= task_out_bytes1_default(cmd_raw_reg, param_set_reg);
                end
              end else begin
                task_out_bytes0_reg <= 32'h0;
                task_out_bytes1_reg <= 32'h0;
              end
            end
          end
          16'h0008: cmd_raw_reg <= wr_data[7:0];
          16'h000c: cfg_raw_reg <= wr_data;
          16'h0010: len_raw_reg <= wr_data;
          16'h0014: begin
            if (!core_busy) begin
              param_set_reg <= wr_data[1:0];
            end
          end
          16'h0018: input0_slot_reg <= wr_data[3:0];
          16'h001c: input1_slot_reg <= wr_data[3:0];
          16'h0020: buf_a_sel_raw_reg <= wr_data[2:0];
          16'h0024: buf_b_sel_raw_reg <= wr_data[2:0];
          16'h0028: buf_r_sel_raw_reg <= wr_data[2:0];
          16'h002c: input2_slot_reg <= wr_data[3:0];
          16'h0030: output0_slot_reg <= wr_data[3:0];
          16'h0034: output1_slot_reg <= wr_data[3:0];
          16'h0038: task_job_cfg_reg <= wr_data;
          16'h0100: host_buf_sel_reg <= wr_data[2:0];
          16'h0104: host_buf_addr_reg <= wr_data[ADDR_W-1:0];
          16'h0108: host_buf_wdata_reg <= wr_data[15:0];
          16'h0120: host_seed_addr_reg <= wr_data[SEEDBUF_ADDR_W-1:0];
          16'h0124: host_seed_wdata_reg <= wr_data[7:0];
          default: ;
        endcase
      end else if (ctrl_reg[0]) begin
        ctrl_reg[0] <= 1'b0;
      end
    end
  end

  assign terminal_task_cmd = is_terminal_task_cmd(cmd_raw_reg);

  always_comb begin
    host_profile_id = profile_valid(param_set_reg) ? param_set_reg : CURRENT_PROFILE_ID;
    host_buf_limit = profile_n(host_profile_id);
    host_seed_limit = profile_seedbuf_bytes(host_profile_id);
    host_buf_sel_valid = (host_buf_sel_reg < BUF_COUNT);
    host_buf_addr_valid = {{(32-ADDR_W){1'b0}}, host_buf_addr_reg} < host_buf_limit;
    host_seed_addr_valid = {{(32-SEEDBUF_ADDR_W){1'b0}}, host_seed_addr_reg} < host_seed_limit;
    task_profile_invalid = terminal_task_cmd && (param_set_reg == 2'd3);
    task_profile_unsupported = terminal_task_cmd &&
                               !task_profile_invalid &&
                               (profile_n(param_set_reg) > ZEN_N);
    task_param_mismatch = 1'b0;
  end

  always_comb begin
    blocked_host_buf_write = wr_en && (wr_addr == 16'h010C) &&
                             (host_access_lock || !host_buf_sel_valid || !host_buf_addr_valid);
    blocked_host_buf_read = rd_en && (rd_addr == 16'h0110) &&
                            (host_access_lock || !host_buf_sel_valid || !host_buf_addr_valid);
    blocked_host_seed_write = wr_en && (wr_addr == 16'h0128) &&
                              (host_access_lock || !host_seed_addr_valid);
    blocked_host_seed_read = rd_en && (rd_addr == 16'h012C) &&
                             (host_access_lock || !host_seed_addr_valid);
    blocked_profile_write = wr_en && core_busy && (wr_addr == 16'h0014);
  end

  always_comb begin
    start_req = ctrl_reg[0] & ~ctrl_start_d;
    start_pulse = start_req && !task_profile_invalid && !task_profile_unsupported &&
                  (!terminal_task_cmd || terminal_slots_ok_i);
    cmd = terminal_task_cmd ? map_terminal_cmd(cmd_raw_reg) : cmd_raw_reg;
    cfg = terminal_task_cmd ?
          task_cfg_effective(cmd_raw_reg, task_job_cfg_reg) : cfg_raw_reg;
    len = terminal_task_cmd ? task_len_default(cmd_raw_reg, param_set_reg) : len_raw_reg;
    buf_a_sel = terminal_task_cmd ? task_buf_a_default(cmd_raw_reg) : buf_a_sel_raw_reg;
    buf_b_sel = terminal_task_cmd ? task_buf_b_default(cmd_raw_reg) : buf_b_sel_raw_reg;
    buf_r_sel = terminal_task_cmd ? task_buf_r_default(cmd_raw_reg) : buf_r_sel_raw_reg;
    job_cmd_raw_o = cmd_raw_reg;
    param_set_o = param_set_reg;
    input0_slot_o = input0_slot_reg;
    input1_slot_o = input1_slot_reg;
    input2_slot_o = input2_slot_reg;
    output0_slot_o = output0_slot_reg;
    output1_slot_o = output1_slot_reg;
    job_cfg_o = task_job_cfg_reg;
  end

  always_comb begin
    host_buf_wr_en = wr_en && (wr_addr == 16'h010C) && !blocked_host_buf_write;
    host_buf_sel = (host_buf_sel_valid && host_buf_addr_valid) ? host_buf_sel_reg : 3'd0;
    host_buf_addr = host_buf_addr_valid ? host_buf_addr_reg : '0;
    host_buf_wdata = host_buf_wdata_reg;
    host_buf_rd_sel = blocked_host_buf_read ? 3'd0 :
                      ((host_buf_sel_valid && host_buf_addr_valid) ? host_buf_sel_reg : 3'd0);
    host_buf_rd_addr = blocked_host_buf_read ? '0 :
                       (host_buf_addr_valid ? host_buf_addr_reg : '0);
    host_seed_wr_en = wr_en && (wr_addr == 16'h0128) && !blocked_host_seed_write;
    host_seed_addr = host_seed_addr_valid ? host_seed_addr_reg : '0;
    host_seed_wdata = host_seed_wdata_reg;
    host_seed_rd_addr = blocked_host_seed_read ? '0 :
                        (host_seed_addr_valid ? host_seed_addr_reg : '0);
  end

  always_comb begin
    rd_data = 32'h0;
    if (rd_en) begin
      unique case (rd_addr)
        16'h0000: rd_data = ctrl_reg;
        16'h0004: rd_data = status_reg;
        16'h0008: rd_data = {24'h0, cmd_raw_reg};
        16'h000c: rd_data = cfg_raw_reg;
        16'h0010: rd_data = len_raw_reg;
        16'h0014: rd_data = {30'h0, param_set_reg};
        16'h0018: rd_data = {28'h0, input0_slot_reg};
        16'h001c: rd_data = {28'h0, input1_slot_reg};
        16'h0020: rd_data = {29'h0, buf_a_sel_raw_reg};
        16'h0024: rd_data = {29'h0, buf_b_sel_raw_reg};
        16'h0028: rd_data = {29'h0, buf_r_sel_raw_reg};
        16'h002c: rd_data = {28'h0, input2_slot_reg};
        16'h0030: rd_data = {28'h0, output0_slot_reg};
        16'h0034: rd_data = {28'h0, output1_slot_reg};
        16'h0038: rd_data = task_job_cfg_reg;
        16'h003c: rd_data = {24'h0, task_errcode_reg};
        16'h0040: rd_data = task_out_bytes0_reg;
        16'h0044: rd_data = task_out_bytes1_reg;
        16'h0100: rd_data = {29'h0, host_buf_sel_reg};
        16'h0104: rd_data = {{(32-ADDR_W){1'b0}}, host_buf_addr_reg};
        16'h0108: rd_data = {16'h0, host_buf_wdata_reg};
        16'h0110: rd_data = blocked_host_buf_read ? 32'h0 :
                            (host_access_lock ? 32'h0 : {16'h0, host_buf_rdata_reg});
        16'h0120: rd_data = {{(32-SEEDBUF_ADDR_W){1'b0}}, host_seed_addr_reg};
        16'h0124: rd_data = {24'h0, host_seed_wdata_reg};
        16'h012C: rd_data = blocked_host_seed_read ? 32'h0 :
                            (host_access_lock ? 32'h0 : {24'h0, host_seed_rdata_reg});
        default: rd_data = 32'h0;
      endcase
    end
  end

endmodule
