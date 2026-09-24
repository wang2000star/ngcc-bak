`ifndef ZEN_PK_SK_SEQ_CORE_SV
`define ZEN_PK_SK_SEQ_CORE_SV

module zen_pk_unpack_seq_core #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int BLOCKS_PER_CYCLE = 1
) (
  input  logic clk,
  input  logic rst_n,
  input  logic start_i,
  input  logic [1:0] profile_id_i,
  input  logic signed [NTT_N*COEFF_W-1:0] pk_bytes_vec_i,
  output logic busy_o,
  output logic done_o,
  output logic signed [NTT_N*COEFF_W-1:0] pk_poly_vec_o,
  output logic [31:0] bytes_consumed_o
);

  import zen_accel_pkg::*;

  logic [31:0] active_n_r;
  logic [31:0] full_blocks_r;
  logic [31:0] tail_coeff_count_r;
  logic [31:0] total_blocks_r;
  logic [31:0] block_idx_r;
  logic [31:0] coeff_base_idx_r;
  logic [31:0] coeff_limit_r;
  logic [31:0] coeff_idx_r;
  logic [63:0] packed_block_r;
  logic        block_active_r;

  logic [63:0] x_work;
  logic [63:0] q_work;
  logic [63:0] r_work;

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

  function automatic int pk_pack_bytes_for_n(input int n_i);
    begin
      unique case (n_i)
        512:     pk_pack_bytes_for_n = 615;
        1024:    pk_pack_bytes_for_n = 1229;
        default: pk_pack_bytes_for_n = 2458;
      endcase
    end
  endfunction

  function automatic logic [7:0] get_pk_byte(
    input logic signed [NTT_N*COEFF_W-1:0] pk_vec,
    input int unsigned byte_idx
  );
    int unsigned word_idx;
    int unsigned safe_word_idx;
    logic [COEFF_W-1:0] packed_word;
    begin
      word_idx = byte_idx >> 1;
      safe_word_idx = (word_idx < NTT_N) ? word_idx : 0;
      packed_word = pk_vec[safe_word_idx*COEFF_W +: COEFF_W];
      if ((word_idx < NTT_N) && (byte_idx < (NTT_N * (COEFF_W / 8)))) begin
        if (byte_idx[0]) begin
          get_pk_byte = packed_word[15:8];
        end else begin
          get_pk_byte = packed_word[7:0];
        end
      end else begin
        get_pk_byte = 8'd0;
      end
    end
  endfunction

  function automatic logic [63:0] get_pk_packed_block(
    input logic [31:0] active_pk_pack_bytes_i,
    input logic [31:0] active_n_i,
    input logic signed [NTT_N*COEFF_W-1:0] pk_vec,
    input int unsigned block_idx
  );
    int unsigned group_base;
    begin
      get_pk_packed_block = 64'd0;
      if (active_n_i == 512) begin
        if (block_idx < 100) begin
          group_base = (block_idx >> 2) * 24;
          unique case (block_idx & 3)
            0: get_pk_packed_block =
                 {16'd0,
                  get_pk_byte(pk_vec, group_base + 5),
                  get_pk_byte(pk_vec, group_base + 4),
                  get_pk_byte(pk_vec, group_base + 3),
                  get_pk_byte(pk_vec, group_base + 2),
                  get_pk_byte(pk_vec, group_base + 1),
                  get_pk_byte(pk_vec, group_base + 0)};
            1: get_pk_packed_block =
                 {16'd0,
                  get_pk_byte(pk_vec, group_base + 13),
                  get_pk_byte(pk_vec, group_base + 12),
                  get_pk_byte(pk_vec, group_base + 11),
                  get_pk_byte(pk_vec, group_base + 10),
                  get_pk_byte(pk_vec, group_base + 9),
                  get_pk_byte(pk_vec, group_base + 8)};
            2: get_pk_packed_block =
                 {16'd0,
                  get_pk_byte(pk_vec, group_base + 21),
                  get_pk_byte(pk_vec, group_base + 20),
                  get_pk_byte(pk_vec, group_base + 19),
                  get_pk_byte(pk_vec, group_base + 18),
                  get_pk_byte(pk_vec, group_base + 17),
                  get_pk_byte(pk_vec, group_base + 16)};
            default: get_pk_packed_block =
                 {16'd0,
                  get_pk_byte(pk_vec, group_base + 23),
                  get_pk_byte(pk_vec, group_base + 22),
                  get_pk_byte(pk_vec, group_base + 15),
                  get_pk_byte(pk_vec, group_base + 14),
                  get_pk_byte(pk_vec, group_base + 7),
                  get_pk_byte(pk_vec, group_base + 6)};
          endcase
        end else if (block_idx == 100) begin
          get_pk_packed_block =
            {16'd0,
             get_pk_byte(pk_vec, 605),
             get_pk_byte(pk_vec, 604),
             get_pk_byte(pk_vec, 603),
             get_pk_byte(pk_vec, 602),
             get_pk_byte(pk_vec, 601),
             get_pk_byte(pk_vec, 600)};
        end else if (block_idx == 101) begin
          get_pk_packed_block =
            {16'd0,
             get_pk_byte(pk_vec, 613),
             get_pk_byte(pk_vec, 612),
             get_pk_byte(pk_vec, 611),
             get_pk_byte(pk_vec, 610),
             get_pk_byte(pk_vec, 609),
             get_pk_byte(pk_vec, 608)};
        end else if (block_idx == 102) begin
          get_pk_packed_block =
            ({40'd0,
              get_pk_byte(pk_vec, 614),
              get_pk_byte(pk_vec, 607),
              get_pk_byte(pk_vec, 606)} & 64'hFFFFF);
        end
      end else if (active_n_i == 1024) begin
        if (block_idx < 204) begin
          group_base = (block_idx >> 2) * 24;
          unique case (block_idx & 3)
            0: get_pk_packed_block =
                 {16'd0,
                  get_pk_byte(pk_vec, group_base + 5),
                  get_pk_byte(pk_vec, group_base + 4),
                  get_pk_byte(pk_vec, group_base + 3),
                  get_pk_byte(pk_vec, group_base + 2),
                  get_pk_byte(pk_vec, group_base + 1),
                  get_pk_byte(pk_vec, group_base + 0)};
            1: get_pk_packed_block =
                 {16'd0,
                  get_pk_byte(pk_vec, group_base + 13),
                  get_pk_byte(pk_vec, group_base + 12),
                  get_pk_byte(pk_vec, group_base + 11),
                  get_pk_byte(pk_vec, group_base + 10),
                  get_pk_byte(pk_vec, group_base + 9),
                  get_pk_byte(pk_vec, group_base + 8)};
            2: get_pk_packed_block =
                 {16'd0,
                  get_pk_byte(pk_vec, group_base + 21),
                  get_pk_byte(pk_vec, group_base + 20),
                  get_pk_byte(pk_vec, group_base + 19),
                  get_pk_byte(pk_vec, group_base + 18),
                  get_pk_byte(pk_vec, group_base + 17),
                  get_pk_byte(pk_vec, group_base + 16)};
            default: get_pk_packed_block =
                 {16'd0,
                  get_pk_byte(pk_vec, group_base + 23),
                  get_pk_byte(pk_vec, group_base + 22),
                  get_pk_byte(pk_vec, group_base + 15),
                  get_pk_byte(pk_vec, group_base + 14),
                  get_pk_byte(pk_vec, group_base + 7),
                  get_pk_byte(pk_vec, group_base + 6)};
          endcase
        end else if (block_idx == 204) begin
          get_pk_packed_block =
            ({24'd0,
              get_pk_byte(pk_vec, 1228),
              get_pk_byte(pk_vec, 1227),
              get_pk_byte(pk_vec, 1226),
              get_pk_byte(pk_vec, 1225),
              get_pk_byte(pk_vec, 1224)} & 64'h7FFFFFFFFF);
        end
      end else if (active_pk_pack_bytes_i != 0) begin
        if (block_idx < 408) begin
          group_base = (block_idx >> 2) * 24;
          unique case (block_idx & 3)
            0: get_pk_packed_block =
                 {16'd0,
                  get_pk_byte(pk_vec, group_base + 5),
                  get_pk_byte(pk_vec, group_base + 4),
                  get_pk_byte(pk_vec, group_base + 3),
                  get_pk_byte(pk_vec, group_base + 2),
                  get_pk_byte(pk_vec, group_base + 1),
                  get_pk_byte(pk_vec, group_base + 0)};
            1: get_pk_packed_block =
                 {16'd0,
                  get_pk_byte(pk_vec, group_base + 13),
                  get_pk_byte(pk_vec, group_base + 12),
                  get_pk_byte(pk_vec, group_base + 11),
                  get_pk_byte(pk_vec, group_base + 10),
                  get_pk_byte(pk_vec, group_base + 9),
                  get_pk_byte(pk_vec, group_base + 8)};
            2: get_pk_packed_block =
                 {16'd0,
                  get_pk_byte(pk_vec, group_base + 21),
                  get_pk_byte(pk_vec, group_base + 20),
                  get_pk_byte(pk_vec, group_base + 19),
                  get_pk_byte(pk_vec, group_base + 18),
                  get_pk_byte(pk_vec, group_base + 17),
                  get_pk_byte(pk_vec, group_base + 16)};
            default: get_pk_packed_block =
                 {16'd0,
                  get_pk_byte(pk_vec, group_base + 23),
                  get_pk_byte(pk_vec, group_base + 22),
                  get_pk_byte(pk_vec, group_base + 15),
                  get_pk_byte(pk_vec, group_base + 14),
                  get_pk_byte(pk_vec, group_base + 7),
                  get_pk_byte(pk_vec, group_base + 6)};
          endcase
        end else if (block_idx == 408) begin
          get_pk_packed_block =
            {16'd0,
             get_pk_byte(pk_vec, 2453),
             get_pk_byte(pk_vec, 2452),
             get_pk_byte(pk_vec, 2451),
             get_pk_byte(pk_vec, 2450),
             get_pk_byte(pk_vec, 2449),
             get_pk_byte(pk_vec, 2448)};
        end else if (block_idx == 409) begin
          get_pk_packed_block =
            ({32'd0,
              get_pk_byte(pk_vec, 2457),
              get_pk_byte(pk_vec, 2456),
              get_pk_byte(pk_vec, 2455),
              get_pk_byte(pk_vec, 2454)} & 64'h1FFFFFFF);
        end
      end
    end
  endfunction

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      busy_o <= 1'b0;
      done_o <= 1'b0;
      active_n_r <= 32'd0;
      full_blocks_r <= 32'd0;
      tail_coeff_count_r <= 32'd0;
      total_blocks_r <= 32'd0;
      block_idx_r <= 32'd0;
      coeff_base_idx_r <= 32'd0;
      coeff_limit_r <= 32'd0;
      coeff_idx_r <= 32'd0;
      packed_block_r <= 64'd0;
      block_active_r <= 1'b0;
      bytes_consumed_o <= 32'd0;
      pk_poly_vec_o <= '0;
    end else begin
      done_o <= 1'b0;

      if (start_i && !busy_o) begin
        active_n_r <= limited_profile_n(profile_id_i);
        full_blocks_r <= limited_profile_n(profile_id_i) / 5;
        tail_coeff_count_r <= limited_profile_n(profile_id_i) - ((limited_profile_n(profile_id_i) / 5) * 5);
        total_blocks_r <= (limited_profile_n(profile_id_i) / 5) +
                          (((limited_profile_n(profile_id_i) - ((limited_profile_n(profile_id_i) / 5) * 5)) != 0) ? 1 : 0);
        block_idx_r <= 32'd0;
        coeff_base_idx_r <= 32'd0;
        coeff_limit_r <= 32'd0;
        coeff_idx_r <= 32'd0;
        packed_block_r <= 64'd0;
        block_active_r <= 1'b0;
        bytes_consumed_o <= pk_pack_bytes_for_n(limited_profile_n(profile_id_i));
        pk_poly_vec_o <= '0;
        busy_o <= 1'b1;
      end else if (busy_o) begin
        if (!block_active_r) begin
          if (block_idx_r < total_blocks_r) begin
            coeff_base_idx_r <= block_idx_r * 32'd5;
            if (block_idx_r < full_blocks_r) begin
              coeff_limit_r <= 32'd5;
            end else begin
              coeff_limit_r <= tail_coeff_count_r;
            end
            coeff_idx_r <= 32'd0;
            packed_block_r <= get_pk_packed_block(bytes_consumed_o, active_n_r, pk_bytes_vec_i, block_idx_r);
            block_active_r <= 1'b1;
          end else begin
            busy_o <= 1'b0;
            done_o <= 1'b1;
          end
        end else begin
          x_work = packed_block_r;
          q_work = x_work / 64'd769;
          r_work = x_work % 64'd769;

          if ((coeff_idx_r < coeff_limit_r) && ((coeff_base_idx_r + coeff_idx_r) < active_n_r)) begin
            pk_poly_vec_o[(coeff_base_idx_r + coeff_idx_r)*COEFF_W +: COEFF_W] <= r_work[COEFF_W-1:0];
          end

          packed_block_r <= q_work;
          if (coeff_idx_r + 1 >= coeff_limit_r) begin
            block_active_r <= 1'b0;
            block_idx_r <= block_idx_r + 1'b1;
            if (block_idx_r + 1 >= total_blocks_r) begin
              busy_o <= 1'b0;
              done_o <= 1'b1;
            end
          end else begin
            coeff_idx_r <= coeff_idx_r + 1'b1;
          end
        end
      end
    end
  end

endmodule

`endif

module zen_sk_unpack_seq_core #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int GROUPS_PER_CYCLE = 4,
  parameter int F2_COEFFS_PER_CYCLE = 32
) (
  input  logic clk,
  input  logic rst_n,
  input  logic start_i,
  input  logic [1:0] profile_id_i,
  input  logic signed [NTT_N*COEFF_W-1:0] sk_lo_bytes_vec_i,
  input  logic signed [NTT_N*COEFF_W-1:0] sk_hi_bytes_vec_i,
  output logic busy_o,
  output logic done_o,
  output logic sk_f_ntt_ready_o,
  output logic sk_f2_ready_o,
  output logic signed [NTT_N*COEFF_W-1:0] sk_f_ntt_poly_vec_o,
  output logic signed [NTT_N*COEFF_W-1:0] sk_f2_poly_vec_o,
  output logic [31:0] bytes_consumed_o
) ;

  import zen_accel_pkg::*;

  localparam int SK_FNTT_COEFFS_PER_GROUP = 4;
  localparam int SK_FNTT_BYTES_PER_GROUP = 5;
  localparam int SK_F2_BITS_PER_BYTE = 8;
  localparam int SK_F2_BYTES_PER_CYCLE =
    (F2_COEFFS_PER_CYCLE + SK_F2_BITS_PER_BYTE - 1) / SK_F2_BITS_PER_BYTE;

  typedef enum logic {
    SK_UNPACK_PHASE_FNTT = 1'b0,
    SK_UNPACK_PHASE_F2   = 1'b1
  } sk_unpack_phase_t;

  sk_unpack_phase_t phase_r;
  logic [31:0] active_n_r;
  logic [31:0] active_n4_r;
  logic [31:0] active_sk_fntt_pack_bytes_r;
  logic [31:0] group_idx_r;
  logic [31:0] f2_idx_r;

  integer slot_idx;
  integer group_idx;
  integer coeff_idx;
  integer next_group_idx;
  integer next_f2_idx;
  integer f2_byte_slot_idx;
  integer f2_bit_idx;
  integer f2_coeff_base_idx;
  integer f2_coeff_limit_idx;
  integer sk_unpack_byte_idx;
  integer sk_unpack_bit_idx;
  logic [7:0] sk_unpack_b0;
  logic [7:0] sk_unpack_b1;
  logic [7:0] sk_unpack_b2;
  logic [7:0] sk_unpack_b3;
  logic [7:0] sk_unpack_b4;
  logic [7:0] sk_unpack_f2_byte;
  logic [9:0] sk_unpack_c0;
  logic [9:0] sk_unpack_c1;
  logic [9:0] sk_unpack_c2;
  logic [9:0] sk_unpack_c3;

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

  function automatic logic [7:0] get_sk_byte(
    input logic [31:0] active_n_i,
    input logic signed [NTT_N*COEFF_W-1:0] sk_lo_vec,
    input logic signed [NTT_N*COEFF_W-1:0] sk_hi_vec,
    input int unsigned byte_idx
  );
    int unsigned coeff_idx_local;
    begin
      if (byte_idx < active_n_i) begin
        coeff_idx_local = byte_idx;
        if (coeff_idx_local < NTT_N) begin
          get_sk_byte = sk_lo_vec[coeff_idx_local*COEFF_W +: 8];
        end else begin
          get_sk_byte = 8'd0;
        end
      end else if (byte_idx < (active_n_i + active_n_i)) begin
        coeff_idx_local = byte_idx - active_n_i;
        if (coeff_idx_local < NTT_N) begin
          get_sk_byte = sk_hi_vec[coeff_idx_local*COEFF_W +: 8];
        end else begin
          get_sk_byte = 8'd0;
        end
      end else begin
        get_sk_byte = 8'd0;
      end
    end
  endfunction

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      busy_o <= 1'b0;
      done_o <= 1'b0;
      sk_f_ntt_ready_o <= 1'b0;
      sk_f2_ready_o <= 1'b0;
      phase_r <= SK_UNPACK_PHASE_FNTT;
      active_n_r <= 32'd0;
      active_n4_r <= 32'd0;
      active_sk_fntt_pack_bytes_r <= 32'd0;
      group_idx_r <= 32'd0;
      f2_idx_r <= 32'd0;
      bytes_consumed_o <= 32'd0;
      sk_f_ntt_poly_vec_o <= '0;
      sk_f2_poly_vec_o <= '0;
    end else begin
      done_o <= 1'b0;

      if (start_i && !busy_o) begin
        sk_f_ntt_ready_o <= 1'b0;
        sk_f2_ready_o <= 1'b0;
        active_n_r <= limited_profile_n(profile_id_i);
        active_n4_r <= limited_profile_n(profile_id_i) / 4;
        active_sk_fntt_pack_bytes_r <= (limited_profile_n(profile_id_i) * 5) / 4;
        bytes_consumed_o <= ((limited_profile_n(profile_id_i) * 5) / 4) + (limited_profile_n(profile_id_i) / 32);
        group_idx_r <= 32'd0;
        f2_idx_r <= 32'd0;
        phase_r <= SK_UNPACK_PHASE_FNTT;
        sk_f_ntt_poly_vec_o <= '0;
        sk_f2_poly_vec_o <= '0;
        busy_o <= 1'b1;
      end else if (busy_o) begin
        if (phase_r == SK_UNPACK_PHASE_FNTT) begin
          next_group_idx = group_idx_r;
          for (slot_idx = 0; slot_idx < GROUPS_PER_CYCLE; slot_idx = slot_idx + 1) begin
            group_idx = group_idx_r + slot_idx;
            if (group_idx < active_n4_r) begin
              sk_unpack_byte_idx = SK_FNTT_BYTES_PER_GROUP * group_idx;
              sk_unpack_b0 = get_sk_byte(active_n_r, sk_lo_bytes_vec_i, sk_hi_bytes_vec_i, sk_unpack_byte_idx + 0);
              sk_unpack_b1 = get_sk_byte(active_n_r, sk_lo_bytes_vec_i, sk_hi_bytes_vec_i, sk_unpack_byte_idx + 1);
              sk_unpack_b2 = get_sk_byte(active_n_r, sk_lo_bytes_vec_i, sk_hi_bytes_vec_i, sk_unpack_byte_idx + 2);
              sk_unpack_b3 = get_sk_byte(active_n_r, sk_lo_bytes_vec_i, sk_hi_bytes_vec_i, sk_unpack_byte_idx + 3);
              sk_unpack_b4 = get_sk_byte(active_n_r, sk_lo_bytes_vec_i, sk_hi_bytes_vec_i, sk_unpack_byte_idx + 4);

              sk_unpack_c0 = {sk_unpack_b1[1:0], sk_unpack_b0};
              sk_unpack_c1 = {sk_unpack_b2[3:0], sk_unpack_b1[7:2]};
              sk_unpack_c2 = {sk_unpack_b3[5:0], sk_unpack_b2[7:4]};
              sk_unpack_c3 = {sk_unpack_b4, sk_unpack_b3[7:6]};

              sk_f_ntt_poly_vec_o[(SK_FNTT_COEFFS_PER_GROUP*group_idx + 0)*COEFF_W +: COEFF_W] <=
                {{(COEFF_W-10){1'b0}}, sk_unpack_c0};
              sk_f_ntt_poly_vec_o[(SK_FNTT_COEFFS_PER_GROUP*group_idx + 1)*COEFF_W +: COEFF_W] <=
                {{(COEFF_W-10){1'b0}}, sk_unpack_c1};
              sk_f_ntt_poly_vec_o[(SK_FNTT_COEFFS_PER_GROUP*group_idx + 2)*COEFF_W +: COEFF_W] <=
                {{(COEFF_W-10){1'b0}}, sk_unpack_c2};
              sk_f_ntt_poly_vec_o[(SK_FNTT_COEFFS_PER_GROUP*group_idx + 3)*COEFF_W +: COEFF_W] <=
                {{(COEFF_W-10){1'b0}}, sk_unpack_c3};
              next_group_idx = group_idx + 1;
            end
          end
          group_idx_r <= next_group_idx;
          if (next_group_idx >= active_n4_r) begin
            sk_f_ntt_ready_o <= 1'b1;
            phase_r <= SK_UNPACK_PHASE_F2;
            f2_idx_r <= 32'd0;
          end
        end else begin
          next_f2_idx = f2_idx_r;
          f2_coeff_limit_idx = f2_idx_r + F2_COEFFS_PER_CYCLE;
          for (f2_byte_slot_idx = 0;
               f2_byte_slot_idx < SK_F2_BYTES_PER_CYCLE;
               f2_byte_slot_idx = f2_byte_slot_idx + 1) begin
            f2_coeff_base_idx = f2_idx_r + (f2_byte_slot_idx * SK_F2_BITS_PER_BYTE);
            if (f2_coeff_base_idx < active_n4_r) begin
              sk_unpack_byte_idx = active_sk_fntt_pack_bytes_r + (f2_coeff_base_idx >> 3);
              sk_unpack_f2_byte = get_sk_byte(
                active_n_r,
                sk_lo_bytes_vec_i,
                sk_hi_bytes_vec_i,
                sk_unpack_byte_idx
              );
              for (f2_bit_idx = 0; f2_bit_idx < SK_F2_BITS_PER_BYTE; f2_bit_idx = f2_bit_idx + 1) begin
                coeff_idx = f2_coeff_base_idx + f2_bit_idx;
                if ((coeff_idx < active_n4_r) && (coeff_idx < f2_coeff_limit_idx)) begin
                  sk_unpack_bit_idx = f2_bit_idx;
                  sk_f2_poly_vec_o[coeff_idx*COEFF_W +: COEFF_W] <=
                    {{(COEFF_W-1){1'b0}}, sk_unpack_f2_byte[sk_unpack_bit_idx]};
                  next_f2_idx = coeff_idx + 1;
                end
              end
            end
          end
          f2_idx_r <= next_f2_idx;
          if (next_f2_idx >= active_n4_r) begin
            busy_o <= 1'b0;
            done_o <= 1'b1;
            sk_f2_ready_o <= 1'b1;
          end
        end
      end
    end
  end

endmodule

module zen_keypair_pack_seq_core #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int SK_GROUPS_PER_CYCLE = 4,
  parameter int SK_HI_BYTES_PER_CYCLE = 16
) (
  input  logic clk,
  input  logic rst_n,
  input  logic start_i,
  input  logic pk_poly_ready_i,
  input  logic [31:0] pk_poly_ready_coeffs_i,
  input  logic sk_f2_ready_i,
  input  logic [31:0] sk_f2_ready_coeffs_i,
  input  logic [1:0] profile_id_i,
  input  logic signed [NTT_N*COEFF_W-1:0] pk_poly_vec_i,
  input  logic signed [NTT_N*COEFF_W-1:0] sk_f_ntt_poly_vec_i,
  input  logic signed [NTT_N*COEFF_W-1:0] sk_f2_poly_vec_i,
  output logic busy_o,
  output logic done_o,
  output logic pk_ready_o,
  output logic sk_lo_ready_o,
  output logic sk_hi_ready_o,
  output logic signed [NTT_N*COEFF_W-1:0] pk_bytes_vec_o,
  output logic signed [NTT_N*COEFF_W-1:0] sk_lo_bytes_vec_o,
  output logic signed [NTT_N*COEFF_W-1:0] sk_hi_bytes_vec_o,
  output logic [31:0] bytes_produced0_o,
  output logic [31:0] bytes_produced1_o
);

  import zen_accel_pkg::*;

  typedef enum logic [2:0] {
    KP_PHASE_PK_GROUP_BUILD,
    KP_PHASE_PK_GROUP_WRITE,
    KP_PHASE_PK_TAIL_BUILD,
    KP_PHASE_PK_TAIL_WRITE,
    KP_PHASE_SK_LO,
    KP_PHASE_SK_HI,
    KP_PHASE_SK_F2_HI
  } keypair_pack_phase_t;

  keypair_pack_phase_t phase_r;
  logic [31:0] active_n_r;
  logic [31:0] active_n4_r;
  logic [31:0] active_sk_hi_base_r;
  logic [31:0] full_pk_group_count_r;
  logic [31:0] pk_tail_block_count_r;
  logic [31:0] pk_tail_base_word_idx_r;
  logic [31:0] pk_tail_total_halfwords_r;
  logic [31:0] pk_group_idx_r;
  logic [31:0] sk_lo_group_idx_r;
  logic [31:0] sk_hi_byte_idx_r;
  logic [31:0] sk_f2_hi_byte_idx_r;
  logic [1:0]  pk_group_slot_r;
  logic [1:0]  pk_tail_slot_r;
  logic [3:0]  pk_group_halfword_idx_r;
  logic [3:0]  pk_tail_halfword_idx_r;
  logic [63:0] pk_group_x0_r;
  logic [63:0] pk_group_x1_r;
  logic [63:0] pk_group_x2_r;
  logic [63:0] pk_group_x3_r;
  logic [63:0] pk_tail_x0_r;
  logic [63:0] pk_tail_x1_r;
  logic [63:0] pk_tail_x2_r;
  logic [2:0]  pk_block_coeff_idx_r;
  logic [2:0]  pk_block_coeff_limit_r;
  logic [31:0] pk_block_base_idx_r;
  logic [63:0] pk_block_acc_r;
  logic        pk_block_active_r;
  logic [2:0]  sk_lo_byte_slot_r;

  integer pk_word_idx;
  integer pk_byte_idx;
  integer hi_byte_base_idx;
  logic [COEFF_W-1:0] pk_bytes_mem [0:NTT_N-1];
  logic [COEFF_W-1:0] sk_lo_bytes_mem [0:NTT_N-1];
  logic [COEFF_W-1:0] sk_hi_bytes_mem [0:NTT_N-1];
  wire [NTT_N*COEFF_W-1:0] pk_bytes_vec_w;
  wire [NTT_N*COEFF_W-1:0] sk_lo_bytes_vec_w;
  wire [NTT_N*COEFF_W-1:0] sk_hi_bytes_vec_w;
  logic [63:0] keypair_pack_block;
  logic [63:0] keypair_pack_word;
  logic [15:0] keypair_pack_halfword;
  logic [7:0] keypair_pack_byte;
  integer clear_mem_idx;

  genvar pack_word_idx_gen;
  generate
    for (pack_word_idx_gen = 0; pack_word_idx_gen < NTT_N; pack_word_idx_gen = pack_word_idx_gen + 1) begin : g_keypair_pack_vec_map
      assign pk_bytes_vec_w[pack_word_idx_gen*COEFF_W +: COEFF_W] = pk_bytes_mem[pack_word_idx_gen];
      assign sk_lo_bytes_vec_w[pack_word_idx_gen*COEFF_W +: COEFF_W] = sk_lo_bytes_mem[pack_word_idx_gen];
      assign sk_hi_bytes_vec_w[pack_word_idx_gen*COEFF_W +: COEFF_W] = sk_hi_bytes_mem[pack_word_idx_gen];
    end
  endgenerate

  assign pk_bytes_vec_o = pk_bytes_vec_w;
  assign sk_lo_bytes_vec_o = sk_lo_bytes_vec_w;
  assign sk_hi_bytes_vec_o = sk_hi_bytes_vec_w;

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

  function automatic int pk_pack_bytes_for_n(input int n_i);
    begin
      unique case (n_i)
        512:     pk_pack_bytes_for_n = 615;
        1024:    pk_pack_bytes_for_n = 1229;
        default: pk_pack_bytes_for_n = 2458;
      endcase
    end
  endfunction

  function automatic logic [2:0] pk_coeff_count_for_base(
    input logic [31:0] active_n_i,
    input logic [31:0] base_idx_i
  );
    int unsigned coeff_cnt;
    begin
      if (base_idx_i >= active_n_i) begin
        coeff_cnt = 0;
      end else begin
        coeff_cnt = active_n_i - base_idx_i;
      end
      if (coeff_cnt > 5) begin
        coeff_cnt = 5;
      end
      pk_coeff_count_for_base = coeff_cnt[2:0];
    end
  endfunction

  function automatic logic [63:0] pk_pack_coeff_term(
    input logic [2:0] coeff_idx_i,
    input logic [COEFF_W-1:0] coeff_i
  );
    begin
      unique case (coeff_idx_i)
        3'd0:    pk_pack_coeff_term = $unsigned(coeff_i);
        3'd1:    pk_pack_coeff_term = $unsigned(coeff_i) * 64'd769;
        3'd2:    pk_pack_coeff_term = $unsigned(coeff_i) * 64'd591361;
        3'd3:    pk_pack_coeff_term = $unsigned(coeff_i) * 64'd454756609;
        default: pk_pack_coeff_term = $unsigned(coeff_i) * 64'd349707832321;
      endcase
    end
  endfunction

  function automatic logic pk_block_ready(
    input logic [31:0] active_n_i,
    input logic [31:0] ready_coeffs_i,
    input int unsigned block_idx
  );
    int unsigned base_idx;
    int unsigned coeff_cnt;
    begin
      base_idx = block_idx * 5;
      coeff_cnt = active_n_i - base_idx;
      if (coeff_cnt > 5) begin
        coeff_cnt = 5;
      end
      if (base_idx >= active_n_i) begin
        pk_block_ready = 1'b1;
      end else begin
        pk_block_ready = (ready_coeffs_i >= (base_idx + coeff_cnt));
      end
    end
  endfunction

  function automatic logic sk_f2_byte_ready(
    input logic [31:0] active_n4_i,
    input logic [31:0] ready_coeffs_i,
    input int unsigned byte_idx
  );
    int unsigned base_idx;
    int unsigned coeff_cnt;
    begin
      base_idx = byte_idx * 8;
      coeff_cnt = active_n4_i - base_idx;
      if (coeff_cnt > 8) begin
        coeff_cnt = 8;
      end
      if (base_idx >= active_n4_i) begin
        sk_f2_byte_ready = 1'b1;
      end else begin
        sk_f2_byte_ready = (ready_coeffs_i >= (base_idx + coeff_cnt));
      end
    end
  endfunction

  function automatic logic [7:0] get_sk_fntt_pack_byte(
    input logic signed [NTT_N*COEFF_W-1:0] sk_vec,
    input int unsigned byte_idx
  );
    int unsigned src_group_idx;
    int unsigned src_sel_idx;
    logic [9:0] c0;
    logic [9:0] c1;
    logic [9:0] c2;
    logic [9:0] c3;
    begin
      src_group_idx = byte_idx / 5;
      src_sel_idx = byte_idx % 5;
      c0 = sk_vec[(4*src_group_idx + 0)*COEFF_W +: 10];
      c1 = sk_vec[(4*src_group_idx + 1)*COEFF_W +: 10];
      c2 = sk_vec[(4*src_group_idx + 2)*COEFF_W +: 10];
      c3 = sk_vec[(4*src_group_idx + 3)*COEFF_W +: 10];
      unique case (src_sel_idx)
        0: get_sk_fntt_pack_byte = c0[7:0];
        1: get_sk_fntt_pack_byte = {c1[5:0], c0[9:8]};
        2: get_sk_fntt_pack_byte = {c2[3:0], c1[9:6]};
        3: get_sk_fntt_pack_byte = {c3[1:0], c2[9:4]};
        default: get_sk_fntt_pack_byte = c3[9:2];
      endcase
    end
  endfunction

  function automatic logic [7:0] get_sk_f2_pack_byte(
    input logic signed [NTT_N*COEFF_W-1:0] sk_f2_vec,
    input int unsigned byte_idx
  );
    int unsigned bit_idx_local;
    logic [7:0] packed_byte;
    begin
      packed_byte = 8'd0;
      for (bit_idx_local = 0; bit_idx_local < 8; bit_idx_local = bit_idx_local + 1) begin
        packed_byte[bit_idx_local] = sk_f2_vec[((byte_idx * 8) + bit_idx_local)*COEFF_W];
      end
      get_sk_f2_pack_byte = packed_byte;
    end
  endfunction

  function automatic logic [63:0] get_pk_group_word(
    input logic [63:0] x0,
    input logic [63:0] x1,
    input logic [63:0] x2,
    input logic [63:0] x3,
    input logic [1:0] word_sel
  );
    begin
      unique case (word_sel)
        2'd0: get_pk_group_word = x0 | ((x3 & 64'hFFFF) << 48);
        2'd1: get_pk_group_word = x1 | (((x3 >> 16) & 64'hFFFF) << 48);
        default: get_pk_group_word = x2 | (((x3 >> 32) & 64'hFFFF) << 48);
      endcase
    end
  endfunction

  function automatic logic [63:0] get_pk_tail_word(
    input logic [31:0] active_n_i,
    input logic [63:0] x0,
    input logic [63:0] x1,
    input logic [63:0] x2,
    input logic word_sel
  );
    begin
      get_pk_tail_word = 64'd0;
      if (active_n_i == 512) begin
        if (!word_sel) begin
          get_pk_tail_word = x0 | ((x2 & 64'hFFFF) << 48);
        end else begin
          get_pk_tail_word = x1 | (((x2 >> 16) & 64'hF) << 48);
        end
      end else if (active_n_i == 1024) begin
        get_pk_tail_word = x0;
      end else begin
        if (!word_sel) begin
          get_pk_tail_word = x0 | ((x1 & 64'hFFFF) << 48);
        end else begin
          get_pk_tail_word = (x1 >> 16) & 64'h1FFF;
        end
      end
    end
  endfunction

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      busy_o <= 1'b0;
      done_o <= 1'b0;
      pk_ready_o <= 1'b0;
      sk_lo_ready_o <= 1'b0;
      sk_hi_ready_o <= 1'b0;
      phase_r <= KP_PHASE_SK_LO;
      active_n_r <= 32'd0;
      active_n4_r <= 32'd0;
      active_sk_hi_base_r <= 32'd0;
      full_pk_group_count_r <= 32'd0;
      pk_tail_block_count_r <= 32'd0;
      pk_tail_base_word_idx_r <= 32'd0;
      pk_tail_total_halfwords_r <= 32'd0;
      pk_group_idx_r <= 32'd0;
      sk_lo_group_idx_r <= 32'd0;
      sk_hi_byte_idx_r <= 32'd0;
      sk_f2_hi_byte_idx_r <= 32'd0;
      pk_group_slot_r <= 2'd0;
      pk_tail_slot_r <= 2'd0;
      pk_group_halfword_idx_r <= 4'd0;
      pk_tail_halfword_idx_r <= 4'd0;
      pk_group_x0_r <= 64'd0;
      pk_group_x1_r <= 64'd0;
      pk_group_x2_r <= 64'd0;
      pk_group_x3_r <= 64'd0;
      pk_tail_x0_r <= 64'd0;
      pk_tail_x1_r <= 64'd0;
      pk_tail_x2_r <= 64'd0;
      pk_block_coeff_idx_r <= 3'd0;
      pk_block_coeff_limit_r <= 3'd0;
      pk_block_base_idx_r <= 32'd0;
      pk_block_acc_r <= 64'd0;
      pk_block_active_r <= 1'b0;
      sk_lo_byte_slot_r <= 3'd0;
      bytes_produced0_o <= 32'd0;
      bytes_produced1_o <= 32'd0;
      pk_bytes_mem <= '{default:'0};
      sk_lo_bytes_mem <= '{default:'0};
      sk_hi_bytes_mem <= '{default:'0};
    end else begin
      done_o <= 1'b0;

      if (start_i && !busy_o) begin
        pk_ready_o <= 1'b0;
        sk_lo_ready_o <= 1'b0;
        sk_hi_ready_o <= 1'b0;
        active_n_r <= limited_profile_n(profile_id_i);
        active_n4_r <= limited_profile_n(profile_id_i) / 4;
        active_sk_hi_base_r <= limited_profile_n(profile_id_i) / 4;
        full_pk_group_count_r <= limited_profile_n(profile_id_i) / 20;
        pk_tail_block_count_r <=
          ((limited_profile_n(profile_id_i) / 5) +
           (((limited_profile_n(profile_id_i) % 5) != 0) ? 1 : 0)) -
          ((limited_profile_n(profile_id_i) / 20) * 4);
        unique case (limited_profile_n(profile_id_i))
          512: begin
            pk_tail_base_word_idx_r <= 32'd300;
            pk_tail_total_halfwords_r <= 32'd8;
          end
          1024: begin
            pk_tail_base_word_idx_r <= 32'd612;
            pk_tail_total_halfwords_r <= 32'd4;
          end
          default: begin
            pk_tail_base_word_idx_r <= 32'd1224;
            pk_tail_total_halfwords_r <= 32'd8;
          end
        endcase
        bytes_produced0_o <= pk_pack_bytes_for_n(limited_profile_n(profile_id_i));
        bytes_produced1_o <= ((limited_profile_n(profile_id_i) * 5) / 4) + (limited_profile_n(profile_id_i) / 32);
        pk_group_idx_r <= 32'd0;
        sk_lo_group_idx_r <= 32'd0;
        sk_hi_byte_idx_r <= 32'd0;
        sk_f2_hi_byte_idx_r <= 32'd0;
        pk_group_slot_r <= 2'd0;
        pk_tail_slot_r <= 2'd0;
        pk_group_halfword_idx_r <= 4'd0;
        pk_tail_halfword_idx_r <= 4'd0;
        pk_group_x0_r <= 64'd0;
        pk_group_x1_r <= 64'd0;
        pk_group_x2_r <= 64'd0;
        pk_group_x3_r <= 64'd0;
        pk_tail_x0_r <= 64'd0;
        pk_tail_x1_r <= 64'd0;
        pk_tail_x2_r <= 64'd0;
        pk_block_coeff_idx_r <= 3'd0;
        pk_block_coeff_limit_r <= 3'd0;
        pk_block_base_idx_r <= 32'd0;
        pk_block_acc_r <= 64'd0;
        pk_block_active_r <= 1'b0;
        sk_lo_byte_slot_r <= 3'd0;
        phase_r <= KP_PHASE_SK_LO;
        pk_bytes_mem <= '{default:'0};
        sk_lo_bytes_mem <= '{default:'0};
        sk_hi_bytes_mem <= '{default:'0};
        busy_o <= 1'b1;
      end else if (busy_o) begin
        case (phase_r)
          KP_PHASE_PK_GROUP_BUILD: begin
            if ((pk_group_idx_r < full_pk_group_count_r) &&
                (pk_poly_ready_i ||
                 pk_block_ready(active_n_r, pk_poly_ready_coeffs_i,
                                (pk_group_idx_r * 4) + pk_group_slot_r))) begin
              if (!pk_block_active_r) begin
                pk_block_base_idx_r <= ((pk_group_idx_r * 4) + pk_group_slot_r) * 5;
                pk_block_coeff_limit_r <=
                  pk_coeff_count_for_base(active_n_r, ((pk_group_idx_r * 4) + pk_group_slot_r) * 5);
                pk_block_coeff_idx_r <= 3'd0;
                pk_block_acc_r <= 64'd0;
                pk_block_active_r <= 1'b1;
              end else begin
                keypair_pack_block = pk_block_acc_r;
                if ((pk_block_coeff_idx_r < pk_block_coeff_limit_r) &&
                    ((pk_block_base_idx_r + pk_block_coeff_idx_r) < NTT_N)) begin
                  keypair_pack_block =
                    pk_block_acc_r +
                    pk_pack_coeff_term(
                      pk_block_coeff_idx_r,
                      pk_poly_vec_i[(pk_block_base_idx_r + pk_block_coeff_idx_r) * COEFF_W +: COEFF_W]
                    );
                end
                if ((pk_block_coeff_idx_r + 1) >= pk_block_coeff_limit_r) begin
                  unique case (pk_group_slot_r)
                    2'd0: pk_group_x0_r <= keypair_pack_block;
                    2'd1: pk_group_x1_r <= keypair_pack_block;
                    2'd2: pk_group_x2_r <= keypair_pack_block;
                    default: pk_group_x3_r <= keypair_pack_block;
                  endcase
                  pk_block_active_r <= 1'b0;
                  if (pk_group_slot_r == 2'd3) begin
                    pk_group_halfword_idx_r <= 4'd0;
                    phase_r <= KP_PHASE_PK_GROUP_WRITE;
                  end else begin
                    pk_group_slot_r <= pk_group_slot_r + 1'b1;
                  end
                end else begin
                  pk_block_acc_r <= keypair_pack_block;
                  pk_block_coeff_idx_r <= pk_block_coeff_idx_r + 1'b1;
                end
              end
            end else if (pk_group_idx_r < full_pk_group_count_r) begin
            end else begin
              pk_block_active_r <= 1'b0;
              pk_tail_slot_r <= 2'd0;
              if (pk_tail_block_count_r != 0) begin
                phase_r <= KP_PHASE_PK_TAIL_BUILD;
              end else begin
                busy_o <= 1'b0;
                done_o <= 1'b1;
                pk_ready_o <= 1'b1;
              end
            end
          end

          KP_PHASE_PK_GROUP_WRITE: begin
            keypair_pack_word =
              get_pk_group_word(pk_group_x0_r, pk_group_x1_r, pk_group_x2_r, pk_group_x3_r, pk_group_halfword_idx_r[3:2]);
            keypair_pack_halfword = keypair_pack_word[16*pk_group_halfword_idx_r[1:0] +: 16];
            pk_bytes_mem[(pk_group_idx_r * 12) + pk_group_halfword_idx_r] <= keypair_pack_halfword;
            if (pk_group_halfword_idx_r == 4'd11) begin
              pk_group_idx_r <= pk_group_idx_r + 1'b1;
              pk_group_slot_r <= 2'd0;
              pk_tail_slot_r <= 2'd0;
              pk_block_active_r <= 1'b0;
              if ((pk_group_idx_r + 1) < full_pk_group_count_r) begin
                phase_r <= KP_PHASE_PK_GROUP_BUILD;
              end else if (pk_tail_block_count_r != 0) begin
                phase_r <= KP_PHASE_PK_TAIL_BUILD;
              end else begin
                busy_o <= 1'b0;
                done_o <= 1'b1;
                pk_ready_o <= 1'b1;
              end
            end else begin
              pk_group_halfword_idx_r <= pk_group_halfword_idx_r + 1'b1;
            end
          end

          KP_PHASE_PK_TAIL_BUILD: begin
            if ((pk_tail_slot_r < pk_tail_block_count_r) &&
                (pk_poly_ready_i ||
                 pk_block_ready(active_n_r, pk_poly_ready_coeffs_i,
                                (full_pk_group_count_r * 4) + pk_tail_slot_r))) begin
              if (!pk_block_active_r) begin
                pk_block_base_idx_r <= ((full_pk_group_count_r * 4) + pk_tail_slot_r) * 5;
                pk_block_coeff_limit_r <=
                  pk_coeff_count_for_base(active_n_r, ((full_pk_group_count_r * 4) + pk_tail_slot_r) * 5);
                pk_block_coeff_idx_r <= 3'd0;
                pk_block_acc_r <= 64'd0;
                pk_block_active_r <= 1'b1;
              end else begin
                keypair_pack_block = pk_block_acc_r;
                if ((pk_block_coeff_idx_r < pk_block_coeff_limit_r) &&
                    ((pk_block_base_idx_r + pk_block_coeff_idx_r) < NTT_N)) begin
                  keypair_pack_block =
                    pk_block_acc_r +
                    pk_pack_coeff_term(
                      pk_block_coeff_idx_r,
                      pk_poly_vec_i[(pk_block_base_idx_r + pk_block_coeff_idx_r) * COEFF_W +: COEFF_W]
                    );
                end
                if ((pk_block_coeff_idx_r + 1) >= pk_block_coeff_limit_r) begin
                  unique case (pk_tail_slot_r)
                    2'd0: pk_tail_x0_r <= keypair_pack_block;
                    2'd1: pk_tail_x1_r <= keypair_pack_block;
                    default: pk_tail_x2_r <= keypair_pack_block;
                  endcase
                  pk_block_active_r <= 1'b0;
                  if ((pk_tail_slot_r + 1) >= pk_tail_block_count_r) begin
                    pk_tail_halfword_idx_r <= 4'd0;
                    phase_r <= KP_PHASE_PK_TAIL_WRITE;
                  end else begin
                    pk_tail_slot_r <= pk_tail_slot_r + 1'b1;
                  end
                end else begin
                  pk_block_acc_r <= keypair_pack_block;
                  pk_block_coeff_idx_r <= pk_block_coeff_idx_r + 1'b1;
                end
              end
            end else if (pk_tail_slot_r < pk_tail_block_count_r) begin
            end else begin
              pk_block_active_r <= 1'b0;
              pk_tail_halfword_idx_r <= 4'd0;
              phase_r <= KP_PHASE_PK_TAIL_WRITE;
            end
          end

          KP_PHASE_PK_TAIL_WRITE: begin
            pk_word_idx = pk_tail_base_word_idx_r + pk_tail_halfword_idx_r;
            keypair_pack_word =
              get_pk_tail_word(active_n_r, pk_tail_x0_r, pk_tail_x1_r, pk_tail_x2_r, pk_tail_halfword_idx_r[2]);
            keypair_pack_halfword = 16'd0;
            pk_byte_idx = 2 * pk_word_idx;
            if (pk_byte_idx < bytes_produced0_o) begin
              keypair_pack_halfword[7:0] = keypair_pack_word[16*pk_tail_halfword_idx_r[1:0] +: 8];
            end
            if ((pk_byte_idx + 1) < bytes_produced0_o) begin
              keypair_pack_halfword[15:8] = keypair_pack_word[16*pk_tail_halfword_idx_r[1:0] + 8 +: 8];
            end
            if (pk_word_idx < NTT_N) begin
              pk_bytes_mem[pk_word_idx] <= keypair_pack_halfword;
            end
            if ((pk_tail_halfword_idx_r + 1) >= pk_tail_total_halfwords_r) begin
              busy_o <= 1'b0;
              done_o <= 1'b1;
              pk_ready_o <= 1'b1;
            end else begin
              pk_tail_halfword_idx_r <= pk_tail_halfword_idx_r + 1'b1;
            end
          end

          KP_PHASE_SK_LO: begin
            if (sk_lo_group_idx_r < active_n4_r) begin
              pk_byte_idx = (5 * sk_lo_group_idx_r) + sk_lo_byte_slot_r;
              keypair_pack_byte = get_sk_fntt_pack_byte(sk_f_ntt_poly_vec_i, pk_byte_idx);
              if ((pk_byte_idx < active_n_r) && (pk_byte_idx < NTT_N)) begin
                sk_lo_bytes_mem[pk_byte_idx] <= {{(COEFF_W-8){1'b0}}, keypair_pack_byte};
              end
              if (sk_lo_byte_slot_r == 3'd4) begin
                sk_lo_byte_slot_r <= 3'd0;
                sk_lo_group_idx_r <= sk_lo_group_idx_r + 1'b1;
                if ((sk_lo_group_idx_r + 1) >= active_n4_r) begin
                  sk_lo_ready_o <= 1'b1;
                  sk_hi_byte_idx_r <= 32'd0;
                  phase_r <= KP_PHASE_SK_HI;
                end
              end else begin
                sk_lo_byte_slot_r <= sk_lo_byte_slot_r + 1'b1;
              end
            end else begin
              sk_lo_ready_o <= 1'b1;
              sk_lo_byte_slot_r <= 3'd0;
              sk_hi_byte_idx_r <= 32'd0;
              phase_r <= KP_PHASE_SK_HI;
            end
          end

          KP_PHASE_SK_HI: begin
            if (sk_hi_byte_idx_r < active_sk_hi_base_r) begin
              keypair_pack_byte = get_sk_fntt_pack_byte(sk_f_ntt_poly_vec_i, active_n_r + sk_hi_byte_idx_r);
              if (sk_hi_byte_idx_r < NTT_N) begin
                sk_hi_bytes_mem[sk_hi_byte_idx_r] <= {{(COEFF_W-8){1'b0}}, keypair_pack_byte};
              end
              sk_hi_byte_idx_r <= sk_hi_byte_idx_r + 1'b1;
              if ((sk_hi_byte_idx_r + 1) >= active_sk_hi_base_r) begin
                sk_f2_hi_byte_idx_r <= 32'd0;
                phase_r <= KP_PHASE_SK_F2_HI;
              end
            end else begin
              sk_f2_hi_byte_idx_r <= 32'd0;
              phase_r <= KP_PHASE_SK_F2_HI;
            end
          end

          KP_PHASE_SK_F2_HI: begin
            hi_byte_base_idx = active_sk_hi_base_r;
            if ((sk_f2_hi_byte_idx_r < (active_n_r / 32)) &&
                !(sk_f2_ready_i ||
                  sk_f2_byte_ready(active_n4_r, sk_f2_ready_coeffs_i, sk_f2_hi_byte_idx_r))) begin
            end else if (sk_f2_hi_byte_idx_r < (active_n_r / 32)) begin
              pk_byte_idx = sk_f2_hi_byte_idx_r;
              keypair_pack_byte = get_sk_f2_pack_byte(sk_f2_poly_vec_i, pk_byte_idx);
              if ((hi_byte_base_idx + pk_byte_idx) < NTT_N) begin
                sk_hi_bytes_mem[hi_byte_base_idx + pk_byte_idx] <=
                  {{(COEFF_W-8){1'b0}}, keypair_pack_byte};
              end
              sk_f2_hi_byte_idx_r <= sk_f2_hi_byte_idx_r + 1'b1;
              if ((sk_f2_hi_byte_idx_r + 1) >= (active_n_r / 32)) begin
                sk_hi_ready_o <= 1'b1;
                pk_group_idx_r <= 32'd0;
                pk_group_slot_r <= 2'd0;
                pk_group_halfword_idx_r <= 4'd0;
                pk_tail_slot_r <= 2'd0;
                pk_tail_halfword_idx_r <= 4'd0;
                pk_block_active_r <= 1'b0;
                phase_r <= KP_PHASE_PK_GROUP_BUILD;
              end
            end else begin
              sk_hi_ready_o <= 1'b1;
              pk_group_idx_r <= 32'd0;
              pk_group_slot_r <= 2'd0;
              pk_group_halfword_idx_r <= 4'd0;
              pk_tail_slot_r <= 2'd0;
              pk_tail_halfword_idx_r <= 4'd0;
              pk_block_active_r <= 1'b0;
              phase_r <= KP_PHASE_PK_GROUP_BUILD;
            end
          end

          default: begin
          end
        endcase
      end
    end
  end

endmodule
