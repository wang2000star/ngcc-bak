module zen_sampler_core (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start,
  input  logic [7:0]  cmd,
  input  logic [31:0] cfg,
  input  logic [31:0] len,
  input  logic [2:0]  buf_r_sel,
  output zen_accel_pkg::zen_seed_addr_t seed_rd_addr,
  input  logic [7:0]  seed_rd_data,
  output logic        vec_out_valid,
  output zen_accel_pkg::zen_poly_vec_t vec_out_data,
  output logic        row_out_valid,
  output zen_accel_pkg::zen_row_addr_t row_out_idx,
  output zen_accel_pkg::zen_buf_row_t row_out_data,
  output logic        busy,
  output logic        done,
  output logic        error
);

  import zen_accel_pkg::*;
  localparam int NTT_N = ZEN_N;
  localparam int MAX_SAMPLE_BYTES = SAMPLE_MAX_BYTES;
  localparam int ACTIVE_N = NTT_N;
  localparam int SAMPLE_ROW_COEFFS = BUF_BANKS;
  localparam int SAMPLE_ROW_BITS = SAMPLE_ROW_COEFFS * COEFF_W;
  localparam int SAMPLE_ROW_COUNT = (ACTIVE_N + SAMPLE_ROW_COEFFS - 1) / SAMPLE_ROW_COEFFS;
  localparam int SAMPLE_ROW_W = (SAMPLE_ROW_COUNT > 1) ? $clog2(SAMPLE_ROW_COUNT) : 1;
  localparam int DECODE_LANES = SAMPLE_ROW_COEFFS;

  typedef enum logic [2:0] {
    ST_IDLE,
    ST_PREP,
    ST_READ_SEED,
    ST_DECODE,
    ST_PACK_ROWS,
    ST_DONE,
    ST_ERROR
  } state_t;

  state_t state, state_n;

  logic [SEEDBUF_ADDR_W-1:0] seed_base;
  logic [SEEDBUF_ADDR_W-1:0] seed_ptr;
  logic [SEEDBUF_ADDR_W-1:0] sample_bytes;
  logic [SEEDBUF_ADDR_W:0] seed_loaded_bytes;
  logic [ADDR_W:0] coeff_ptr;
  logic [ADDR_W:0] coeff_last_idx;
  logic [SEEDBUF_ADDR_W:0] coeff_required_bytes;
  logic can_decode_batch;
  logic valid_cmd;
  logic vec_mode_active;
  logic [7:0] cmd_reg;
  logic [7:0] cmd_cur;
  logic [7:0] seed_cache [0:MAX_SAMPLE_BYTES-1];
  logic [SAMPLE_ROW_BITS-1:0] sample_rows [0:SAMPLE_ROW_COUNT-1];
  logic [SAMPLE_ROW_BITS-1:0] decode_row_data;
  logic [SAMPLE_ROW_W-1:0] decode_row_idx;
  logic [SAMPLE_ROW_W-1:0] pack_row_idx;
  logic seed_xof_start;
  logic seed_xof_byte_valid;
  logic [7:0] seed_xof_byte_data;
  logic seed_xof_busy;
  logic seed_xof_done;
  logic seed_xof_error;
  function automatic logic [SEEDBUF_ADDR_W-1:0] get_sample_bytes(
    input logic [7:0] cmd_i
  );
    int sample_bytes_raw;
    begin
      get_sample_bytes = '0;
      case (cmd_i)
        CMD_SAMPLE_F: sample_bytes_raw = 128;
        CMD_SAMPLE_G: sample_bytes_raw = 320;
        CMD_SAMPLE_S: sample_bytes_raw = 448;
        CMD_SAMPLE_E: sample_bytes_raw = 256;
        default:      sample_bytes_raw = 0;
      endcase
      if (sample_bytes_raw > MAX_SAMPLE_BYTES) begin
        get_sample_bytes = SEEDBUF_ADDR_W'(MAX_SAMPLE_BYTES);
      end else begin
        get_sample_bytes = SEEDBUF_ADDR_W'(sample_bytes_raw);
      end
    end
  endfunction

  function automatic logic [SEEDBUF_ADDR_W-1:0] get_sample_bytes_cur(input logic [7:0] cmd_i);
    begin
      get_sample_bytes_cur = get_sample_bytes(cmd_i);
    end
  endfunction

  assign cmd_cur = cmd;

  function automatic logic signed [31:0] load32_le(input integer base_idx);
    logic signed [31:0] r;
    begin
      r = seed_cache[base_idx + 0];
      r = r | (seed_cache[base_idx + 1] << 8);
      r = r | (seed_cache[base_idx + 2] << 16);
      r = r | (seed_cache[base_idx + 3] << 24);
      load32_le = r;
    end
  endfunction

  function automatic logic signed [15:0] bit_unpack_at(
    input integer base_idx,
    input integer bit_idx
  );
    integer byte_idx;
    integer shift_idx;
    begin
      byte_idx = base_idx + (bit_idx >> 3);
      shift_idx = bit_idx & 7;
      bit_unpack_at = (seed_cache[byte_idx] >> shift_idx) & 8'h1;
    end
  endfunction

  function automatic logic signed [15:0] cbd1_coeff(input integer coeff_idx, input integer base_idx);
    logic signed [31:0] t;
    integer j;
    logic signed [15:0] a, b;
    begin
      t = load32_le(base_idx + 4 * (coeff_idx / 16));
      j = coeff_idx % 16;
      a = (t >> (2 * j + 0)) & 32'h1;
      b = (t >> (2 * j + 1)) & 32'h1;
      cbd1_coeff = a - b;
    end
  endfunction

  function automatic logic signed [15:0] cbd2_coeff(input integer coeff_idx, input integer base_idx);
    logic signed [31:0] t, d;
    integer j;
    logic signed [15:0] a, b;
    begin
      t = load32_le(base_idx + 4 * (coeff_idx / 8));
      d = (t & 32'h5555_5555) + ((t >> 1) & 32'h5555_5555);
      j = coeff_idx % 8;
      a = (d >> (4 * j + 0)) & 32'h3;
      b = (d >> (4 * j + 2)) & 32'h3;
      cbd2_coeff = a - b;
    end
  endfunction

  function automatic logic signed [15:0] ternary1_8_coeff(input integer coeff_idx, input integer base_idx);
    logic signed [15:0] t0, t1, t2;
    begin
      t0 = bit_unpack_at(base_idx, coeff_idx);
      t1 = bit_unpack_at(base_idx, coeff_idx + ACTIVE_N);
      t2 = bit_unpack_at(base_idx, coeff_idx + (2 * ACTIVE_N));
      ternary1_8_coeff = (t0 - t1) * t2;
    end
  endfunction

  function automatic logic signed [15:0] ternary3_16_coeff(input integer coeff_idx, input integer base_idx);
    logic signed [15:0] t0, t1, t2, t3;
    begin
      t0 = bit_unpack_at(base_idx, coeff_idx);
      t1 = bit_unpack_at(base_idx, coeff_idx + ACTIVE_N);
      t2 = bit_unpack_at(base_idx, coeff_idx + (2 * ACTIVE_N));
      t3 = bit_unpack_at(base_idx, coeff_idx + (3 * ACTIVE_N));
      ternary3_16_coeff = (t0 & t1) - (t2 & t3);
    end
  endfunction

  function automatic logic signed [15:0] ternary3_32_coeff(input integer coeff_idx, input integer base_idx);
    logic signed [15:0] t0, t1, t2, t3, t4;
    begin
      t0 = bit_unpack_at(base_idx, coeff_idx);
      t1 = bit_unpack_at(base_idx, coeff_idx + ACTIVE_N);
      t2 = bit_unpack_at(base_idx, coeff_idx + (2 * ACTIVE_N));
      t3 = bit_unpack_at(base_idx, coeff_idx + (3 * ACTIVE_N));
      t4 = bit_unpack_at(base_idx, coeff_idx + (4 * ACTIVE_N));
      ternary3_32_coeff = ((t0 & t1) - (t2 & t3)) * t4;
    end
  endfunction

  function automatic logic signed [15:0] sample_coeff(
    input logic [7:0] cmd_i,
    input integer coeff_idx
  );
    logic signed [15:0] coeff;
    begin
      case (cmd_i)
        CMD_SAMPLE_F: coeff = cbd1_coeff(coeff_idx, 0);
        CMD_SAMPLE_G: coeff = cbd1_coeff(coeff_idx, 0) + ternary1_8_coeff(coeff_idx, 128);
        CMD_SAMPLE_S: coeff = cbd1_coeff(coeff_idx, 0) + ternary3_32_coeff(coeff_idx, 128);
        CMD_SAMPLE_E: coeff = cbd2_coeff(coeff_idx, 0);
        default:      coeff = 16'sd0;
      endcase
      sample_coeff = coeff;
    end
  endfunction

  function automatic logic [SAMPLE_ROW_BITS-1:0] build_sample_row(
    input logic [7:0] cmd_i,
    input integer coeff_base
  );
    integer lane_idx;
    integer coeff_idx_local;
    logic [SAMPLE_ROW_BITS-1:0] row_data;
    begin
      row_data = '0;
      for (lane_idx = 0; lane_idx < SAMPLE_ROW_COEFFS; lane_idx = lane_idx + 1) begin
        coeff_idx_local = coeff_base + lane_idx;
        if (coeff_idx_local < ACTIVE_N) begin
          row_data[lane_idx*COEFF_W +: COEFF_W] = sample_coeff(cmd_i, coeff_idx_local);
        end
      end
      build_sample_row = row_data;
    end
  endfunction

  function automatic logic [SEEDBUF_ADDR_W:0] sample_required_bytes(
    input logic [7:0] cmd_i,
    input integer coeff_idx
  );
    logic [SEEDBUF_ADDR_W:0] req;
    integer req_a;
    integer req_b;
    begin
      req = '0;
      req_a = 0;
      req_b = 0;
      case (cmd_i)
        CMD_SAMPLE_F: req = (4 * (coeff_idx / 16)) + 4;
        CMD_SAMPLE_G: begin
          req_a = (4 * (coeff_idx / 16)) + 4;
          req_b = 128 + ((coeff_idx + (2 * ACTIVE_N)) >> 3) + 1;
          req = (req_a > req_b) ? req_a : req_b;
        end
        CMD_SAMPLE_S: begin
          req_a = (4 * (coeff_idx / 16)) + 4;
          req_b = 128 + ((coeff_idx + (4 * ACTIVE_N)) >> 3) + 1;
          req = (req_a > req_b) ? req_a : req_b;
        end
        CMD_SAMPLE_E: req = (4 * (coeff_idx / 8)) + 4;
        default:      req = '0;
      endcase
      sample_required_bytes = req;
    end
  endfunction

  assign valid_cmd = (cmd == CMD_SAMPLE_F) || (cmd == CMD_SAMPLE_G) ||
                     (cmd == CMD_SAMPLE_S) || (cmd == CMD_SAMPLE_E);

  always_comb begin
    decode_row_idx = SAMPLE_ROW_W'($unsigned(coeff_ptr / SAMPLE_ROW_COEFFS));
    decode_row_data = build_sample_row(cmd_reg, coeff_ptr);
  end

  always_comb begin
    if (coeff_ptr >= ACTIVE_N) begin
      coeff_last_idx = coeff_ptr;
      coeff_required_bytes = '0;
      can_decode_batch = 1'b0;
    end else begin
      if ((coeff_ptr + DECODE_LANES) >= ACTIVE_N) begin
        coeff_last_idx = ACTIVE_N - 1;
      end else begin
        coeff_last_idx = coeff_ptr + DECODE_LANES - 1;
      end
      coeff_required_bytes = sample_required_bytes(cmd_reg, coeff_last_idx);
      can_decode_batch = vec_mode_active && (seed_loaded_bytes >= coeff_required_bytes);
    end
  end

  zen_seed_xof_core u_seed_xof_core (
    .clk(clk),
    .rst_n(rst_n),
    .start(seed_xof_start),
    .sample_cmd(cmd_reg),
    .cfg({cfg[31:SEEDBUF_ADDR_W], seed_base}),
    .req_bytes({{(16-SEEDBUF_ADDR_W){1'b0}}, sample_bytes}),
    .seed_rd_addr(seed_rd_addr),
    .seed_rd_data(seed_rd_data),
    .byte_valid(seed_xof_byte_valid),
    .byte_data(seed_xof_byte_data),
    .busy(seed_xof_busy),
    .done(seed_xof_done),
    .error(seed_xof_error)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= ST_IDLE;
      seed_base <= '0;
      seed_ptr <= '0;
      sample_bytes <= '0;
      seed_loaded_bytes <= '0;
      coeff_ptr <= '0;
      vec_mode_active <= 1'b0;
      cmd_reg <= CMD_NOP;
      vec_out_data <= '0;
      vec_out_valid <= 1'b0;
      row_out_valid <= 1'b0;
      row_out_idx <= '0;
      row_out_data <= '0;
      pack_row_idx <= '0;
    end else begin
      state <= state_n;
      vec_out_valid <= (state_n == ST_DONE) && vec_mode_active;
      row_out_valid <= 1'b0;

      case (state)
        ST_IDLE: begin
          if (start && valid_cmd) begin
            seed_base <= cfg[SEEDBUF_ADDR_W-1:0];
            sample_bytes <= get_sample_bytes_cur(cmd_cur);
            seed_ptr <= '0;
            seed_loaded_bytes <= '0;
            coeff_ptr <= '0;
            vec_mode_active <= 1'b1;
            cmd_reg <= cmd_cur;
            row_out_idx <= '0;
            row_out_data <= '0;
            pack_row_idx <= '0;
          end else if (start && !valid_cmd) begin
            vec_mode_active <= 1'b0;
            cmd_reg <= cmd_cur;
          end
        end
        ST_PREP: begin
          seed_ptr <= '0;
          seed_loaded_bytes <= '0;
          coeff_ptr <= '0;
          row_out_idx <= '0;
          row_out_data <= '0;
          pack_row_idx <= '0;
        end
        ST_READ_SEED: begin
          if (seed_xof_byte_valid) begin
            seed_cache[seed_ptr] <= seed_xof_byte_data;
            seed_loaded_bytes <= seed_loaded_bytes + 1'b1;
          end
          if (seed_xof_byte_valid && (seed_ptr + 1 < sample_bytes)) begin
            seed_ptr <= seed_ptr + 1'b1;
          end
          if (can_decode_batch) begin
            sample_rows[decode_row_idx] <= decode_row_data;
            if (coeff_ptr + DECODE_LANES < ACTIVE_N) begin
              coeff_ptr <= coeff_ptr + DECODE_LANES;
            end
          end
        end
        ST_DECODE: begin
          if (can_decode_batch) begin
            sample_rows[decode_row_idx] <= decode_row_data;
            if (coeff_ptr + DECODE_LANES < ACTIVE_N) begin
              coeff_ptr <= coeff_ptr + DECODE_LANES;
            end
          end
        end
        ST_PACK_ROWS: begin
          row_out_valid <= 1'b1;
          row_out_idx <= ADDR_W'(pack_row_idx);
          row_out_data <= sample_rows[pack_row_idx];
          vec_out_data[pack_row_idx * SAMPLE_ROW_BITS +: SAMPLE_ROW_BITS] <= sample_rows[pack_row_idx];
          if ((pack_row_idx + 1) < SAMPLE_ROW_COUNT) begin
            pack_row_idx <= pack_row_idx + 1'b1;
          end
        end
        ST_DONE: begin
          vec_mode_active <= 1'b0;
        end
        ST_ERROR: begin
          vec_mode_active <= 1'b0;
        end
        default: begin
        end
      endcase
    end
  end

  always_comb begin
    state_n = state;
    busy = 1'b1;
    done = 1'b0;
    error = 1'b0;
    seed_xof_start = 1'b0;

    unique case (state)
      ST_IDLE: begin
        busy = 1'b0;
        if (start) begin
          if (!valid_cmd) state_n = ST_ERROR;
          else state_n = ST_PREP;
        end
      end
      ST_PREP: begin
        seed_xof_start = 1'b1;
        state_n = ST_READ_SEED;
      end
      ST_READ_SEED: begin
        if (sample_bytes == 0) state_n = ST_ERROR;
        else if (seed_xof_error) state_n = ST_ERROR;
        else if (seed_xof_done) begin
          if (can_decode_batch && (coeff_ptr + DECODE_LANES >= ACTIVE_N)) begin
            state_n = ST_PACK_ROWS;
          end else begin
            state_n = ST_DECODE;
          end
        end
      end
      ST_DECODE: begin
        if (can_decode_batch && (coeff_ptr + DECODE_LANES >= ACTIVE_N)) state_n = ST_PACK_ROWS;
      end
      ST_PACK_ROWS: begin
        if ((pack_row_idx + 1) >= SAMPLE_ROW_COUNT) state_n = ST_DONE;
      end
      ST_DONE: begin
        busy = 1'b0;
        done = 1'b1;
        state_n = ST_IDLE;
      end
      ST_ERROR: begin
        busy = 1'b0;
        error = 1'b1;
        state_n = ST_IDLE;
      end
      default: begin
        busy = 1'b0;
        error = 1'b1;
        state_n = ST_IDLE;
      end
    endcase
  end

endmodule
