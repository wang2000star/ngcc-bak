module zen_ooc_seed_to_poly (
  input  logic [63:0] seed_i,
  output zen_accel_pkg::zen_poly_vec_t vec_o
);
  import zen_accel_pkg::*;
  genvar g_coeff;
  generate
    for (g_coeff = 0; g_coeff < ZEN_N; g_coeff++) begin : g_seed_poly
      localparam int SEED_BASE = (g_coeff % 4) * COEFF_W;
      assign vec_o[g_coeff*COEFF_W +: COEFF_W] = $signed(seed_i[SEED_BASE +: COEFF_W]);
    end
  endgenerate
endmodule

module zen_ooc_seed_to_buf_row (
  input  logic [63:0] seed_i,
  output zen_accel_pkg::zen_buf_row_t row_o
);
  import zen_accel_pkg::*;
  genvar g_lane;
  generate
    for (g_lane = 0; g_lane < BUF_BANKS; g_lane++) begin : g_seed_row
      localparam int SEED_BASE = (g_lane % 4) * COEFF_W;
      assign row_o[g_lane*COEFF_W +: COEFF_W] = seed_i[SEED_BASE +: COEFF_W];
    end
  endgenerate
endmodule

module zen_ooc_seed_to_stream_row (
  input  logic [63:0] seed_i,
  output zen_accel_pkg::zen_stream_row_t row_o
);
  import zen_accel_pkg::*;
  genvar g_lane;
  generate
    for (g_lane = 0; g_lane < STREAM_ROW_COEFFS; g_lane++) begin : g_seed_stream_row
      localparam int SEED_BASE = (g_lane % 4) * COEFF_W;
      assign row_o[g_lane*COEFF_W +: COEFF_W] = $signed(seed_i[SEED_BASE +: COEFF_W]);
    end
  endgenerate
endmodule

module zen_ooc_msg_codec_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [7:0]  cmd_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [63:0] seed0_i,
  input  logic [63:0] seed1_i,
  input  logic [63:0] seed2_i,
  input  logic [63:0] seed3_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        error_o
);
  import zen_accel_pkg::*;
  zen_poly_vec_t msg_bytes_vec;
  zen_poly_vec_t msg_poly_vec;
  zen_poly_vec_t vec_out_w;
  logic [31:0] bytes_consumed_w;
  logic [31:0] bytes_produced_w;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t vec_sink_r;
  (* keep = "true", dont_touch = "true" *) logic [31:0] bytes0_sink_r;
  (* keep = "true", dont_touch = "true" *) logic [31:0] bytes1_sink_r;

  zen_ooc_seed_to_poly u_seed_msg_bytes (.seed_i(seed0_i), .vec_o(msg_bytes_vec));
  zen_ooc_seed_to_poly u_seed_msg_poly  (.seed_i(seed1_i), .vec_o(msg_poly_vec));

  zen_msg_codec u_dut (
    .op               (cfg_i[1:0]),
    .msg_bytes_vec_i  (msg_bytes_vec),
    .msg_poly_vec_i   (msg_poly_vec),
    .vec_out_o        (vec_out_w),
    .bytes_consumed_o (bytes_consumed_w),
    .bytes_produced_o (bytes_produced_w)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      vec_sink_r <= '0;
      bytes0_sink_r <= '0;
      bytes1_sink_r <= '0;
      done_o <= 1'b0;
      busy_o <= 1'b0;
      error_o <= 1'b0;
    end else begin
      done_o <= start_i;
      busy_o <= 1'b0;
      error_o <= 1'b0;
      if (start_i) begin
        vec_sink_r <= vec_out_w;
        bytes0_sink_r <= bytes_consumed_w;
        bytes1_sink_r <= bytes_produced_w;
      end
    end
  end
endmodule

module zen_ooc_ct_pack_row_core_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [7:0]  cmd_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [63:0] seed0_i,
  input  logic [63:0] seed1_i,
  input  logic [63:0] seed2_i,
  input  logic [63:0] seed3_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        error_o
);
  import zen_accel_pkg::*;
  zen_poly_vec_t hs_poly_vec;
  zen_poly_vec_t e_poly_vec;
  zen_poly_vec_t msg_poly_vec;
  zen_buf_row_t row_vec_w;
  (* keep = "true", dont_touch = "true" *) zen_buf_row_t row_sink_r;

  zen_ooc_seed_to_poly u_seed_hs  (.seed_i(seed0_i), .vec_o(hs_poly_vec));
  zen_ooc_seed_to_poly u_seed_e   (.seed_i(seed1_i), .vec_o(e_poly_vec));
  zen_ooc_seed_to_poly u_seed_msg (.seed_i(seed2_i), .vec_o(msg_poly_vec));

  zen_ct_pack_row_core u_dut (
    .row_i         (cfg_i[ADDR_W-1:0]),
    .hs_poly_vec_i (hs_poly_vec),
    .e_poly_vec_i  (e_poly_vec),
    .msg_poly_vec_i(msg_poly_vec),
    .row_vec_o     (row_vec_w)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      row_sink_r <= '0;
      done_o <= 1'b0;
      busy_o <= 1'b0;
      error_o <= 1'b0;
    end else begin
      done_o <= start_i;
      busy_o <= 1'b0;
      error_o <= 1'b0;
      if (start_i) begin
        row_sink_r <= row_vec_w;
      end
    end
  end
endmodule

module zen_ooc_pk_unpack_seq_core_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [7:0]  cmd_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [63:0] seed0_i,
  input  logic [63:0] seed1_i,
  input  logic [63:0] seed2_i,
  input  logic [63:0] seed3_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        error_o
);
  import zen_accel_pkg::*;
  zen_poly_vec_t pk_bytes_vec;
  zen_poly_vec_t pk_poly_vec_w;
  logic [31:0] bytes_consumed_w;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t pk_poly_sink_r;
  (* keep = "true", dont_touch = "true" *) logic [31:0] bytes_sink_r;

  zen_ooc_seed_to_poly u_seed_pk (.seed_i(seed0_i), .vec_o(pk_bytes_vec));

  zen_pk_unpack_seq_core u_dut (
    .clk              (clk),
    .rst_n            (rst_n),
    .start_i          (start_i),
    .pk_bytes_vec_i   (pk_bytes_vec),
    .busy_o           (busy_o),
    .done_o           (done_o),
    .pk_poly_vec_o    (pk_poly_vec_w),
    .bytes_consumed_o (bytes_consumed_w)
  );

  assign error_o = 1'b0;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      pk_poly_sink_r <= '0;
      bytes_sink_r <= '0;
    end else if (done_o) begin
      pk_poly_sink_r <= pk_poly_vec_w;
      bytes_sink_r <= bytes_consumed_w;
    end
  end
