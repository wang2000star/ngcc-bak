// reference_only:
// - Full-vector pk/sk golden/reference codec used for TB compare and historical debug.
// - Excluded from filelist_xcvu37p.f and not part of the mainline synthesis/OOC sweep.
module zen_pk_sk_codec #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter bit SUPPORT_PK_UNPACK = 1'b1,
  parameter bit SUPPORT_SK_UNPACK = 1'b1,
  parameter bit SUPPORT_KEYPAIR_PACK = 1'b1
) (
  input  logic [2:0] op,
  input  logic [1:0] profile_id_i,
  input  logic signed [NTT_N*COEFF_W-1:0] pk_bytes_vec_i,
  input  logic signed [NTT_N*COEFF_W-1:0] sk_lo_bytes_vec_i,
  input  logic signed [NTT_N*COEFF_W-1:0] sk_hi_bytes_vec_i,
  input  logic signed [NTT_N*COEFF_W-1:0] pk_poly_vec_i,
  input  logic signed [NTT_N*COEFF_W-1:0] sk_f_ntt_poly_vec_i,
  input  logic signed [NTT_N*COEFF_W-1:0] sk_f2_poly_vec_i,
  output logic signed [NTT_N*COEFF_W-1:0] pk_bytes_vec_o,
  output logic signed [NTT_N*COEFF_W-1:0] sk_lo_bytes_vec_o,
  output logic signed [NTT_N*COEFF_W-1:0] sk_hi_bytes_vec_o,
  output logic signed [NTT_N*COEFF_W-1:0] pk_poly_vec_o,
  output logic signed [NTT_N*COEFF_W-1:0] sk_f_ntt_poly_vec_o,
  output logic signed [NTT_N*COEFF_W-1:0] sk_f2_poly_vec_o,
  output logic [31:0] bytes_consumed_o,
  output logic [31:0] bytes_produced0_o,
  output logic [31:0] bytes_produced1_o
);

  import zen_accel_pkg::*;

  localparam logic [2:0] OP_PK_UNPACK    = 3'd1;
  localparam logic [2:0] OP_SK_UNPACK    = 3'd2;
  localparam logic [2:0] OP_KEYPAIR_PACK = 3'd3;
  localparam int PK_FULL_BLOCK_LOOP_MAX = NTT_N / 5;
  localparam int PK_TAIL_COEFF_COUNT = NTT_N - (5 * PK_FULL_BLOCK_LOOP_MAX);
  localparam int PK_TAIL_BASE = 5 * PK_FULL_BLOCK_LOOP_MAX;
  localparam int N4_LOOP_MAX = NTT_N / 4;
  localparam int SK_F2_PACK_MAX_BYTES = NTT_N / 32;

  logic [31:0] active_n;
  logic [31:0] active_n4;
  logic [31:0] active_pk_pack_bytes;
  logic [31:0] active_sk_fntt_pack_bytes;
  logic [31:0] active_sk_f2_pack_bytes;
  logic [31:0] active_sk_pack_bytes;
  integer pk_unpack_idx;
  integer pk_unpack_block_idx;
  integer pk_unpack_coeff_base;
  integer sk_unpack_group_idx;
  integer sk_unpack_byte_idx;
  integer sk_unpack_coeff_idx;
  integer sk_unpack_bit_idx;
  logic [63:0] pk_unpack_x;
  logic [63:0] pk_unpack_q;
  logic [63:0] pk_unpack_r;
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
  logic signed [NTT_N*COEFF_W-1:0] keypair_pk_bytes_vec;
  logic signed [NTT_N*COEFF_W-1:0] keypair_sk_lo_bytes_vec;
  logic signed [NTT_N*COEFF_W-1:0] keypair_sk_hi_bytes_vec;
  logic [31:0] keypair_pk_bytes_produced;
  logic [31:0] keypair_sk_bytes_produced;

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

  assign active_n = limited_profile_n(profile_id_i);
  assign active_n4 = active_n / 4;
  assign active_pk_pack_bytes = pk_pack_bytes_for_n(active_n);
  assign active_sk_fntt_pack_bytes = (active_n * 5) / 4;
  assign active_sk_f2_pack_bytes = active_n / 32;
  assign active_sk_pack_bytes = active_sk_fntt_pack_bytes + active_sk_f2_pack_bytes;

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

  function automatic logic [7:0] get_sk_byte(
    input logic [31:0] active_n_i,
    input logic signed [NTT_N*COEFF_W-1:0] sk_lo_vec,
    input logic signed [NTT_N*COEFF_W-1:0] sk_hi_vec,
    input int unsigned byte_idx
  );
    int unsigned coeff_idx;
    begin
      if (byte_idx < active_n_i) begin
        coeff_idx = byte_idx;
        if (coeff_idx < NTT_N) begin
          get_sk_byte = sk_lo_vec[coeff_idx*COEFF_W +: 8];
        end else begin
          get_sk_byte = 8'd0;
        end
      end else if (byte_idx < (active_n_i + active_n_i)) begin
        coeff_idx = byte_idx - active_n_i;
        if (coeff_idx < NTT_N) begin
          get_sk_byte = sk_hi_vec[coeff_idx*COEFF_W +: 8];
        end else begin
          get_sk_byte = 8'd0;
        end
      end else begin
        get_sk_byte = 8'd0;
      end
    end
  endfunction

  generate
    if (SUPPORT_KEYPAIR_PACK) begin : g_keypair_pack
      zen_pk_poly_pack_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W)
      ) u_pk_poly_pack_codec (
        .profile_id_i(profile_id_i),
        .pk_poly_vec_i(pk_poly_vec_i),
        .pk_bytes_vec_o(keypair_pk_bytes_vec),
        .bytes_produced_o(keypair_pk_bytes_produced)
      );

      zen_sk_poly_pack_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W)
      ) u_sk_poly_pack_codec (
        .profile_id_i(profile_id_i),
        .sk_f_ntt_poly_vec_i(sk_f_ntt_poly_vec_i),
        .sk_f2_poly_vec_i(sk_f2_poly_vec_i),
        .sk_lo_bytes_vec_o(keypair_sk_lo_bytes_vec),
        .sk_hi_bytes_vec_o(keypair_sk_hi_bytes_vec),
        .bytes_produced_o(keypair_sk_bytes_produced)
      );
    end else begin : g_no_keypair_pack
      assign keypair_pk_bytes_vec = '0;
      assign keypair_sk_lo_bytes_vec = '0;
      assign keypair_sk_hi_bytes_vec = '0;
      assign keypair_pk_bytes_produced = 32'd0;
      assign keypair_sk_bytes_produced = 32'd0;
    end
  endgenerate

  always_comb begin
    pk_bytes_vec_o = '0;
    sk_lo_bytes_vec_o = '0;
    sk_hi_bytes_vec_o = '0;
    pk_poly_vec_o = '0;
    sk_f_ntt_poly_vec_o = '0;
    sk_f2_poly_vec_o = '0;
    bytes_consumed_o = 32'd0;
    bytes_produced0_o = 32'd0;
    bytes_produced1_o = 32'd0;

    unique case (op)
      OP_PK_UNPACK: begin
        if (SUPPORT_PK_UNPACK) begin
          bytes_consumed_o = active_pk_pack_bytes;
          // Decode one packed 5-coefficient block once, instead of recomputing it for every output coefficient.
          for (pk_unpack_block_idx = 0; pk_unpack_block_idx < PK_FULL_BLOCK_LOOP_MAX; pk_unpack_block_idx++) begin
            pk_unpack_coeff_base = 5 * pk_unpack_block_idx;
            if (pk_unpack_coeff_base < active_n) begin
              pk_unpack_x = get_pk_packed_block(active_pk_pack_bytes, active_n, pk_bytes_vec_i, pk_unpack_block_idx);

              pk_unpack_q = pk_unpack_x / 64'd769;
              pk_unpack_r = pk_unpack_x % 64'd769;
              pk_poly_vec_o[(pk_unpack_coeff_base + 0)*COEFF_W +: COEFF_W] = pk_unpack_r[COEFF_W-1:0];
              pk_unpack_x = pk_unpack_q;

              if ((pk_unpack_coeff_base + 1) < active_n) begin
                pk_unpack_q = pk_unpack_x / 64'd769;
                pk_unpack_r = pk_unpack_x % 64'd769;
                pk_poly_vec_o[(pk_unpack_coeff_base + 1)*COEFF_W +: COEFF_W] = pk_unpack_r[COEFF_W-1:0];
                pk_unpack_x = pk_unpack_q;
              end

              if ((pk_unpack_coeff_base + 2) < active_n) begin
                pk_unpack_q = pk_unpack_x / 64'd769;
                pk_unpack_r = pk_unpack_x % 64'd769;
                pk_poly_vec_o[(pk_unpack_coeff_base + 2)*COEFF_W +: COEFF_W] = pk_unpack_r[COEFF_W-1:0];
                pk_unpack_x = pk_unpack_q;
              end

              if ((pk_unpack_coeff_base + 3) < active_n) begin
                pk_unpack_q = pk_unpack_x / 64'd769;
                pk_unpack_r = pk_unpack_x % 64'd769;
                pk_poly_vec_o[(pk_unpack_coeff_base + 3)*COEFF_W +: COEFF_W] = pk_unpack_r[COEFF_W-1:0];
                pk_unpack_x = pk_unpack_q;
              end

              if ((pk_unpack_coeff_base + 4) < active_n) begin
                pk_unpack_q = pk_unpack_x / 64'd769;
                pk_unpack_r = pk_unpack_x % 64'd769;
                pk_poly_vec_o[(pk_unpack_coeff_base + 4)*COEFF_W +: COEFF_W] = pk_unpack_r[COEFF_W-1:0];
              end
            end
          end

          // Handle the compile-time tail block separately so every part-select stays within [0, NTT_N).
          if ((PK_TAIL_COEFF_COUNT > 0) && (PK_TAIL_BASE < active_n)) begin
            pk_unpack_coeff_base = PK_TAIL_BASE;
            pk_unpack_x = get_pk_packed_block(active_pk_pack_bytes, active_n, pk_bytes_vec_i, PK_FULL_BLOCK_LOOP_MAX);

            pk_unpack_q = pk_unpack_x / 64'd769;
            pk_unpack_r = pk_unpack_x % 64'd769;
            pk_poly_vec_o[(pk_unpack_coeff_base + 0)*COEFF_W +: COEFF_W] = pk_unpack_r[COEFF_W-1:0];
            pk_unpack_x = pk_unpack_q;

            if ((PK_TAIL_COEFF_COUNT > 1) && ((pk_unpack_coeff_base + 1) < active_n)) begin
              pk_unpack_q = pk_unpack_x / 64'd769;
              pk_unpack_r = pk_unpack_x % 64'd769;
              pk_poly_vec_o[(pk_unpack_coeff_base + 1)*COEFF_W +: COEFF_W] = pk_unpack_r[COEFF_W-1:0];
              pk_unpack_x = pk_unpack_q;
            end

            if ((PK_TAIL_COEFF_COUNT > 2) && ((pk_unpack_coeff_base + 2) < active_n)) begin
              pk_unpack_q = pk_unpack_x / 64'd769;
              pk_unpack_r = pk_unpack_x % 64'd769;
              pk_poly_vec_o[(pk_unpack_coeff_base + 2)*COEFF_W +: COEFF_W] = pk_unpack_r[COEFF_W-1:0];
              pk_unpack_x = pk_unpack_q;
            end

            if ((PK_TAIL_COEFF_COUNT > 3) && ((pk_unpack_coeff_base + 3) < active_n)) begin
              pk_unpack_q = pk_unpack_x / 64'd769;
              pk_unpack_r = pk_unpack_x % 64'd769;
              pk_poly_vec_o[(pk_unpack_coeff_base + 3)*COEFF_W +: COEFF_W] = pk_unpack_r[COEFF_W-1:0];
            end
          end
        end
      end

      OP_SK_UNPACK: begin
        if (SUPPORT_SK_UNPACK) begin
          bytes_consumed_o = active_sk_pack_bytes;
          for (sk_unpack_group_idx = 0; sk_unpack_group_idx < N4_LOOP_MAX; sk_unpack_group_idx++) begin
            if (sk_unpack_group_idx < active_n4) begin
              sk_unpack_byte_idx = 5 * sk_unpack_group_idx;
              sk_unpack_b0 = get_sk_byte(active_n, sk_lo_bytes_vec_i, sk_hi_bytes_vec_i, sk_unpack_byte_idx + 0);
              sk_unpack_b1 = get_sk_byte(active_n, sk_lo_bytes_vec_i, sk_hi_bytes_vec_i, sk_unpack_byte_idx + 1);
              sk_unpack_b2 = get_sk_byte(active_n, sk_lo_bytes_vec_i, sk_hi_bytes_vec_i, sk_unpack_byte_idx + 2);
              sk_unpack_b3 = get_sk_byte(active_n, sk_lo_bytes_vec_i, sk_hi_bytes_vec_i, sk_unpack_byte_idx + 3);
              sk_unpack_b4 = get_sk_byte(active_n, sk_lo_bytes_vec_i, sk_hi_bytes_vec_i, sk_unpack_byte_idx + 4);

              sk_unpack_c0 = {sk_unpack_b1[1:0], sk_unpack_b0};
              sk_unpack_c1 = {sk_unpack_b2[3:0], sk_unpack_b1[7:2]};
              sk_unpack_c2 = {sk_unpack_b3[5:0], sk_unpack_b2[7:4]};
              sk_unpack_c3 = {sk_unpack_b4, sk_unpack_b3[7:6]};

              sk_f_ntt_poly_vec_o[(4*sk_unpack_group_idx + 0)*COEFF_W +: COEFF_W] = {{(COEFF_W-10){1'b0}}, sk_unpack_c0};
              sk_f_ntt_poly_vec_o[(4*sk_unpack_group_idx + 1)*COEFF_W +: COEFF_W] = {{(COEFF_W-10){1'b0}}, sk_unpack_c1};
              sk_f_ntt_poly_vec_o[(4*sk_unpack_group_idx + 2)*COEFF_W +: COEFF_W] = {{(COEFF_W-10){1'b0}}, sk_unpack_c2};
              sk_f_ntt_poly_vec_o[(4*sk_unpack_group_idx + 3)*COEFF_W +: COEFF_W] = {{(COEFF_W-10){1'b0}}, sk_unpack_c3};
            end
          end

          for (sk_unpack_coeff_idx = 0; sk_unpack_coeff_idx < N4_LOOP_MAX; sk_unpack_coeff_idx++) begin
            if (sk_unpack_coeff_idx < active_n4) begin
              sk_unpack_byte_idx = active_sk_fntt_pack_bytes + (sk_unpack_coeff_idx >> 3);
              sk_unpack_bit_idx = sk_unpack_coeff_idx & 7;
              sk_unpack_f2_byte = get_sk_byte(active_n, sk_lo_bytes_vec_i, sk_hi_bytes_vec_i, sk_unpack_byte_idx);
              sk_f2_poly_vec_o[sk_unpack_coeff_idx*COEFF_W +: COEFF_W] =
                {{(COEFF_W-1){1'b0}}, sk_unpack_f2_byte[sk_unpack_bit_idx]};
            end
          end
        end
      end

      OP_KEYPAIR_PACK: begin
        pk_bytes_vec_o = keypair_pk_bytes_vec;
        sk_lo_bytes_vec_o = keypair_sk_lo_bytes_vec;
        sk_hi_bytes_vec_o = keypair_sk_hi_bytes_vec;
        bytes_produced0_o = keypair_pk_bytes_produced;
        bytes_produced1_o = keypair_sk_bytes_produced;
      end

      default: begin
        pk_bytes_vec_o = '0;
        sk_lo_bytes_vec_o = '0;
        sk_hi_bytes_vec_o = '0;
        pk_poly_vec_o = '0;
        sk_f_ntt_poly_vec_o = '0;
        sk_f2_poly_vec_o = '0;
        bytes_consumed_o = 32'd0;
        bytes_produced0_o = 32'd0;
        bytes_produced1_o = 32'd0;
      end
    endcase
  end

endmodule

module zen_pk_poly_pack_group_chunk_codec #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int ACTIVE_N_CONST = 512,
  parameter int START_GROUP_IDX = 0,
  parameter int GROUP_COUNT = 16
) (
  input  logic signed [GROUP_COUNT*20*COEFF_W-1:0] pk_poly_chunk_i,
  output logic signed [GROUP_COUNT*12*COEFF_W-1:0] pk_chunk_vec_o
);

  localparam int HALFWORDS_PER_GROUP = 12;
  localparam int GROUP_POLY_COEFFS = 20;
  localparam int LOCAL_ACTIVE_N_CONST = ACTIVE_N_CONST - (START_GROUP_IDX * GROUP_POLY_COEFFS);

  integer local_group_idx;
  integer local_word_sel_idx;
  integer local_halfword_idx;
  integer block_base_idx;
  logic [63:0] keypair_pack_x0;
  logic [63:0] keypair_pack_x1;
  logic [63:0] keypair_pack_x2;
  logic [63:0] keypair_pack_x3;
  logic [63:0] keypair_pack_word;
  logic [15:0] keypair_pack_halfword;

  function automatic logic [63:0] get_pk_pack_block_from_poly_const(
    input logic signed [GROUP_COUNT*20*COEFF_W-1:0] pkpoly_chunk,
    input int unsigned block_idx
  );
    int unsigned base_idx;
    int unsigned coeff_cnt;
    int unsigned coeff_idx;
    logic [63:0] x;
    logic [63:0] mul;
    begin
      base_idx = block_idx * 5;
      coeff_cnt = LOCAL_ACTIVE_N_CONST - base_idx;
      if (coeff_cnt > 5) begin
        coeff_cnt = 5;
      end
      x = 64'd0;
      mul = 64'd1;
      for (coeff_idx = 0; coeff_idx < 5; coeff_idx++) begin
        if ((coeff_idx < coeff_cnt) && ((base_idx + coeff_idx) < (GROUP_COUNT * GROUP_POLY_COEFFS))) begin
          x = x + ($unsigned(pkpoly_chunk[(base_idx + coeff_idx)*COEFF_W +: COEFF_W]) * mul);
        end
        if (coeff_idx < coeff_cnt) begin
          mul = mul * 64'd769;
        end
      end
      get_pk_pack_block_from_poly_const = x;
    end
  endfunction

  always_comb begin
    pk_chunk_vec_o = '0;
    keypair_pack_x0 = 64'd0;
    keypair_pack_x1 = 64'd0;
    keypair_pack_x2 = 64'd0;
    keypair_pack_x3 = 64'd0;
    keypair_pack_word = 64'd0;
    keypair_pack_halfword = 16'd0;

    for (local_group_idx = 0; local_group_idx < GROUP_COUNT; local_group_idx++) begin
      block_base_idx = 4 * local_group_idx;
      keypair_pack_x0 = get_pk_pack_block_from_poly_const(pk_poly_chunk_i, block_base_idx + 0);
      keypair_pack_x1 = get_pk_pack_block_from_poly_const(pk_poly_chunk_i, block_base_idx + 1);
      keypair_pack_x2 = get_pk_pack_block_from_poly_const(pk_poly_chunk_i, block_base_idx + 2);
      keypair_pack_x3 = get_pk_pack_block_from_poly_const(pk_poly_chunk_i, block_base_idx + 3);

      for (local_word_sel_idx = 0; local_word_sel_idx < 3; local_word_sel_idx++) begin
        unique case (local_word_sel_idx)
          0: keypair_pack_word = keypair_pack_x0 | ((keypair_pack_x3 & 64'hFFFF) << 48);
          1: keypair_pack_word = keypair_pack_x1 | (((keypair_pack_x3 >> 16) & 64'hFFFF) << 48);
          default: keypair_pack_word = keypair_pack_x2 | (((keypair_pack_x3 >> 32) & 64'hFFFF) << 48);
        endcase

        for (local_halfword_idx = 0; local_halfword_idx < 4; local_halfword_idx++) begin
          keypair_pack_halfword = keypair_pack_word[16*local_halfword_idx +: 16];
          pk_chunk_vec_o[((local_group_idx * HALFWORDS_PER_GROUP) +
                          (local_word_sel_idx * 4) +
                          local_halfword_idx)*COEFF_W +: COEFF_W] = keypair_pack_halfword;
        end
      end
    end
  end

endmodule

module zen_pk_poly_pack_codec #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic [1:0] profile_id_i,
  input  logic signed [NTT_N*COEFF_W-1:0] pk_poly_vec_i,
  output logic signed [NTT_N*COEFF_W-1:0] pk_bytes_vec_o,
  output logic [31:0] bytes_produced_o
);

  import zen_accel_pkg::*;

  localparam int PK_CHUNK16_HALFWORDS = 16 * 12;
  localparam int PK_CHUNK9_HALFWORDS = 9 * 12;
  localparam int PK_CHUNK6_HALFWORDS = 6 * 12;
  localparam int PK_CHUNK3_HALFWORDS = 3 * 12;
  localparam int PK_GROUP_POLY_COEFFS = 20;

  logic [31:0] active_n;
  logic [31:0] active_pk_pack_bytes;
  logic signed [PK_CHUNK16_HALFWORDS*COEFF_W-1:0] pk128_chunk0;
  logic signed [PK_CHUNK9_HALFWORDS*COEFF_W-1:0] pk128_chunk1;
  logic signed [PK_CHUNK16_HALFWORDS*COEFF_W-1:0] pk256_chunk0;
  logic signed [PK_CHUNK16_HALFWORDS*COEFF_W-1:0] pk256_chunk1;
  logic signed [PK_CHUNK16_HALFWORDS*COEFF_W-1:0] pk256_chunk2;
  logic signed [PK_CHUNK3_HALFWORDS*COEFF_W-1:0] pk256_chunk3;
  logic signed [PK_CHUNK16_HALFWORDS*COEFF_W-1:0] pk512_chunk0;
  logic signed [PK_CHUNK16_HALFWORDS*COEFF_W-1:0] pk512_chunk1;
  logic signed [PK_CHUNK16_HALFWORDS*COEFF_W-1:0] pk512_chunk2;
  logic signed [PK_CHUNK16_HALFWORDS*COEFF_W-1:0] pk512_chunk3;
  logic signed [PK_CHUNK16_HALFWORDS*COEFF_W-1:0] pk512_chunk4;
  logic signed [PK_CHUNK16_HALFWORDS*COEFF_W-1:0] pk512_chunk5;
  logic signed [PK_CHUNK6_HALFWORDS*COEFF_W-1:0] pk512_chunk6;
  integer keypair_pack_rem;
  integer keypair_pack_byte_idx;
  integer keypair_pack_word_idx;
  integer keypair_pack_bit_idx;
  logic [63:0] keypair_pack_x0;
  logic [63:0] keypair_pack_x1;
  logic [63:0] keypair_pack_x2;
  logic [63:0] keypair_pack_x3;
  logic [63:0] keypair_pack_word;
  logic [15:0] keypair_pack_halfword;
  integer keypair_copy_idx;

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

  function automatic logic [63:0] get_pk_pack_block_from_poly(
    input logic [31:0] active_n_i,
    input logic signed [NTT_N*COEFF_W-1:0] pkpoly_vec,
    input int unsigned block_idx
  );
    int unsigned base_idx;
    int unsigned coeff_cnt;
    int unsigned coeff_idx;
    logic [63:0] x;
    logic [63:0] mul;
    begin
      base_idx = block_idx * 5;
      coeff_cnt = active_n_i - base_idx;
      if (coeff_cnt > 5) begin
        coeff_cnt = 5;
      end
      x = 64'd0;
      mul = 64'd1;
      for (coeff_idx = 0; coeff_idx < 5; coeff_idx++) begin
        if ((coeff_idx < coeff_cnt) && ((base_idx + coeff_idx) < NTT_N)) begin
          x = x + ($unsigned(pkpoly_vec[(base_idx + coeff_idx)*COEFF_W +: COEFF_W]) * mul);
        end
        if (coeff_idx < coeff_cnt) begin
          mul = mul * 64'd769;
        end
      end
      get_pk_pack_block_from_poly = x;
    end
  endfunction

  assign active_n = limited_profile_n(profile_id_i);
  assign active_pk_pack_bytes = pk_pack_bytes_for_n(active_n);

  zen_pk_poly_pack_group_chunk_codec #(
    .NTT_N(NTT_N),
    .COEFF_W(COEFF_W),
    .ACTIVE_N_CONST(512),
    .START_GROUP_IDX(0),
    .GROUP_COUNT(16)
  ) u_pk128_chunk0 (
    .pk_poly_chunk_i(pk_poly_vec_i[0 +: (16 * PK_GROUP_POLY_COEFFS * COEFF_W)]),
    .pk_chunk_vec_o(pk128_chunk0)
  );

  zen_pk_poly_pack_group_chunk_codec #(
    .NTT_N(NTT_N),
    .COEFF_W(COEFF_W),
    .ACTIVE_N_CONST(512),
    .START_GROUP_IDX(16),
    .GROUP_COUNT(9)
  ) u_pk128_chunk1 (
    .pk_poly_chunk_i(pk_poly_vec_i[(16 * PK_GROUP_POLY_COEFFS * COEFF_W) +:
                                   (9 * PK_GROUP_POLY_COEFFS * COEFF_W)]),
    .pk_chunk_vec_o(pk128_chunk1)
  );

  generate
    if (NTT_N >= 1024) begin : g_pk256_chunks
      zen_pk_poly_pack_group_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .ACTIVE_N_CONST(1024),
        .START_GROUP_IDX(0),
        .GROUP_COUNT(16)
      ) u_pk256_chunk0 (
        .pk_poly_chunk_i(pk_poly_vec_i[0 +: (16 * PK_GROUP_POLY_COEFFS * COEFF_W)]),
        .pk_chunk_vec_o(pk256_chunk0)
      );

      zen_pk_poly_pack_group_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .ACTIVE_N_CONST(1024),
        .START_GROUP_IDX(16),
        .GROUP_COUNT(16)
      ) u_pk256_chunk1 (
        .pk_poly_chunk_i(pk_poly_vec_i[(16 * PK_GROUP_POLY_COEFFS * COEFF_W) +:
                                       (16 * PK_GROUP_POLY_COEFFS * COEFF_W)]),
        .pk_chunk_vec_o(pk256_chunk1)
      );

      zen_pk_poly_pack_group_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .ACTIVE_N_CONST(1024),
        .START_GROUP_IDX(32),
        .GROUP_COUNT(16)
      ) u_pk256_chunk2 (
        .pk_poly_chunk_i(pk_poly_vec_i[(32 * PK_GROUP_POLY_COEFFS * COEFF_W) +:
                                       (16 * PK_GROUP_POLY_COEFFS * COEFF_W)]),
        .pk_chunk_vec_o(pk256_chunk2)
      );

      zen_pk_poly_pack_group_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .ACTIVE_N_CONST(1024),
        .START_GROUP_IDX(48),
        .GROUP_COUNT(3)
      ) u_pk256_chunk3 (
        .pk_poly_chunk_i(pk_poly_vec_i[(48 * PK_GROUP_POLY_COEFFS * COEFF_W) +:
                                       (3 * PK_GROUP_POLY_COEFFS * COEFF_W)]),
        .pk_chunk_vec_o(pk256_chunk3)
      );
    end else begin : g_no_pk256_chunks
      assign pk256_chunk0 = '0;
      assign pk256_chunk1 = '0;
      assign pk256_chunk2 = '0;
      assign pk256_chunk3 = '0;
    end
  endgenerate

  generate
    if (NTT_N >= 2048) begin : g_pk512_chunks
      zen_pk_poly_pack_group_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .ACTIVE_N_CONST(2048),
        .START_GROUP_IDX(0),
        .GROUP_COUNT(16)
      ) u_pk512_chunk0 (
        .pk_poly_chunk_i(pk_poly_vec_i[0 +: (16 * PK_GROUP_POLY_COEFFS * COEFF_W)]),
        .pk_chunk_vec_o(pk512_chunk0)
      );

      zen_pk_poly_pack_group_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .ACTIVE_N_CONST(2048),
        .START_GROUP_IDX(16),
        .GROUP_COUNT(16)
      ) u_pk512_chunk1 (
        .pk_poly_chunk_i(pk_poly_vec_i[(16 * PK_GROUP_POLY_COEFFS * COEFF_W) +:
                                       (16 * PK_GROUP_POLY_COEFFS * COEFF_W)]),
        .pk_chunk_vec_o(pk512_chunk1)
      );

      zen_pk_poly_pack_group_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .ACTIVE_N_CONST(2048),
        .START_GROUP_IDX(32),
        .GROUP_COUNT(16)
      ) u_pk512_chunk2 (
        .pk_poly_chunk_i(pk_poly_vec_i[(32 * PK_GROUP_POLY_COEFFS * COEFF_W) +:
                                       (16 * PK_GROUP_POLY_COEFFS * COEFF_W)]),
        .pk_chunk_vec_o(pk512_chunk2)
      );

      zen_pk_poly_pack_group_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .ACTIVE_N_CONST(2048),
        .START_GROUP_IDX(48),
        .GROUP_COUNT(16)
      ) u_pk512_chunk3 (
        .pk_poly_chunk_i(pk_poly_vec_i[(48 * PK_GROUP_POLY_COEFFS * COEFF_W) +:
                                       (16 * PK_GROUP_POLY_COEFFS * COEFF_W)]),
        .pk_chunk_vec_o(pk512_chunk3)
      );

      zen_pk_poly_pack_group_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .ACTIVE_N_CONST(2048),
        .START_GROUP_IDX(64),
        .GROUP_COUNT(16)
      ) u_pk512_chunk4 (
        .pk_poly_chunk_i(pk_poly_vec_i[(64 * PK_GROUP_POLY_COEFFS * COEFF_W) +:
                                       (16 * PK_GROUP_POLY_COEFFS * COEFF_W)]),
        .pk_chunk_vec_o(pk512_chunk4)
      );

      zen_pk_poly_pack_group_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .ACTIVE_N_CONST(2048),
        .START_GROUP_IDX(80),
        .GROUP_COUNT(16)
      ) u_pk512_chunk5 (
        .pk_poly_chunk_i(pk_poly_vec_i[(80 * PK_GROUP_POLY_COEFFS * COEFF_W) +:
                                       (16 * PK_GROUP_POLY_COEFFS * COEFF_W)]),
        .pk_chunk_vec_o(pk512_chunk5)
      );

      zen_pk_poly_pack_group_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .ACTIVE_N_CONST(2048),
        .START_GROUP_IDX(96),
        .GROUP_COUNT(6)
      ) u_pk512_chunk6 (
        .pk_poly_chunk_i(pk_poly_vec_i[(96 * PK_GROUP_POLY_COEFFS * COEFF_W) +:
                                       (6 * PK_GROUP_POLY_COEFFS * COEFF_W)]),
        .pk_chunk_vec_o(pk512_chunk6)
      );
    end else begin : g_no_pk512_chunks
      assign pk512_chunk0 = '0;
      assign pk512_chunk1 = '0;
      assign pk512_chunk2 = '0;
      assign pk512_chunk3 = '0;
      assign pk512_chunk4 = '0;
      assign pk512_chunk5 = '0;
      assign pk512_chunk6 = '0;
    end
  endgenerate

  always_comb begin
    pk_bytes_vec_o = '0;
    bytes_produced_o = active_pk_pack_bytes;
    keypair_pack_word_idx = 0;
    keypair_pack_byte_idx = 0;
    keypair_pack_x0 = 64'd0;
    keypair_pack_x1 = 64'd0;
    keypair_pack_x2 = 64'd0;
    keypair_pack_x3 = 64'd0;
    keypair_pack_word = 64'd0;
    keypair_pack_halfword = 16'd0;

    if (active_n == 512) begin
      for (keypair_copy_idx = 0; keypair_copy_idx < PK_CHUNK16_HALFWORDS; keypair_copy_idx++) begin
        pk_bytes_vec_o[keypair_copy_idx*COEFF_W +: COEFF_W] =
          pk128_chunk0[keypair_copy_idx*COEFF_W +: COEFF_W];
      end
      for (keypair_copy_idx = 0; keypair_copy_idx < PK_CHUNK9_HALFWORDS; keypair_copy_idx++) begin
        pk_bytes_vec_o[(PK_CHUNK16_HALFWORDS + keypair_copy_idx)*COEFF_W +: COEFF_W] =
          pk128_chunk1[keypair_copy_idx*COEFF_W +: COEFF_W];
      end
      keypair_pack_word_idx = PK_CHUNK16_HALFWORDS + PK_CHUNK9_HALFWORDS;
      keypair_pack_x0 = get_pk_pack_block_from_poly(active_n, pk_poly_vec_i, 100);
      keypair_pack_x1 = get_pk_pack_block_from_poly(active_n, pk_poly_vec_i, 101);
      keypair_pack_x2 = get_pk_pack_block_from_poly(active_n, pk_poly_vec_i, 102);
      for (keypair_pack_bit_idx = 0; keypair_pack_bit_idx < 2; keypair_pack_bit_idx++) begin
        if (keypair_pack_bit_idx == 0) begin
          keypair_pack_word = keypair_pack_x0 | ((keypair_pack_x2 & 64'hFFFF) << 48);
        end else begin
          keypair_pack_word = keypair_pack_x1 | (((keypair_pack_x2 >> 16) & 64'hF) << 48);
        end
        for (keypair_pack_rem = 0; keypair_pack_rem < 4; keypair_pack_rem++) begin
          keypair_pack_halfword = 16'd0;
          keypair_pack_byte_idx = 2 * (keypair_pack_word_idx + keypair_pack_rem);
          if (keypair_pack_byte_idx < active_pk_pack_bytes) begin
            keypair_pack_halfword[7:0] = keypair_pack_word[16*keypair_pack_rem +: 8];
          end
          if ((keypair_pack_byte_idx + 1) < active_pk_pack_bytes) begin
            keypair_pack_halfword[15:8] = keypair_pack_word[16*keypair_pack_rem + 8 +: 8];
          end
          pk_bytes_vec_o[(keypair_pack_word_idx + keypair_pack_rem)*COEFF_W +: COEFF_W] = keypair_pack_halfword;
        end
        keypair_pack_word_idx = keypair_pack_word_idx + 4;
      end
    end else if ((NTT_N >= 1024) && (active_n == 1024)) begin
      for (keypair_copy_idx = 0; keypair_copy_idx < PK_CHUNK16_HALFWORDS; keypair_copy_idx++) begin
        pk_bytes_vec_o[keypair_copy_idx*COEFF_W +: COEFF_W] =
          pk256_chunk0[keypair_copy_idx*COEFF_W +: COEFF_W];
        pk_bytes_vec_o[(PK_CHUNK16_HALFWORDS + keypair_copy_idx)*COEFF_W +: COEFF_W] =
          pk256_chunk1[keypair_copy_idx*COEFF_W +: COEFF_W];
        pk_bytes_vec_o[((2 * PK_CHUNK16_HALFWORDS) + keypair_copy_idx)*COEFF_W +: COEFF_W] =
          pk256_chunk2[keypair_copy_idx*COEFF_W +: COEFF_W];
      end
      for (keypair_copy_idx = 0; keypair_copy_idx < PK_CHUNK3_HALFWORDS; keypair_copy_idx++) begin
        pk_bytes_vec_o[((3 * PK_CHUNK16_HALFWORDS) + keypair_copy_idx)*COEFF_W +: COEFF_W] =
          pk256_chunk3[keypair_copy_idx*COEFF_W +: COEFF_W];
      end
      keypair_pack_word_idx = (3 * PK_CHUNK16_HALFWORDS) + PK_CHUNK3_HALFWORDS;
      keypair_pack_word = get_pk_pack_block_from_poly(active_n, pk_poly_vec_i, 204);
      for (keypair_pack_rem = 0; keypair_pack_rem < 4; keypair_pack_rem++) begin
        keypair_pack_halfword = 16'd0;
        keypair_pack_byte_idx = 2 * (keypair_pack_word_idx + keypair_pack_rem);
        if (keypair_pack_byte_idx < active_pk_pack_bytes) begin
          keypair_pack_halfword[7:0] = keypair_pack_word[16*keypair_pack_rem +: 8];
        end
        if ((keypair_pack_byte_idx + 1) < active_pk_pack_bytes) begin
          keypair_pack_halfword[15:8] = keypair_pack_word[16*keypair_pack_rem + 8 +: 8];
        end
        pk_bytes_vec_o[(keypair_pack_word_idx + keypair_pack_rem)*COEFF_W +: COEFF_W] = keypair_pack_halfword;
      end
    end else if (NTT_N >= 2048) begin
      for (keypair_copy_idx = 0; keypair_copy_idx < PK_CHUNK16_HALFWORDS; keypair_copy_idx++) begin
        pk_bytes_vec_o[keypair_copy_idx*COEFF_W +: COEFF_W] =
          pk512_chunk0[keypair_copy_idx*COEFF_W +: COEFF_W];
        pk_bytes_vec_o[(PK_CHUNK16_HALFWORDS + keypair_copy_idx)*COEFF_W +: COEFF_W] =
          pk512_chunk1[keypair_copy_idx*COEFF_W +: COEFF_W];
        pk_bytes_vec_o[((2 * PK_CHUNK16_HALFWORDS) + keypair_copy_idx)*COEFF_W +: COEFF_W] =
          pk512_chunk2[keypair_copy_idx*COEFF_W +: COEFF_W];
        pk_bytes_vec_o[((3 * PK_CHUNK16_HALFWORDS) + keypair_copy_idx)*COEFF_W +: COEFF_W] =
          pk512_chunk3[keypair_copy_idx*COEFF_W +: COEFF_W];
        pk_bytes_vec_o[((4 * PK_CHUNK16_HALFWORDS) + keypair_copy_idx)*COEFF_W +: COEFF_W] =
          pk512_chunk4[keypair_copy_idx*COEFF_W +: COEFF_W];
        pk_bytes_vec_o[((5 * PK_CHUNK16_HALFWORDS) + keypair_copy_idx)*COEFF_W +: COEFF_W] =
          pk512_chunk5[keypair_copy_idx*COEFF_W +: COEFF_W];
      end
      for (keypair_copy_idx = 0; keypair_copy_idx < PK_CHUNK6_HALFWORDS; keypair_copy_idx++) begin
        pk_bytes_vec_o[((6 * PK_CHUNK16_HALFWORDS) + keypair_copy_idx)*COEFF_W +: COEFF_W] =
          pk512_chunk6[keypair_copy_idx*COEFF_W +: COEFF_W];
      end
      keypair_pack_word_idx = (6 * PK_CHUNK16_HALFWORDS) + PK_CHUNK6_HALFWORDS;
      keypair_pack_x0 = get_pk_pack_block_from_poly(active_n, pk_poly_vec_i, 408);
      keypair_pack_x1 = get_pk_pack_block_from_poly(active_n, pk_poly_vec_i, 409);
      keypair_pack_word = keypair_pack_x0 | ((keypair_pack_x1 & 64'hFFFF) << 48);
      for (keypair_pack_rem = 0; keypair_pack_rem < 4; keypair_pack_rem++) begin
        keypair_pack_halfword = 16'd0;
        keypair_pack_byte_idx = 2 * (keypair_pack_word_idx + keypair_pack_rem);
        if (keypair_pack_byte_idx < active_pk_pack_bytes) begin
          keypair_pack_halfword[7:0] = keypair_pack_word[16*keypair_pack_rem +: 8];
        end
        if ((keypair_pack_byte_idx + 1) < active_pk_pack_bytes) begin
          keypair_pack_halfword[15:8] = keypair_pack_word[16*keypair_pack_rem + 8 +: 8];
        end
        pk_bytes_vec_o[(keypair_pack_word_idx + keypair_pack_rem)*COEFF_W +: COEFF_W] = keypair_pack_halfword;
      end
      keypair_pack_word_idx = keypair_pack_word_idx + 4;
      keypair_pack_word = (keypair_pack_x1 >> 16) & 64'h1FFF;
      for (keypair_pack_rem = 0; keypair_pack_rem < 4; keypair_pack_rem++) begin
        keypair_pack_halfword = 16'd0;
        keypair_pack_byte_idx = 2 * (keypair_pack_word_idx + keypair_pack_rem);
        if (keypair_pack_byte_idx < active_pk_pack_bytes) begin
          keypair_pack_halfword[7:0] = keypair_pack_word[16*keypair_pack_rem +: 8];
        end
        if ((keypair_pack_byte_idx + 1) < active_pk_pack_bytes) begin
          keypair_pack_halfword[15:8] = keypair_pack_word[16*keypair_pack_rem + 8 +: 8];
        end
        pk_bytes_vec_o[(keypair_pack_word_idx + keypair_pack_rem)*COEFF_W +: COEFF_W] = keypair_pack_halfword;
      end
    end
  end

endmodule

module zen_sk_poly_pack_codec #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic [1:0] profile_id_i,
  input  logic signed [NTT_N*COEFF_W-1:0] sk_f_ntt_poly_vec_i,
  input  logic signed [NTT_N*COEFF_W-1:0] sk_f2_poly_vec_i,
  output logic signed [NTT_N*COEFF_W-1:0] sk_lo_bytes_vec_o,
  output logic signed [NTT_N*COEFF_W-1:0] sk_hi_bytes_vec_o,
  output logic [31:0] bytes_produced_o
);

  import zen_accel_pkg::*;

  logic [31:0] active_n;
  logic [31:0] active_sk_fntt_pack_bytes;
  logic [31:0] active_sk_f2_pack_bytes;
  logic [31:0] active_sk_pack_bytes;
  logic signed [NTT_N*COEFF_W-1:0] sk_fntt_lo_bytes_vec;
  logic signed [NTT_N*COEFF_W-1:0] sk_fntt_hi_bytes_vec;
  logic signed [NTT_N*COEFF_W-1:0] sk_f2_hi_bytes_vec;

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

  assign active_n = limited_profile_n(profile_id_i);
  assign active_sk_fntt_pack_bytes = (active_n * 5) / 4;
  assign active_sk_f2_pack_bytes = active_n / 32;
  assign active_sk_pack_bytes = active_sk_fntt_pack_bytes + active_sk_f2_pack_bytes;

  zen_sk_fntt_lo_pack_codec #(
    .NTT_N(NTT_N),
    .COEFF_W(COEFF_W)
  ) u_sk_fntt_lo_pack_codec (
    .profile_id_i(profile_id_i),
    .sk_f_ntt_poly_vec_i(sk_f_ntt_poly_vec_i),
    .sk_lo_bytes_vec_o(sk_fntt_lo_bytes_vec)
  );

  zen_sk_fntt_hi_pack_codec #(
    .NTT_N(NTT_N),
    .COEFF_W(COEFF_W)
  ) u_sk_fntt_hi_pack_codec (
    .profile_id_i(profile_id_i),
    .sk_f_ntt_poly_vec_i(sk_f_ntt_poly_vec_i),
    .sk_hi_bytes_vec_o(sk_fntt_hi_bytes_vec)
  );

  zen_sk_f2_hi_pack_codec #(
    .NTT_N(NTT_N),
    .COEFF_W(COEFF_W)
  ) u_sk_f2_hi_pack_codec (
    .profile_id_i(profile_id_i),
    .sk_f2_poly_vec_i(sk_f2_poly_vec_i),
    .sk_hi_bytes_vec_o(sk_f2_hi_bytes_vec)
  );

  assign sk_lo_bytes_vec_o = sk_fntt_lo_bytes_vec;
  assign sk_hi_bytes_vec_o = sk_fntt_hi_bytes_vec | sk_f2_hi_bytes_vec;
  assign bytes_produced_o = active_sk_pack_bytes;

endmodule

module zen_sk_fntt_lo_pack_codec #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic [1:0] profile_id_i,
  input  logic signed [NTT_N*COEFF_W-1:0] sk_f_ntt_poly_vec_i,
  output logic signed [NTT_N*COEFF_W-1:0] sk_lo_bytes_vec_o
);

  import zen_accel_pkg::*;

  localparam int N4_LOOP_MAX = NTT_N / 4;

  logic [31:0] active_n;
  logic [31:0] active_n4;
  integer keypair_pack_idx;
  integer keypair_pack_bit_idx;
  integer keypair_pack_byte_idx;
  logic [7:0] keypair_pack_byte;
  logic [9:0] sk_pack_c0;
  logic [9:0] sk_pack_c1;
  logic [9:0] sk_pack_c2;
  logic [9:0] sk_pack_c3;

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

  assign active_n = limited_profile_n(profile_id_i);
  assign active_n4 = active_n / 4;

  always_comb begin
    sk_lo_bytes_vec_o = '0;

    for (keypair_pack_idx = 0; keypair_pack_idx < N4_LOOP_MAX; keypair_pack_idx++) begin
      if (keypair_pack_idx < active_n4) begin
        sk_pack_c0 = sk_f_ntt_poly_vec_i[(4*keypair_pack_idx + 0)*COEFF_W +: 10];
        sk_pack_c1 = sk_f_ntt_poly_vec_i[(4*keypair_pack_idx + 1)*COEFF_W +: 10];
        sk_pack_c2 = sk_f_ntt_poly_vec_i[(4*keypair_pack_idx + 2)*COEFF_W +: 10];
        sk_pack_c3 = sk_f_ntt_poly_vec_i[(4*keypair_pack_idx + 3)*COEFF_W +: 10];
        for (keypair_pack_bit_idx = 0; keypair_pack_bit_idx < 5; keypair_pack_bit_idx++) begin
          keypair_pack_byte_idx = 5 * keypair_pack_idx + keypair_pack_bit_idx;
          unique case (keypair_pack_bit_idx)
            0: keypair_pack_byte = sk_pack_c0[7:0];
            1: keypair_pack_byte = {sk_pack_c1[5:0], sk_pack_c0[9:8]};
            2: keypair_pack_byte = {sk_pack_c2[3:0], sk_pack_c1[9:6]};
            3: keypair_pack_byte = {sk_pack_c3[1:0], sk_pack_c2[9:4]};
            default: keypair_pack_byte = sk_pack_c3[9:2];
          endcase
          if ((keypair_pack_byte_idx < active_n) && (keypair_pack_byte_idx < NTT_N)) begin
            sk_lo_bytes_vec_o[keypair_pack_byte_idx*COEFF_W +: 8] = keypair_pack_byte;
          end
        end
      end
    end
  end

endmodule

module zen_sk_fntt_hi_pack_chunk_codec #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int SRC_BASE_BYTE = 0,
  parameter int CHUNK_HI_BYTES = 128
) (
  input  logic signed [((((SRC_BASE_BYTE + CHUNK_HI_BYTES - 1) / 5) - (SRC_BASE_BYTE / 5) + 1) * 4 * COEFF_W)-1:0] sk_f_ntt_chunk_i,
  output logic signed [CHUNK_HI_BYTES*COEFF_W-1:0] sk_hi_chunk_vec_o
);

  localparam int MAX_VALID_PACK_BYTES = (NTT_N * 5) / 4;
  localparam int FIRST_GROUP_IDX = SRC_BASE_BYTE / 5;

  integer local_hi_idx;
  integer src_byte_idx;
  integer src_group_idx;
  integer src_group_local_idx;
  integer src_sel_idx;
  logic [7:0] keypair_pack_byte;
  logic [9:0] sk_pack_c0;
  logic [9:0] sk_pack_c1;
  logic [9:0] sk_pack_c2;
  logic [9:0] sk_pack_c3;

  generate
    if ((SRC_BASE_BYTE + CHUNK_HI_BYTES) <= MAX_VALID_PACK_BYTES) begin : gen_valid_chunk
      always_comb begin
        sk_hi_chunk_vec_o = '0;
        for (local_hi_idx = 0; local_hi_idx < CHUNK_HI_BYTES; local_hi_idx++) begin
          src_byte_idx = SRC_BASE_BYTE + local_hi_idx;
          src_group_idx = src_byte_idx / 5;
          src_group_local_idx = src_group_idx - FIRST_GROUP_IDX;
          src_sel_idx = src_byte_idx % 5;
          sk_pack_c0 = sk_f_ntt_chunk_i[(4*src_group_local_idx + 0)*COEFF_W +: 10];
          sk_pack_c1 = sk_f_ntt_chunk_i[(4*src_group_local_idx + 1)*COEFF_W +: 10];
          sk_pack_c2 = sk_f_ntt_chunk_i[(4*src_group_local_idx + 2)*COEFF_W +: 10];
          sk_pack_c3 = sk_f_ntt_chunk_i[(4*src_group_local_idx + 3)*COEFF_W +: 10];
          unique case (src_sel_idx)
            0: keypair_pack_byte = sk_pack_c0[7:0];
            1: keypair_pack_byte = {sk_pack_c1[5:0], sk_pack_c0[9:8]};
            2: keypair_pack_byte = {sk_pack_c2[3:0], sk_pack_c1[9:6]};
            3: keypair_pack_byte = {sk_pack_c3[1:0], sk_pack_c2[9:4]};
            default: keypair_pack_byte = sk_pack_c3[9:2];
          endcase
          sk_hi_chunk_vec_o[local_hi_idx*COEFF_W +: 8] = keypair_pack_byte;
        end
      end
    end else begin : gen_invalid_chunk
      always_comb begin
        sk_hi_chunk_vec_o = '0;
      end
    end
  endgenerate

endmodule

module zen_sk_fntt_hi_pack_codec #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic [1:0] profile_id_i,
  input  logic signed [NTT_N*COEFF_W-1:0] sk_f_ntt_poly_vec_i,
  output logic signed [NTT_N*COEFF_W-1:0] sk_hi_bytes_vec_o
);

  import zen_accel_pkg::*;

  localparam int HI_SEG_BYTES = 128;
  localparam int HI_SEG_BITS = HI_SEG_BYTES * COEFF_W;

  logic signed [HI_SEG_BITS-1:0] hi128_seg0;
  logic signed [HI_SEG_BITS-1:0] hi256_seg0;
  logic signed [HI_SEG_BITS-1:0] hi256_seg1;
  logic signed [HI_SEG_BITS-1:0] hi512_seg0;
  logic signed [HI_SEG_BITS-1:0] hi512_seg1;
  logic signed [HI_SEG_BITS-1:0] hi512_seg2;
  logic signed [HI_SEG_BITS-1:0] hi512_seg3;

  zen_sk_fntt_hi_pack_chunk_codec #(
    .NTT_N(NTT_N),
    .COEFF_W(COEFF_W),
    .SRC_BASE_BYTE(512),
    .CHUNK_HI_BYTES(HI_SEG_BYTES)
  ) u_hi128_seg0 (
    .sk_f_ntt_chunk_i(sk_f_ntt_poly_vec_i[((512 / 5) * 4 * COEFF_W) +:
                                          ((((512 + HI_SEG_BYTES - 1) / 5) - (512 / 5) + 1) * 4 * COEFF_W)]),
    .sk_hi_chunk_vec_o(hi128_seg0)
  );

  generate
    if (NTT_N >= 1024) begin : g_hi256_segments
      zen_sk_fntt_hi_pack_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .SRC_BASE_BYTE(1024),
        .CHUNK_HI_BYTES(HI_SEG_BYTES)
      ) u_hi256_seg0 (
        .sk_f_ntt_chunk_i(sk_f_ntt_poly_vec_i[((1024 / 5) * 4 * COEFF_W) +:
                                              ((((1024 + HI_SEG_BYTES - 1) / 5) - (1024 / 5) + 1) * 4 * COEFF_W)]),
        .sk_hi_chunk_vec_o(hi256_seg0)
      );

      zen_sk_fntt_hi_pack_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .SRC_BASE_BYTE(1152),
        .CHUNK_HI_BYTES(HI_SEG_BYTES)
      ) u_hi256_seg1 (
        .sk_f_ntt_chunk_i(sk_f_ntt_poly_vec_i[((1152 / 5) * 4 * COEFF_W) +:
                                              ((((1152 + HI_SEG_BYTES - 1) / 5) - (1152 / 5) + 1) * 4 * COEFF_W)]),
        .sk_hi_chunk_vec_o(hi256_seg1)
      );
    end else begin : g_no_hi256_segments
      assign hi256_seg0 = '0;
      assign hi256_seg1 = '0;
    end
  endgenerate

  generate
    if (NTT_N >= 2048) begin : g_hi512_segments
      zen_sk_fntt_hi_pack_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .SRC_BASE_BYTE(2048),
        .CHUNK_HI_BYTES(HI_SEG_BYTES)
      ) u_hi512_seg0 (
        .sk_f_ntt_chunk_i(sk_f_ntt_poly_vec_i[((2048 / 5) * 4 * COEFF_W) +:
                                              ((((2048 + HI_SEG_BYTES - 1) / 5) - (2048 / 5) + 1) * 4 * COEFF_W)]),
        .sk_hi_chunk_vec_o(hi512_seg0)
      );

      zen_sk_fntt_hi_pack_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .SRC_BASE_BYTE(2176),
        .CHUNK_HI_BYTES(HI_SEG_BYTES)
      ) u_hi512_seg1 (
        .sk_f_ntt_chunk_i(sk_f_ntt_poly_vec_i[((2176 / 5) * 4 * COEFF_W) +:
                                              ((((2176 + HI_SEG_BYTES - 1) / 5) - (2176 / 5) + 1) * 4 * COEFF_W)]),
        .sk_hi_chunk_vec_o(hi512_seg1)
      );

      zen_sk_fntt_hi_pack_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .SRC_BASE_BYTE(2304),
        .CHUNK_HI_BYTES(HI_SEG_BYTES)
      ) u_hi512_seg2 (
        .sk_f_ntt_chunk_i(sk_f_ntt_poly_vec_i[((2304 / 5) * 4 * COEFF_W) +:
                                              ((((2304 + HI_SEG_BYTES - 1) / 5) - (2304 / 5) + 1) * 4 * COEFF_W)]),
        .sk_hi_chunk_vec_o(hi512_seg2)
      );

      zen_sk_fntt_hi_pack_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .SRC_BASE_BYTE(2432),
        .CHUNK_HI_BYTES(HI_SEG_BYTES)
      ) u_hi512_seg3 (
        .sk_f_ntt_chunk_i(sk_f_ntt_poly_vec_i[((2432 / 5) * 4 * COEFF_W) +:
                                              ((((2432 + HI_SEG_BYTES - 1) / 5) - (2432 / 5) + 1) * 4 * COEFF_W)]),
        .sk_hi_chunk_vec_o(hi512_seg3)
      );
    end else begin : g_no_hi512_segments
      assign hi512_seg0 = '0;
      assign hi512_seg1 = '0;
      assign hi512_seg2 = '0;
      assign hi512_seg3 = '0;
    end
  endgenerate

  always_comb begin
    sk_hi_bytes_vec_o = '0;

    unique case (profile_id_i)
      PROFILE_SWIFT128: begin
        sk_hi_bytes_vec_o[0 +: HI_SEG_BITS] = hi128_seg0;
      end
      PROFILE_SWIFT256: begin
        sk_hi_bytes_vec_o[0 +: HI_SEG_BITS] = hi256_seg0;
        sk_hi_bytes_vec_o[HI_SEG_BITS +: HI_SEG_BITS] = hi256_seg1;
      end
      PROFILE_SWIFT512: if (NTT_N >= 2048) begin
        sk_hi_bytes_vec_o[0 +: HI_SEG_BITS] = hi512_seg0;
        sk_hi_bytes_vec_o[HI_SEG_BITS +: HI_SEG_BITS] = hi512_seg1;
        sk_hi_bytes_vec_o[(2*HI_SEG_BITS) +: HI_SEG_BITS] = hi512_seg2;
        sk_hi_bytes_vec_o[(3*HI_SEG_BITS) +: HI_SEG_BITS] = hi512_seg3;
      end
      default: begin
      end
    endcase
  end

