module zen_seed_xof_core (
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  input  logic [7:0] sample_cmd,
  input  logic [31:0] cfg,
  input  logic [15:0] req_bytes,
  output zen_accel_pkg::zen_seed_addr_t seed_rd_addr,
  input  logic [7:0] seed_rd_data,
  output logic byte_valid,
  output logic [7:0] byte_data,
  output logic busy,
  output logic done,
  output logic error
);

  import zen_accel_pkg::*;
  localparam int MAX_BYTES = SAMPLE_MAX_BYTES;

  localparam int RAW_SEED_BYTES = zen_swift_profile_pkg::SWIFT_SEED_LEN_BYTES;

  localparam logic [31:0] SM3_IV0 = 32'h7380_166f;
  localparam logic [31:0] SM3_IV1 = 32'h4914_b2b9;
  localparam logic [31:0] SM3_IV2 = 32'h1724_42d7;
  localparam logic [31:0] SM3_IV3 = 32'hda8a_0600;
  localparam logic [31:0] SM3_IV4 = 32'ha96f_30bc;
  localparam logic [31:0] SM3_IV5 = 32'h1631_38aa;
  localparam logic [31:0] SM3_IV6 = 32'he38d_ee4d;
  localparam logic [31:0] SM3_IV7 = 32'hb0fb_0e4e;
  localparam logic [31:0] SM3_FIXED_LEN_BITS = 32'd552;

  typedef enum logic [3:0] {
    ST_IDLE,
    ST_REPLAY,
    ST_RAW_LOAD,
    ST_RAW_INIT,
    ST_RAW_SCHED,
    ST_RAW_ROUND,
    ST_RAW_OUTPUT,
    ST_DONE,
    ST_ERROR
  } state_t;

  state_t state, state_n;

  logic valid_cmd;
  logic [SEEDBUF_ADDR_W-1:0] seed_base;
  logic [15:0] req_bytes_reg;
  logic [15:0] produced_bytes;
  logic [7:0] nonce_reg;
  logic [6:0] seed_load_ptr;
  logic seed_cache_hit;
  logic raw_seed_match;
  logic prefix_cache_valid;
  logic prefix_ready;
  logic raw_block_sel;
  logic [31:0] counter_reg;
  logic [6:0] sched_idx;
  logic [5:0] round_idx;
  logic [4:0] digest_ptr;
  logic [7:0] digest_bytes [0:31];
  logic [7:0] raw_seed_cache [0:RAW_SEED_BYTES-1];
  logic [7:0] prefix_seed_cache [0:RAW_SEED_BYTES-1];
  logic [31:0] w_mem [0:67];

  logic [31:0] cv_a, cv_b, cv_c, cv_d, cv_e, cv_f, cv_g, cv_h;
  logic [31:0] prefix_cv_a, prefix_cv_b, prefix_cv_c, prefix_cv_d;
  logic [31:0] prefix_cv_e, prefix_cv_f, prefix_cv_g, prefix_cv_h;
  logic [31:0] a, b, c, d, e, f, g, h;

  logic [255:0] round_state1, round_state2, round_state3, round_state4;
  logic [31:0] round_next_a, round_next_b, round_next_c, round_next_d;
  logic [31:0] round_next_e, round_next_f, round_next_g, round_next_h;
  logic [31:0] round_cv0, round_cv1, round_cv2, round_cv3;
  logic [31:0] round_cv4, round_cv5, round_cv6, round_cv7;
  logic [31:0] sched_w0, sched_w1, sched_w2, sched_w3;

  integer idx;

  function automatic logic [31:0] rotl32(
    input logic [31:0] x,
    input integer shamt
  );
    integer s;
    begin
      s = shamt & 31;
      if (s == 0) begin
        rotl32 = x;
      end else begin
        rotl32 = (x << s) | (x >> (32 - s));
      end
    end
  endfunction

  function automatic logic [31:0] p0(input logic [31:0] x);
    begin
      p0 = x ^ rotl32(x, 9) ^ rotl32(x, 17);
    end
  endfunction

  function automatic logic [31:0] p1(input logic [31:0] x);
    begin
      p1 = x ^ rotl32(x, 15) ^ rotl32(x, 23);
    end
  endfunction

  function automatic logic [31:0] sm3_sched_word(
    input logic [31:0] w_m16,
    input logic [31:0] w_m9,
    input logic [31:0] w_m3,
    input logic [31:0] w_m13,
    input logic [31:0] w_m6
  );
    begin
      sm3_sched_word = p1(w_m16 ^ w_m9 ^ rotl32(w_m3, 15)) ^
                       rotl32(w_m13, 7) ^
                       w_m6;
    end
  endfunction

  function automatic logic [31:0] ff_word(
    input logic [31:0] x,
    input logic [31:0] y,
    input logic [31:0] z,
    input integer round
  );
    begin
      if (round < 16) begin
        ff_word = x ^ y ^ z;
      end else begin
        ff_word = (x & y) | (x & z) | (y & z);
      end
    end
  endfunction

  function automatic logic [31:0] gg_word(
    input logic [31:0] x,
    input logic [31:0] y,
    input logic [31:0] z,
    input integer round
  );
    begin
      if (round < 16) begin
        gg_word = x ^ y ^ z;
      end else begin
        gg_word = ((y ^ z) & x) ^ z;
      end
    end
  endfunction

  function automatic logic [31:0] tj_word(input integer round);
    begin
      if (round < 16) begin
        tj_word = 32'h79cc_4519;
      end else begin
        tj_word = 32'h7a87_9d8a;
      end
    end
  endfunction

  function automatic logic [31:0] raw_block_word(
    input logic block_sel_i,
    input integer word_idx,
    input logic [31:0] counter_i,
    input logic [7:0] nonce_i
  );
    integer base_idx;
    begin
      if (!block_sel_i) begin
        base_idx = word_idx * 4;
        raw_block_word = {
          raw_seed_cache[base_idx + 0],
          raw_seed_cache[base_idx + 1],
          raw_seed_cache[base_idx + 2],
          raw_seed_cache[base_idx + 3]
        };
      end else begin
        case (word_idx)
          0: raw_block_word = {nonce_i, counter_i[31:24], counter_i[23:16], counter_i[15:8]};
          1: raw_block_word = {counter_i[7:0], 8'h80, 16'h0000};
          15: raw_block_word = SM3_FIXED_LEN_BITS;
          default: raw_block_word = 32'h0000_0000;
        endcase
      end
    end
  endfunction

  function automatic logic [255:0] sm3_round_step(
    input logic [255:0] state_i,
    input integer round_i,
    input logic [31:0] wj_i,
    input logic [31:0] wj4_i
  );
    logic [31:0] a_i, b_i, c_i, d_i, e_i, f_i, g_i, h_i;
    logic [31:0] ss1_i, ss2_i, tt1_i, tt2_i;
    logic [31:0] next_a_i, next_b_i, next_c_i, next_d_i;
    logic [31:0] next_e_i, next_f_i, next_g_i, next_h_i;
    begin
      a_i = state_i[255:224];
      b_i = state_i[223:192];
      c_i = state_i[191:160];
      d_i = state_i[159:128];
      e_i = state_i[127:96];
      f_i = state_i[95:64];
      g_i = state_i[63:32];
      h_i = state_i[31:0];

      ss1_i = rotl32(rotl32(a_i, 12) + e_i + rotl32(tj_word(round_i), round_i), 7);
      ss2_i = ss1_i ^ rotl32(a_i, 12);
      tt1_i = ff_word(a_i, b_i, c_i, round_i) + d_i + ss2_i + (wj_i ^ wj4_i);
      tt2_i = gg_word(e_i, f_i, g_i, round_i) + h_i + ss1_i + wj_i;

      next_a_i = tt1_i;
      next_b_i = a_i;
      next_c_i = rotl32(b_i, 9);
      next_d_i = c_i;
      next_e_i = p0(tt2_i);
      next_f_i = e_i;
      next_g_i = rotl32(f_i, 19);
      next_h_i = g_i;

      sm3_round_step = {
        next_a_i, next_b_i, next_c_i, next_d_i,
        next_e_i, next_f_i, next_g_i, next_h_i
      };
    end
  endfunction

  assign valid_cmd = (sample_cmd == CMD_SAMPLE_F) || (sample_cmd == CMD_SAMPLE_G) ||
                     (sample_cmd == CMD_SAMPLE_S) || (sample_cmd == CMD_SAMPLE_E) ||
                     (sample_cmd == CMD_SAMPLE_GF) || (sample_cmd == CMD_SAMPLE_SE);

  assign seed_cache_hit = prefix_cache_valid && raw_seed_match;

  always_comb begin
    if (state == ST_REPLAY) begin
      seed_rd_addr = seed_base + produced_bytes[SEEDBUF_ADDR_W-1:0];
    end else if (state == ST_RAW_LOAD) begin
      seed_rd_addr = seed_base + SEEDBUF_ADDR_W'(seed_load_ptr);
    end else begin
      seed_rd_addr = seed_base;
    end
  end

  always_comb begin
    round_state1 = sm3_round_step({a, b, c, d, e, f, g, h}, round_idx, w_mem[round_idx], w_mem[round_idx + 4]);
    round_state2 = sm3_round_step(round_state1, round_idx + 1, w_mem[round_idx + 1], w_mem[round_idx + 5]);
    round_state3 = sm3_round_step(round_state2, round_idx + 2, w_mem[round_idx + 2], w_mem[round_idx + 6]);
    round_state4 = sm3_round_step(round_state3, round_idx + 3, w_mem[round_idx + 3], w_mem[round_idx + 7]);

    round_next_a = round_state4[255:224];
    round_next_b = round_state4[223:192];
    round_next_c = round_state4[191:160];
    round_next_d = round_state4[159:128];
    round_next_e = round_state4[127:96];
    round_next_f = round_state4[95:64];
    round_next_g = round_state4[63:32];
    round_next_h = round_state4[31:0];

    round_cv0 = cv_a ^ round_state4[255:224];
    round_cv1 = cv_b ^ round_state4[223:192];
    round_cv2 = cv_c ^ round_state4[191:160];
    round_cv3 = cv_d ^ round_state4[159:128];
    round_cv4 = cv_e ^ round_state4[127:96];
    round_cv5 = cv_f ^ round_state4[95:64];
    round_cv6 = cv_g ^ round_state4[63:32];
    round_cv7 = cv_h ^ round_state4[31:0];
  end

  always_comb begin
    sched_w0 = sm3_sched_word(
      w_mem[sched_idx - 16],
      w_mem[sched_idx - 9],
      w_mem[sched_idx - 3],
      w_mem[sched_idx - 13],
      w_mem[sched_idx - 6]
    );
    sched_w1 = sm3_sched_word(
      w_mem[sched_idx - 15],
      w_mem[sched_idx - 8],
      w_mem[sched_idx - 2],
      w_mem[sched_idx - 12],
      w_mem[sched_idx - 5]
    );
    sched_w2 = sm3_sched_word(
      w_mem[sched_idx - 14],
      w_mem[sched_idx - 7],
      w_mem[sched_idx - 1],
      w_mem[sched_idx - 11],
      w_mem[sched_idx - 4]
    );
    sched_w3 = sm3_sched_word(
      w_mem[sched_idx - 13],
      w_mem[sched_idx - 6],
      sched_w0,
      w_mem[sched_idx - 10],
      w_mem[sched_idx - 3]
    );
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= ST_IDLE;
      seed_base <= '0;
      req_bytes_reg <= '0;
      produced_bytes <= '0;
      nonce_reg <= '0;
      seed_load_ptr <= '0;
      raw_seed_match <= 1'b0;
      prefix_cache_valid <= 1'b0;
      prefix_ready <= 1'b0;
      raw_block_sel <= 1'b0;
      counter_reg <= 32'd1;
      sched_idx <= '0;
      round_idx <= '0;
      digest_ptr <= '0;
      cv_a <= SM3_IV0;
      cv_b <= SM3_IV1;
      cv_c <= SM3_IV2;
      cv_d <= SM3_IV3;
      cv_e <= SM3_IV4;
      cv_f <= SM3_IV5;
      cv_g <= SM3_IV6;
      cv_h <= SM3_IV7;
      prefix_cv_a <= SM3_IV0;
      prefix_cv_b <= SM3_IV1;
      prefix_cv_c <= SM3_IV2;
      prefix_cv_d <= SM3_IV3;
      prefix_cv_e <= SM3_IV4;
      prefix_cv_f <= SM3_IV5;
      prefix_cv_g <= SM3_IV6;
      prefix_cv_h <= SM3_IV7;
      a <= SM3_IV0;
      b <= SM3_IV1;
      c <= SM3_IV2;
      d <= SM3_IV3;
      e <= SM3_IV4;
      f <= SM3_IV5;
      g <= SM3_IV6;
      h <= SM3_IV7;
    end else begin
      state <= state_n;

      case (state)
        ST_IDLE: begin
          if (start) begin
            seed_base <= cfg[SEEDBUF_ADDR_W-1:0];
            req_bytes_reg <= req_bytes;
            produced_bytes <= 16'd0;
            nonce_reg <= cfg[23:16];
            seed_load_ptr <= 7'd0;
            raw_seed_match <= prefix_cache_valid;
            prefix_ready <= 1'b0;
            raw_block_sel <= 1'b0;
            counter_reg <= 32'd1;
            sched_idx <= 7'd0;
            round_idx <= 6'd0;
            digest_ptr <= 5'd0;
          end
        end

        ST_REPLAY: begin
          if (produced_bytes + 16'd1 < req_bytes_reg) begin
            produced_bytes <= produced_bytes + 16'd1;
          end
        end

        ST_RAW_LOAD: begin
          raw_seed_cache[seed_load_ptr] <= seed_rd_data;
          raw_seed_match <= raw_seed_match && (seed_rd_data == prefix_seed_cache[seed_load_ptr]);
          if (seed_load_ptr + 7'd1 < RAW_SEED_BYTES) begin
            seed_load_ptr <= seed_load_ptr + 7'd1;
          end
        end

        ST_RAW_INIT: begin
          if (!prefix_ready && !seed_cache_hit) begin
            cv_a <= SM3_IV0;
            cv_b <= SM3_IV1;
            cv_c <= SM3_IV2;
            cv_d <= SM3_IV3;
            cv_e <= SM3_IV4;
            cv_f <= SM3_IV5;
            cv_g <= SM3_IV6;
            cv_h <= SM3_IV7;
            a <= SM3_IV0;
            b <= SM3_IV1;
            c <= SM3_IV2;
            d <= SM3_IV3;
            e <= SM3_IV4;
            f <= SM3_IV5;
            g <= SM3_IV6;
            h <= SM3_IV7;
          end else begin
            prefix_ready <= 1'b1;
            raw_block_sel <= 1'b1;
            cv_a <= prefix_cv_a;
            cv_b <= prefix_cv_b;
            cv_c <= prefix_cv_c;
            cv_d <= prefix_cv_d;
            cv_e <= prefix_cv_e;
            cv_f <= prefix_cv_f;
            cv_g <= prefix_cv_g;
            cv_h <= prefix_cv_h;
            a <= prefix_cv_a;
            b <= prefix_cv_b;
            c <= prefix_cv_c;
            d <= prefix_cv_d;
            e <= prefix_cv_e;
            f <= prefix_cv_f;
            g <= prefix_cv_g;
            h <= prefix_cv_h;
          end
          for (idx = 0; idx < 16; idx = idx + 1) begin
`ifdef VERILATOR
            w_mem[idx] = raw_block_word(prefix_ready || seed_cache_hit, idx, counter_reg, nonce_reg);
`else
            w_mem[idx] <= raw_block_word(prefix_ready || seed_cache_hit, idx, counter_reg, nonce_reg);
`endif
          end
          sched_idx <= 7'd16;
          round_idx <= 6'd0;
        end

        ST_RAW_SCHED: begin
          w_mem[sched_idx + 0] <= sched_w0;
          w_mem[sched_idx + 1] <= sched_w1;
          w_mem[sched_idx + 2] <= sched_w2;
          w_mem[sched_idx + 3] <= sched_w3;
          if (sched_idx < 7'd64) begin
            sched_idx <= sched_idx + 7'd4;
          end
        end

        ST_RAW_ROUND: begin
          a <= round_next_a;
          b <= round_next_b;
          c <= round_next_c;
          d <= round_next_d;
          e <= round_next_e;
          f <= round_next_f;
          g <= round_next_g;
          h <= round_next_h;

          if (round_idx == 6'd60) begin
            if (!prefix_ready) begin
              prefix_ready <= 1'b1;
              raw_block_sel <= 1'b1;
              prefix_cache_valid <= 1'b1;
              prefix_cv_a <= round_cv0;
              prefix_cv_b <= round_cv1;
              prefix_cv_c <= round_cv2;
              prefix_cv_d <= round_cv3;
              prefix_cv_e <= round_cv4;
              prefix_cv_f <= round_cv5;
              prefix_cv_g <= round_cv6;
              prefix_cv_h <= round_cv7;
              for (idx = 0; idx < RAW_SEED_BYTES; idx = idx + 1) begin
`ifdef VERILATOR
                prefix_seed_cache[idx] = raw_seed_cache[idx];
`else
                prefix_seed_cache[idx] <= raw_seed_cache[idx];
`endif
              end
            end else begin
              raw_block_sel <= 1'b1;
              digest_bytes[0]  <= round_cv0[31:24];
              digest_bytes[1]  <= round_cv0[23:16];
              digest_bytes[2]  <= round_cv0[15:8];
              digest_bytes[3]  <= round_cv0[7:0];
              digest_bytes[4]  <= round_cv1[31:24];
              digest_bytes[5]  <= round_cv1[23:16];
              digest_bytes[6]  <= round_cv1[15:8];
              digest_bytes[7]  <= round_cv1[7:0];
              digest_bytes[8]  <= round_cv2[31:24];
              digest_bytes[9]  <= round_cv2[23:16];
              digest_bytes[10] <= round_cv2[15:8];
              digest_bytes[11] <= round_cv2[7:0];
              digest_bytes[12] <= round_cv3[31:24];
              digest_bytes[13] <= round_cv3[23:16];
              digest_bytes[14] <= round_cv3[15:8];
              digest_bytes[15] <= round_cv3[7:0];
              digest_bytes[16] <= round_cv4[31:24];
              digest_bytes[17] <= round_cv4[23:16];
              digest_bytes[18] <= round_cv4[15:8];
              digest_bytes[19] <= round_cv4[7:0];
              digest_bytes[20] <= round_cv5[31:24];
              digest_bytes[21] <= round_cv5[23:16];
              digest_bytes[22] <= round_cv5[15:8];
              digest_bytes[23] <= round_cv5[7:0];
              digest_bytes[24] <= round_cv6[31:24];
              digest_bytes[25] <= round_cv6[23:16];
              digest_bytes[26] <= round_cv6[15:8];
              digest_bytes[27] <= round_cv6[7:0];
              digest_bytes[28] <= round_cv7[31:24];
              digest_bytes[29] <= round_cv7[23:16];
              digest_bytes[30] <= round_cv7[15:8];
              digest_bytes[31] <= round_cv7[7:0];
              digest_ptr <= 5'd0;
            end
          end else begin
            round_idx <= round_idx + 6'd4;
          end
        end

        ST_RAW_OUTPUT: begin
          if (produced_bytes + 16'd1 < req_bytes_reg) begin
            produced_bytes <= produced_bytes + 16'd1;
            if (digest_ptr == 5'd31) begin
              digest_ptr <= 5'd0;
              counter_reg <= counter_reg + 32'd1;
            end else begin
              digest_ptr <= digest_ptr + 5'd1;
            end
          end
        end

        default: begin
        end
      endcase
    end
  end

  always_comb begin
    state_n = state;
    byte_valid = 1'b0;
    byte_data = seed_rd_data;
    busy = 1'b1;
    done = 1'b0;
    error = 1'b0;

    unique case (state)
      ST_IDLE: begin
        busy = 1'b0;
        if (start) begin
          if (!valid_cmd || (req_bytes == 0) || (req_bytes > MAX_BYTES)) begin
            state_n = ST_ERROR;
          end else if (cfg[31]) begin
            state_n = ST_RAW_LOAD;
          end else begin
            state_n = ST_REPLAY;
          end
        end
      end

      ST_REPLAY: begin
        byte_valid = 1'b1;
        if (produced_bytes + 16'd1 >= req_bytes_reg) begin
          state_n = ST_DONE;
        end
      end

      ST_RAW_LOAD: begin
        if (seed_load_ptr + 7'd1 >= RAW_SEED_BYTES) begin
          state_n = ST_RAW_INIT;
        end
      end

      ST_RAW_INIT: begin
        state_n = ST_RAW_SCHED;
      end

      ST_RAW_SCHED: begin
        if (sched_idx == 7'd64) begin
          state_n = ST_RAW_ROUND;
        end
      end

      ST_RAW_ROUND: begin
        if (round_idx == 6'd60) begin
          if (!prefix_ready) begin
            state_n = ST_RAW_INIT;
          end else begin
            state_n = ST_RAW_OUTPUT;
          end
        end
      end

      ST_RAW_OUTPUT: begin
        byte_valid = 1'b1;
        byte_data = digest_bytes[digest_ptr];
        if (produced_bytes + 16'd1 >= req_bytes_reg) begin
          state_n = ST_DONE;
        end else if (digest_ptr == 5'd31) begin
          state_n = ST_RAW_INIT;
        end
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