endmodule

module zen_ooc_sk_unpack_seq_core_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [7:0]  cmd_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [63:0] seed0_i,
  input  logic [63:0] seed1_i,
  input  logic [63:0] seed2_i,
  input  logic [63:0] seed3_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        error_o
);
  import zen_accel_pkg::*;
  zen_poly_vec_t sk_lo_vec;
  zen_poly_vec_t sk_hi_vec;
  zen_poly_vec_t f_ntt_vec_w;
  zen_poly_vec_t f2_vec_w;
  logic [31:0] bytes_consumed_w;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t f_ntt_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t f2_sink_r;
  (* keep = "true", dont_touch = "true" *) logic [31:0] bytes_sink_r;

  zen_ooc_seed_to_poly u_seed_sk_lo (.seed_i(seed0_i), .vec_o(sk_lo_vec));
  zen_ooc_seed_to_poly u_seed_sk_hi (.seed_i(seed1_i), .vec_o(sk_hi_vec));

  zen_sk_unpack_seq_core u_dut (
    .clk                 (clk),
    .rst_n               (rst_n),
    .start_i             (start_i),
    .sk_lo_bytes_vec_i   (sk_lo_vec),
    .sk_hi_bytes_vec_i   (sk_hi_vec),
    .busy_o              (busy_o),
    .done_o              (done_o),
    .sk_f_ntt_poly_vec_o (f_ntt_vec_w),
    .sk_f2_poly_vec_o    (f2_vec_w),
    .bytes_consumed_o    (bytes_consumed_w)
  );

  assign error_o = 1'b0;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      f_ntt_sink_r <= '0;
      f2_sink_r <= '0;
      bytes_sink_r <= '0;
    end else if (done_o) begin
      f_ntt_sink_r <= f_ntt_vec_w;
      f2_sink_r <= f2_vec_w;
      bytes_sink_r <= bytes_consumed_w;
    end
  end
endmodule

