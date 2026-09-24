module zen_resident_buf_fabric (
  input  logic        job_terminal_i,
  input  logic [7:0]  job_cmd_raw_i,
  input  logic [3:0]  input0_slot_i,
  input  logic [3:0]  input1_slot_i,
  input  logic [3:0]  input2_slot_i,
  input  logic [3:0]  output0_slot_i,
  input  logic [3:0]  output1_slot_i,

  input  logic        host_access_lock_i,
  input  logic        sampler_seed_active_i,

  input  logic        host_buf_wr_en_i,
  input  logic [2:0]  host_buf_sel_i,
  input  logic [zen_accel_pkg::ADDR_W-1:0] host_buf_addr_i,
  input  logic [15:0] host_buf_wdata_i,
  input  logic [2:0]  host_buf_rd_sel_i,
  input  logic [zen_accel_pkg::ADDR_W-1:0] host_buf_rd_addr_i,
  input  logic [15:0] buf_rd_data_i,

  input  logic        host_seed_wr_en_i,
  input  logic [zen_accel_pkg::SEEDBUF_ADDR_W-1:0] host_seed_addr_i,
  input  logic [7:0]  host_seed_wdata_i,
  input  logic [zen_accel_pkg::SEEDBUF_ADDR_W-1:0] host_seed_rd_addr_i,
  input  logic [zen_accel_pkg::SEEDBUF_ADDR_W-1:0] sampler_seed_rd_addr_i,
  input  logic [7:0]  seedbuf_rd_data_i,

  output logic        terminal_slots_ok_o,
  output logic [2:0]  term_buf_a_sel_o,
  output logic [2:0]  term_buf_b_sel_o,
  output logic [2:0]  term_buf_r_sel_o,

  output logic        buf_wr_en_o,
  output logic [2:0]  buf_wr_sel_o,
  output logic [zen_accel_pkg::ADDR_W-1:0] buf_wr_addr_o,
  output logic [15:0] buf_wr_data_o,
  output logic [2:0]  buf_rd_sel_o,
  output logic [zen_accel_pkg::ADDR_W-1:0] buf_rd_addr_o,
  output logic [15:0] host_buf_rdata_o,

  output logic        seed_wr_en_o,
  output logic [zen_accel_pkg::SEEDBUF_ADDR_W-1:0] seed_wr_addr_o,
  output logic [7:0]  seed_wr_data_o,
  output logic [zen_accel_pkg::SEEDBUF_ADDR_W-1:0] seed_rd_addr_o,
  output logic [7:0]  host_seed_rdata_o
);

  import zen_accel_pkg::*;

  always_comb begin
    terminal_slots_ok_o = 1'b1;
    term_buf_a_sel_o = 3'd0;
    term_buf_b_sel_o = 3'd0;
    term_buf_r_sel_o = 3'd0;

    if (job_terminal_i) begin
      unique case (job_cmd_raw_i)
        CMD_RUN_PKE_KEYGEN: begin
          terminal_slots_ok_o =
              (input0_slot_i == SLOT_SEED_IN) &&
              (input1_slot_i == SLOT_NONE) &&
              (input2_slot_i == SLOT_NONE) &&
              (output0_slot_i == SLOT_PK_OUT) &&
              (output1_slot_i == SLOT_SK_OUT);
          term_buf_a_sel_o = 3'd0;
          term_buf_b_sel_o = 3'd1;
          term_buf_r_sel_o = 3'd5;
        end
        CMD_RUN_PKE_ENC: begin
          terminal_slots_ok_o =
              (input0_slot_i == SLOT_PK_IN) &&
              (input1_slot_i == SLOT_MSG_IN) &&
              (input2_slot_i == SLOT_SEED_IN) &&
              (output0_slot_i == SLOT_CT_OUT) &&
              (output1_slot_i == SLOT_NONE);
          term_buf_a_sel_o = 3'd0;
          term_buf_b_sel_o = 3'd4;
          term_buf_r_sel_o = 3'd5;
        end
        CMD_RUN_PKE_DEC: begin
          terminal_slots_ok_o =
              (input0_slot_i == SLOT_CT_IN) &&
              (input1_slot_i == SLOT_SK_IN) &&
              (input2_slot_i == SLOT_NONE) &&
              (output0_slot_i == SLOT_MSG_OUT) &&
              (output1_slot_i == SLOT_NONE);
          term_buf_a_sel_o = 3'd0;
          term_buf_b_sel_o = 3'd1;
          term_buf_r_sel_o = 3'd2;
        end
        default: begin
          terminal_slots_ok_o = 1'b0;
          term_buf_a_sel_o = 3'd0;
          term_buf_b_sel_o = 3'd0;
          term_buf_r_sel_o = 3'd0;
        end
      endcase
    end

    buf_wr_en_o = host_buf_wr_en_i && !host_access_lock_i;
    buf_wr_sel_o = host_access_lock_i ? 3'd0 : host_buf_sel_i;
    buf_wr_addr_o = host_access_lock_i ? '0 : host_buf_addr_i;
    buf_wr_data_o = host_access_lock_i ? 16'h0 : host_buf_wdata_i;
    buf_rd_sel_o = host_access_lock_i ? 3'd0 : host_buf_rd_sel_i;
    buf_rd_addr_o = host_access_lock_i ? '0 : host_buf_rd_addr_i;
    host_buf_rdata_o = host_access_lock_i ? 16'h0 : buf_rd_data_i;

    seed_wr_en_o = host_seed_wr_en_i && !host_access_lock_i;
    seed_wr_addr_o = host_seed_addr_i;
    seed_wr_data_o = host_seed_wdata_i;
    host_seed_rdata_o = 8'h00;

    if (sampler_seed_active_i) begin
      seed_rd_addr_o = sampler_seed_rd_addr_i;
    end else if (host_access_lock_i) begin
      seed_rd_addr_o = '0;
    end else begin
      seed_rd_addr_o = host_seed_rd_addr_i;
      host_seed_rdata_o = seedbuf_rd_data_i;
    end
  end

endmodule
