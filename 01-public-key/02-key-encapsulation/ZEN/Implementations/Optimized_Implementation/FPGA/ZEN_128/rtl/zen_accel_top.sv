module zen_accel_top (
  input  logic        clk,
  input  logic        rst_n,

  input  logic        wr_en,
  input  logic [15:0] wr_addr,
  input  logic [31:0] wr_data,
  input  logic        rd_en,
  input  logic [15:0] rd_addr,
  output logic [31:0] rd_data,

  output logic        busy,
  output logic        done,
  output logic        error,
  output logic        irq
);

  import zen_accel_pkg::*;
  localparam int BUF_BANKS = zen_accel_pkg::BUF_BANKS;
  localparam int NTT_BFLY_LANES = zen_accel_pkg::NTT_BFLY_LANES;
  localparam int BASEMUL_LANES = zen_accel_pkg::BASEMUL_LANES;
  localparam int BASEINV_LANES = zen_accel_pkg::BASEINV_LANES;
  localparam int BINARY_LANES = zen_accel_pkg::BINARY_LANES;
  localparam int SAMPLE_COEFF_LANES = zen_accel_pkg::SAMPLE_COEFF_LANES;

  logic        start;
  logic [7:0]  cmd;
  logic [31:0] cfg;
  logic [31:0] len;
  logic [2:0]  buf_a_sel;
  logic [2:0]  buf_b_sel;
  logic [2:0]  buf_r_sel;

  core_sel_t active_core;

  logic [31:0] ctrl_rd_data;
  logic        host_buf_wr_en;
  logic [2:0]  host_buf_sel;
  logic [ADDR_W-1:0] host_buf_addr;
  logic [COEFF_W-1:0] host_buf_wdata;
  logic [2:0]  host_buf_rd_sel;
  logic [ADDR_W-1:0] host_buf_rd_addr;
  logic [COEFF_W-1:0] host_buf_rdata;
  logic        host_seed_wr_en;
  logic [SEEDBUF_ADDR_W-1:0] host_seed_addr;
  logic [7:0]  host_seed_wdata;
  logic [SEEDBUF_ADDR_W-1:0] host_seed_rd_addr;
  logic [7:0]  host_seed_rdata;
  logic [SEEDBUF_ADDR_W-1:0] sampler_seed_rd_addr;
  logic [SEEDBUF_ADDR_W-1:0] seedbuf_rd_addr;
  logic [7:0]  seedbuf_rd_data;
  logic        host_access_lock;
  logic        sampler_seed_active;
  logic [7:0]  task_cmd_raw;
  logic [3:0]  task_input0_slot;
  logic [3:0]  task_input1_slot;
  logic [3:0]  task_input2_slot;
  logic [3:0]  task_output0_slot;
  logic [3:0]  task_output1_slot;
  logic [31:0] task_job_cfg;
  logic        terminal_slots_ok;
  logic [2:0]  term_buf_a_sel;
  logic [2:0]  term_buf_b_sel;
  logic [2:0]  term_buf_r_sel;
  logic [2:0]  launch_buf_a_sel;
  logic [2:0]  launch_buf_b_sel;
  logic [2:0]  launch_buf_r_sel;
  logic        resident_buf_wr_en;
  logic [2:0]  resident_buf_wr_sel;
  logic [ADDR_W-1:0] resident_buf_wr_addr;
  logic [COEFF_W-1:0] resident_buf_wr_data;
  logic [2:0]  resident_buf_rd_sel;
  logic [ADDR_W-1:0] resident_buf_rd_addr;
  logic        resident_seed_wr_en;
  logic [SEEDBUF_ADDR_W-1:0] resident_seed_wr_addr;
  logic [7:0]  resident_seed_wr_data;
  logic signed [ZEN_N*COEFF_W-1:0] pk_unpack_pk_poly_vec_out;
  logic pk_unpack_core_busy;
  logic pk_unpack_core_done;
  logic [31:0] pk_unpack_bytes_consumed;

  logic ntt_start;
  logic basemul_start;
  logic baseinv_start;
  logic binary_start;
  logic sampler_start;

  logic ntt_busy, ntt_done, ntt_error;
  logic basemul_busy, basemul_done, basemul_error;
  logic baseinv_busy, baseinv_done, baseinv_error;
  logic binary_busy, binary_done, binary_error;
  logic sampler_busy, sampler_done, sampler_error;

  logic                buf_wr_en;
  logic [2:0]          buf_wr_sel;
  logic [ADDR_W-1:0]   buf_wr_addr;
  logic [COEFF_W-1:0]  buf_wr_data;
  logic [2:0]          buf_rd0_sel;
  logic [ADDR_W-1:0]   buf_rd0_addr;
  logic [COEFF_W-1:0]  buf_rd0_data;
  logic [2:0]          buf_rd1_sel;
  logic [ADDR_W-1:0]   buf_rd1_addr;
  logic [COEFF_W-1:0]  buf_rd1_data;
  logic [2:0]          vec_rd0_buf_sel;
  logic [BUF_BANKS*COEFF_W-1:0] vec_rd0_row_data;
  logic [2:0]          vec_rd1_buf_sel;
  logic [BUF_BANKS*COEFF_W-1:0] vec_rd1_row_data;
  logic [ADDR_W-1:0]   vec_rd_row;
  logic                vec_wr_en;
  logic [2:0]          vec_wr_buf_sel;
  logic [ADDR_W-1:0]   vec_wr_row;
  logic [BUF_BANKS*COEFF_W-1:0] vec_wr_data;
  localparam int TOP_BANK_DEPTH = BANK_DEPTH;

  typedef enum logic [2:0] {
    ARITH_IDLE,
    ARITH_PREFETCH,
    ARITH_LAUNCH,
    ARITH_WAIT,
    ARITH_WRITEBACK
  } arith_state_t;

  typedef enum logic [2:0] {
    PK_UNPACK_IDLE,
    PK_UNPACK_PREFETCH,
    PK_UNPACK_PREP,
    PK_UNPACK_WAIT,
    PK_UNPACK_WRITEBACK
  } pk_unpack_state_t;

  typedef enum logic [1:0] {
    CTRL_ROUTE_LOCAL,
    CTRL_ROUTE_PKE_ENC,
    CTRL_ROUTE_PKE_KEYGEN,
    CTRL_ROUTE_PKE_DEC
  } ctrl_route_src_t;

  typedef enum logic [3:0] {
    STATUS_ROUTE_NONE,
    STATUS_ROUTE_INVALID,
    STATUS_ROUTE_PKE_KEYGEN,
    STATUS_ROUTE_PKE_ENC,
    STATUS_ROUTE_PKE_DEC,
    STATUS_ROUTE_PK_UNPACK,
    STATUS_ROUTE_ARITH,
    STATUS_ROUTE_SAMPLE,
    STATUS_ROUTE_IDLE_SAMPLER
  } status_route_src_t;

  arith_state_t arith_state, arith_state_n;
  arith_state_t sample_state, sample_state_n;
  pk_unpack_state_t pk_unpack_state, pk_unpack_state_n;
  ctrl_route_src_t ctrl_route_src;
  status_route_src_t status_route_src;

  logic        arith_start;
  logic        arith_busy_i;
  logic        arith_done_i;
  logic        arith_error_i;
  core_sel_t   arith_core;
  logic [7:0]  job_cmd;
  logic [31:0] job_cfg;
  logic [31:0] job_len;
  logic [2:0]  job_buf_a_sel;
  logic [2:0]  job_buf_b_sel;
  logic [2:0]  job_buf_r_sel;
  logic [7:0]  arith_cmd;
  logic [7:0]  arith_cmd_d;
  logic [31:0] arith_cfg;
  logic [31:0] arith_len;
  logic [2:0]  arith_buf_a_sel;
  logic [2:0]  arith_buf_b_sel;
  logic [2:0]  arith_buf_r_sel;
  logic        vec_in_valid;
  logic        vec_in_valid_d;
  logic signed [ZEN_N*COEFF_W-1:0] vec_in_a;
  logic signed [ZEN_N*COEFF_W-1:0] vec_in_b;
  logic signed [ZEN_N*COEFF_W-1:0] vec_in_a_d;
  logic signed [ZEN_N*COEFF_W-1:0] vec_in_b_d;
  logic signed [ZEN_N*COEFF_W-1:0] vec_in_a_reg;
  logic signed [ZEN_N*COEFF_W-1:0] vec_in_b_reg;
  logic signed [ZEN_N*COEFF_W-1:0] ntt_vec_out;
  logic signed [ZEN_N*COEFF_W-1:0] basemul_vec_out;
  logic signed [ZEN_N*COEFF_W-1:0] baseinv_vec_out;
  logic signed [ZEN_N*COEFF_W-1:0] binary_vec_out;
  logic ntt_vec_out_valid;
  logic basemul_vec_out_valid;
  logic baseinv_vec_out_valid;
  logic binary_vec_out_valid;
  logic basemul_row_out_valid;
  logic [ADDR_W-1:0] basemul_row_out_idx;
  logic signed [(16*COEFF_W)-1:0] basemul_row_out_data;
  logic baseinv_row_out_valid;
  logic [ADDR_W-1:0] baseinv_row_out_idx;
  logic signed [(16*COEFF_W)-1:0] baseinv_row_out_data;
  logic binary_row_out_valid;
  logic [ADDR_W-1:0] binary_row_out_idx;
  logic signed [(16*COEFF_W)-1:0] binary_row_out_data;
  logic core_done_sel;
  logic core_error_sel;
  logic core_vec_valid_sel;
  logic signed [ZEN_N*COEFF_W-1:0] writeback_vec;
  logic [ADDR_W-1:0] arith_wr_row;
  logic ntt_core_start;
  logic basemul_core_start;
  logic baseinv_core_start;
  logic binary_core_start;
  logic sampler_core_start;
  logic ntt_core_start_d;
  logic basemul_core_start_d;
  logic baseinv_core_start_d;
  logic binary_core_start_d;
  logic sampler_core_start_d;
  logic sample_start_i;
  logic sample_busy_i;
  logic sample_done_i;
  logic sample_error_i;
  logic pke_dec_start_i;
  logic pke_dec_busy_i;
  logic pke_dec_done_i;
  logic pke_dec_error_i;
  logic [7:0] pke_dec_errcode_i;
  logic [31:0] pke_dec_out_bytes0_i;
  logic [31:0] pke_dec_out_bytes1_i;
  logic pke_enc_start_i;
  logic pke_enc_busy_i;
  logic pke_enc_done_i;
  logic pke_enc_error_i;
  logic [7:0] pke_enc_errcode_i;
  logic [31:0] pke_enc_out_bytes0_i;
  logic [31:0] pke_enc_out_bytes1_i;
  logic pke_enc_route_active;
  logic pke_keygen_start_i;
  logic pke_keygen_busy_i;
  logic pke_keygen_done_i;
  logic pke_keygen_error_i;
  logic [7:0] pke_keygen_errcode_i;
  logic [31:0] pke_keygen_out_bytes0_i;
  logic [31:0] pke_keygen_out_bytes1_i;
  logic pke_keygen_route_active;
  logic pk_unpack_start_i;
  logic pk_unpack_busy_i;
  logic pk_unpack_done_i;
  logic pk_unpack_error_i;
  logic pke_dec_route_active;
  logic terminal_job_active;
  logic [7:0] terminal_job_cmd_raw_reg;
  logic [ADDR_W-1:0] active_writeback_last_row;
  logic [7:0] job_errcode_ctrl;

  logic [31:0] active_writeback_rows;
  localparam int ACTIVE_WRITEBACK_ROWS_CONST = ZEN_N / BUF_BANKS;
  localparam int ACTIVE_WRITEBACK_LAST_ROW_CONST = ACTIVE_WRITEBACK_ROWS_CONST - 1;
  assign active_writeback_rows = ACTIVE_WRITEBACK_ROWS_CONST;
  assign active_writeback_last_row = ADDR_W'(ACTIVE_WRITEBACK_LAST_ROW_CONST);
  logic [31:0] out_bytes0_ctrl;
  logic [31:0] out_bytes1_ctrl;
  logic        pke_enc_sampler_seed_active;
  logic        pke_enc_prefetch_active;
  logic [2:0]  pke_enc_vec_rd0_buf_sel;
  logic [2:0]  pke_enc_vec_rd1_buf_sel;
  logic [ADDR_W-1:0] pke_enc_vec_rd_row;
  logic        pke_enc_sampler_start;
  logic [7:0]  pke_enc_sample_cmd;
  logic [31:0] pke_enc_sample_cfg;
  logic [31:0] pke_enc_sample_len;
  logic [2:0]  pke_enc_sample_buf_r_sel;
  logic        pke_enc_ntt_start;
  logic        pke_enc_basemul_start;
  logic [7:0]  pke_enc_arith_cmd;
  logic        pke_enc_vec_in_valid;
  logic signed [ZEN_N*COEFF_W-1:0] pke_enc_vec_in_a;
  logic signed [ZEN_N*COEFF_W-1:0] pke_enc_vec_in_b;
  logic        pke_enc_vec_wr_en;
  logic [2:0]  pke_enc_vec_wr_buf_sel;
  logic [ADDR_W-1:0] pke_enc_vec_wr_row;
  logic [BUF_BANKS*COEFF_W-1:0] pke_enc_vec_wr_data;
  logic        pke_keygen_sampler_seed_active;
  logic        pke_keygen_sampler_start;
  logic [7:0]  pke_keygen_sample_cmd;
  logic [31:0] pke_keygen_sample_cfg;
  logic [31:0] pke_keygen_sample_len;
  logic [2:0]  pke_keygen_sample_buf_r_sel;
  logic        pke_keygen_ntt_start;
  logic        pke_keygen_basemul_start;
  logic        pke_keygen_baseinv_start;
  logic        pke_keygen_binary_start;
  logic [7:0]  pke_keygen_arith_cmd;
  logic        pke_keygen_vec_in_valid;
  logic signed [ZEN_N*COEFF_W-1:0] pke_keygen_vec_in_a;
  logic signed [ZEN_N*COEFF_W-1:0] pke_keygen_vec_in_b;
  logic        pke_keygen_vec_wr_en;
  logic [2:0]  pke_keygen_vec_wr_buf_sel;
  logic [ADDR_W-1:0] pke_keygen_vec_wr_row;
  logic [BUF_BANKS*COEFF_W-1:0] pke_keygen_vec_wr_data;
  logic [2:0]  pke_dec_vec_rd0_buf_sel;
  logic [2:0]  pke_dec_vec_rd1_buf_sel;
  logic [ADDR_W-1:0] pke_dec_vec_rd_row;
  logic        pke_dec_binary_start;
  logic        pke_dec_ntt_start;
  logic        pke_dec_basemul_start;
  logic [7:0]  pke_dec_arith_cmd;
  logic        pke_dec_vec_in_valid;
  logic signed [ZEN_N*COEFF_W-1:0] pke_dec_vec_in_a;
  logic signed [ZEN_N*COEFF_W-1:0] pke_dec_vec_in_b;
  logic        pke_dec_vec_wr_en;
  logic [2:0]  pke_dec_vec_wr_buf_sel;
  logic [ADDR_W-1:0] pke_dec_vec_wr_row;
  logic [BUF_BANKS*COEFF_W-1:0] pke_dec_vec_wr_data;
  logic        arith_engine_active;
  logic        pk_unpack_ctrl_active;
  logic        pke_enc_ctrl_active;
  logic        pke_keygen_ctrl_active;
  logic        pke_dec_ctrl_active;
  logic        task_terminal;
  logic [2:0]  local_vec_rd0_buf_sel;
  logic [2:0]  local_vec_rd1_buf_sel;
  logic [ADDR_W-1:0] local_vec_rd_row;
  logic signed [ZEN_N*COEFF_W-1:0] local_vec_in_a;
  logic signed [ZEN_N*COEFF_W-1:0] local_vec_in_b;
  logic [7:0]  local_arith_cmd;
  logic [7:0]  local_sample_cmd;
  logic [31:0] local_sample_cfg;
  logic [31:0] local_sample_len;
  logic [2:0]  local_sample_buf_r_sel;
  logic        local_vec_in_valid;
  logic        local_ntt_core_start;
  logic        local_basemul_core_start;
  logic        local_baseinv_core_start;
  logic        local_binary_core_start;
  logic        local_sampler_core_start;
  logic        local_vec_wr_en;
  logic [2:0]  local_vec_wr_buf_sel;
  logic [ADDR_W-1:0] local_vec_wr_row;
  logic [BUF_BANKS*COEFF_W-1:0] local_vec_wr_data;
  logic signed [ZEN_N*COEFF_W-1:0] pk_unpack_packed_vec;
  logic signed [ZEN_N*COEFF_W-1:0] pk_unpack_stage_vec;
  logic [ADDR_W-1:0] pk_unpack_wr_row;
  logic invalid_cmd_pulse;
  logic [7:0] sample_cmd_reg;
  logic [31:0] sample_cfg_reg;
  logic [31:0] sample_len_reg;
  logic [2:0] sample_buf_r_sel_reg;
  logic [7:0] sample_cmd_cur;
  logic [31:0] sample_cfg_cur;
  logic [31:0] sample_len_cur;
  logic [2:0] sample_buf_r_sel_cur;
  logic [7:0] sample_cmd_cur_d;
  logic [31:0] sample_cfg_cur_d;
  logic [31:0] sample_len_cur_d;
  logic [2:0] sample_buf_r_sel_cur_d;
  logic busy_d;
  logic done_d;
  logic error_d;
  logic signed [ZEN_N*COEFF_W-1:0] sampler_vec_out;
  logic sampler_vec_out_valid;
  logic sampler_row_out_valid;
  logic [ADDR_W-1:0] sampler_row_out_idx;
  logic [BUF_BANKS*COEFF_W-1:0] sampler_row_out_data;
  logic [BUF_BANKS*COEFF_W-1:0] arith_writeback_row_data;
  logic [BUF_BANKS*COEFF_W-1:0] pk_unpack_writeback_row_data;
  logic        arith_prefetch_start;
  logic        arith_prefetch_active;
  logic        arith_prefetch_load;
  logic        arith_prefetch_done;
  logic [ADDR_W-1:0] arith_prefetch_row;
  logic [ADDR_W-1:0] arith_prefetch_load_row;
  logic        pk_unpack_prefetch_start;
  logic        pk_unpack_prefetch_active;
  logic        pk_unpack_prefetch_load;
  logic        pk_unpack_prefetch_done;
  logic [ADDR_W-1:0] pk_unpack_prefetch_row;
  logic [ADDR_W-1:0] pk_unpack_prefetch_load_row;

  function automatic logic is_terminal_task_raw(input logic [7:0] cmd_word);
    begin
      is_terminal_task_raw = (cmd_word == CMD_RUN_PKE_KEYGEN) ||
                             (cmd_word == CMD_RUN_PKE_ENC) ||
                             (cmd_word == CMD_RUN_PKE_DEC);
    end
  endfunction

  assign task_terminal = is_terminal_task_raw(task_cmd_raw);

  zen_full_offload_ctrl_if u_ctrl_if (
    .clk         (clk),
    .rst_n       (rst_n),
    .wr_en       (wr_en),
    .wr_addr     (wr_addr),
    .wr_data     (wr_data),
    .rd_en       (rd_en),
    .rd_addr     (rd_addr),
    .rd_data     (ctrl_rd_data),
    .start_pulse (start),
    .cmd         (cmd),
    .cfg         (cfg),
    .len         (len),
    .buf_a_sel   (buf_a_sel),
    .buf_b_sel   (buf_b_sel),
    .buf_r_sel   (buf_r_sel),
    .host_buf_wr_en (host_buf_wr_en),
    .host_buf_sel   (host_buf_sel),
    .host_buf_addr  (host_buf_addr),
    .host_buf_wdata (host_buf_wdata),
    .host_buf_rd_sel(host_buf_rd_sel),
    .host_buf_rd_addr(host_buf_rd_addr),
    .host_buf_rdata (host_buf_rdata),
    .host_seed_wr_en(host_seed_wr_en),
    .host_seed_addr (host_seed_addr),
    .host_seed_wdata(host_seed_wdata),
    .host_seed_rd_addr(host_seed_rd_addr),
    .host_seed_rdata(host_seed_rdata),
    .core_busy   (busy),
    .core_done   (done),
    .core_error  (error),
    .host_access_lock(host_access_lock),
    .terminal_slots_ok_i(terminal_slots_ok),
    .job_errcode_i(job_errcode_ctrl),
    .out_bytes0_i (out_bytes0_ctrl),
    .out_bytes1_i (out_bytes1_ctrl),
    .job_cmd_raw_o(task_cmd_raw),
    .input0_slot_o(task_input0_slot),
    .input1_slot_o(task_input1_slot),
    .input2_slot_o(task_input2_slot),
    .output0_slot_o(task_output0_slot),
    .output1_slot_o(task_output1_slot),
    .job_cfg_o   (task_job_cfg)
  );

  zen_resident_buf_fabric u_resident_fabric (
    .job_terminal_i(task_terminal),
    .job_cmd_raw_i(task_cmd_raw),
    .input0_slot_i(task_input0_slot),
    .input1_slot_i(task_input1_slot),
    .input2_slot_i(task_input2_slot),
    .output0_slot_i(task_output0_slot),
    .output1_slot_i(task_output1_slot),
    .host_access_lock_i(host_access_lock),
    .sampler_seed_active_i(sampler_seed_active),
    .host_buf_wr_en_i(host_buf_wr_en),
    .host_buf_sel_i(host_buf_sel),
    .host_buf_addr_i(host_buf_addr),
    .host_buf_wdata_i(host_buf_wdata),
    .host_buf_rd_sel_i(host_buf_rd_sel),
    .host_buf_rd_addr_i(host_buf_rd_addr),
    .buf_rd_data_i(buf_rd0_data),
    .host_seed_wr_en_i(host_seed_wr_en),
    .host_seed_addr_i(host_seed_addr),
    .host_seed_wdata_i(host_seed_wdata),
    .host_seed_rd_addr_i(host_seed_rd_addr),
    .sampler_seed_rd_addr_i(sampler_seed_rd_addr),
    .seedbuf_rd_data_i(seedbuf_rd_data),
    .terminal_slots_ok_o(terminal_slots_ok),
    .term_buf_a_sel_o(term_buf_a_sel),
    .term_buf_b_sel_o(term_buf_b_sel),
    .term_buf_r_sel_o(term_buf_r_sel),
    .buf_wr_en_o(resident_buf_wr_en),
    .buf_wr_sel_o(resident_buf_wr_sel),
    .buf_wr_addr_o(resident_buf_wr_addr),
    .buf_wr_data_o(resident_buf_wr_data),
    .buf_rd_sel_o(resident_buf_rd_sel),
    .buf_rd_addr_o(resident_buf_rd_addr),
    .host_buf_rdata_o(host_buf_rdata),
    .seed_wr_en_o(resident_seed_wr_en),
    .seed_wr_addr_o(resident_seed_wr_addr),
    .seed_wr_data_o(resident_seed_wr_data),
    .seed_rd_addr_o(seedbuf_rd_addr),
    .host_seed_rdata_o(host_seed_rdata)
  );

  zen_pke_enc_core u_pke_enc_core (
    .clk(clk),
    .rst_n(rst_n),
    .start_i(pke_enc_start_i),
    .cfg_i(cfg),
    .len_i(len),
    .buf_a_sel_i(launch_buf_a_sel),
    .buf_b_sel_i(launch_buf_b_sel),
    .buf_r_sel_i(launch_buf_r_sel),
    .vec_rd0_row_data_i(vec_rd0_row_data),
    .vec_rd1_row_data_i(vec_rd1_row_data),
    .sampler_done_i(sampler_done),
    .sampler_error_i(sampler_error),
    .sampler_vec_out_valid_i(sampler_vec_out_valid),
    .sampler_vec_out_i(sampler_vec_out),
    .ntt_done_i(ntt_done),
    .ntt_error_i(ntt_error),
    .ntt_vec_out_valid_i(ntt_vec_out_valid),
    .ntt_vec_out_i(ntt_vec_out),
    .basemul_done_i(basemul_done),
    .basemul_error_i(basemul_error),
    .basemul_vec_out_valid_i(basemul_vec_out_valid),
    .basemul_vec_out_i(basemul_vec_out),
    .busy_o(pke_enc_busy_i),
    .done_o(pke_enc_done_i),
    .error_o(pke_enc_error_i),
    .errcode_o(pke_enc_errcode_i),
    .out_bytes0_o(pke_enc_out_bytes0_i),
    .out_bytes1_o(pke_enc_out_bytes1_i),
    .sampler_seed_active_o(pke_enc_sampler_seed_active),
    .prefetch_active_o(pke_enc_prefetch_active),
    .vec_rd0_buf_sel_o(pke_enc_vec_rd0_buf_sel),
    .vec_rd1_buf_sel_o(pke_enc_vec_rd1_buf_sel),
    .vec_rd_row_o(pke_enc_vec_rd_row),
    .sampler_start_o(pke_enc_sampler_start),
    .sample_cmd_o(pke_enc_sample_cmd),
    .sample_cfg_o(pke_enc_sample_cfg),
    .sample_len_o(pke_enc_sample_len),
    .sample_buf_r_sel_o(pke_enc_sample_buf_r_sel),
    .ntt_start_o(pke_enc_ntt_start),
    .basemul_start_o(pke_enc_basemul_start),
    .arith_cmd_o(pke_enc_arith_cmd),
    .vec_in_valid_o(pke_enc_vec_in_valid),
    .vec_in_a_o(pke_enc_vec_in_a),
    .vec_in_b_o(pke_enc_vec_in_b),
    .vec_wr_en_o(pke_enc_vec_wr_en),
    .vec_wr_buf_sel_o(pke_enc_vec_wr_buf_sel),
    .vec_wr_row_o(pke_enc_vec_wr_row),
    .vec_wr_data_o(pke_enc_vec_wr_data)
  );

  zen_pke_keygen_core u_pke_keygen_core (
    .clk(clk),
    .rst_n(rst_n),
    .start_i(pke_keygen_start_i),
    .cfg_i(cfg),
    .len_i(len),
    .buf_a_sel_i(launch_buf_a_sel),
    .buf_b_sel_i(launch_buf_b_sel),
    .buf_r_sel_i(launch_buf_r_sel),
    .sampler_done_i(sampler_done),
    .sampler_error_i(sampler_error),
    .sampler_vec_out_valid_i(sampler_vec_out_valid),
    .sampler_vec_out_i(sampler_vec_out),
    .ntt_done_i(ntt_done),
    .ntt_error_i(ntt_error),
    .ntt_vec_out_valid_i(ntt_vec_out_valid),
    .ntt_vec_out_i(ntt_vec_out),
    .basemul_done_i(basemul_done),
    .basemul_error_i(basemul_error),
    .basemul_vec_out_valid_i(basemul_vec_out_valid),
    .basemul_vec_out_i(basemul_vec_out),
    .basemul_row_valid_i(basemul_row_out_valid),
    .basemul_row_idx_i(basemul_row_out_idx),
    .basemul_row_data_i(basemul_row_out_data),
    .baseinv_done_i(baseinv_done),
    .baseinv_error_i(baseinv_error),
    .baseinv_vec_out_valid_i(baseinv_vec_out_valid),
    .baseinv_vec_out_i(baseinv_vec_out),
    .baseinv_row_valid_i(baseinv_row_out_valid),
    .baseinv_row_idx_i(baseinv_row_out_idx),
    .baseinv_row_data_i(baseinv_row_out_data),
    .binary_done_i(binary_done),
    .binary_error_i(binary_error),
    .binary_vec_out_valid_i(binary_vec_out_valid),
    .binary_vec_out_i(binary_vec_out),
    .binary_row_valid_i(binary_row_out_valid),
    .binary_row_idx_i(binary_row_out_idx),
    .binary_row_data_i(binary_row_out_data),
    .busy_o(pke_keygen_busy_i),
    .done_o(pke_keygen_done_i),
    .error_o(pke_keygen_error_i),
    .errcode_o(pke_keygen_errcode_i),
    .out_bytes0_o(pke_keygen_out_bytes0_i),
    .out_bytes1_o(pke_keygen_out_bytes1_i),
    .sampler_seed_active_o(pke_keygen_sampler_seed_active),
    .sampler_start_o(pke_keygen_sampler_start),
    .sample_cmd_o(pke_keygen_sample_cmd),
    .sample_cfg_o(pke_keygen_sample_cfg),
    .sample_len_o(pke_keygen_sample_len),
    .sample_buf_r_sel_o(pke_keygen_sample_buf_r_sel),
    .ntt_start_o(pke_keygen_ntt_start),
    .basemul_start_o(pke_keygen_basemul_start),
    .baseinv_start_o(pke_keygen_baseinv_start),
    .binary_start_o(pke_keygen_binary_start),
    .arith_cmd_o(pke_keygen_arith_cmd),
    .vec_in_valid_o(pke_keygen_vec_in_valid),
    .vec_in_a_o(pke_keygen_vec_in_a),
    .vec_in_b_o(pke_keygen_vec_in_b),
    .vec_wr_en_o(pke_keygen_vec_wr_en),
    .vec_wr_buf_sel_o(pke_keygen_vec_wr_buf_sel),
    .vec_wr_row_o(pke_keygen_vec_wr_row),
    .vec_wr_data_o(pke_keygen_vec_wr_data)
  );

  zen_pke_dec_core u_pke_dec_core (
    .clk(clk),
    .rst_n(rst_n),
    .start_i(pke_dec_start_i),
    .cfg_i(cfg),
    .len_i(len),
    .buf_a_sel_i(launch_buf_a_sel),
    .buf_b_sel_i(launch_buf_b_sel),
    .buf_r_sel_i(launch_buf_r_sel),
    .vec_rd0_row_data_i(vec_rd0_row_data),
    .vec_rd1_row_data_i(vec_rd1_row_data),
    .binary_done_i(binary_done),
    .binary_error_i(binary_error),
    .binary_vec_out_valid_i(binary_vec_out_valid),
    .binary_vec_out_i(binary_vec_out),
    .ntt_done_i(ntt_done),
    .ntt_error_i(ntt_error),
    .ntt_vec_out_valid_i(ntt_vec_out_valid),
    .ntt_vec_out_i(ntt_vec_out),
    .basemul_done_i(basemul_done),
    .basemul_error_i(basemul_error),
    .basemul_vec_out_valid_i(basemul_vec_out_valid),
    .basemul_vec_out_i(basemul_vec_out),
    .busy_o(pke_dec_busy_i),
    .done_o(pke_dec_done_i),
    .error_o(pke_dec_error_i),
    .errcode_o(pke_dec_errcode_i),
    .out_bytes0_o(pke_dec_out_bytes0_i),
    .out_bytes1_o(pke_dec_out_bytes1_i),
    .vec_rd0_buf_sel_o(pke_dec_vec_rd0_buf_sel),
    .vec_rd1_buf_sel_o(pke_dec_vec_rd1_buf_sel),
    .vec_rd_row_o(pke_dec_vec_rd_row),
    .binary_start_o(pke_dec_binary_start),
    .ntt_start_o(pke_dec_ntt_start),
    .basemul_start_o(pke_dec_basemul_start),
    .arith_cmd_o(pke_dec_arith_cmd),
    .vec_in_valid_o(pke_dec_vec_in_valid),
    .vec_in_a_o(pke_dec_vec_in_a),
    .vec_in_b_o(pke_dec_vec_in_b),
    .vec_wr_en_o(pke_dec_vec_wr_en),
    .vec_wr_buf_sel_o(pke_dec_vec_wr_buf_sel),
    .vec_wr_row_o(pke_dec_vec_wr_row),
    .vec_wr_data_o(pke_dec_vec_wr_data)
  );

  zen_pk_unpack_seq_core u_pk_unpack_seq_core (
    .clk(clk),
    .rst_n(rst_n),
    .start_i(pk_unpack_state == PK_UNPACK_PREP),
    .pk_bytes_vec_i(pk_unpack_packed_vec),
    .busy_o(pk_unpack_core_busy),
    .done_o(pk_unpack_core_done),
    .pk_poly_vec_o(pk_unpack_pk_poly_vec_out),
    .bytes_consumed_o(pk_unpack_bytes_consumed)
  );

  zen_cmd_dispatch u_cmd_dispatch (
    .cmd           (cmd),
    .start         (start),
    .active_core   (active_core),
    .ntt_start     (ntt_start),
    .basemul_start (basemul_start),
    .baseinv_start (baseinv_start),
    .binary_start  (binary_start),
    .sampler_start (sampler_start)
  );

  zen_ntt_core u_ntt_core (
    .clk       (clk),
    .rst_n     (rst_n),
    .start     (ntt_core_start),
    .cmd       (arith_cmd),
    .cfg       (arith_cfg),
    .len       (arith_len),
    .buf_a_sel (arith_buf_a_sel),
    .buf_r_sel (arith_buf_r_sel),
    .vec_in_valid(vec_in_valid),
    .vec_in_data(vec_in_a),
    .vec_out_valid(ntt_vec_out_valid),
    .vec_out_data(ntt_vec_out),
    .busy      (ntt_busy),
    .done      (ntt_done),
    .error     (ntt_error)
  );

  zen_basemul_core u_basemul_core (
    .clk       (clk),
    .rst_n     (rst_n),
    .start     (basemul_core_start),
    .cmd       (arith_cmd),
    .cfg       (arith_cfg),
    .len       (arith_len),
    .buf_a_sel (arith_buf_a_sel),
    .buf_b_sel (arith_buf_b_sel),
    .buf_r_sel (arith_buf_r_sel),
    .vec_in_valid(vec_in_valid),
    .vec_a_data(vec_in_a),
    .vec_b_data(vec_in_b),
    .vec_out_valid(basemul_vec_out_valid),
    .vec_r_data(basemul_vec_out),
    .row_out_valid(basemul_row_out_valid),
    .row_out_idx(basemul_row_out_idx),
    .row_out_data(basemul_row_out_data),
    .busy      (basemul_busy),
    .done      (basemul_done),
    .error     (basemul_error)
  );

  zen_baseinv_core u_baseinv_core (
    .clk       (clk),
    .rst_n     (rst_n),
    .start     (baseinv_core_start),
    .cfg       (arith_cfg),
    .len       (arith_len),
    .buf_a_sel (arith_buf_a_sel),
    .buf_r_sel (arith_buf_r_sel),
    .vec_in_valid(vec_in_valid),
    .vec_a_data(vec_in_a),
    .vec_out_valid(baseinv_vec_out_valid),
    .vec_r_data(baseinv_vec_out),
    .row_out_valid(baseinv_row_out_valid),
    .row_out_idx(baseinv_row_out_idx),
    .row_out_data(baseinv_row_out_data),
    .busy      (baseinv_busy),
    .done      (baseinv_done),
    .error     (baseinv_error)
  );

  zen_binary_core u_binary_core (
    .clk       (clk),
    .rst_n     (rst_n),
    .start     (binary_core_start),
    .cmd       (arith_cmd),
    .cfg       (arith_cfg),
    .len       (arith_len),
    .buf_a_sel (arith_buf_a_sel),
    .buf_b_sel (arith_buf_b_sel),
    .buf_r_sel (arith_buf_r_sel),
    .vec_in_valid(vec_in_valid),
    .vec_a_data(vec_in_a),
    .vec_b_data(vec_in_b),
    .vec_out_valid(binary_vec_out_valid),
    .vec_r_data(binary_vec_out),
    .row_out_valid(binary_row_out_valid),
    .row_out_idx(binary_row_out_idx),
    .row_out_data(binary_row_out_data),
    .busy      (binary_busy),
    .done      (binary_done),
    .error     (binary_error)
  );

  zen_sampler_core u_sampler_core (
    .clk       (clk),
    .rst_n     (rst_n),
    .start     (sampler_core_start),
    .cmd       (sample_cmd_cur),
    .cfg       (sample_cfg_cur),
    .len       (sample_len_cur),
    .buf_r_sel (sample_buf_r_sel_cur),
    .seed_rd_addr (sampler_seed_rd_addr),
    .seed_rd_data (seedbuf_rd_data),
    .vec_out_valid(sampler_vec_out_valid),
    .vec_out_data(sampler_vec_out),
    .row_out_valid(sampler_row_out_valid),
    .row_out_idx(sampler_row_out_idx),
    .row_out_data(sampler_row_out_data),
    .busy      (sampler_busy),
    .done      (sampler_done),
    .error     (sampler_error)
  );

  zen_buf_mgr u_buf_mgr (
    .clk        (clk),
    .wr_en      (buf_wr_en),
    .wr_buf_sel (buf_wr_sel),
    .wr_addr    (buf_wr_addr),
    .wr_data    (buf_wr_data),
    .rd0_buf_sel(buf_rd0_sel),
    .rd0_addr   (buf_rd0_addr),
    .rd0_data   (buf_rd0_data),
    .rd1_buf_sel(buf_rd1_sel),
    .rd1_addr   (buf_rd1_addr),
    .rd1_data   (buf_rd1_data),
    .vec_rd0_buf_sel(vec_rd0_buf_sel),
    .vec_rd0_row_data(vec_rd0_row_data),
    .vec_rd1_buf_sel(vec_rd1_buf_sel),
    .vec_rd1_row_data(vec_rd1_row_data),
    .vec_rd_row(vec_rd_row),
    .vec_wr_en  (vec_wr_en),
    .vec_wr_buf_sel(vec_wr_buf_sel),
    .vec_wr_row (vec_wr_row),
    .vec_wr_data(vec_wr_data)
  );

  zen_vec_prefetch_ctrl u_arith_prefetch_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .start_i(arith_prefetch_start),
    .rows_i(ADDR_W'(active_writeback_rows)),
    .active_o(arith_prefetch_active),
    .load_o(arith_prefetch_load),
    .done_o(arith_prefetch_done),
    .req_row_o(arith_prefetch_row),
    .load_row_o(arith_prefetch_load_row)
  );

  zen_vec_row_loader u_arith_vec_a_loader (
    .clk(clk),
    .rst_n(rst_n),
    .clear_i(arith_prefetch_start),
    .load_i(arith_prefetch_load),
    .row_i(arith_prefetch_load_row),
    .row_vec_i(vec_rd0_row_data),
    .vec_o(vec_in_a_reg)
  );

  zen_vec_row_loader u_arith_vec_b_loader (
    .clk(clk),
    .rst_n(rst_n),
    .clear_i(arith_prefetch_start),
    .load_i(arith_prefetch_load),
    .row_i(arith_prefetch_load_row),
    .row_vec_i(vec_rd1_row_data),
    .vec_o(vec_in_b_reg)
  );

  zen_vec_prefetch_ctrl u_pk_unpack_prefetch_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .start_i(pk_unpack_prefetch_start),
    .rows_i(ADDR_W'(active_writeback_rows)),
    .active_o(pk_unpack_prefetch_active),
    .load_o(pk_unpack_prefetch_load),
    .done_o(pk_unpack_prefetch_done),
    .req_row_o(pk_unpack_prefetch_row),
    .load_row_o(pk_unpack_prefetch_load_row)
  );

  zen_vec_row_loader u_pk_unpack_loader (
    .clk(clk),
    .rst_n(rst_n),
    .clear_i(pk_unpack_prefetch_start),
    .load_i(pk_unpack_prefetch_load),
    .row_i(pk_unpack_prefetch_load_row),
    .row_vec_i(vec_rd0_row_data),
    .vec_o(pk_unpack_packed_vec)
  );

  zen_vec_row_slice u_arith_writeback_row_slice (
    .vec_i(writeback_vec),
    .row_i(arith_wr_row),
    .row_vec_o(arith_writeback_row_data)
  );

  zen_vec_row_slice u_pk_unpack_writeback_row_slice (
    .vec_i(pk_unpack_stage_vec),
    .row_i(pk_unpack_wr_row),
    .row_vec_o(pk_unpack_writeback_row_data)
  );

  zen_seedbuf_mgr u_seedbuf_mgr (
    .clk     (clk),
    .wr_en   (resident_seed_wr_en),
    .wr_addr (resident_seed_wr_addr),
    .wr_data (resident_seed_wr_data),
    .rd_addr (seedbuf_rd_addr),
    .rd_data (seedbuf_rd_data)
  );

  assign host_access_lock =
    pke_keygen_busy_i ||
    pke_enc_busy_i ||
    pke_dec_busy_i;

  assign sampler_seed_active =
    (active_core == CORE_SAMPLER) ||
    pke_keygen_sampler_seed_active ||
    pke_enc_sampler_seed_active;

  assign launch_buf_a_sel = task_terminal ? term_buf_a_sel : buf_a_sel;
  assign launch_buf_b_sel = task_terminal ? term_buf_b_sel : buf_b_sel;
  assign launch_buf_r_sel = task_terminal ? term_buf_r_sel : buf_r_sel;
  assign pke_enc_start_i = start && (cmd == CMD_PKE_ENC);
  assign pke_keygen_start_i = start && (cmd == CMD_PKE_KEYGEN);
  assign pke_dec_start_i = start && (cmd == CMD_PKE_DEC);
  assign arith_engine_active =
    (active_core == CORE_NTT) ||
    (active_core == CORE_BASEMUL) ||
    (active_core == CORE_BASEINV) ||
    (active_core == CORE_BINARY);
  assign pk_unpack_ctrl_active =
    (pk_unpack_state != PK_UNPACK_IDLE) ||
    (start && (cmd == CMD_PK_UNPACK));
  assign pke_enc_ctrl_active =
    pke_enc_route_active ||
    pke_enc_start_i;
  assign pke_keygen_ctrl_active =
    pke_keygen_route_active ||
    pke_keygen_start_i;
  assign pke_dec_ctrl_active =
    pke_dec_route_active ||
    pke_dec_start_i;
  assign invalid_cmd_pulse =
    start &&
    (active_core == CORE_NONE) &&
    (cmd != CMD_PKE_DEC) &&
    (cmd != CMD_PK_UNPACK) &&
    (cmd != CMD_PKE_ENC) &&
    (cmd != CMD_PKE_KEYGEN);
  assign irq = done;

  always_comb begin
    ctrl_route_src = CTRL_ROUTE_LOCAL;
    if (pke_enc_ctrl_active) begin
      ctrl_route_src = CTRL_ROUTE_PKE_ENC;
    end
    if (pke_keygen_ctrl_active) begin
      ctrl_route_src = CTRL_ROUTE_PKE_KEYGEN;
    end
    if (pke_dec_ctrl_active) begin
      ctrl_route_src = CTRL_ROUTE_PKE_DEC;
    end
  end

  always_comb begin
    status_route_src = STATUS_ROUTE_NONE;

    if (invalid_cmd_pulse) begin
      status_route_src = STATUS_ROUTE_INVALID;
    end else if (pke_keygen_ctrl_active) begin
      status_route_src = STATUS_ROUTE_PKE_KEYGEN;
    end else if (pke_enc_ctrl_active) begin
      status_route_src = STATUS_ROUTE_PKE_ENC;
    end else if (pke_dec_ctrl_active) begin
      status_route_src = STATUS_ROUTE_PKE_DEC;
    end else if ((pk_unpack_state != PK_UNPACK_IDLE) || pk_unpack_start_i) begin
      status_route_src = STATUS_ROUTE_PK_UNPACK;
    end else if ((arith_state != ARITH_IDLE) || arith_start) begin
      status_route_src = STATUS_ROUTE_ARITH;
    end else if ((sample_state != ARITH_IDLE) || sample_start_i) begin
      status_route_src = STATUS_ROUTE_SAMPLE;
    end else if (active_core == CORE_SAMPLER) begin
      status_route_src = STATUS_ROUTE_IDLE_SAMPLER;
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      arith_state <= ARITH_IDLE;
      pk_unpack_state <= PK_UNPACK_IDLE;
      arith_core <= CORE_NONE;
      job_cmd <= '0;
      job_cfg <= '0;
      job_len <= '0;
      job_buf_a_sel <= '0;
      job_buf_b_sel <= '0;
      job_buf_r_sel <= '0;
      writeback_vec <= '0;
      arith_wr_row <= '0;
      sample_state <= ARITH_IDLE;
      sample_cmd_reg <= CMD_NOP;
      sample_cfg_reg <= '0;
      sample_len_reg <= '0;
      sample_buf_r_sel_reg <= '0;
      pke_enc_route_active <= 1'b0;
      pke_keygen_route_active <= 1'b0;
      pke_dec_route_active <= 1'b0;
      terminal_job_active <= 1'b0;
      terminal_job_cmd_raw_reg <= CMD_NOP;
      pk_unpack_stage_vec <= '0;
      pk_unpack_wr_row <= '0;
    end else begin
      arith_state <= arith_state_n;
      sample_state <= sample_state_n;
      pk_unpack_state <= pk_unpack_state_n;

      if (pke_enc_start_i) begin
        pke_enc_route_active <= 1'b1;
      end else if (pke_enc_done_i || pke_enc_error_i) begin
        pke_enc_route_active <= 1'b0;
      end

      if (pke_keygen_start_i) begin
        pke_keygen_route_active <= 1'b1;
      end else if (pke_keygen_done_i || pke_keygen_error_i) begin
        pke_keygen_route_active <= 1'b0;
      end

      if (pke_dec_start_i) begin
        pke_dec_route_active <= 1'b1;
      end else if (pke_dec_done_i || pke_dec_error_i) begin
        pke_dec_route_active <= 1'b0;
      end

      if (start && task_terminal) begin
        terminal_job_active <= 1'b1;
        terminal_job_cmd_raw_reg <= task_cmd_raw;
      end else if (done || error) begin
        terminal_job_active <= 1'b0;
        terminal_job_cmd_raw_reg <= CMD_NOP;
      end

      if (arith_start) begin
        arith_core <= active_core;
        job_cmd <= cmd;
        job_cfg <= cfg;
        job_len <= len;
        job_buf_a_sel <= launch_buf_a_sel;
        job_buf_b_sel <= launch_buf_b_sel;
        job_buf_r_sel <= launch_buf_r_sel;
      end

      if ((arith_state == ARITH_WAIT) && core_done_sel && core_vec_valid_sel) begin
        unique case (arith_core)
          CORE_NTT: begin
            writeback_vec <= ntt_vec_out;
          end
          CORE_BASEMUL: begin
            writeback_vec <= basemul_vec_out;
          end
          CORE_BASEINV: begin
            writeback_vec <= baseinv_vec_out;
          end
          CORE_BINARY: begin
            writeback_vec <= binary_vec_out;
          end
          default: begin
            writeback_vec <= '0;
          end
        endcase
        arith_wr_row <= '0;
      end else if (arith_state == ARITH_WRITEBACK) begin
        if (arith_wr_row < active_writeback_last_row) begin
          arith_wr_row <= arith_wr_row + 1'b1;
        end else begin
          arith_wr_row <= '0;
        end
      end

      if (sample_start_i) begin
        sample_cmd_reg <= cmd;
        sample_cfg_reg <= cfg;
        sample_len_reg <= len;
        sample_buf_r_sel_reg <= launch_buf_r_sel;
      end

      if ((pk_unpack_state == PK_UNPACK_WAIT) && pk_unpack_core_done) begin
        pk_unpack_stage_vec <= pk_unpack_pk_poly_vec_out;
        pk_unpack_wr_row <= '0;
      end else if (pk_unpack_state == PK_UNPACK_WRITEBACK) begin
        if (pk_unpack_wr_row < active_writeback_last_row) begin
          pk_unpack_wr_row <= pk_unpack_wr_row + 1'b1;
        end else begin
          pk_unpack_wr_row <= '0;
        end
      end
    end
  end

  always_comb begin
    core_done_sel = 1'b0;
    core_error_sel = 1'b0;
    core_vec_valid_sel = 1'b0;

    unique case (arith_core)
      CORE_NTT: begin
        core_done_sel = ntt_done;
        core_error_sel = ntt_error;
        core_vec_valid_sel = ntt_vec_out_valid;
      end
      CORE_BASEMUL: begin
        core_done_sel = basemul_done;
        core_error_sel = basemul_error;
        core_vec_valid_sel = basemul_vec_out_valid;
      end
      CORE_BASEINV: begin
        core_done_sel = baseinv_done;
        core_error_sel = baseinv_error;
        core_vec_valid_sel = baseinv_vec_out_valid;
      end
      CORE_BINARY: begin
        core_done_sel = binary_done;
        core_error_sel = binary_error;
        core_vec_valid_sel = binary_vec_out_valid;
      end
      default: begin
      end
    endcase
  end

  always_comb begin
    arith_start = 1'b0;
    arith_busy_i = 1'b0;
    arith_done_i = 1'b0;
    arith_error_i = 1'b0;
    arith_state_n = arith_state;
    sample_start_i = 1'b0;
    sample_busy_i = 1'b0;
    sample_done_i = 1'b0;
    sample_error_i = 1'b0;
    sample_state_n = sample_state;
    pk_unpack_start_i = 1'b0;
    pk_unpack_busy_i = 1'b0;
    pk_unpack_done_i = 1'b0;
    pk_unpack_error_i = 1'b0;
    pk_unpack_state_n = pk_unpack_state;
    arith_prefetch_start = 1'b0;
    pk_unpack_prefetch_start = 1'b0;

    local_arith_cmd = (arith_state == ARITH_IDLE) ? cmd : job_cmd;
    arith_cfg = (arith_state == ARITH_IDLE) ? cfg : job_cfg;
    arith_len = (arith_state == ARITH_IDLE) ? len : job_len;
    arith_buf_a_sel = (arith_state == ARITH_IDLE) ? buf_a_sel : job_buf_a_sel;
    arith_buf_b_sel = (arith_state == ARITH_IDLE) ? buf_b_sel : job_buf_b_sel;
    arith_buf_r_sel = (arith_state == ARITH_IDLE) ? buf_r_sel : job_buf_r_sel;
    local_sample_cmd = (sample_state == ARITH_IDLE) ? cmd : sample_cmd_reg;
    local_sample_cfg = (sample_state == ARITH_IDLE) ? cfg : sample_cfg_reg;
    local_sample_len = (sample_state == ARITH_IDLE) ? len : sample_len_reg;
    local_sample_buf_r_sel = (sample_state == ARITH_IDLE) ? buf_r_sel : sample_buf_r_sel_reg;

    local_vec_rd0_buf_sel = arith_buf_a_sel;
    local_vec_rd1_buf_sel = arith_buf_b_sel;
    local_vec_rd_row = '0;
    local_vec_in_a = vec_in_a_reg;
    local_vec_in_b = vec_in_b_reg;
    local_vec_in_valid = 1'b0;
    local_ntt_core_start = 1'b0;
    local_basemul_core_start = 1'b0;
    local_baseinv_core_start = 1'b0;
    local_binary_core_start = 1'b0;
    local_sampler_core_start = 1'b0;
    local_vec_wr_en = 1'b0;
    local_vec_wr_buf_sel = job_buf_r_sel;
    local_vec_wr_row = arith_wr_row;
    local_vec_wr_data = arith_writeback_row_data;

    if (arith_engine_active) begin
      arith_busy_i = (arith_state != ARITH_IDLE);
      unique case (arith_state)
        ARITH_IDLE: begin
          if (start) begin
            arith_start = 1'b1;
            arith_prefetch_start = 1'b1;
            arith_state_n = ARITH_PREFETCH;
            arith_busy_i = 1'b1;
          end
        end
        ARITH_PREFETCH: begin
          local_vec_rd0_buf_sel = arith_buf_a_sel;
          local_vec_rd1_buf_sel = arith_buf_b_sel;
          local_vec_rd_row = arith_prefetch_row;
          if (arith_prefetch_done) begin
            arith_state_n = ARITH_LAUNCH;
          end
        end
        ARITH_LAUNCH: begin
          local_vec_in_valid = 1'b1;
          unique case (arith_core)
            CORE_NTT: local_ntt_core_start = 1'b1;
            CORE_BASEMUL: local_basemul_core_start = 1'b1;
            CORE_BASEINV: local_baseinv_core_start = 1'b1;
            CORE_BINARY: local_binary_core_start = 1'b1;
            default: begin
            end
          endcase
          arith_state_n = ARITH_WAIT;
        end
        ARITH_WAIT: begin
          if (core_error_sel) begin
            arith_error_i = 1'b1;
            arith_state_n = ARITH_IDLE;
            arith_busy_i = 1'b0;
          end else if (core_done_sel && core_vec_valid_sel) begin
            arith_state_n = ARITH_WRITEBACK;
          end
        end
        ARITH_WRITEBACK: begin
          local_vec_wr_en = 1'b1;
          if (arith_wr_row == active_writeback_last_row) begin
            arith_done_i = 1'b1;
            arith_state_n = ARITH_IDLE;
            arith_busy_i = 1'b0;
          end
        end
        default: begin
          arith_state_n = ARITH_IDLE;
        end
      endcase
    end

    if (active_core == CORE_SAMPLER) begin
      sample_busy_i = (sample_state != ARITH_IDLE);
      local_vec_wr_buf_sel = local_sample_buf_r_sel;
      local_vec_wr_row = sampler_row_out_idx;
      local_vec_wr_data = sampler_row_out_data;
      unique case (sample_state)
        ARITH_IDLE: begin
          if (start) begin
            sample_start_i = 1'b1;
            local_sampler_core_start = 1'b1;
            sample_state_n = ARITH_WAIT;
            sample_busy_i = 1'b1;
          end
        end
        ARITH_WAIT: begin
          local_vec_wr_en = sampler_row_out_valid;
          if (sampler_error) begin
            sample_error_i = 1'b1;
            sample_state_n = ARITH_IDLE;
            sample_busy_i = 1'b0;
          end else if (sampler_done) begin
            sample_done_i = 1'b1;
            sample_state_n = ARITH_IDLE;
            sample_busy_i = 1'b0;
          end
        end
        default: begin
          sample_state_n = ARITH_IDLE;
        end
      endcase
    end

    if (pk_unpack_ctrl_active) begin
      pk_unpack_busy_i = (pk_unpack_state != PK_UNPACK_IDLE);
      unique case (pk_unpack_state)
        PK_UNPACK_IDLE: begin
          if (start && (cmd == CMD_PK_UNPACK)) begin
            pk_unpack_start_i = 1'b1;
            pk_unpack_prefetch_start = 1'b1;
            pk_unpack_state_n = PK_UNPACK_PREFETCH;
            pk_unpack_busy_i = 1'b1;
          end
        end
        PK_UNPACK_PREFETCH: begin
          local_vec_rd0_buf_sel = buf_a_sel;
          local_vec_rd1_buf_sel = '0;
          local_vec_rd_row = pk_unpack_prefetch_row;
          if (pk_unpack_prefetch_done) begin
            pk_unpack_state_n = PK_UNPACK_PREP;
          end
        end
        PK_UNPACK_PREP: begin
          pk_unpack_state_n = PK_UNPACK_WAIT;
        end
        PK_UNPACK_WAIT: begin
          if (pk_unpack_core_done) begin
            pk_unpack_state_n = PK_UNPACK_WRITEBACK;
          end
        end
        PK_UNPACK_WRITEBACK: begin
          local_vec_wr_en = 1'b1;
          local_vec_wr_buf_sel = buf_r_sel;
          local_vec_wr_row = pk_unpack_wr_row;
          local_vec_wr_data = pk_unpack_writeback_row_data;
          if (pk_unpack_wr_row == active_writeback_last_row) begin
            pk_unpack_done_i = 1'b1;
            pk_unpack_state_n = PK_UNPACK_IDLE;
            pk_unpack_busy_i = 1'b0;
          end
        end
        default: begin
          pk_unpack_state_n = PK_UNPACK_IDLE;
        end
      endcase
    end
  end

  always_comb begin
    arith_cmd_d = local_arith_cmd;
    sample_cmd_cur_d = local_sample_cmd;
    sample_cfg_cur_d = local_sample_cfg;
    sample_len_cur_d = local_sample_len;
    sample_buf_r_sel_cur_d = local_sample_buf_r_sel;
    vec_rd0_buf_sel = local_vec_rd0_buf_sel;
    vec_rd1_buf_sel = local_vec_rd1_buf_sel;
    vec_rd_row = local_vec_rd_row;
    vec_in_a_d = local_vec_in_a;
    vec_in_b_d = local_vec_in_b;
    vec_in_valid_d = local_vec_in_valid;
    ntt_core_start_d = local_ntt_core_start;
    basemul_core_start_d = local_basemul_core_start;
    baseinv_core_start_d = local_baseinv_core_start;
    binary_core_start_d = local_binary_core_start;
    sampler_core_start_d = local_sampler_core_start;
    vec_wr_en = local_vec_wr_en;
    vec_wr_buf_sel = local_vec_wr_buf_sel;
    vec_wr_row = local_vec_wr_row;
    vec_wr_data = local_vec_wr_data;

    unique case (ctrl_route_src)
      CTRL_ROUTE_PKE_ENC: begin
        if (pke_enc_prefetch_active) begin
          vec_rd0_buf_sel = pke_enc_vec_rd0_buf_sel;
          vec_rd1_buf_sel = pke_enc_vec_rd1_buf_sel;
          vec_rd_row = pke_enc_vec_rd_row;
        end
        sample_cmd_cur_d = pke_enc_sample_cmd;
        sample_cfg_cur_d = pke_enc_sample_cfg;
        sample_len_cur_d = pke_enc_sample_len;
        sample_buf_r_sel_cur_d = pke_enc_sample_buf_r_sel;
        vec_in_a_d = pke_enc_vec_in_a;
        vec_in_b_d = pke_enc_vec_in_b;
        arith_cmd_d = pke_enc_arith_cmd;
        vec_in_valid_d = pke_enc_vec_in_valid;
        ntt_core_start_d = pke_enc_ntt_start;
        basemul_core_start_d = pke_enc_basemul_start;
        sampler_core_start_d = pke_enc_sampler_start;
        vec_wr_en = pke_enc_vec_wr_en;
        vec_wr_buf_sel = pke_enc_vec_wr_buf_sel;
        vec_wr_row = pke_enc_vec_wr_row;
        vec_wr_data = pke_enc_vec_wr_data;
      end
      CTRL_ROUTE_PKE_KEYGEN: begin
        sample_cmd_cur_d = pke_keygen_sample_cmd;
        sample_cfg_cur_d = pke_keygen_sample_cfg;
        sample_len_cur_d = pke_keygen_sample_len;
        sample_buf_r_sel_cur_d = pke_keygen_sample_buf_r_sel;
        vec_in_a_d = pke_keygen_vec_in_a;
        vec_in_b_d = pke_keygen_vec_in_b;
        arith_cmd_d = pke_keygen_arith_cmd;
        vec_in_valid_d = pke_keygen_vec_in_valid;
        ntt_core_start_d = pke_keygen_ntt_start;
        basemul_core_start_d = pke_keygen_basemul_start;
        baseinv_core_start_d = pke_keygen_baseinv_start;
        binary_core_start_d = pke_keygen_binary_start;
        sampler_core_start_d = pke_keygen_sampler_start;
        vec_wr_en = pke_keygen_vec_wr_en;
        vec_wr_buf_sel = pke_keygen_vec_wr_buf_sel;
        vec_wr_row = pke_keygen_vec_wr_row;
        vec_wr_data = pke_keygen_vec_wr_data;
      end
      CTRL_ROUTE_PKE_DEC: begin
        vec_rd0_buf_sel = pke_dec_vec_rd0_buf_sel;
        vec_rd1_buf_sel = pke_dec_vec_rd1_buf_sel;
        vec_rd_row = pke_dec_vec_rd_row;
        vec_in_a_d = pke_dec_vec_in_a;
        vec_in_b_d = pke_dec_vec_in_b;
        arith_cmd_d = pke_dec_arith_cmd;
        vec_in_valid_d = pke_dec_vec_in_valid;
        binary_core_start_d = pke_dec_binary_start;
        ntt_core_start_d = pke_dec_ntt_start;
        basemul_core_start_d = pke_dec_basemul_start;
        vec_wr_en = pke_dec_vec_wr_en;
        vec_wr_buf_sel = pke_dec_vec_wr_buf_sel;
        vec_wr_row = pke_dec_vec_wr_row;
        vec_wr_data = pke_dec_vec_wr_data;
      end
      default: begin
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      arith_cmd <= CMD_NOP;
      sample_cmd_cur <= CMD_NOP;
      sample_cfg_cur <= '0;
      sample_len_cur <= '0;
      sample_buf_r_sel_cur <= '0;
      vec_in_a <= '0;
      vec_in_b <= '0;
      vec_in_valid <= 1'b0;
      ntt_core_start <= 1'b0;
      basemul_core_start <= 1'b0;
      baseinv_core_start <= 1'b0;
      binary_core_start <= 1'b0;
      sampler_core_start <= 1'b0;
    end else begin
      arith_cmd <= arith_cmd_d;
      sample_cmd_cur <= sample_cmd_cur_d;
      sample_cfg_cur <= sample_cfg_cur_d;
      sample_len_cur <= sample_len_cur_d;
      sample_buf_r_sel_cur <= sample_buf_r_sel_cur_d;
      vec_in_a <= vec_in_a_d;
      vec_in_b <= vec_in_b_d;
      vec_in_valid <= vec_in_valid_d;
      ntt_core_start <= ntt_core_start_d;
      basemul_core_start <= basemul_core_start_d;
      baseinv_core_start <= baseinv_core_start_d;
      binary_core_start <= binary_core_start_d;
      sampler_core_start <= sampler_core_start_d;
    end
  end

  always_comb begin
    rd_data = ctrl_rd_data;
    buf_wr_en = resident_buf_wr_en;
    buf_wr_sel = resident_buf_wr_sel;
    buf_wr_addr = resident_buf_wr_addr;
    buf_wr_data = resident_buf_wr_data;
    buf_rd0_sel = resident_buf_rd_sel;
    buf_rd0_addr = resident_buf_rd_addr;
    buf_rd1_sel = '0;
    buf_rd1_addr = '0;
    if (vec_wr_en) begin
      buf_wr_en = 1'b0;
      buf_wr_sel = '0;
      buf_wr_addr = '0;
      buf_wr_data = '0;
    end
  end

  always_comb begin
    job_errcode_ctrl = 8'h00;
    out_bytes0_ctrl = 32'h0;
    out_bytes1_ctrl = 32'h0;

    if (terminal_job_active) begin
      unique case (terminal_job_cmd_raw_reg)
        CMD_RUN_PKE_KEYGEN: begin
          job_errcode_ctrl = pke_keygen_errcode_i;
          out_bytes0_ctrl = pke_keygen_out_bytes0_i;
          out_bytes1_ctrl = pke_keygen_out_bytes1_i;
        end
        CMD_RUN_PKE_ENC: begin
          job_errcode_ctrl = pke_enc_errcode_i;
          out_bytes0_ctrl = pke_enc_out_bytes0_i;
          out_bytes1_ctrl = pke_enc_out_bytes1_i;
        end
        CMD_RUN_PKE_DEC: begin
          job_errcode_ctrl = pke_dec_errcode_i;
          out_bytes0_ctrl = pke_dec_out_bytes0_i;
          out_bytes1_ctrl = pke_dec_out_bytes1_i;
        end
        default: begin
        end
      endcase
    end

    busy_d = 1'b0;
    done_d = 1'b0;
    error_d = 1'b0;

    unique case (status_route_src)
      STATUS_ROUTE_INVALID: begin
        error_d = 1'b1;
      end
      STATUS_ROUTE_PKE_KEYGEN: begin
        busy_d = pke_keygen_busy_i;
        done_d = pke_keygen_done_i;
        error_d = pke_keygen_error_i;
      end
      STATUS_ROUTE_PKE_ENC: begin
        busy_d = pke_enc_busy_i;
        done_d = pke_enc_done_i;
        error_d = pke_enc_error_i;
      end
      STATUS_ROUTE_PKE_DEC: begin
        busy_d = pke_dec_busy_i;
        done_d = pke_dec_done_i;
        error_d = pke_dec_error_i;
      end
      STATUS_ROUTE_PK_UNPACK: begin
        busy_d = pk_unpack_busy_i;
        done_d = pk_unpack_done_i;
        error_d = pk_unpack_error_i;
      end
      STATUS_ROUTE_ARITH: begin
        busy_d = arith_busy_i;
        done_d = arith_done_i;
        error_d = arith_error_i;
      end
      STATUS_ROUTE_SAMPLE: begin
        busy_d = sample_busy_i;
        done_d = sample_done_i;
        error_d = sample_error_i;
      end
      STATUS_ROUTE_IDLE_SAMPLER: begin
        busy_d = sample_busy_i;
        done_d = sample_done_i;
        error_d = sample_error_i;
      end
      default: begin
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      busy <= 1'b0;
      done <= 1'b0;
      error <= 1'b0;
    end else begin
      busy <= busy_d;
      done <= done_d;
      error <= error_d;
    end
  end

endmodule

module zen_vec_row_slice (
  input  zen_accel_pkg::zen_poly_vec_t vec_i,
  input  zen_accel_pkg::zen_row_addr_t row_i,
  output zen_accel_pkg::zen_buf_row_t row_vec_o
);

  import zen_accel_pkg::*;

  genvar g_bank;
  generate
    for (g_bank = 0; g_bank < BUF_BANKS; g_bank++) begin : g_row_bank
      assign row_vec_o[g_bank*COEFF_W +: COEFF_W] =
        vec_i[((row_i * BUF_BANKS) + g_bank) * COEFF_W +: COEFF_W];
    end
  endgenerate

endmodule