module zen_ooc_keypair_pack_seq_core_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [7:0]  cmd_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [63:0] seed0_i,
  input  logic [63:0] seed1_i,
  input  logic [63:0] seed2_i,
  input  logic [63:0] seed3_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        error_o
);
  import zen_accel_pkg::*;
  zen_poly_vec_t pk_poly_vec;
  zen_poly_vec_t sk_f_ntt_poly_vec;
  zen_poly_vec_t sk_f2_poly_vec;
  zen_poly_vec_t pk_bytes_vec_w;
  zen_poly_vec_t sk_lo_vec_w;
  zen_poly_vec_t sk_hi_vec_w;
  logic [31:0] bytes0_w;
  logic [31:0] bytes1_w;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t pk_bytes_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t sk_lo_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t sk_hi_sink_r;
  (* keep = "true", dont_touch = "true" *) logic [31:0] bytes0_sink_r;
  (* keep = "true", dont_touch = "true" *) logic [31:0] bytes1_sink_r;

  zen_ooc_seed_to_poly u_seed_pk_poly (.seed_i(seed0_i), .vec_o(pk_poly_vec));
  zen_ooc_seed_to_poly u_seed_sk_f    (.seed_i(seed1_i), .vec_o(sk_f_ntt_poly_vec));
  zen_ooc_seed_to_poly u_seed_sk_f2   (.seed_i(seed2_i), .vec_o(sk_f2_poly_vec));

  zen_keypair_pack_seq_core u_dut (
    .clk                  (clk),
    .rst_n                (rst_n),
    .start_i              (start_i),
    .pk_poly_ready_i      (cfg_i[31]),
    .pk_poly_ready_coeffs_i(len_i),
    .sk_f2_ready_coeffs_i ({23'd0, cfg_i[8:0]}),
    .pk_poly_vec_i        (pk_poly_vec),
    .sk_f_ntt_poly_vec_i  (sk_f_ntt_poly_vec),
    .sk_f2_poly_vec_i     (sk_f2_poly_vec),
    .busy_o               (busy_o),
    .done_o               (done_o),
    .pk_bytes_vec_o       (pk_bytes_vec_w),
    .sk_lo_bytes_vec_o    (sk_lo_vec_w),
    .sk_hi_bytes_vec_o    (sk_hi_vec_w),
    .bytes_produced0_o    (bytes0_w),
    .bytes_produced1_o    (bytes1_w)
  );

  assign error_o = 1'b0;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      pk_bytes_sink_r <= '0;
      sk_lo_sink_r <= '0;
      sk_hi_sink_r <= '0;
      bytes0_sink_r <= '0;
      bytes1_sink_r <= '0;
    end else if (done_o) begin
      pk_bytes_sink_r <= pk_bytes_vec_w;
      sk_lo_sink_r <= sk_lo_vec_w;
      sk_hi_sink_r <= sk_hi_vec_w;
      bytes0_sink_r <= bytes0_w;
      bytes1_sink_r <= bytes1_w;
    end
  end
endmodule

module zen_ooc_sampler_core_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [7:0]  cmd_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [63:0] seed0_i,
  input  logic [63:0] seed1_i,
  input  logic [63:0] seed2_i,
  input  logic [63:0] seed3_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        error_o
);
  import zen_accel_pkg::*;
  zen_seed_addr_t seed_rd_addr_w;
  logic [7:0] seed_rd_data_w;
  logic vec_out_valid_w;
  zen_poly_vec_t vec_out_w;
  logic row_out_valid_w;
  zen_row_addr_t row_out_idx_w;
  zen_buf_row_t row_out_data_w;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t vec_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_buf_row_t row_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_row_addr_t row_idx_sink_r;

  always_comb begin
    unique case (seed_rd_addr_w[2:0])
      3'd0: seed_rd_data_w = seed0_i[7:0];
      3'd1: seed_rd_data_w = seed0_i[15:8];
      3'd2: seed_rd_data_w = seed0_i[23:16];
      3'd3: seed_rd_data_w = seed0_i[31:24];
      3'd4: seed_rd_data_w = seed0_i[39:32];
      3'd5: seed_rd_data_w = seed0_i[47:40];
      3'd6: seed_rd_data_w = seed0_i[55:48];
      default: seed_rd_data_w = seed0_i[63:56];
    endcase
  end

  zen_sampler_core u_dut (
    .clk         (clk),
    .rst_n       (rst_n),
    .start       (start_i),
    .cmd         (cmd_i),
    .cfg         (cfg_i),
    .len         (len_i),
    .buf_r_sel   (cfg_i[2:0]),
    .seed_rd_addr(seed_rd_addr_w),
    .seed_rd_data(seed_rd_data_w),
    .vec_out_valid(vec_out_valid_w),
    .vec_out_data (vec_out_w),
    .row_out_valid(row_out_valid_w),
    .row_out_idx  (row_out_idx_w),
    .row_out_data (row_out_data_w),
    .busy        (busy_o),
    .done        (done_o),
    .error       (error_o)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      vec_sink_r <= '0;
      row_sink_r <= '0;
      row_idx_sink_r <= '0;
    end else begin
      if (vec_out_valid_w) begin
        vec_sink_r <= vec_out_w;
      end
      if (row_out_valid_w) begin
        row_sink_r <= row_out_data_w;
        row_idx_sink_r <= row_out_idx_w;
      end
    end
  end
endmodule

module zen_ooc_ntt_core_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [7:0]  cmd_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [63:0] seed0_i,
  input  logic [63:0] seed1_i,
  input  logic [63:0] seed2_i,
  input  logic [63:0] seed3_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        error_o
);
  import zen_accel_pkg::*;
  zen_poly_vec_t vec_in_w;
  logic vec_out_valid_w;
  zen_poly_vec_t vec_out_w;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t vec_sink_r;

  zen_ooc_seed_to_poly u_seed_in (.seed_i(seed0_i), .vec_o(vec_in_w));

  zen_ntt_core u_dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .start        (start_i),
    .cmd          (cmd_i),
    .cfg          (cfg_i),
    .len          (len_i),
    .buf_a_sel    (cfg_i[2:0]),
    .buf_r_sel    (cfg_i[5:3]),
    .vec_in_valid (start_i),
    .vec_in_data  (vec_in_w),
    .vec_out_valid(vec_out_valid_w),
    .vec_out_data (vec_out_w),
    .busy         (busy_o),
    .done         (done_o),
    .error        (error_o)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      vec_sink_r <= '0;
    end else if (vec_out_valid_w) begin
      vec_sink_r <= vec_out_w;
    end
  end
endmodule

module zen_ooc_basemul_core_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [7:0]  cmd_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [63:0] seed0_i,
  input  logic [63:0] seed1_i,
  input  logic [63:0] seed2_i,
  input  logic [63:0] seed3_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        error_o
);
  import zen_accel_pkg::*;
  zen_poly_vec_t vec_a_w;
  zen_poly_vec_t vec_b_w;
  logic vec_out_valid_w;
  zen_poly_vec_t vec_out_w;
  logic row_out_valid_w;
  zen_row_addr_t row_out_idx_w;
  zen_stream_row_t row_out_data_w;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t vec_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_stream_row_t row_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_row_addr_t row_idx_sink_r;

  zen_ooc_seed_to_poly u_seed_a (.seed_i(seed0_i), .vec_o(vec_a_w));
  zen_ooc_seed_to_poly u_seed_b (.seed_i(seed1_i), .vec_o(vec_b_w));

  zen_basemul_core u_dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .start        (start_i),
    .cmd          (cmd_i),
    .cfg          (cfg_i),
    .len          (len_i),
    .buf_a_sel    (cfg_i[2:0]),
    .buf_b_sel    (cfg_i[5:3]),
    .buf_r_sel    (cfg_i[8:6]),
    .vec_in_valid (start_i),
    .vec_a_data   (vec_a_w),
    .vec_b_data   (vec_b_w),
    .vec_out_valid(vec_out_valid_w),
    .vec_r_data   (vec_out_w),
    .row_out_valid(row_out_valid_w),
    .row_out_idx  (row_out_idx_w),
    .row_out_data (row_out_data_w),
    .busy         (busy_o),
    .done         (done_o),
    .error        (error_o)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      vec_sink_r <= '0;
      row_sink_r <= '0;
      row_idx_sink_r <= '0;
    end else begin
      if (vec_out_valid_w) begin
        vec_sink_r <= vec_out_w;
      end
      if (row_out_valid_w) begin
        row_sink_r <= row_out_data_w;
        row_idx_sink_r <= row_out_idx_w;
      end
    end
  end