endmodule

module zen_sk_f2_hi_pack_chunk_codec #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int SRC_BASE_BYTE = 0,
  parameter int CHUNK_HI_BYTES = 16
) (
  input  logic signed [CHUNK_HI_BYTES*8*COEFF_W-1:0] sk_f2_chunk_i,
  output logic signed [CHUNK_HI_BYTES*COEFF_W-1:0] sk_hi_chunk_vec_o
);

  localparam int MAX_VALID_PACK_BYTES = NTT_N / 32;

  integer local_hi_idx;
  integer local_bit_idx;
  logic [7:0] keypair_pack_byte;

  generate
    if ((SRC_BASE_BYTE + CHUNK_HI_BYTES) <= MAX_VALID_PACK_BYTES) begin : gen_valid_chunk
      always_comb begin
        sk_hi_chunk_vec_o = '0;
        keypair_pack_byte = 8'd0;
        for (local_hi_idx = 0; local_hi_idx < CHUNK_HI_BYTES; local_hi_idx++) begin
          keypair_pack_byte = 8'd0;
          for (local_bit_idx = 0; local_bit_idx < 8; local_bit_idx++) begin
            keypair_pack_byte[local_bit_idx] = sk_f2_chunk_i[((local_hi_idx * 8) + local_bit_idx)*COEFF_W];
          end
          sk_hi_chunk_vec_o[local_hi_idx*COEFF_W +: 8] = keypair_pack_byte;
        end
      end
    end else begin : gen_invalid_chunk
      always_comb begin
        sk_hi_chunk_vec_o = '0;
      end
    end
  endgenerate

