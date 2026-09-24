module zen_binary_chunk_core #(
  parameter int NTT_N = zen_accel_pkg::ZEN_N,
  parameter int COEFF_W = zen_accel_pkg::COEFF_W,
  parameter int XOR_LANES = ((zen_accel_pkg::BINARY_LANES > 32) ? 32 : zen_accel_pkg::BINARY_LANES),
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
  localparam logic [1:0] BINARY_CHUNK_OP_DEC_POST   = 2'd3;
  localparam int DECODE_Q2 = ZEN_Q / 2;

  logic [ROW_ADDR_W-1:0] row_idx_cache [0:XOR_LANES-1];
  logic [ROW_ADDR_W-1:0] row_sel_idx_cache [0:XOR_LANES-1];
  logic row_active_cache [0:XOR_LANES-1];
  logic row_lo_en_cache [0:XOR_LANES-1];
  logic row_hi_en_cache [0:XOR_LANES-1];

  always_comb begin
    integer lane_idx;
    integer row_idx;
    integer ring_n2;
    integer c0;
    integer c1;
    integer c2;
    integer c3;
    integer idx0;
    integer idx1;
    logic parity_bit;
    logic signed [COEFF_W-1:0] t0_0;
    logic signed [COEFF_W-1:0] t0_1;
    logic signed [COEFF_W-1:0] t0_2;
    logic signed [COEFF_W-1:0] t0_3;
    logic signed [31:0] mont_in_0;
    logic signed [31:0] mont_in_1;
    logic signed [31:0] mont_in_2;
    logic signed [31:0] mont_in_3;
    logic signed [31:0] mont_t_0;
    logic signed [31:0] mont_t_1;
    logic signed [31:0] mont_t_2;
    logic signed [31:0] mont_t_3;
    logic signed [15:0] mont_u_0;
    logic signed [15:0] mont_u_1;
    logic signed [15:0] mont_u_2;
    logic signed [15:0] mont_u_3;

    row_idx = 0;
    ring_n2 = 0;
    c0 = 0;
    c1 = 0;
    c2 = 0;
    c3 = 0;
    idx0 = 0;
    idx1 = 0;
    parity_bit = 1'b0;
    t0_0 = '0;
    t0_1 = '0;
    t0_2 = '0;
    t0_3 = '0;
    mont_in_0 = '0;
    mont_in_1 = '0;
    mont_in_2 = '0;
    mont_in_3 = '0;
    mont_t_0 = '0;
    mont_t_1 = '0;
    mont_t_2 = '0;
    mont_t_3 = '0;
    mont_u_0 = '0;
    mont_u_1 = '0;
    mont_u_2 = '0;
    mont_u_3 = '0;

    for (lane_idx = 0; lane_idx < XOR_LANES; lane_idx++) begin
      row_idx_cache[lane_idx] = '0;
      row_sel_idx_cache[lane_idx] = '0;
      row_active_cache[lane_idx] = 1'b0;
      row_lo_en_cache[lane_idx] = 1'b0;
      row_hi_en_cache[lane_idx] = 1'b0;
      row_idx = $unsigned(row_base) + lane_idx;

      if (row_idx < active_ring_n_i) begin
        row_idx_cache[lane_idx] = row_idx[ROW_ADDR_W-1:0];
        row_active_cache[lane_idx] = 1'b1;

        unique case (op_mode_i)
          BINARY_CHUNK_OP_R2: begin
            row_lo_en_cache[lane_idx] = vec_sel_data[row_idx*COEFF_W];
          end
          BINARY_CHUNK_OP_R2_FROM_T0: begin
            row_lo_en_cache[lane_idx] =
              vec_sel_data[row_idx*COEFF_W] ^
              vec_sel_data[(row_idx + active_ring_n_i)*COEFF_W];
          end
          BINARY_CHUNK_OP_DECODE: begin
            parity_bit =
              vec_sel_data[row_idx*COEFF_W] ^
              vec_sel_data[(row_idx + active_ring_n_i)*COEFF_W] ^
              vec_sel_data[(row_idx + (2 * active_ring_n_i))*COEFF_W] ^
              vec_sel_data[(row_idx + (3 * active_ring_n_i))*COEFF_W];

            c0 = $signed(vec_sel_data[row_idx*COEFF_W +: COEFF_W]);
            c1 = $signed(vec_sel_data[(row_idx + active_ring_n_i)*COEFF_W +: COEFF_W]);
            c2 = $signed(vec_sel_data[(row_idx + (2 * active_ring_n_i))*COEFF_W +: COEFF_W]);
            c3 = $signed(vec_sel_data[(row_idx + (3 * active_ring_n_i))*COEFF_W +: COEFF_W]);

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

            if (c0 <= c1) begin
              row_sel_idx_cache[lane_idx] = idx0[ROW_ADDR_W-1:0];
            end else begin
              row_sel_idx_cache[lane_idx] = idx1[ROW_ADDR_W-1:0];
            end
          end
          BINARY_CHUNK_OP_DEC_POST: begin
            ring_n2 = 2 * active_ring_n_i;

            mont_in_0 =
              (vec_sel_data[(row_idx + ring_n2)*COEFF_W +: COEFF_W] -
               vec_sel_data[row_idx*COEFF_W +: COEFF_W]) * 16'sd171;
            mont_u_0 = mont_in_0 * (-16'sd767);
            mont_t_0 = mont_in_0 - (mont_u_0 * 16'sd769);
            t0_0 = mont_t_0 >>> 16;

            mont_in_1 =
              (vec_sel_data[(row_idx + (3 * active_ring_n_i))*COEFF_W +: COEFF_W] -
               vec_sel_data[(row_idx + active_ring_n_i)*COEFF_W +: COEFF_W]) * 16'sd171;
            mont_u_1 = mont_in_1 * (-16'sd767);
            mont_t_1 = mont_in_1 - (mont_u_1 * 16'sd769);
            t0_1 = mont_t_1 >>> 16;

            mont_in_2 =
              (vec_sel_data[row_idx*COEFF_W +: COEFF_W] +
               vec_sel_data[(row_idx + ring_n2)*COEFF_W +: COEFF_W]) * 16'sd171;
            mont_u_2 = mont_in_2 * (-16'sd767);
            mont_t_2 = mont_in_2 - (mont_u_2 * 16'sd769);
            t0_2 = mont_t_2 >>> 16;

            mont_in_3 =
              (vec_sel_data[(row_idx + active_ring_n_i)*COEFF_W +: COEFF_W] +
               vec_sel_data[(row_idx + (3 * active_ring_n_i))*COEFF_W +: COEFF_W]) * 16'sd171;
            mont_u_3 = mont_in_3 * (-16'sd767);
            mont_t_3 = mont_in_3 - (mont_u_3 * 16'sd769);
            t0_3 = mont_t_3 >>> 16;

            row_lo_en_cache[lane_idx] = t0_0[0] ^ t0_2[0];
            row_hi_en_cache[lane_idx] = t0_1[0] ^ t0_3[0];
            parity_bit = t0_0[0] ^ t0_1[0] ^ t0_2[0] ^ t0_3[0];

            c0 = $signed(t0_0);
            c1 = $signed(t0_1);
            c2 = $signed(t0_2);
            c3 = $signed(t0_3);

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

            if (c0 <= c1) begin
              row_sel_idx_cache[lane_idx] = idx0[ROW_ADDR_W-1:0];
            end else begin
              row_sel_idx_cache[lane_idx] = idx1[ROW_ADDR_W-1:0];
            end
          end
          default: begin
          end
        endcase
      end
    end
  end

  always_comb begin
    integer col_idx;
    integer lane_idx;
    integer src_idx;
    integer ring_n2;
    integer row_idx;
    integer sel_idx;
    logic acc_bit;

    acc_bit = 1'b0;
    src_idx = 0;
    ring_n2 = 2 * active_ring_n_i;
    row_idx = 0;
    sel_idx = 0;
    chunk_data = '0;

    for (col_idx = 0; col_idx < BIN_COL_LANES; col_idx++) begin
      if (($unsigned(col_base) + col_idx) < active_acc_n_i) begin
        acc_bit = vec_acc_data[($unsigned(col_base) + col_idx)*COEFF_W];
        for (lane_idx = 0; lane_idx < XOR_LANES; lane_idx++) begin
          if (row_active_cache[lane_idx]) begin
            row_idx = $unsigned(row_idx_cache[lane_idx]);
            sel_idx = $unsigned(row_sel_idx_cache[lane_idx]);
            unique case (op_mode_i)
              BINARY_CHUNK_OP_R2,
              BINARY_CHUNK_OP_R2_FROM_T0: begin
                if (row_lo_en_cache[lane_idx]) begin
                  src_idx = (($unsigned(col_base) + col_idx) + active_ring_n_i - row_idx) &
                            (active_ring_n_i - 1);
                  acc_bit = acc_bit ^ vec_src_data[src_idx*COEFF_W];
                end
              end
              BINARY_CHUNK_OP_DECODE: begin
                src_idx = (($unsigned(col_base) + col_idx) + ring_n2 - sel_idx) &
                          (ring_n2 - 1);
                acc_bit = acc_bit ^ vec_src_data[src_idx*COEFF_W];
              end
              BINARY_CHUNK_OP_DEC_POST: begin
                if (row_lo_en_cache[lane_idx]) begin
                  src_idx = (($unsigned(col_base) + col_idx) + ring_n2 - row_idx) &
                            (ring_n2 - 1);
                  acc_bit = acc_bit ^ vec_src_data[src_idx*COEFF_W];
                end
                if (row_hi_en_cache[lane_idx]) begin
                  src_idx = (($unsigned(col_base) + col_idx) + ring_n2 -
                             (row_idx + active_ring_n_i)) & (ring_n2 - 1);
                  acc_bit = acc_bit ^ vec_src_data[src_idx*COEFF_W];
                end
                src_idx = (($unsigned(col_base) + col_idx) + ring_n2 - sel_idx) &
                          (ring_n2 - 1);
                acc_bit = acc_bit ^ vec_src_data[src_idx*COEFF_W];
              end
              default: begin
              end
            endcase
          end
        end

        if (COEFF_W > 1) begin
          chunk_data[col_idx*COEFF_W +: COEFF_W] = {{(COEFF_W - 1){1'b0}}, acc_bit};
        end else begin
          chunk_data[col_idx*COEFF_W +: COEFF_W] = acc_bit;
        end
      end
    end
  end

endmodule