endmodule

module zen_ooc_baseinv_core_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [7:0]  cmd_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [63:0] seed0_i,
  input  logic [63:0] seed1_i,
  input  logic [63:0] seed2_i,
  input  logic [63:0] seed3_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        error_o
);
  import zen_accel_pkg::*;
  zen_poly_vec_t vec_a_w;
  logic vec_out_valid_w;
  zen_poly_vec_t vec_out_w;
  logic row_out_valid_w;
  zen_row_addr_t row_out_idx_w;
  zen_stream_row_t row_out_data_w;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t vec_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_stream_row_t row_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_row_addr_t row_idx_sink_r;

  zen_ooc_seed_to_poly u_seed_a (.seed_i(seed0_i), .vec_o(vec_a_w));

  zen_baseinv_core u_dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .start        (start_i),
    .cfg          (cfg_i),
    .len          (len_i),
    .buf_a_sel    (cfg_i[2:0]),
    .buf_r_sel    (cfg_i[5:3]),
    .vec_in_valid (start_i),
    .vec_a_data   (vec_a_w),
    .vec_out_valid(vec_out_valid_w),
    .vec_r_data   (vec_out_w),
    .row_out_valid(row_out_valid_w),
    .row_out_idx  (row_out_idx_w),
    .row_out_data (row_out_data_w),
    .busy         (busy_o),
    .done         (done_o),
    .error        (error_o)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      vec_sink_r <= '0;
      row_sink_r <= '0;
      row_idx_sink_r <= '0;
    end else begin
      if (vec_out_valid_w) begin
        vec_sink_r <= vec_out_w;
      end
      if (row_out_valid_w) begin
        row_sink_r <= row_out_data_w;
        row_idx_sink_r <= row_out_idx_w;
      end
    end
  end
endmodule

module zen_ooc_binary_fast_inv_core_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [7:0]  cmd_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [63:0] seed0_i,
  input  logic [63:0] seed1_i,
  input  logic [63:0] seed2_i,
  input  logic [63:0] seed3_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        error_o
);
  import zen_accel_pkg::*;
  zen_poly_vec_t vec_a_w;
  logic row_out_valid_w;
  zen_row_addr_t row_out_idx_w;
  zen_stream_row_t row_out_data_w;
  (* keep = "true", dont_touch = "true" *) zen_stream_row_t row_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_row_addr_t row_idx_sink_r;

  zen_ooc_seed_to_poly u_seed_a (.seed_i(seed0_i), .vec_o(vec_a_w));

  zen_binary_fast_inv_core u_dut (
    .clk            (clk),
    .rst_n          (rst_n),
    .start_i        (start_i),
    .vec_a_data     (vec_a_w),
    .done_o         (done_o),
    .row_out_valid_o(row_out_valid_w),
    .row_out_idx_o  (row_out_idx_w),
    .row_out_data_o (row_out_data_w)
  );

  assign busy_o = 1'b0;
  assign error_o = 1'b0;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      row_sink_r <= '0;
      row_idx_sink_r <= '0;
    end else begin
      if (row_out_valid_w) begin
        row_sink_r <= row_out_data_w;
        row_idx_sink_r <= row_out_idx_w;
      end
    end
  end
