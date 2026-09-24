module zen_sampler_core #(
  parameter int COEFF_LANES = zen_accel_pkg::SAMPLE_COEFF_LANES,
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int MAX_SAMPLE_BYTES = zen_accel_pkg::SAMPLE_MAX_BYTES
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start,
  input  logic [7:0]  cmd,
  input  logic [1:0]  profile_id_i,
  input  logic [31:0] cfg,
  input  logic [31:0] len,
  input  logic [2:0]  buf_r_sel,
  output logic [zen_accel_pkg::SEEDBUF_ADDR_W-1:0] seed_rd_addr,
  input  logic [7:0]  seed_rd_data,
  output logic        vec_out_valid,
  output logic signed [NTT_N*COEFF_W-1:0] vec_out_data,
  output logic        busy,
  output logic        done,
  output logic        error
);

  import zen_accel_pkg::*;

  typedef enum logic [2:0] {
    ST_IDLE,
    ST_PREP,
    ST_READ_SEED,
    ST_DECODE,
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
  logic seed_xof_start;
  logic seed_xof_byte_valid;
  logic [7:0] seed_xof_byte_data;
  logic seed_xof_busy;
  logic seed_xof_done;
  logic seed_xof_error;
  logic [31:0] active_n;
  integer idx;

  function automatic int limited_profile_n(input logic [1:0] profile_id);
    int profile_n_raw;
    begin
      profile_n_raw = profile_n(profile_id);
      if (profile_n_raw > NTT_N) begin
        limited_profile_n = NTT_N;
      end else begin
        limited_profile_n = profile_n_raw;
      end
    end
  endfunction

  function automatic logic [SEEDBUF_ADDR_W-1:0] get_sample_bytes(
    input logic [1:0] profile_id,
    input logic [7:0] cmd_i
  );
    int sample_bytes_raw;
    begin
      sample_bytes_raw = 0;
      get_sample_bytes = '0;
      unique case (profile_id)
        PROFILE_SWIFT128: begin
          case (cmd_i)
            CMD_SAMPLE_F: sample_bytes_raw = 128;
            CMD_SAMPLE_G: sample_bytes_raw = 320;
            CMD_SAMPLE_S: sample_bytes_raw = 448;
            CMD_SAMPLE_E: sample_bytes_raw = 256;
            default:      sample_bytes_raw = 0;
          endcase
        end
        PROFILE_SWIFT256: begin
          case (cmd_i)
            CMD_SAMPLE_F: sample_bytes_raw = 384;
            CMD_SAMPLE_G: sample_bytes_raw = 512;
            CMD_SAMPLE_S: sample_bytes_raw = 256;
            CMD_SAMPLE_E: sample_bytes_raw = 256;
            default:      sample_bytes_raw = 0;
          endcase
        end
        default: begin
          case (cmd_i)
            CMD_SAMPLE_F: sample_bytes_raw = 1280;
            CMD_SAMPLE_G: sample_bytes_raw = 1280;
            CMD_SAMPLE_S: sample_bytes_raw = 768;
            CMD_SAMPLE_E: sample_bytes_raw = 768;
            default:      sample_bytes_raw = 0;
          endcase
        end
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
      get_sample_bytes_cur = get_sample_bytes(profile_id_i, canonical_sample_cmd(profile_id_i, cmd_i));
    end
  endfunction

  assign active_n = limited_profile_n(profile_id_i);
  assign cmd_cur = canonical_sample_cmd(profile_id_i, cmd);

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
      t1 = bit_unpack_at(base_idx, coeff_idx + active_n);
      t2 = bit_unpack_at(base_idx, coeff_idx + 2 * active_n);
      ternary1_8_coeff = (t0 - t1) * t2;
    end
  endfunction

  function automatic logic signed [15:0] ternary3_16_coeff(input integer coeff_idx, input integer base_idx);
    logic signed [15:0] t0, t1, t2, t3;
    begin
      t0 = bit_unpack_at(base_idx, coeff_idx);
      t1 = bit_unpack_at(base_idx, coeff_idx + active_n);
      t2 = bit_unpack_at(base_idx, coeff_idx + 2 * active_n);
      t3 = bit_unpack_at(base_idx, coeff_idx + 3 * active_n);
      ternary3_16_coeff = (t0 & t1) - (t2 & t3);
    end
  endfunction

  function automatic logic signed [15:0] ternary3_32_coeff(input integer coeff_idx, input integer base_idx);
    logic signed [15:0] t0, t1, t2, t3, t4;
    begin
      t0 = bit_unpack_at(base_idx, coeff_idx);
      t1 = bit_unpack_at(base_idx, coeff_idx + active_n);
      t2 = bit_unpack_at(base_idx, coeff_idx + 2 * active_n);
      t3 = bit_unpack_at(base_idx, coeff_idx + 3 * active_n);
      t4 = bit_unpack_at(base_idx, coeff_idx + 4 * active_n);
      ternary3_32_coeff = ((t0 & t1) - (t2 & t3)) * t4;
    end
  endfunction

  function automatic logic signed [15:0] sample_coeff(
    input logic [7:0] cmd_i,
    input integer coeff_idx
  );
    logic signed [15:0] coeff;
    begin
      coeff = 16'sd0;
      unique case (profile_id_i)
        PROFILE_SWIFT128: begin
          case (cmd_i)
            CMD_SAMPLE_F: coeff = cbd1_coeff(coeff_idx, 0);
            CMD_SAMPLE_G: coeff = cbd1_coeff(coeff_idx, 0) + ternary1_8_coeff(coeff_idx, 128);
            CMD_SAMPLE_S: coeff = cbd1_coeff(coeff_idx, 0) + ternary3_32_coeff(coeff_idx, 128);
            CMD_SAMPLE_E: coeff = cbd2_coeff(coeff_idx, 0);
            default:      coeff = 16'sd0;
          endcase
        end
        PROFILE_SWIFT256: begin
          case (cmd_i)
            CMD_SAMPLE_F: coeff = ternary1_8_coeff(coeff_idx, 0);
            CMD_SAMPLE_G: coeff = ternary3_16_coeff(coeff_idx, 0);
            CMD_SAMPLE_S: coeff = cbd1_coeff(coeff_idx, 0);
            CMD_SAMPLE_E: coeff = cbd1_coeff(coeff_idx, 0);
            default:      coeff = 16'sd0;
          endcase
        end
        default: begin
          case (cmd_i)
            CMD_SAMPLE_F: coeff = ternary3_32_coeff(coeff_idx, 0);
            CMD_SAMPLE_G: coeff = ternary3_32_coeff(coeff_idx, 0);
            CMD_SAMPLE_S: coeff = ternary1_8_coeff(coeff_idx, 0);
            CMD_SAMPLE_E: coeff = ternary1_8_coeff(coeff_idx, 0);
            default:      coeff = 16'sd0;
          endcase
        end
      endcase
      sample_coeff = coeff;
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
      unique case (profile_id_i)
        PROFILE_SWIFT128: begin
          case (cmd_i)
            CMD_SAMPLE_F: req = (4 * (coeff_idx / 16)) + 4;
            CMD_SAMPLE_G: begin
              req_a = (4 * (coeff_idx / 16)) + 4;
              req_b = 128 + ((coeff_idx + 2 * active_n) >> 3) + 1;
              req = (req_a > req_b) ? req_a : req_b;
            end
            CMD_SAMPLE_S: begin
              req_a = (4 * (coeff_idx / 16)) + 4;
              req_b = 128 + ((coeff_idx + 4 * active_n) >> 3) + 1;
              req = (req_a > req_b) ? req_a : req_b;
            end
            CMD_SAMPLE_E: req = (4 * (coeff_idx / 8)) + 4;
            default:      req = '0;
          endcase
        end
        PROFILE_SWIFT256: begin
          case (cmd_i)
            CMD_SAMPLE_F: req = ((coeff_idx + 2 * active_n) >> 3) + 1;
            CMD_SAMPLE_G: req = ((coeff_idx + 3 * active_n) >> 3) + 1;
            CMD_SAMPLE_S: req = (4 * (coeff_idx / 16)) + 4;
            CMD_SAMPLE_E: req = (4 * (coeff_idx / 16)) + 4;
            default:      req = '0;
          endcase
        end
        default: begin
          case (cmd_i)
            CMD_SAMPLE_F: req = ((coeff_idx + 4 * active_n) >> 3) + 1;
            CMD_SAMPLE_G: req = ((coeff_idx + 4 * active_n) >> 3) + 1;
            CMD_SAMPLE_S: req = ((coeff_idx + 2 * active_n) >> 3) + 1;
            CMD_SAMPLE_E: req = ((coeff_idx + 2 * active_n) >> 3) + 1;
            default:      req = '0;
          endcase
        end
      endcase
      sample_required_bytes = req;
    end
  endfunction

  assign valid_cmd = sample_cmd_valid(profile_id_i, cmd);

  always_comb begin
    if (coeff_ptr >= active_n) begin
      coeff_last_idx = coeff_ptr;
      coeff_required_bytes = '0;
      can_decode_batch = 1'b0;
    end else begin
      if ((coeff_ptr + COEFF_LANES) >= active_n) begin
        coeff_last_idx = active_n - 1;
      end else begin
        coeff_last_idx = coeff_ptr + COEFF_LANES - 1;
      end
      coeff_required_bytes = sample_required_bytes(cmd_reg, coeff_last_idx);
      can_decode_batch = vec_mode_active && (seed_loaded_bytes >= coeff_required_bytes);
    end
  end

  zen_seed_xof_core #(
    .MAX_BYTES(MAX_SAMPLE_BYTES)
  ) u_seed_xof_core (
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
      for (idx = 0; idx < MAX_SAMPLE_BYTES; idx++) begin
`ifdef VERILATOR
        seed_cache[idx] = 8'h00;
`else
        seed_cache[idx] <= 8'h00;
`endif
      end
    end else begin
      state <= state_n;
      vec_out_valid <= (state_n == ST_DONE) && vec_mode_active;

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
            vec_out_data <= '0;
          end else if (start && !valid_cmd) begin
            vec_mode_active <= 1'b0;
            cmd_reg <= cmd_cur;
          end
        end
        ST_PREP: begin
          seed_ptr <= '0;
          seed_loaded_bytes <= '0;
          coeff_ptr <= '0;
          vec_out_data <= '0;
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
            for (idx = 0; idx < COEFF_LANES; idx++) begin
              if ((coeff_ptr + idx) < active_n) begin
                vec_out_data[(coeff_ptr + idx) * COEFF_W +: COEFF_W] <= sample_coeff(cmd_reg, coeff_ptr + idx);
              end
            end
            if (coeff_ptr + COEFF_LANES < active_n) begin
              coeff_ptr <= coeff_ptr + COEFF_LANES;
            end
          end
        end
        ST_DECODE: begin
          if (can_decode_batch) begin
            for (idx = 0; idx < COEFF_LANES; idx++) begin
              if ((coeff_ptr + idx) < active_n) begin
                vec_out_data[(coeff_ptr + idx) * COEFF_W +: COEFF_W] <= sample_coeff(cmd_reg, coeff_ptr + idx);
              end
            end
            if (coeff_ptr + COEFF_LANES < active_n) begin
              coeff_ptr <= coeff_ptr + COEFF_LANES;
            end
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
          if (can_decode_batch && (coeff_ptr + COEFF_LANES >= active_n)) begin
            state_n = ST_DONE;
          end else begin
            state_n = ST_DECODE;
          end
        end
      end
      ST_DECODE: begin
        if (can_decode_batch && (coeff_ptr + COEFF_LANES >= active_n)) state_n = ST_DONE;
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