endmodule

module zen_sk_f2_hi_pack_codec #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W
) (
  input  logic [1:0] profile_id_i,
  input  logic signed [NTT_N*COEFF_W-1:0] sk_f2_poly_vec_i,
  output logic signed [NTT_N*COEFF_W-1:0] sk_hi_bytes_vec_o
);

  import zen_accel_pkg::*;

  localparam int HI_SEG_BYTES = 16;
  localparam int HI_SEG_BITS = HI_SEG_BYTES * COEFF_W;

  logic signed [HI_SEG_BITS-1:0] hi128_seg0;
  logic signed [HI_SEG_BITS-1:0] hi256_seg0;
  logic signed [HI_SEG_BITS-1:0] hi256_seg1;
  logic signed [HI_SEG_BITS-1:0] hi512_seg0;
  logic signed [HI_SEG_BITS-1:0] hi512_seg1;
  logic signed [HI_SEG_BITS-1:0] hi512_seg2;
  logic signed [HI_SEG_BITS-1:0] hi512_seg3;
  integer hi_copy_idx;
  integer hi_byte_base;

  zen_sk_f2_hi_pack_chunk_codec #(
    .NTT_N(NTT_N),
    .COEFF_W(COEFF_W),
    .SRC_BASE_BYTE(0),
    .CHUNK_HI_BYTES(HI_SEG_BYTES)
  ) u_hi128_seg0 (
    .sk_f2_chunk_i(sk_f2_poly_vec_i[(0 * 8 * COEFF_W) +: (HI_SEG_BYTES * 8 * COEFF_W)]),
    .sk_hi_chunk_vec_o(hi128_seg0)
  );

  generate
    if (NTT_N >= 1024) begin : g_hi256_segments
      zen_sk_f2_hi_pack_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .SRC_BASE_BYTE(0),
        .CHUNK_HI_BYTES(HI_SEG_BYTES)
      ) u_hi256_seg0 (
        .sk_f2_chunk_i(sk_f2_poly_vec_i[(0 * 8 * COEFF_W) +: (HI_SEG_BYTES * 8 * COEFF_W)]),
        .sk_hi_chunk_vec_o(hi256_seg0)
      );

      zen_sk_f2_hi_pack_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .SRC_BASE_BYTE(16),
        .CHUNK_HI_BYTES(HI_SEG_BYTES)
      ) u_hi256_seg1 (
        .sk_f2_chunk_i(sk_f2_poly_vec_i[(16 * 8 * COEFF_W) +: (HI_SEG_BYTES * 8 * COEFF_W)]),
        .sk_hi_chunk_vec_o(hi256_seg1)
      );
    end else begin : g_no_hi256_segments
      assign hi256_seg0 = '0;
      assign hi256_seg1 = '0;
    end
  endgenerate

  generate
    if (NTT_N >= 2048) begin : g_hi512_segments
      zen_sk_f2_hi_pack_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .SRC_BASE_BYTE(0),
        .CHUNK_HI_BYTES(HI_SEG_BYTES)
      ) u_hi512_seg0 (
        .sk_f2_chunk_i(sk_f2_poly_vec_i[(0 * 8 * COEFF_W) +: (HI_SEG_BYTES * 8 * COEFF_W)]),
        .sk_hi_chunk_vec_o(hi512_seg0)
      );

      zen_sk_f2_hi_pack_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .SRC_BASE_BYTE(16),
        .CHUNK_HI_BYTES(HI_SEG_BYTES)
      ) u_hi512_seg1 (
        .sk_f2_chunk_i(sk_f2_poly_vec_i[(16 * 8 * COEFF_W) +: (HI_SEG_BYTES * 8 * COEFF_W)]),
        .sk_hi_chunk_vec_o(hi512_seg1)
      );

      zen_sk_f2_hi_pack_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .SRC_BASE_BYTE(32),
        .CHUNK_HI_BYTES(HI_SEG_BYTES)
      ) u_hi512_seg2 (
        .sk_f2_chunk_i(sk_f2_poly_vec_i[(32 * 8 * COEFF_W) +: (HI_SEG_BYTES * 8 * COEFF_W)]),
        .sk_hi_chunk_vec_o(hi512_seg2)
      );

      zen_sk_f2_hi_pack_chunk_codec #(
        .NTT_N(NTT_N),
        .COEFF_W(COEFF_W),
        .SRC_BASE_BYTE(48),
        .CHUNK_HI_BYTES(HI_SEG_BYTES)
      ) u_hi512_seg3 (
        .sk_f2_chunk_i(sk_f2_poly_vec_i[(48 * 8 * COEFF_W) +: (HI_SEG_BYTES * 8 * COEFF_W)]),
        .sk_hi_chunk_vec_o(hi512_seg3)
      );
    end else begin : g_no_hi512_segments
      assign hi512_seg0 = '0;
      assign hi512_seg1 = '0;
      assign hi512_seg2 = '0;
      assign hi512_seg3 = '0;
    end
  endgenerate

  always_comb begin
    sk_hi_bytes_vec_o = '0;

    unique case (profile_id_i)
      PROFILE_SWIFT128: begin
        hi_byte_base = 128;
        for (hi_copy_idx = 0; hi_copy_idx < HI_SEG_BYTES; hi_copy_idx++) begin
          sk_hi_bytes_vec_o[(hi_byte_base + hi_copy_idx)*COEFF_W +: COEFF_W] =
            hi128_seg0[hi_copy_idx*COEFF_W +: COEFF_W];
        end
      end
      PROFILE_SWIFT256: if (NTT_N >= 1024) begin
        hi_byte_base = 256;
        for (hi_copy_idx = 0; hi_copy_idx < HI_SEG_BYTES; hi_copy_idx++) begin
          sk_hi_bytes_vec_o[(hi_byte_base + hi_copy_idx)*COEFF_W +: COEFF_W] =
            hi256_seg0[hi_copy_idx*COEFF_W +: COEFF_W];
          sk_hi_bytes_vec_o[(hi_byte_base + HI_SEG_BYTES + hi_copy_idx)*COEFF_W +: COEFF_W] =
            hi256_seg1[hi_copy_idx*COEFF_W +: COEFF_W];
        end
      end
      PROFILE_SWIFT512: if (NTT_N >= 2048) begin
        hi_byte_base = 512;
        for (hi_copy_idx = 0; hi_copy_idx < HI_SEG_BYTES; hi_copy_idx++) begin
          sk_hi_bytes_vec_o[(hi_byte_base + hi_copy_idx)*COEFF_W +: COEFF_W] =
            hi512_seg0[hi_copy_idx*COEFF_W +: COEFF_W];
          sk_hi_bytes_vec_o[(hi_byte_base + HI_SEG_BYTES + hi_copy_idx)*COEFF_W +: COEFF_W] =
            hi512_seg1[hi_copy_idx*COEFF_W +: COEFF_W];
          sk_hi_bytes_vec_o[(hi_byte_base + (2 * HI_SEG_BYTES) + hi_copy_idx)*COEFF_W +: COEFF_W] =
            hi512_seg2[hi_copy_idx*COEFF_W +: COEFF_W];
          sk_hi_bytes_vec_o[(hi_byte_base + (3 * HI_SEG_BYTES) + hi_copy_idx)*COEFF_W +: COEFF_W] =
            hi512_seg3[hi_copy_idx*COEFF_W +: COEFF_W];
        end
      end
      default: begin
      end
    endcase
  end

endmodule
