module zen_binary_core #(
  parameter int XOR_LANES = zen_accel_pkg::BINARY_LANES,
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COL_FACTOR = ((NTT_N >= 2048) ? 8 :
                              ((NTT_N > 512) ? 4 : 2)),
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int ADDR_W = zen_accel_pkg::ADDR_W
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start,
  input  logic [7:0]  cmd,
  input  logic [1:0]  profile_id_i,
  input  logic [31:0] cfg,
  input  logic [31:0] len,
  input  logic [2:0]  buf_a_sel,
  input  logic [2:0]  buf_b_sel,
  input  logic [2:0]  buf_r_sel,
  input  logic        vec_in_valid,
  input  logic signed [NTT_N*COEFF_W-1:0] vec_a_data,
  input  logic signed [NTT_N*COEFF_W-1:0] vec_b_data,
  output logic        vec_out_valid,
  output logic signed [NTT_N*COEFF_W-1:0] vec_r_data,
  output logic        row_out_valid,
  output logic [ADDR_W-1:0] row_out_idx,
  output logic signed [(16*COEFF_W)-1:0] row_out_data,
  output logic        busy,
  output logic        done,
  output logic        error
);

  import zen_accel_pkg::*;
  localparam int ZEN_Q2 = ZEN_Q / 2;
  localparam int ZEN_MSG_LIFT_VAL = (ZEN_Q + 1) / 2;
  localparam int LOCAL_N2 = NTT_N / 2;
  localparam int LOCAL_N4 = NTT_N / 4;
  localparam int ZEN_MSG_BYTES = LOCAL_N4 / 8;
  localparam int BIN_COL_LANES = ((XOR_LANES * COL_FACTOR) > LOCAL_N2) ? LOCAL_N2
                                                                        : (XOR_LANES * COL_FACTOR);
  localparam int BINARY_XOR_PHASE_LANES = (XOR_LANES > 4) ? 4 : XOR_LANES;
  localparam int BINARY_XOR_PHASES = (XOR_LANES + BINARY_XOR_PHASE_LANES - 1) /
                                     BINARY_XOR_PHASE_LANES;
  localparam int BINARY_PHASE_W = (BINARY_XOR_PHASES <= 1) ? 1 : $clog2(BINARY_XOR_PHASES);
  // Keep the binary chunk fanout bounded; the outer state machine time-multiplexes columns.
  localparam int BINARY_CHUNK_COL_LANES = (((2 * BINARY_XOR_PHASE_LANES) > BIN_COL_LANES) ?
                                           BIN_COL_LANES : (2 * BINARY_XOR_PHASE_LANES));
  localparam int BINARY_COL_PHASES = (BIN_COL_LANES + BINARY_CHUNK_COL_LANES - 1) /
                                     BINARY_CHUNK_COL_LANES;
  localparam int BINARY_COL_PHASE_W = (BINARY_COL_PHASES <= 1) ? 1 :
                                      $clog2(BINARY_COL_PHASES);
  localparam int MAX_PROFILE_MSG_BYTES = MAX_ZEN_N / 32;
  localparam logic [1:0] BINARY_CHUNK_OP_R2         = 2'd0;
  localparam logic [1:0] BINARY_CHUNK_OP_R2_FROM_T0 = 2'd1;
  localparam logic [1:0] BINARY_CHUNK_OP_DECODE     = 2'd2;

  typedef enum logic [4:0] {
    ST_IDLE,
    ST_PREP,
    ST_RUN_R2,
    ST_RUN_FAST_INV,
    ST_RUN_DECODE,
    ST_RUN_CT_DECOMP,
    ST_RUN_MSG_UNPACK,
    ST_RUN_MSG_PACK,
    ST_RUN_T0,
    ST_RUN_A_MOD2,
    ST_RUN_POLY_ADD,
    ST_RUN_ENC_POST,
    ST_RUN_DEC_T0,
    ST_RUN_DEC_R2,
    ST_RUN_DEC_DECODE,
    ST_RUN_DEC_PACK,
    ST_DONE,
    ST_ERROR
  } state_t;

  state_t state, state_n;
  logic [15:0] cycle_count;
  logic [ADDR_W:0] row_ptr;
  logic [ADDR_W:0] col_ptr;
  logic valid_cmd;
  logic active_profile_supported_calc;
  logic vec_mode_active;
  logic [7:0] cmd_reg;
  logic [1:0] profile_id_reg;
  logic signed [NTT_N*COEFF_W-1:0] vec_a_data_reg;
  logic signed [NTT_N*COEFF_W-1:0] vec_b_data_reg;
  logic signed [NTT_N*COEFF_W-1:0] fast_inv_result_vec;
  logic fast_inv_start;
  logic fast_inv_done;
  logic fast_inv_row_out_valid;
  logic [ADDR_W-1:0] fast_inv_row_out_idx;
  logic signed [(16*COEFF_W)-1:0] fast_inv_row_out_data;
  logic signed [NTT_N*COEFF_W-1:0] dec_t0_vec;
  logic signed [LOCAL_N4*COEFF_W-1:0] dec_r2_vec;
  logic [1:0] binary_chunk_op;
  logic signed [NTT_N*COEFF_W-1:0] binary_chunk_acc_vec;
  logic signed [NTT_N*COEFF_W-1:0] binary_chunk_sel_vec;
  logic signed [BINARY_CHUNK_COL_LANES*COEFF_W-1:0] binary_chunk_data;
  int unsigned binary_chunk_active_ring_n;
  int unsigned binary_chunk_active_acc_n;
  int unsigned active_n_calc;
  int unsigned active_n2_calc;
  int unsigned active_n4_calc;
  int unsigned active_msg_bytes_calc;
  int unsigned active_col_factor_calc;
  int unsigned active_bin_col_lanes_calc;
  int unsigned active_n;
  int unsigned active_n2;
  int unsigned active_n4;
  int unsigned active_msg_bytes;
  int unsigned active_bin_col_lanes;
  integer idx;
  logic [BINARY_PHASE_W-1:0] xor_phase;
  logic [BINARY_COL_PHASE_W-1:0] col_phase;
  logic [ADDR_W:0] binary_phase_row_base;
  logic [ADDR_W:0] binary_phase_col_base;
  logic binary_phase_last;
  logic binary_col_phase_last;

  function automatic int profile_binary_col_factor(input logic [1:0] profile_id);
    begin
      if (profile_n(profile_id) >= 2048) begin
        profile_binary_col_factor = 8;
      end else if (profile_n(profile_id) > 512) begin
        profile_binary_col_factor = 4;
      end else begin
        profile_binary_col_factor = 2;
      end
    end
  endfunction

  function automatic logic signed [15:0] montgomery_reduce(input logic signed [31:0] a);
    logic signed [15:0] u;
    logic signed [31:0] t;
    begin
      u = a * (-16'sd767);
      t = a - (u * 16'sd769);
      montgomery_reduce = t >>> 16;
    end
  endfunction

  function automatic logic signed [15:0] vec_a_coeff(input integer coeff_idx);
    begin
      vec_a_coeff = vec_a_data_reg[coeff_idx*COEFF_W +: COEFF_W];
    end
  endfunction

  function automatic logic signed [15:0] vec_b_coeff(input integer coeff_idx);
    begin
      vec_b_coeff = vec_b_data_reg[coeff_idx*COEFF_W +: COEFF_W];
    end
  endfunction

  function automatic logic signed [15:0] vec_r_coeff(input integer coeff_idx);
    begin
      vec_r_coeff = vec_r_data[coeff_idx*COEFF_W +: COEFF_W];
    end
  endfunction

  function automatic logic signed [15:0] dec_t0_coeff(input integer coeff_idx);
    begin
      dec_t0_coeff = dec_t0_vec[coeff_idx*COEFF_W +: COEFF_W];
    end
  endfunction

  function automatic logic signed [15:0] dec_r2_coeff(input integer coeff_idx);
    begin
      dec_r2_coeff = dec_r2_vec[coeff_idx*COEFF_W +: COEFF_W];
    end
  endfunction

  function automatic logic signed [15:0] t0_transform_coeff_a(
    input integer coeff_idx
  );
    logic signed [15:0] lhs;
    logic signed [15:0] rhs;
    begin
      if (coeff_idx < active_n2) begin
        lhs = vec_a_coeff(coeff_idx + active_n2);
        rhs = vec_a_coeff(coeff_idx);
      end else begin
        lhs = vec_a_coeff(coeff_idx - active_n2);
        rhs = -vec_a_coeff(coeff_idx);
      end
      t0_transform_coeff_a = montgomery_reduce((lhs - rhs) * 16'sd171);
    end
  endfunction

  function automatic logic signed [15:0] a_mod2_coeff_a(
    input integer coeff_idx
  );
    begin
      if (coeff_idx < active_n2) begin
        a_mod2_coeff_a = (vec_a_coeff(coeff_idx) & 16'sd1) ^
                         (vec_a_coeff(coeff_idx + active_n2) & 16'sd1);
      end else begin
        a_mod2_coeff_a = 16'sd0;
      end
    end
  endfunction

  function automatic logic signed [15:0] ct_decomp_coeff_a(
    input integer coeff_idx
  );
    logic signed [15:0] coeff_word;
    logic [7:0] packed_byte;
    logic [31:0] scaled;
    begin
      coeff_word = vec_a_coeff(coeff_idx);
      packed_byte = coeff_word[7:0];
      scaled = (((packed_byte * ZEN_Q) + 32'd128) >> 8);
      ct_decomp_coeff_a = $signed(scaled[15:0]);
    end
  endfunction

  function automatic logic signed [15:0] msg_unpack_coeff_a(
    input integer coeff_idx
  );
    integer byte_idx;
    integer bit_idx;
    integer src_idx;
    logic signed [15:0] coeff_word;
    logic bit_val;
    begin
      if (coeff_idx < active_n) begin
        src_idx = coeff_idx & (active_n4 - 1);
        byte_idx = src_idx >>> 3;
        bit_idx = src_idx & 7;
        coeff_word = vec_a_coeff(byte_idx);
        bit_val = coeff_word[bit_idx];
        if (bit_val) begin
          msg_unpack_coeff_a = $signed(ZEN_MSG_LIFT_VAL);
        end else begin
          msg_unpack_coeff_a = 16'sd0;
        end
      end else begin
        msg_unpack_coeff_a = 16'sd0;
      end
    end
  endfunction

  function automatic logic signed [15:0] msg_pack_coeff_a(
    input integer coeff_idx
  );
    integer base_idx;
    integer bit_idx;
    logic [7:0] packed_byte;
    logic signed [15:0] coeff_word;
    begin
      if (coeff_idx < active_msg_bytes) begin
        base_idx = coeff_idx << 3;
        packed_byte = 8'd0;
        for (bit_idx = 0; bit_idx < 8; bit_idx++) begin
          coeff_word = vec_a_coeff(base_idx + bit_idx);
          packed_byte[bit_idx] = coeff_word[0];
        end
        msg_pack_coeff_a = $signed({8'd0, packed_byte});
      end else begin
        msg_pack_coeff_a = 16'sd0;
      end
    end
  endfunction

  function automatic logic signed [15:0] poly_add_coeff_ab(
    input integer coeff_idx
  );
    begin
      poly_add_coeff_ab = vec_a_coeff(coeff_idx) + vec_b_coeff(coeff_idx);
    end
  endfunction

  function automatic logic signed [15:0] enc_postproc_coeff_ab(
    input integer coeff_idx
  );
    logic signed [16:0] accum;
    logic signed [15:0] reduced;
    begin
      accum = vec_a_coeff(coeff_idx) + vec_b_coeff(coeff_idx);
      reduced = montgomery_reduce(accum * 16'sd171);
      enc_postproc_coeff_ab = reduced + ((reduced >>> 15) & 16'sd769);
    end
  endfunction

  assign fast_inv_start = (state == ST_PREP) && (cmd_reg == CMD_FAST_INV);

  zen_binary_fast_inv_core #(
    .NTT_N   (NTT_N),
    .COEFF_W (COEFF_W)
  ) fast_inv_core (
    .clk(clk),
    .rst_n(rst_n),
    .start_i(fast_inv_start),
    .profile_id_i(profile_id_reg),
    .vec_a_data(vec_a_data_reg),
    .done_o(fast_inv_done),
    .vec_r_data(fast_inv_result_vec),
    .row_out_valid_o(fast_inv_row_out_valid),
    .row_out_idx_o(fast_inv_row_out_idx),
    .row_out_data_o(fast_inv_row_out_data)
  );

  zen_binary_chunk_core #(
    .NTT_N         (NTT_N),
    .COEFF_W       (COEFF_W),
    .XOR_LANES     (BINARY_XOR_PHASE_LANES),
    .BIN_COL_LANES (BINARY_CHUNK_COL_LANES),
    .ROW_ADDR_W    (ADDR_W + 1),
    .COL_ADDR_W    (ADDR_W + 1)
  ) binary_chunk_core (
    .op_mode_i        (binary_chunk_op),
    .vec_acc_data     (binary_chunk_acc_vec),
    .vec_sel_data     (binary_chunk_sel_vec),
    .vec_src_data     (vec_b_data_reg),
    .active_ring_n_i  (binary_chunk_active_ring_n),
    .active_acc_n_i   (binary_chunk_active_acc_n),
    .row_base         (binary_phase_row_base),
    .col_base         (binary_phase_col_base),
    .chunk_data       (binary_chunk_data)
  );

  assign valid_cmd = (cmd == CMD_R2_MUL) || (cmd == CMD_FAST_INV) ||
                     (cmd == CMD_DECODE_HELPER) || (cmd == CMD_T0_TRANSFORM) ||
                     (cmd == CMD_A_MOD2) || (cmd == CMD_POLY_ADD) ||
                     (cmd == CMD_ENC_POSTPROC) || (cmd == CMD_DEC_POSTPROC) ||
                     (cmd == CMD_CT_DECOMP) || (cmd == CMD_MSG_UNPACK) ||
                     (cmd == CMD_MSG_PACK);

  always_comb begin
    active_n_calc = profile_n(profile_id_i);
    active_n2_calc = profile_n2(profile_id_i);
    active_n4_calc = profile_n4(profile_id_i);
    active_msg_bytes_calc = profile_msg_bytes(profile_id_i);
    active_col_factor_calc = profile_binary_col_factor(profile_id_i);
    if ((XOR_LANES * active_col_factor_calc) > active_n2_calc) begin
      active_bin_col_lanes_calc = active_n2_calc;
    end else begin
      active_bin_col_lanes_calc = XOR_LANES * active_col_factor_calc;
    end

    active_profile_supported_calc = profile_valid(profile_id_i) &&
                                    (active_n_calc <= NTT_N) &&
                                    (active_n2_calc <= (NTT_N / 2)) &&
                                    (active_n4_calc <= (NTT_N / 4)) &&
                                    (active_msg_bytes_calc <= MAX_PROFILE_MSG_BYTES) &&
                                    (active_bin_col_lanes_calc <= BIN_COL_LANES);
  end

  always_comb begin
    binary_phase_row_base = row_ptr + (xor_phase * BINARY_XOR_PHASE_LANES);
    binary_phase_col_base = col_ptr + (col_phase * BINARY_CHUNK_COL_LANES);
    binary_phase_last = (xor_phase == (BINARY_XOR_PHASES - 1));
    binary_col_phase_last = ((col_phase + 1) * BINARY_CHUNK_COL_LANES >= active_bin_col_lanes);
    binary_chunk_op = BINARY_CHUNK_OP_R2;
    binary_chunk_acc_vec = '0;
    binary_chunk_sel_vec = '0;
    binary_chunk_active_ring_n = '0;
    binary_chunk_active_acc_n = '0;

    case (state)
      ST_RUN_R2: begin
        binary_chunk_op = BINARY_CHUNK_OP_R2;
        binary_chunk_acc_vec = vec_r_data;
        binary_chunk_sel_vec = vec_a_data_reg;
        binary_chunk_active_ring_n = active_n2;
        binary_chunk_active_acc_n = active_n2;
      end
      ST_RUN_DECODE: begin
        binary_chunk_op = BINARY_CHUNK_OP_DECODE;
        binary_chunk_acc_vec = vec_r_data;
        binary_chunk_sel_vec = vec_a_data_reg;
        binary_chunk_active_ring_n = active_n4;
        binary_chunk_active_acc_n = active_n2;
      end
      ST_RUN_DEC_R2: begin
        binary_chunk_op = BINARY_CHUNK_OP_R2_FROM_T0;
        binary_chunk_acc_vec[LOCAL_N4*COEFF_W-1:0] = dec_r2_vec;
        binary_chunk_sel_vec = dec_t0_vec;
        binary_chunk_active_ring_n = active_n2;
        binary_chunk_active_acc_n = active_n4;
      end
      ST_RUN_DEC_DECODE: begin
        binary_chunk_op = BINARY_CHUNK_OP_DECODE;
        binary_chunk_acc_vec = vec_r_data;
        binary_chunk_sel_vec = dec_t0_vec;
        binary_chunk_active_ring_n = active_n4;
        binary_chunk_active_acc_n = active_n4;
      end
      default: begin
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= ST_IDLE;
      cycle_count <= '0;
      row_ptr <= '0;
      col_ptr <= '0;
      xor_phase <= '0;
      col_phase <= '0;
      vec_mode_active <= 1'b0;
      cmd_reg <= CMD_NOP;
      profile_id_reg <= PROFILE_SWIFT128;
      active_n <= '0;
      active_n2 <= '0;
      active_n4 <= '0;
      active_msg_bytes <= '0;
      active_bin_col_lanes <= '0;
      vec_a_data_reg <= '0;
      vec_b_data_reg <= '0;
      dec_t0_vec <= '0;
      dec_r2_vec <= '0;
      vec_r_data <= '0;
      vec_out_valid <= 1'b0;
    end else begin
      state <= state_n;
      vec_out_valid <= (state_n == ST_DONE) && vec_mode_active;

      case (state)
      ST_IDLE: begin
        cycle_count <= '0;
        xor_phase <= '0;
        col_phase <= '0;
        if (start) begin
            row_ptr <= '0;
            col_ptr <= '0;
            vec_mode_active <= vec_in_valid;
            cmd_reg <= cmd;
            profile_id_reg <= profile_id_i;
            active_n <= active_n_calc;
            active_n2 <= active_n2_calc;
            active_n4 <= active_n4_calc;
            active_msg_bytes <= active_msg_bytes_calc;
            active_bin_col_lanes <= active_bin_col_lanes_calc;
            vec_a_data_reg <= vec_a_data;
            vec_b_data_reg <= vec_b_data;
          end
        end
        ST_PREP: begin
          cycle_count <= '0;
          row_ptr <= '0;
          col_ptr <= '0;
          xor_phase <= '0;
          col_phase <= '0;
          vec_r_data <= '0;
          if (cmd_reg == CMD_DEC_POSTPROC) begin
            dec_t0_vec <= '0;
            dec_r2_vec <= '0;
          end
        end
        ST_RUN_R2: begin
          cycle_count <= cycle_count + 16'd1;
          for (idx = 0; idx < BINARY_CHUNK_COL_LANES; idx++) begin
            if ((((col_phase * BINARY_CHUNK_COL_LANES) + idx) < active_bin_col_lanes) &&
                ((binary_phase_col_base + idx) < active_n2)) begin
              vec_r_data[(binary_phase_col_base + idx) * COEFF_W +: COEFF_W] <=
                binary_chunk_data[idx * COEFF_W +: COEFF_W];
            end
          end
          if (!binary_col_phase_last) begin
            col_phase <= col_phase + 1'b1;
          end else begin
            col_phase <= '0;
            if (!binary_phase_last) begin
              xor_phase <= xor_phase + 1'b1;
            end else begin
              xor_phase <= '0;
              if (col_ptr + active_bin_col_lanes < active_n2) begin
                col_ptr <= col_ptr + active_bin_col_lanes;
              end else begin
                col_ptr <= '0;
                if (row_ptr + XOR_LANES < active_n2) begin
                  row_ptr <= row_ptr + XOR_LANES;
                end
              end
            end
          end
        end
        ST_RUN_FAST_INV: begin
          cycle_count <= cycle_count + 16'd1;
          if (fast_inv_done) begin
            vec_r_data <= fast_inv_result_vec;
          end
        end
        ST_RUN_DECODE: begin
          cycle_count <= cycle_count + 16'd1;
          for (idx = 0; idx < BINARY_CHUNK_COL_LANES; idx++) begin
            if ((((col_phase * BINARY_CHUNK_COL_LANES) + idx) < active_bin_col_lanes) &&
                ((binary_phase_col_base + idx) < active_n2)) begin
              vec_r_data[(binary_phase_col_base + idx) * COEFF_W +: COEFF_W] <=
                binary_chunk_data[idx * COEFF_W +: COEFF_W];
            end
          end
          if (!binary_col_phase_last) begin
            col_phase <= col_phase + 1'b1;
          end else begin
            col_phase <= '0;
            if (!binary_phase_last) begin
              xor_phase <= xor_phase + 1'b1;
            end else begin
              xor_phase <= '0;
              if (col_ptr + active_bin_col_lanes < active_n2) begin
                col_ptr <= col_ptr + active_bin_col_lanes;
              end else begin
                col_ptr <= '0;
                if (row_ptr + XOR_LANES < active_n4) begin
                  row_ptr <= row_ptr + XOR_LANES;
                end
              end
            end
          end
        end
        ST_RUN_CT_DECOMP: begin
          cycle_count <= cycle_count + 16'd1;
          for (idx = 0; idx < XOR_LANES; idx++) begin
            if ((col_ptr + idx) < active_n) begin
              vec_r_data[(col_ptr + idx) * COEFF_W +: COEFF_W] <=
                ct_decomp_coeff_a(col_ptr + idx);
            end
          end
          if (col_ptr + XOR_LANES < active_n) begin
            col_ptr <= col_ptr + XOR_LANES;
          end
        end
        ST_RUN_MSG_UNPACK: begin
          cycle_count <= cycle_count + 16'd1;
          for (idx = 0; idx < XOR_LANES; idx++) begin
            if ((col_ptr + idx) < active_n) begin
              vec_r_data[(col_ptr + idx) * COEFF_W +: COEFF_W] <=
                msg_unpack_coeff_a(col_ptr + idx);
            end
          end
          if (col_ptr + XOR_LANES < active_n) begin
            col_ptr <= col_ptr + XOR_LANES;
          end
        end
        ST_RUN_MSG_PACK: begin
          cycle_count <= cycle_count + 16'd1;
          for (idx = 0; idx < XOR_LANES; idx++) begin
            if ((col_ptr + idx) < active_msg_bytes) begin
              vec_r_data[(col_ptr + idx) * COEFF_W +: COEFF_W] <=
                msg_pack_coeff_a(col_ptr + idx);
            end
          end
          if (col_ptr + XOR_LANES < active_msg_bytes) begin
            col_ptr <= col_ptr + XOR_LANES;
          end
        end
        ST_RUN_T0: begin
          cycle_count <= cycle_count + 16'd1;
          for (idx = 0; idx < XOR_LANES; idx++) begin
            if ((col_ptr + idx) < active_n) begin
              vec_r_data[(col_ptr + idx) * COEFF_W +: COEFF_W] <=
                t0_transform_coeff_a(col_ptr + idx);
            end
          end
          if (col_ptr + XOR_LANES < active_n) begin
            col_ptr <= col_ptr + XOR_LANES;
          end
        end
        ST_RUN_A_MOD2: begin
          cycle_count <= cycle_count + 16'd1;
          for (idx = 0; idx < XOR_LANES; idx++) begin
            if ((col_ptr + idx) < active_n) begin
              vec_r_data[(col_ptr + idx) * COEFF_W +: COEFF_W] <=
                a_mod2_coeff_a(col_ptr + idx);
            end
          end
          if (col_ptr + XOR_LANES < active_n) begin
            col_ptr <= col_ptr + XOR_LANES;
          end
        end
        ST_RUN_POLY_ADD: begin
          cycle_count <= cycle_count + 16'd1;
          for (idx = 0; idx < XOR_LANES; idx++) begin
            if ((col_ptr + idx) < active_n) begin
              vec_r_data[(col_ptr + idx) * COEFF_W +: COEFF_W] <=
                poly_add_coeff_ab(col_ptr + idx);
            end
          end
          if (col_ptr + XOR_LANES < active_n) begin
            col_ptr <= col_ptr + XOR_LANES;
          end
        end
        ST_RUN_ENC_POST: begin
          cycle_count <= cycle_count + 16'd1;
          for (idx = 0; idx < XOR_LANES; idx++) begin
            if ((col_ptr + idx) < active_n) begin
              vec_r_data[(col_ptr + idx) * COEFF_W +: COEFF_W] <=
                enc_postproc_coeff_ab(col_ptr + idx);
            end
          end
          if (col_ptr + XOR_LANES < active_n) begin
            col_ptr <= col_ptr + XOR_LANES;
          end
        end
        ST_RUN_DEC_T0: begin
          cycle_count <= cycle_count + 16'd1;
          for (idx = 0; idx < XOR_LANES; idx++) begin
            if ((col_ptr + idx) < active_n) begin
              dec_t0_vec[(col_ptr + idx) * COEFF_W +: COEFF_W] <=
                t0_transform_coeff_a(col_ptr + idx);
            end
          end
          if (col_ptr + XOR_LANES < active_n) begin
            col_ptr <= col_ptr + XOR_LANES;
          end else begin
            col_ptr <= '0;
            row_ptr <= '0;
            xor_phase <= '0;
            col_phase <= '0;
          end
        end
        ST_RUN_DEC_R2: begin
          cycle_count <= cycle_count + 16'd1;
          for (idx = 0; idx < BINARY_CHUNK_COL_LANES; idx++) begin
            if ((((col_phase * BINARY_CHUNK_COL_LANES) + idx) < active_bin_col_lanes) &&
                ((binary_phase_col_base + idx) < active_n4)) begin
              dec_r2_vec[(binary_phase_col_base + idx) * COEFF_W +: COEFF_W] <=
                binary_chunk_data[idx * COEFF_W +: COEFF_W];
            end
          end
          if (!binary_col_phase_last) begin
            col_phase <= col_phase + 1'b1;
          end else begin
            col_phase <= '0;
            if (!binary_phase_last) begin
              xor_phase <= xor_phase + 1'b1;
            end else begin
              xor_phase <= '0;
              if (col_ptr + active_bin_col_lanes < active_n4) begin
                col_ptr <= col_ptr + active_bin_col_lanes;
              end else begin
                col_ptr <= '0;
                if (row_ptr + XOR_LANES < active_n2) begin
                  row_ptr <= row_ptr + XOR_LANES;
                end else begin
                  row_ptr <= '0;
                end
              end
            end
          end
        end
        ST_RUN_DEC_DECODE: begin
          cycle_count <= cycle_count + 16'd1;
          for (idx = 0; idx < BINARY_CHUNK_COL_LANES; idx++) begin
            if ((((col_phase * BINARY_CHUNK_COL_LANES) + idx) < active_bin_col_lanes) &&
                ((binary_phase_col_base + idx) < active_n4)) begin
              vec_r_data[(binary_phase_col_base + idx) * COEFF_W +: COEFF_W] <=
                binary_chunk_data[idx * COEFF_W +: COEFF_W];
            end
          end
          if (!binary_col_phase_last) begin
            col_phase <= col_phase + 1'b1;
          end else begin
            col_phase <= '0;
            if (!binary_phase_last) begin
              xor_phase <= xor_phase + 1'b1;
            end else begin
              xor_phase <= '0;
              if (col_ptr + active_bin_col_lanes < active_n4) begin
                col_ptr <= col_ptr + active_bin_col_lanes;
              end else begin
                col_ptr <= '0;
                if (row_ptr + XOR_LANES < active_n4) begin
                  row_ptr <= row_ptr + XOR_LANES;
                end else begin
                  row_ptr <= '0;
                end
              end
            end
          end
        end
        ST_RUN_DEC_PACK: begin
          cycle_count <= cycle_count + 16'd1;
          for (idx = 0; idx < BINARY_CHUNK_COL_LANES; idx++) begin
            if ((((col_phase * BINARY_CHUNK_COL_LANES) + idx) < active_bin_col_lanes) &&
                ((binary_phase_col_base + idx) < active_n4)) begin
              vec_r_data[(binary_phase_col_base + idx) * COEFF_W +: COEFF_W] <=
                vec_r_data[(binary_phase_col_base + idx) * COEFF_W +: COEFF_W] ^
                dec_r2_vec[(binary_phase_col_base + idx) * COEFF_W +: COEFF_W];
            end
          end
          if (!binary_col_phase_last) begin
            col_phase <= col_phase + 1'b1;
          end else begin
            col_phase <= '0;
            if (col_ptr + active_bin_col_lanes < active_n4) begin
              col_ptr <= col_ptr + active_bin_col_lanes;
            end
          end
        end
        ST_DONE: begin
          vec_mode_active <= 1'b0;
          xor_phase <= '0;
          col_phase <= '0;
        end
        ST_ERROR: begin
          vec_mode_active <= 1'b0;
          xor_phase <= '0;
          col_phase <= '0;
        end
        default: begin
        end
      endcase
    end
  end

  always_comb begin
    row_out_valid = 1'b0;
    row_out_idx = '0;
    row_out_data = '0;
    if ((state == ST_RUN_FAST_INV) && (cmd_reg == CMD_FAST_INV)) begin
      row_out_valid = fast_inv_row_out_valid;
      row_out_idx = fast_inv_row_out_idx;
      row_out_data = fast_inv_row_out_data;
    end
  end

  always_comb begin
    state_n = state;
    busy = 1'b1;
    done = 1'b0;
    error = 1'b0;

    unique case (state)
      ST_IDLE: begin
        busy = 1'b0;
        if (start) begin
          if (!valid_cmd || !active_profile_supported_calc) begin
            state_n = ST_ERROR;
          end else begin
            state_n = ST_PREP;
          end
        end
      end
      ST_PREP: begin
        if (cmd_reg == CMD_R2_MUL) begin
          state_n = ST_RUN_R2;
        end else if (cmd_reg == CMD_FAST_INV) begin
          state_n = ST_RUN_FAST_INV;
        end else if (cmd_reg == CMD_CT_DECOMP) begin
          state_n = ST_RUN_CT_DECOMP;
        end else if (cmd_reg == CMD_MSG_UNPACK) begin
          state_n = ST_RUN_MSG_UNPACK;
        end else if (cmd_reg == CMD_MSG_PACK) begin
          state_n = ST_RUN_MSG_PACK;
        end else if (cmd_reg == CMD_T0_TRANSFORM) begin
          state_n = ST_RUN_T0;
        end else if (cmd_reg == CMD_A_MOD2) begin
          state_n = ST_RUN_A_MOD2;
        end else if (cmd_reg == CMD_POLY_ADD) begin
          state_n = ST_RUN_POLY_ADD;
        end else if (cmd_reg == CMD_ENC_POSTPROC) begin
          state_n = ST_RUN_ENC_POST;
        end else if (cmd_reg == CMD_DEC_POSTPROC) begin
          state_n = ST_RUN_DEC_T0;
        end else begin
          state_n = ST_RUN_DECODE;
        end
      end
      ST_RUN_R2: begin
        if (binary_col_phase_last &&
            binary_phase_last &&
            (row_ptr + XOR_LANES >= active_n2) &&
            (col_ptr + active_bin_col_lanes >= active_n2)) state_n = ST_DONE;
      end
      ST_RUN_FAST_INV: begin
        if (fast_inv_done) state_n = ST_DONE;
      end
      ST_RUN_DECODE: begin
        if (binary_col_phase_last &&
            binary_phase_last &&
            (row_ptr + XOR_LANES >= active_n4) &&
            (col_ptr + active_bin_col_lanes >= active_n2)) state_n = ST_DONE;
      end
      ST_RUN_CT_DECOMP: begin
        if (col_ptr + XOR_LANES >= active_n) state_n = ST_DONE;
      end
      ST_RUN_MSG_UNPACK: begin
        if (col_ptr + XOR_LANES >= active_n) state_n = ST_DONE;
      end
      ST_RUN_MSG_PACK: begin
        if (col_ptr + XOR_LANES >= active_msg_bytes) state_n = ST_DONE;
      end
      ST_RUN_T0: begin
        if (col_ptr + XOR_LANES >= active_n) state_n = ST_DONE;
      end
      ST_RUN_A_MOD2: begin
        if (col_ptr + XOR_LANES >= active_n) state_n = ST_DONE;
      end
      ST_RUN_POLY_ADD: begin
        if (col_ptr + XOR_LANES >= active_n) state_n = ST_DONE;
      end
      ST_RUN_ENC_POST: begin
        if (col_ptr + XOR_LANES >= active_n) state_n = ST_DONE;
      end
      ST_RUN_DEC_T0: begin
        if (col_ptr + XOR_LANES >= active_n) state_n = ST_RUN_DEC_R2;
      end
      ST_RUN_DEC_R2: begin
        if (binary_col_phase_last &&
            binary_phase_last &&
            (row_ptr + XOR_LANES >= active_n2) &&
            (col_ptr + active_bin_col_lanes >= active_n4)) state_n = ST_RUN_DEC_DECODE;
      end
      ST_RUN_DEC_DECODE: begin
        if (binary_col_phase_last &&
            binary_phase_last &&
            (row_ptr + XOR_LANES >= active_n4) &&
            (col_ptr + active_bin_col_lanes >= active_n4)) state_n = ST_RUN_DEC_PACK;
      end
      ST_RUN_DEC_PACK: begin
        if (binary_col_phase_last &&
            (col_ptr + active_bin_col_lanes >= active_n4)) state_n = ST_DONE;
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

module zen_binary_chunk_core #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int XOR_LANES = ((zen_accel_pkg::BINARY_LANES > 4) ? 4 : zen_accel_pkg::BINARY_LANES),
  parameter int BIN_COL_LANES = zen_accel_pkg::BINARY_LANES,
  parameter int ROW_ADDR_W = $clog2(NTT_N + 1),
  parameter int COL_ADDR_W = $clog2(NTT_N + 1)
) (
  input  logic [1:0]                        op_mode_i,
  input  logic signed [NTT_N*COEFF_W-1:0]   vec_acc_data,
  input  logic signed [NTT_N*COEFF_W-1:0]   vec_sel_data,
  input  logic signed [NTT_N*COEFF_W-1:0]   vec_src_data,
  input  int unsigned                       active_ring_n_i,
  input  int unsigned                       active_acc_n_i,
  input  logic [ROW_ADDR_W-1:0]             row_base,
  input  logic [COL_ADDR_W-1:0]             col_base,
  output logic signed [BIN_COL_LANES*COEFF_W-1:0] chunk_data
);

  import zen_accel_pkg::*;
  localparam logic [1:0] BINARY_CHUNK_OP_R2         = 2'd0;
  localparam logic [1:0] BINARY_CHUNK_OP_R2_FROM_T0 = 2'd1;
  localparam logic [1:0] BINARY_CHUNK_OP_DECODE     = 2'd2;
  localparam int DECODE_Q2 = ZEN_Q / 2;

  function automatic logic coeff_bit_at(
    input logic signed [NTT_N*COEFF_W-1:0] flat_vec,
    input integer coeff_idx
  );
    begin
      coeff_bit_at = flat_vec[coeff_idx*COEFF_W];
    end
  endfunction

  function automatic logic signed [COEFF_W-1:0] coeff_word_at(
    input logic signed [NTT_N*COEFF_W-1:0] flat_vec,
    input integer coeff_idx
  );
    begin
      coeff_word_at = flat_vec[coeff_idx*COEFF_W +: COEFF_W];
    end
  endfunction

  always_comb begin
    integer col_idx;
    integer lane_idx;
    integer row_idx;
    integer sel_idx;
    integer src_idx;
    integer c0;
    integer c1;
    integer c2;
    integer c3;
    integer idx0;
    integer idx1;
    logic acc_bit;
    logic parity_bit;

    acc_bit = 1'b0;
    row_idx = 0;
    sel_idx = 0;
    src_idx = 0;
    c0 = 0;
    c1 = 0;
    c2 = 0;
    c3 = 0;
    idx0 = 0;
    idx1 = 0;
    parity_bit = 1'b0;
    chunk_data = '0;
    for (col_idx = 0; col_idx < BIN_COL_LANES; col_idx++) begin
      if (($unsigned(col_base) + col_idx) < active_acc_n_i) begin
        acc_bit = coeff_bit_at(vec_acc_data, $unsigned(col_base) + col_idx);
        for (lane_idx = 0; lane_idx < XOR_LANES; lane_idx++) begin
          row_idx = $unsigned(row_base) + lane_idx;
          if (row_idx < active_ring_n_i) begin
            unique case (op_mode_i)
              BINARY_CHUNK_OP_R2: begin
                if (coeff_bit_at(vec_sel_data, row_idx) != 0) begin
                  src_idx = (($unsigned(col_base) + col_idx) + active_ring_n_i - row_idx) &
                            (active_ring_n_i - 1);
                  acc_bit = acc_bit ^ coeff_bit_at(vec_src_data, src_idx);
                end
              end
              BINARY_CHUNK_OP_R2_FROM_T0: begin
                if ((coeff_bit_at(vec_sel_data, row_idx) ^
                     coeff_bit_at(vec_sel_data, row_idx + active_ring_n_i)) != 0) begin
                  src_idx = (($unsigned(col_base) + col_idx) + active_ring_n_i - row_idx) &
                            (active_ring_n_i - 1);
                  acc_bit = acc_bit ^ coeff_bit_at(vec_src_data, src_idx);
                end
              end
              BINARY_CHUNK_OP_DECODE: begin
                parity_bit = coeff_bit_at(vec_sel_data, row_idx) ^
                             coeff_bit_at(vec_sel_data, row_idx + active_ring_n_i) ^
                             coeff_bit_at(vec_sel_data, row_idx + (2 * active_ring_n_i)) ^
                             coeff_bit_at(vec_sel_data, row_idx + (3 * active_ring_n_i));

                c0 = $signed(coeff_word_at(vec_sel_data, row_idx));
                c1 = $signed(coeff_word_at(vec_sel_data, row_idx + active_ring_n_i));
                c2 = $signed(coeff_word_at(vec_sel_data, row_idx + (2 * active_ring_n_i)));
                c3 = $signed(coeff_word_at(vec_sel_data, row_idx + (3 * active_ring_n_i)));

                if (c0 >= 0) c0 = DECODE_Q2 - c0; else c0 = DECODE_Q2 + c0;
                if (c1 >= 0) c1 = DECODE_Q2 - c1; else c1 = DECODE_Q2 + c1;
                if (c2 >= 0) c2 = DECODE_Q2 - c2; else c2 = DECODE_Q2 + c2;
                if (c3 >= 0) c3 = DECODE_Q2 - c3; else c3 = DECODE_Q2 + c3;

                if (c0 > c2) c0 = c2;
                if (c1 > c3) c1 = c3;

                if (parity_bit != 0) begin
                  idx0 = row_idx;
                  idx1 = row_idx + active_ring_n_i;
                end else begin
                  idx0 = 0;
                  idx1 = 0;
                end

                if (c0 <= c1) sel_idx = idx0;
                else sel_idx = idx1;
                src_idx = (($unsigned(col_base) + col_idx) + (2 * active_ring_n_i) - sel_idx) &
                          ((2 * active_ring_n_i) - 1);
                acc_bit = acc_bit ^ coeff_bit_at(vec_src_data, src_idx);
              end
              default: begin
              end
            endcase
          end
        end
        if (COEFF_W > 1) begin
          chunk_data[col_idx * COEFF_W +: COEFF_W] = {{(COEFF_W - 1){1'b0}}, acc_bit};
        end else begin
          chunk_data[col_idx * COEFF_W +: COEFF_W] = acc_bit;
        end
      end
    end
  end

endmodule

module zen_binary_r2_core #(
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int XOR_LANES = ((zen_accel_pkg::BINARY_LANES > 4) ? 4 : zen_accel_pkg::BINARY_LANES),
  parameter int RING_N = zen_accel_pkg::ZEN_N2,
  parameter int ACC_N = zen_accel_pkg::ZEN_N2,
  parameter int BIN_COL_LANES = zen_accel_pkg::BINARY_LANES,
  parameter int SRC_N = zen_accel_pkg::ZEN_N,
  parameter int ROW_ADDR_W = $clog2(RING_N + 1),
  parameter int COL_ADDR_W = $clog2(ACC_N + 1)
) (
  input  logic signed [ACC_N*COEFF_W-1:0] vec_acc_data,
  input  logic signed [RING_N*COEFF_W-1:0] vec_sel_data,
  input  logic signed [SRC_N*COEFF_W-1:0] vec_src_data,
  input  logic [31:0] active_ring_n_i,
  input  logic [31:0] active_acc_n_i,
  input  logic [ROW_ADDR_W-1:0] row_base,
  input  logic [COL_ADDR_W-1:0] col_base,
  output logic signed [BIN_COL_LANES*COEFF_W-1:0] chunk_data
);

  localparam logic [1:0] BINARY_CHUNK_OP_R2 = 2'd0;

  logic signed [SRC_N*COEFF_W-1:0] vec_acc_full;
  logic signed [SRC_N*COEFF_W-1:0] vec_sel_full;

  always_comb begin
    vec_acc_full = '0;
    vec_sel_full = '0;
    vec_acc_full[ACC_N*COEFF_W-1:0] = vec_acc_data;
    vec_sel_full[RING_N*COEFF_W-1:0] = vec_sel_data;
  end

  zen_binary_chunk_core #(
    .NTT_N         (SRC_N),
    .COEFF_W       (COEFF_W),
    .XOR_LANES     (XOR_LANES),
    .BIN_COL_LANES (BIN_COL_LANES),
    .ROW_ADDR_W    (ROW_ADDR_W),
    .COL_ADDR_W    (COL_ADDR_W)
  ) u_binary_chunk_core (
    .op_mode_i       (BINARY_CHUNK_OP_R2),
    .vec_acc_data    (vec_acc_full),
    .vec_sel_data    (vec_sel_full),
    .vec_src_data    (vec_src_data),
    .active_ring_n_i (active_ring_n_i),
    .active_acc_n_i  (active_acc_n_i),
    .row_base        (row_base),
    .col_base        (col_base),
    .chunk_data      (chunk_data)
  );

endmodule

module zen_binary_r2_from_t0_core #(
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int RING_N = zen_accel_pkg::ZEN_N2,
  parameter int ACC_N = zen_accel_pkg::ZEN_N4,
  parameter int SRC_N = zen_accel_pkg::ZEN_N,
  parameter int XOR_LANES = ((zen_accel_pkg::BINARY_LANES > 4) ? 4 : zen_accel_pkg::BINARY_LANES),
  parameter int BIN_COL_LANES = zen_accel_pkg::BINARY_LANES,
  parameter int ROW_ADDR_W = $clog2(RING_N + 1),
  parameter int COL_ADDR_W = $clog2(ACC_N + 1)
) (
  input  logic signed [ACC_N*COEFF_W-1:0] vec_acc_data,
  input  logic signed [(2*RING_N)*COEFF_W-1:0] vec_t0_data,
  input  logic signed [SRC_N*COEFF_W-1:0] vec_src_data,
  input  logic [31:0] active_ring_n_i,
  input  logic [31:0] active_acc_n_i,
  input  logic [ROW_ADDR_W-1:0] row_base,
  input  logic [COL_ADDR_W-1:0] col_base,
  output logic signed [BIN_COL_LANES*COEFF_W-1:0] chunk_data
);

  localparam logic [1:0] BINARY_CHUNK_OP_R2_FROM_T0 = 2'd1;

  logic signed [SRC_N*COEFF_W-1:0] vec_acc_full;
  logic signed [SRC_N*COEFF_W-1:0] vec_sel_full;

  always_comb begin
    vec_acc_full = '0;
    vec_sel_full = '0;
    vec_acc_full[ACC_N*COEFF_W-1:0] = vec_acc_data;
    vec_sel_full[(2*RING_N)*COEFF_W-1:0] = vec_t0_data;
  end

  zen_binary_chunk_core #(
    .NTT_N         (SRC_N),
    .COEFF_W       (COEFF_W),
    .XOR_LANES     (XOR_LANES),
    .BIN_COL_LANES (BIN_COL_LANES),
    .ROW_ADDR_W    (ROW_ADDR_W),
    .COL_ADDR_W    (COL_ADDR_W)
  ) u_binary_chunk_core (
    .op_mode_i       (BINARY_CHUNK_OP_R2_FROM_T0),
    .vec_acc_data    (vec_acc_full),
    .vec_sel_data    (vec_sel_full),
    .vec_src_data    (vec_src_data),
    .active_ring_n_i (active_ring_n_i),
    .active_acc_n_i  (active_acc_n_i),
    .row_base        (row_base),
    .col_base        (col_base),
    .chunk_data      (chunk_data)
  );

endmodule

module zen_binary_decode_core #(
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int XOR_LANES = ((zen_accel_pkg::BINARY_LANES > 4) ? 4 : zen_accel_pkg::BINARY_LANES),
  parameter int RING_N = zen_accel_pkg::ZEN_N4,
  parameter int ACC_N = zen_accel_pkg::ZEN_N2,
  parameter int SRC_N = zen_accel_pkg::ZEN_N,
  parameter int BIN_COL_LANES = zen_accel_pkg::BINARY_LANES,
  parameter int ROW_ADDR_W = $clog2(RING_N + 1),
  parameter int COL_ADDR_W = $clog2(ACC_N + 1)
) (
  input  logic signed [ACC_N*COEFF_W-1:0] vec_acc_data,
  input  logic signed [(4*RING_N)*COEFF_W-1:0] vec_sel4_data,
  input  logic signed [SRC_N*COEFF_W-1:0] vec_src_data,
  input  logic [31:0] active_ring_n_i,
  input  logic [31:0] active_acc_n_i,
  input  logic [ROW_ADDR_W-1:0] row_base,
  input  logic [COL_ADDR_W-1:0] col_base,
  output logic signed [BIN_COL_LANES*COEFF_W-1:0] chunk_data
);

  localparam logic [1:0] BINARY_CHUNK_OP_DECODE = 2'd2;

  logic signed [SRC_N*COEFF_W-1:0] vec_acc_full;
  logic signed [SRC_N*COEFF_W-1:0] vec_sel_full;

  always_comb begin
    vec_acc_full = '0;
    vec_sel_full = '0;
    vec_acc_full[ACC_N*COEFF_W-1:0] = vec_acc_data;
    vec_sel_full[(4*RING_N)*COEFF_W-1:0] = vec_sel4_data;
  end

  zen_binary_chunk_core #(
    .NTT_N         (SRC_N),
    .COEFF_W       (COEFF_W),
    .XOR_LANES     (XOR_LANES),
    .BIN_COL_LANES (BIN_COL_LANES),
    .ROW_ADDR_W    (ROW_ADDR_W),
    .COL_ADDR_W    (COL_ADDR_W)
  ) u_binary_chunk_core (
    .op_mode_i       (BINARY_CHUNK_OP_DECODE),
    .vec_acc_data    (vec_acc_full),
    .vec_sel_data    (vec_sel_full),
    .vec_src_data    (vec_src_data),
    .active_ring_n_i (active_ring_n_i),
    .active_acc_n_i  (active_acc_n_i),
    .row_base        (row_base),
    .col_base        (col_base),
    .chunk_data      (chunk_data)
  );

endmodule

module zen_binary_fast_inv_core #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int ADDR_W = zen_accel_pkg::ADDR_W
) (
  input  logic                             clk,
  input  logic                             rst_n,
  input  logic                             start_i,
  input  logic [1:0]                       profile_id_i,
  input  logic signed [NTT_N*COEFF_W-1:0] vec_a_data,
  output logic                             done_o,
  output logic signed [NTT_N*COEFF_W-1:0] vec_r_data,
  output logic                             row_out_valid_o,
  output logic [ADDR_W-1:0]                row_out_idx_o,
  output logic signed [(16*COEFF_W)-1:0]   row_out_data_o
);

  import zen_accel_pkg::*;

  localparam int FAST_INV_N4 = NTT_N / 4;
  localparam int FAST_INV_CHUNK_LANES = (FAST_INV_N4 >= 32) ? 32 : FAST_INV_N4;
  localparam int FAST_INV_PACK_ROW_COEFFS = 16;

  logic [31:0] init_f_chunk;
  logic [ADDR_W:0] init_f_work_idx;
  logic fast_inv_done_int;
  logic fast_inv_row_out_valid;
  logic [ADDR_W-1:0] fast_inv_row_out_idx;
  logic signed [(FAST_INV_PACK_ROW_COEFFS*COEFF_W)-1:0] fast_inv_row_out_data;
  logic [ADDR_W:0] active_n4_local;

  always_comb begin
    integer lane_idx;
    integer coeff_idx0;
    integer coeff_idx1;
    integer coeff_idx2;
    integer coeff_idx3;

    active_n4_local = FAST_INV_N4;
    if (profile_valid(profile_id_i) && (profile_n4(profile_id_i) < FAST_INV_N4)) begin
      active_n4_local = profile_n4(profile_id_i);
    end

    init_f_chunk = '0;
    for (lane_idx = 0; lane_idx < FAST_INV_CHUNK_LANES; lane_idx++) begin
      coeff_idx0 = $unsigned(init_f_work_idx) + lane_idx;
      coeff_idx1 = coeff_idx0 + active_n4_local;
      coeff_idx2 = coeff_idx0 + (2 * active_n4_local);
      coeff_idx3 = coeff_idx0 + (3 * active_n4_local);
      if (coeff_idx0 < active_n4_local) begin
        init_f_chunk[lane_idx] =
          vec_a_data[coeff_idx0*COEFF_W] ^
          vec_a_data[coeff_idx1*COEFF_W] ^
          vec_a_data[coeff_idx2*COEFF_W] ^
          vec_a_data[coeff_idx3*COEFF_W];
      end
    end
  end

  zen_binary_fast_inv_row_core #(
    .NTT_N   (NTT_N),
    .COEFF_W (COEFF_W)
  ) u_fast_inv_row_core (
    .clk             (clk),
    .rst_n           (rst_n),
    .start_i         (start_i),
    .init_f_chunk_i  (init_f_chunk),
    .done_o          (fast_inv_done_int),
    .init_f_work_idx_o(init_f_work_idx),
    .row_out_valid_o (fast_inv_row_out_valid),
    .row_out_idx_o   (fast_inv_row_out_idx),
    .row_out_data_o  (fast_inv_row_out_data)
  );

  assign row_out_valid_o = fast_inv_row_out_valid;
  assign row_out_idx_o = fast_inv_row_out_idx;
  assign row_out_data_o = fast_inv_row_out_data;

  always_ff @(posedge clk) begin
    integer row_coeff_idx;
    integer coeff_base;
    integer coeff_idx;

    if (!rst_n) begin
      done_o <= 1'b0;
      vec_r_data <= '0;
    end else begin
      done_o <= 1'b0;

      if (start_i) begin
        vec_r_data <= '0;
      end

      if (fast_inv_row_out_valid) begin
        coeff_base = $unsigned(fast_inv_row_out_idx) * FAST_INV_PACK_ROW_COEFFS;
        for (row_coeff_idx = 0; row_coeff_idx < FAST_INV_PACK_ROW_COEFFS; row_coeff_idx++) begin
          coeff_idx = coeff_base + row_coeff_idx;
          if (coeff_idx < FAST_INV_N4) begin
            vec_r_data[coeff_idx*COEFF_W +: COEFF_W] <=
              fast_inv_row_out_data[row_coeff_idx*COEFF_W +: COEFF_W];
          end
        end
      end

      if (fast_inv_done_int) begin
        done_o <= 1'b1;
      end
    end
  end

endmodule
module zen_binary_fast_inv_init_core #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  int unsigned                     active_n4_i,
  input  logic signed [NTT_N*COEFF_W-1:0] vec_a_data,
  output logic [(NTT_N/4)-1:0]            f_vec_o,
  output logic [(NTT_N/4)-1:0]            k_vec_o,
  output logic [(NTT_N/4)-1:0]            f_inv_vec_o
);

  localparam int FAST_INV_N4 = NTT_N / 4;

  logic [FAST_INV_N4-1:0] f_bits;
  logic [FAST_INV_N4-1:0] k_bits;
  logic [FAST_INV_N4-1:0] f_inv_bits;
  logic b0;
  integer i_local;

  always_comb begin
    f_vec_o = '0;
    k_vec_o = '0;
    f_inv_vec_o = '0;
    f_bits = '0;
    k_bits = '0;
    f_inv_bits = '0;
    b0 = 1'b0;

    for (i_local = 0; i_local < FAST_INV_N4; i_local++) begin
      if (i_local < active_n4_i) begin
        f_bits[i_local] =
          vec_a_data[i_local*COEFF_W] ^
          vec_a_data[(i_local + active_n4_i)*COEFF_W] ^
          vec_a_data[(i_local + (2 * active_n4_i))*COEFF_W] ^
          vec_a_data[(i_local + (3 * active_n4_i))*COEFF_W];
      end
    end

    if (active_n4_i != 0) begin
      k_bits[0] = f_bits[0];
      for (i_local = 1; i_local < FAST_INV_N4; i_local++) begin
        if (i_local < active_n4_i) begin
          k_bits[i_local] = f_bits[i_local] ^ k_bits[i_local - 1];
        end
      end

      for (i_local = 0; i_local < FAST_INV_N4; i_local++) begin
        if (i_local < active_n4_i) begin
          b0 = b0 ^ k_bits[i_local];
        end
      end

      for (i_local = 0; i_local < FAST_INV_N4; i_local++) begin
        if (i_local < active_n4_i) begin
          k_bits[i_local] = k_bits[i_local] ^ (b0 & f_bits[i_local]);
        end
      end

      for (i_local = 1; i_local < FAST_INV_N4; i_local++) begin
        if (i_local < active_n4_i) begin
          k_bits[i_local] = k_bits[i_local] ^ k_bits[i_local - 1];
        end
      end

      f_inv_bits[0] = !b0;
      if (FAST_INV_N4 > 1) begin
        f_inv_bits[1] = b0;
      end
    end

    f_vec_o = f_bits;
    k_vec_o = k_bits;
    f_inv_vec_o = f_inv_bits;
  end

endmodule

module zen_binary_fast_inv_stage_core #(
  parameter int FAST_INV_N4 = 512,
  parameter int STAGE_L = 1
) (
  input  int unsigned                           active_n4_i,
  input  int unsigned                           active_n4_log2_i,
  input  logic [FAST_INV_N4-1:0]               f_vec_i,
  input  logic [FAST_INV_N4-1:0]               k_vec_i,
  input  logic [FAST_INV_N4-1:0]               f_inv_vec_i,
  output logic [FAST_INV_N4-1:0]               k_vec_o,
  output logic [FAST_INV_N4-1:0]               f_inv_vec_o
);

  localparam int STAGE_N = (1 << STAGE_L);
  localparam int STAGE_DOUBLE_N = (2 * STAGE_N);
  localparam int STAGE_MAX_STEPS = (FAST_INV_N4 + STAGE_N - 1) / STAGE_N;

  logic [FAST_INV_N4-1:0] k_bits;
  logic [FAST_INV_N4-1:0] f_inv_bits;
  logic [FAST_INV_N4-1:0] tmp_bits;
  logic [FAST_INV_N4-1:0] b_bits;
  logic [FAST_INV_N4-1:0] prod_bits;
  integer i_local;
  integer j_local;
  integer n_local;
  integer src_idx;
  integer step_local;
  integer offset_local;
  integer block_base;

  always_comb begin
    k_bits = k_vec_i;
    f_inv_bits = f_inv_vec_i;
    tmp_bits = '0;
    b_bits = '0;
    prod_bits = '0;
    n_local = 0;
    src_idx = 0;
    block_base = 0;
    offset_local = 0;

    if (STAGE_L < active_n4_log2_i) begin
      n_local = STAGE_N;

      for (i_local = 0; i_local < STAGE_N; i_local++) begin
        if (i_local < active_n4_i) begin
          for (step_local = 0; step_local < STAGE_MAX_STEPS; step_local++) begin
            j_local = i_local + (step_local * n_local);
            if (j_local < active_n4_i) begin
              tmp_bits[i_local] = tmp_bits[i_local] ^ k_bits[j_local];
            end
          end
        end
      end

      for (i_local = 0; i_local < STAGE_N; i_local++) begin
        if (f_inv_bits[i_local]) begin
          for (j_local = 0; j_local < STAGE_N; j_local++) begin
            src_idx = j_local + n_local - i_local;
            if (src_idx >= n_local) begin
              src_idx = src_idx - n_local;
            end
            b_bits[j_local] = b_bits[j_local] ^ tmp_bits[src_idx];
          end
        end
      end

      for (i_local = 0; i_local < STAGE_N; i_local++) begin
        if (b_bits[i_local]) begin
          for (j_local = 0; j_local < FAST_INV_N4; j_local++) begin
            if (j_local < active_n4_i) begin
              if (j_local >= i_local) begin
                src_idx = j_local - i_local;
              end else begin
                src_idx = j_local + active_n4_i - i_local;
              end
              prod_bits[j_local] = prod_bits[j_local] ^ f_vec_i[src_idx];
            end
          end
        end
      end

      for (j_local = 0; j_local < FAST_INV_N4; j_local++) begin
        if (j_local < active_n4_i) begin
          k_bits[j_local] = k_bits[j_local] ^ prod_bits[j_local];
        end
      end

      for (step_local = 1; step_local < STAGE_MAX_STEPS; step_local++) begin
        block_base = step_local * n_local;
        if (block_base < active_n4_i) begin
          for (offset_local = 0; offset_local < STAGE_N; offset_local++) begin
            j_local = block_base + offset_local;
            if (j_local < active_n4_i) begin
              k_bits[j_local] = k_bits[j_local] ^ k_bits[j_local - n_local];
            end
          end
        end
      end

      tmp_bits = '0;
      for (i_local = 0; i_local < STAGE_N; i_local++) begin
        tmp_bits[i_local] = b_bits[i_local];
        if ((i_local + n_local) < FAST_INV_N4) begin
          tmp_bits[i_local + n_local] = b_bits[i_local];
        end
      end
      for (i_local = 0; i_local < STAGE_DOUBLE_N; i_local++) begin
        if (i_local < FAST_INV_N4) begin
          f_inv_bits[i_local] = f_inv_bits[i_local] ^ tmp_bits[i_local];
        end
      end
    end

    k_vec_o = k_bits;
    f_inv_vec_o = f_inv_bits;
  end

endmodule