endmodule

module zen_ooc_binary_core_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [7:0]  cmd_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [63:0] seed0_i,
  input  logic [63:0] seed1_i,
  input  logic [63:0] seed2_i,
  input  logic [63:0] seed3_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        error_o
);
  import zen_accel_pkg::*;
  zen_poly_vec_t vec_a_w;
  zen_poly_vec_t vec_b_w;
  logic vec_out_valid_w;
  zen_poly_vec_t vec_out_w;
  logic row_out_valid_w;
  zen_row_addr_t row_out_idx_w;
  zen_stream_row_t row_out_data_w;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t vec_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_stream_row_t row_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_row_addr_t row_idx_sink_r;

  zen_ooc_seed_to_poly u_seed_a (.seed_i(seed0_i), .vec_o(vec_a_w));
  zen_ooc_seed_to_poly u_seed_b (.seed_i(seed1_i), .vec_o(vec_b_w));

  zen_binary_core u_dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .start        (start_i),
    .cmd          (cmd_i),
    .cfg          (cfg_i),
    .len          (len_i),
    .buf_a_sel    (cfg_i[2:0]),
    .buf_b_sel    (cfg_i[5:3]),
    .buf_r_sel    (cfg_i[8:6]),
    .vec_in_valid (start_i),
    .vec_a_data   (vec_a_w),
    .vec_b_data   (vec_b_w),
    .vec_out_valid(vec_out_valid_w),
    .vec_r_data   (vec_out_w),
    .row_out_valid(row_out_valid_w),
    .row_out_idx  (row_out_idx_w),
    .row_out_data (row_out_data_w),
    .busy         (busy_o),
    .done         (done_o),
    .error        (error_o)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      vec_sink_r <= '0;
      row_sink_r <= '0;
      row_idx_sink_r <= '0;
    end else begin
      if (vec_out_valid_w) begin
        vec_sink_r <= vec_out_w;
      end
      if (row_out_valid_w) begin
        row_sink_r <= row_out_data_w;
        row_idx_sink_r <= row_out_idx_w;
      end
    end
  end
endmodule

module zen_ooc_pke_enc_core_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [7:0]  cmd_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [63:0] seed0_i,
  input  logic [63:0] seed1_i,
  input  logic [63:0] seed2_i,
  input  logic [63:0] seed3_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        error_o
);
  import zen_accel_pkg::*;
  zen_buf_row_t row0_w;
  zen_buf_row_t row1_w;
  zen_poly_vec_t sampler_vec_w;
  zen_poly_vec_t ntt_vec_w;
  zen_poly_vec_t basemul_vec_w;
  logic [7:0] errcode_w;
  logic [31:0] out_bytes0_w;
  logic [31:0] out_bytes1_w;
  logic sampler_seed_active_w;
  logic prefetch_active_w;
  logic [2:0] vec_rd0_buf_sel_w;
  logic [2:0] vec_rd1_buf_sel_w;
  zen_row_addr_t vec_rd_row_w;
  logic sampler_start_w;
  logic [7:0] sample_cmd_w;
  logic [31:0] sample_cfg_w;
  logic [31:0] sample_len_w;
  logic [2:0] sample_buf_r_sel_w;
  logic ntt_start_w;
  logic basemul_start_w;
  logic [7:0] arith_cmd_w;
  logic vec_in_valid_w;
  zen_poly_vec_t vec_in_a_w;
  zen_poly_vec_t vec_in_b_w;
  logic vec_wr_en_w;
  logic [2:0] vec_wr_buf_sel_w;
  zen_row_addr_t vec_wr_row_w;
  zen_buf_row_t vec_wr_data_w;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t vec_in_a_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t vec_in_b_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_buf_row_t vec_wr_sink_r;
  (* keep = "true", dont_touch = "true" *) logic [31:0] bytes_sink_r;

  zen_ooc_seed_to_buf_row u_seed_row0 (.seed_i(seed0_i), .row_o(row0_w));
  zen_ooc_seed_to_buf_row u_seed_row1 (.seed_i(seed1_i), .row_o(row1_w));
  zen_ooc_seed_to_poly    u_seed_samp (.seed_i(seed1_i), .vec_o(sampler_vec_w));
  zen_ooc_seed_to_poly    u_seed_ntt  (.seed_i(seed2_i), .vec_o(ntt_vec_w));
  zen_ooc_seed_to_poly    u_seed_bm   (.seed_i(seed3_i), .vec_o(basemul_vec_w));

  zen_pke_enc_core u_dut (
    .clk                  (clk),
    .rst_n                (rst_n),
    .start_i              (start_i),
    .cfg_i                (cfg_i),
    .len_i                (len_i),
    .buf_a_sel_i          (cfg_i[2:0]),
    .buf_b_sel_i          (cfg_i[5:3]),
    .buf_r_sel_i          (cfg_i[8:6]),
    .vec_rd0_row_data_i   (row0_w),
    .vec_rd1_row_data_i   (row1_w),
    .sampler_done_i       (cfg_i[9]),
    .sampler_error_i      (cfg_i[10]),
    .sampler_vec_out_valid_i(cfg_i[11]),
    .sampler_vec_out_i    (sampler_vec_w),
    .ntt_done_i           (cfg_i[12]),
    .ntt_error_i          (cfg_i[13]),
    .ntt_vec_out_valid_i  (cfg_i[14]),
    .ntt_vec_out_i        (ntt_vec_w),
    .basemul_done_i       (cfg_i[15]),
    .basemul_error_i      (cfg_i[16]),
    .basemul_vec_out_valid_i(cfg_i[17]),
    .basemul_vec_out_i    (basemul_vec_w),
    .busy_o               (busy_o),
    .done_o               (done_o),
    .error_o              (error_o),
    .errcode_o            (errcode_w),
    .out_bytes0_o         (out_bytes0_w),
    .out_bytes1_o         (out_bytes1_w),
    .sampler_seed_active_o(sampler_seed_active_w),
    .prefetch_active_o    (prefetch_active_w),
    .vec_rd0_buf_sel_o    (vec_rd0_buf_sel_w),
    .vec_rd1_buf_sel_o    (vec_rd1_buf_sel_w),
    .vec_rd_row_o         (vec_rd_row_w),
    .sampler_start_o      (sampler_start_w),
    .sample_cmd_o         (sample_cmd_w),
    .sample_cfg_o         (sample_cfg_w),
    .sample_len_o         (sample_len_w),
    .sample_buf_r_sel_o   (sample_buf_r_sel_w),
    .ntt_start_o          (ntt_start_w),
    .basemul_start_o      (basemul_start_w),
    .arith_cmd_o          (arith_cmd_w),
    .vec_in_valid_o       (vec_in_valid_w),
    .vec_in_a_o           (vec_in_a_w),
    .vec_in_b_o           (vec_in_b_w),
    .vec_wr_en_o          (vec_wr_en_w),
    .vec_wr_buf_sel_o     (vec_wr_buf_sel_w),
    .vec_wr_row_o         (vec_wr_row_w),
    .vec_wr_data_o        (vec_wr_data_w)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      vec_in_a_sink_r <= '0;
      vec_in_b_sink_r <= '0;
      vec_wr_sink_r <= '0;
      bytes_sink_r <= '0;
    end else begin
      if (vec_in_valid_w) begin
        vec_in_a_sink_r <= vec_in_a_w;
        vec_in_b_sink_r <= vec_in_b_w;
      end
      if (vec_wr_en_w) begin
        vec_wr_sink_r <= vec_wr_data_w;
      end
      if (done_o) begin
        bytes_sink_r <= out_bytes0_w ^ out_bytes1_w ^ {24'd0, errcode_w};
      end
    end
  end
endmodule

module zen_ooc_pke_keygen_core_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [7:0]  cmd_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [63:0] seed0_i,
  input  logic [63:0] seed1_i,
  input  logic [63:0] seed2_i,
  input  logic [63:0] seed3_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        error_o
);
  import zen_accel_pkg::*;
  zen_poly_vec_t sampler_vec_w;
  zen_poly_vec_t ntt_vec_w;
  zen_poly_vec_t basemul_vec_w;
  zen_poly_vec_t baseinv_vec_w;
  zen_poly_vec_t binary_vec_w;
  zen_stream_row_t basemul_row_w;
  zen_stream_row_t baseinv_row_w;
  zen_stream_row_t binary_row_w;
  logic [7:0] errcode_w;
  logic [31:0] out_bytes0_w;
  logic [31:0] out_bytes1_w;
  logic sampler_seed_active_w;
  logic sampler_start_w;
  logic [7:0] sample_cmd_w;
  logic [31:0] sample_cfg_w;
  logic [31:0] sample_len_w;
  logic [2:0] sample_buf_r_sel_w;
  logic ntt_start_w;
  logic basemul_start_w;
  logic baseinv_start_w;
  logic binary_start_w;
  logic [7:0] arith_cmd_w;
  logic vec_in_valid_w;
  zen_poly_vec_t vec_in_a_w;
  zen_poly_vec_t vec_in_b_w;
  logic vec_wr_en_w;
  logic [2:0] vec_wr_buf_sel_w;
  zen_row_addr_t vec_wr_row_w;
  zen_buf_row_t vec_wr_data_w;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t vec_in_a_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t vec_in_b_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_buf_row_t vec_wr_sink_r;
  (* keep = "true", dont_touch = "true" *) logic [31:0] bytes_sink_r;

  zen_ooc_seed_to_poly       u_seed_samp      (.seed_i(seed0_i), .vec_o(sampler_vec_w));
  zen_ooc_seed_to_poly       u_seed_ntt       (.seed_i(seed1_i), .vec_o(ntt_vec_w));
  zen_ooc_seed_to_poly       u_seed_basemul   (.seed_i(seed2_i), .vec_o(basemul_vec_w));
  zen_ooc_seed_to_poly       u_seed_baseinv   (.seed_i(seed3_i), .vec_o(baseinv_vec_w));
  zen_ooc_seed_to_poly       u_seed_binary    (.seed_i(seed0_i ^ seed3_i), .vec_o(binary_vec_w));
  zen_ooc_seed_to_stream_row u_seed_bm_row    (.seed_i(seed1_i), .row_o(basemul_row_w));
  zen_ooc_seed_to_stream_row u_seed_bi_row    (.seed_i(seed2_i), .row_o(baseinv_row_w));
  zen_ooc_seed_to_stream_row u_seed_bin_row   (.seed_i(seed3_i), .row_o(binary_row_w));

  zen_pke_keygen_core u_dut (
    .clk                   (clk),
    .rst_n                 (rst_n),
    .start_i               (start_i),
    .cfg_i                 (cfg_i),
    .len_i                 (len_i),
    .buf_a_sel_i           (cfg_i[2:0]),
    .buf_b_sel_i           (cfg_i[5:3]),
    .buf_r_sel_i           (cfg_i[8:6]),
    .sampler_done_i        (cfg_i[9]),
    .sampler_error_i       (cfg_i[10]),
    .sampler_vec_out_valid_i(cfg_i[11]),
    .sampler_vec_out_i     (sampler_vec_w),
    .ntt_done_i            (cfg_i[12]),
    .ntt_error_i           (cfg_i[13]),
    .ntt_vec_out_valid_i   (cfg_i[14]),
    .ntt_vec_out_i         (ntt_vec_w),
    .basemul_done_i        (cfg_i[15]),
    .basemul_error_i       (cfg_i[16]),
    .basemul_vec_out_valid_i(cfg_i[17]),
    .basemul_vec_out_i     (basemul_vec_w),
    .basemul_row_valid_i   (cfg_i[18]),
    .basemul_row_idx_i     (len_i[ADDR_W-1:0]),
    .basemul_row_data_i    (basemul_row_w),
    .baseinv_done_i        (cfg_i[19]),
    .baseinv_error_i       (cfg_i[20]),
    .baseinv_vec_out_valid_i(cfg_i[21]),
    .baseinv_vec_out_i     (baseinv_vec_w),
    .baseinv_row_valid_i   (cfg_i[22]),
    .baseinv_row_idx_i     (len_i[ADDR_W-1:0]),
    .baseinv_row_data_i    (baseinv_row_w),
    .binary_done_i         (cfg_i[23]),
    .binary_error_i        (cfg_i[24]),
    .binary_vec_out_valid_i(cfg_i[25]),
    .binary_vec_out_i      (binary_vec_w),
    .binary_row_valid_i    (cfg_i[26]),
    .binary_row_idx_i      (len_i[ADDR_W-1:0]),
    .binary_row_data_i     (binary_row_w),
    .busy_o                (busy_o),
    .done_o                (done_o),
    .error_o               (error_o),
    .errcode_o             (errcode_w),
    .out_bytes0_o          (out_bytes0_w),
    .out_bytes1_o          (out_bytes1_w),
    .sampler_seed_active_o (sampler_seed_active_w),
    .sampler_start_o       (sampler_start_w),
    .sample_cmd_o          (sample_cmd_w),
    .sample_cfg_o          (sample_cfg_w),
    .sample_len_o          (sample_len_w),
    .sample_buf_r_sel_o    (sample_buf_r_sel_w),
    .ntt_start_o           (ntt_start_w),
    .basemul_start_o       (basemul_start_w),
    .baseinv_start_o       (baseinv_start_w),
    .binary_start_o        (binary_start_w),
    .arith_cmd_o           (arith_cmd_w),
    .vec_in_valid_o        (vec_in_valid_w),
    .vec_in_a_o            (vec_in_a_w),
    .vec_in_b_o            (vec_in_b_w),
    .vec_wr_en_o           (vec_wr_en_w),
    .vec_wr_buf_sel_o      (vec_wr_buf_sel_w),
    .vec_wr_row_o          (vec_wr_row_w),
    .vec_wr_data_o         (vec_wr_data_w)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      vec_in_a_sink_r <= '0;
      vec_in_b_sink_r <= '0;
      vec_wr_sink_r <= '0;
      bytes_sink_r <= '0;
    end else begin
      if (vec_in_valid_w) begin
        vec_in_a_sink_r <= vec_in_a_w;
        vec_in_b_sink_r <= vec_in_b_w;
      end
      if (vec_wr_en_w) begin
        vec_wr_sink_r <= vec_wr_data_w;
      end
      if (done_o) begin
        bytes_sink_r <= out_bytes0_w ^ out_bytes1_w ^ {24'd0, errcode_w};
      end
    end
  end
endmodule

module zen_ooc_pke_dec_core_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [7:0]  cmd_i,
  input  logic [31:0] cfg_i,
  input  logic [31:0] len_i,
  input  logic [63:0] seed0_i,
  input  logic [63:0] seed1_i,
  input  logic [63:0] seed2_i,
  input  logic [63:0] seed3_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        error_o
);
  import zen_accel_pkg::*;
  zen_buf_row_t row0_w;
  zen_buf_row_t row1_w;
  zen_poly_vec_t binary_vec_w;
  zen_poly_vec_t ntt_vec_w;
  zen_poly_vec_t basemul_vec_w;
  logic [7:0] errcode_w;
  logic [31:0] out_bytes0_w;
  logic [31:0] out_bytes1_w;
  logic [2:0] vec_rd0_buf_sel_w;
  logic [2:0] vec_rd1_buf_sel_w;
  zen_row_addr_t vec_rd_row_w;
  logic binary_start_w;
  logic ntt_start_w;
  logic basemul_start_w;
  logic [7:0] arith_cmd_w;
  logic vec_in_valid_w;
  zen_poly_vec_t vec_in_a_w;
  zen_poly_vec_t vec_in_b_w;
  logic vec_wr_en_w;
  logic [2:0] vec_wr_buf_sel_w;
  zen_row_addr_t vec_wr_row_w;
  zen_buf_row_t vec_wr_data_w;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t vec_in_a_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_poly_vec_t vec_in_b_sink_r;
  (* keep = "true", dont_touch = "true" *) zen_buf_row_t vec_wr_sink_r;
  (* keep = "true", dont_touch = "true" *) logic [31:0] bytes_sink_r;

  zen_ooc_seed_to_buf_row u_seed_row0 (.seed_i(seed0_i), .row_o(row0_w));
  zen_ooc_seed_to_buf_row u_seed_row1 (.seed_i(seed1_i), .row_o(row1_w));
  zen_ooc_seed_to_poly    u_seed_bin  (.seed_i(seed1_i), .vec_o(binary_vec_w));
  zen_ooc_seed_to_poly    u_seed_ntt  (.seed_i(seed2_i), .vec_o(ntt_vec_w));
  zen_ooc_seed_to_poly    u_seed_bm   (.seed_i(seed3_i), .vec_o(basemul_vec_w));

  zen_pke_dec_core u_dut (
    .clk                 (clk),
    .rst_n               (rst_n),
    .start_i             (start_i),
    .cfg_i               (cfg_i),
    .len_i               (len_i),
    .buf_a_sel_i         (cfg_i[2:0]),
    .buf_b_sel_i         (cfg_i[5:3]),
    .buf_r_sel_i         (cfg_i[8:6]),
    .vec_rd0_row_data_i  (row0_w),
    .vec_rd1_row_data_i  (row1_w),
    .binary_done_i       (cfg_i[9]),
    .binary_error_i      (cfg_i[10]),
    .binary_vec_out_valid_i(cfg_i[11]),
    .binary_vec_out_i    (binary_vec_w),
    .ntt_done_i          (cfg_i[12]),
    .ntt_error_i         (cfg_i[13]),
    .ntt_vec_out_valid_i (cfg_i[14]),
    .ntt_vec_out_i       (ntt_vec_w),
    .basemul_done_i      (cfg_i[15]),
    .basemul_error_i     (cfg_i[16]),
    .basemul_vec_out_valid_i(cfg_i[17]),
    .basemul_vec_out_i   (basemul_vec_w),
    .busy_o              (busy_o),
    .done_o              (done_o),
    .error_o             (error_o),
    .errcode_o           (errcode_w),
    .out_bytes0_o        (out_bytes0_w),
    .out_bytes1_o        (out_bytes1_w),
    .vec_rd0_buf_sel_o   (vec_rd0_buf_sel_w),
    .vec_rd1_buf_sel_o   (vec_rd1_buf_sel_w),
    .vec_rd_row_o        (vec_rd_row_w),
    .binary_start_o      (binary_start_w),
    .ntt_start_o         (ntt_start_w),
    .basemul_start_o     (basemul_start_w),
    .arith_cmd_o         (arith_cmd_w),
    .vec_in_valid_o      (vec_in_valid_w),
    .vec_in_a_o          (vec_in_a_w),
    .vec_in_b_o          (vec_in_b_w),
    .vec_wr_en_o         (vec_wr_en_w),
    .vec_wr_buf_sel_o    (vec_wr_buf_sel_w),
    .vec_wr_row_o        (vec_wr_row_w),
    .vec_wr_data_o       (vec_wr_data_w)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      vec_in_a_sink_r <= '0;
      vec_in_b_sink_r <= '0;
      vec_wr_sink_r <= '0;
      bytes_sink_r <= '0;
    end else begin
      if (vec_in_valid_w) begin
        vec_in_a_sink_r <= vec_in_a_w;
        vec_in_b_sink_r <= vec_in_b_w;
      end
      if (vec_wr_en_w) begin
        vec_wr_sink_r <= vec_wr_data_w;
      end
      if (done_o) begin
        bytes_sink_r <= out_bytes0_w ^ out_bytes1_w ^ {24'd0, errcode_w};
      end
    end
  end
endmodule
