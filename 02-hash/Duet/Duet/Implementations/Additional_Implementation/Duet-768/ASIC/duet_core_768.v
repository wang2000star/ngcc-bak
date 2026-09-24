//======================================================================
//
// duet_core_768.v
// -----------------
// Verilog 2001 implementation of the Duet-768 hash core (shared with
// Duet-1024 at the permutation level; only the rate/capacity split and
// the sigma word-permutation table differ between the two).
//
// Parameters: r = 1088 bits (rate, A/B = 17 x 64-bit words),
// c = 832 bits (capacity, C = 13 x 64-bit words), permutation
// width = 1920 bits (30 x 64-bit words), ROUNDS = 18.
// digest_len = 768 bits, which is <= c, so a single capacity
// readout after the final absorb is sufficient (no extra squeeze
// rounds are ever needed for the fixed-length Duet-768 digest).
//
// ARCHITECTURE: Single duet_perm_unit_768 instantiated to save area.
// f1 and f2 are multiplexed onto the same physical 1920-bit
// datapath since they run strictly sequentially, exactly as in
// duet_core.v (Duet-512).
//
//======================================================================

`default_nettype none

module duet_core_768(
                 input wire             clk,
                 input wire             reset_n,

                 input wire             init,   // clear A,B,C to zero
                 input wire             absorb, // absorb one padded 1088-bit block

                 input wire [1087 : 0]  block,  // Mi, MSB word first (17 x 64-bit)

                 output wire            ready,
                 output wire [767 : 0]  digest,
                 output wire            digest_valid
                );

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam CTRL_IDLE    = 3'h0;
  localparam CTRL_F1_RUN  = 3'h1;
  localparam CTRL_F1_DONE = 3'h2;
  localparam CTRL_F2_RUN  = 3'h3;
  localparam CTRL_F2_DONE = 3'h4;

  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [63 : 0] A0_reg, A1_reg, A2_reg, A3_reg, A4_reg, A5_reg;
  reg [63 : 0] A6_reg, A7_reg, A8_reg, A9_reg, A10_reg, A11_reg;
  reg [63 : 0] A12_reg, A13_reg, A14_reg, A15_reg, A16_reg;
  reg [63 : 0] A0_new, A1_new, A2_new, A3_new, A4_new, A5_new;
  reg [63 : 0] A6_new, A7_new, A8_new, A9_new, A10_new, A11_new;
  reg [63 : 0] A12_new, A13_new, A14_new, A15_new, A16_new;
  reg          A_we;

  reg [63 : 0] B0_reg, B1_reg, B2_reg, B3_reg, B4_reg, B5_reg;
  reg [63 : 0] B6_reg, B7_reg, B8_reg, B9_reg, B10_reg, B11_reg;
  reg [63 : 0] B12_reg, B13_reg, B14_reg, B15_reg, B16_reg;
  reg [63 : 0] B0_new, B1_new, B2_new, B3_new, B4_new, B5_new;
  reg [63 : 0] B6_new, B7_new, B8_new, B9_new, B10_new, B11_new;
  reg [63 : 0] B12_new, B13_new, B14_new, B15_new, B16_new;
  reg          B_we;

  reg [63 : 0] C0_reg, C1_reg, C2_reg, C3_reg, C4_reg, C5_reg;
  reg [63 : 0] C6_reg, C7_reg, C8_reg, C9_reg, C10_reg, C11_reg;
  reg [63 : 0] C12_reg;
  reg [63 : 0] C0_new, C1_new, C2_new, C3_new, C4_new, C5_new;
  reg [63 : 0] C6_new, C7_new, C8_new, C9_new, C10_new, C11_new;
  reg [63 : 0] C12_new;
  reg          C_we;

  reg [63 : 0] CL0_reg, CL1_reg, CL2_reg, CL3_reg, CL4_reg, CL5_reg;
  reg [63 : 0] CL6_reg, CL7_reg, CL8_reg, CL9_reg, CL10_reg, CL11_reg;
  reg [63 : 0] CL12_reg;
  reg [63 : 0] CL0_new, CL1_new, CL2_new, CL3_new, CL4_new, CL5_new;
  reg [63 : 0] CL6_new, CL7_new, CL8_new, CL9_new, CL10_new, CL11_new;
  reg [63 : 0] CL12_new;
  reg          CL_we;

  reg [63 : 0] SM0_reg, SM1_reg, SM2_reg, SM3_reg, SM4_reg, SM5_reg;
  reg [63 : 0] SM6_reg, SM7_reg, SM8_reg, SM9_reg, SM10_reg, SM11_reg;
  reg [63 : 0] SM12_reg, SM13_reg, SM14_reg, SM15_reg, SM16_reg;
  reg [63 : 0] SM0_new, SM1_new, SM2_new, SM3_new, SM4_new, SM5_new;
  reg [63 : 0] SM6_new, SM7_new, SM8_new, SM9_new, SM10_new, SM11_new;
  reg [63 : 0] SM12_new, SM13_new, SM14_new, SM15_new, SM16_new;
  reg          SM_we;

  reg          ready_reg, ready_new, ready_we;
  reg          digest_valid_reg, digest_valid_new, digest_valid_we;

  reg [2 : 0]  ctrl_reg, ctrl_new;
  reg          ctrl_we;


  //----------------------------------------------------------------
  // Wires (Unified for single permutation unit).
  //----------------------------------------------------------------
  reg          perm_start;
  reg [1919:0]  perm_load_state;
  wire         perm_busy, perm_done;
  wire [1919:0] perm_result;
  wire [63:0]  perm_pi_data;
  reg  [4:0]   perm_round_idx;

  reg capture_f1, capture_f2;
  reg latch_sigma_m;
  reg chain_init;

  // Signal indicating whether the permutation unit is executing f2
  wire is_f2 = (ctrl_reg == CTRL_F1_DONE) || (ctrl_reg == CTRL_F2_RUN);


  //----------------------------------------------------------------
  // Single Module instantiation.
  //----------------------------------------------------------------
  duet_perm_unit_768 perm_inst(
                        .clk(clk),
                        .reset_n(reset_n),
                        .start(perm_start),
                        .load_state(perm_load_state),
                        .pi_data(perm_pi_data),
                        .busy(perm_busy),
                        .done(perm_done),
                        .result_state(perm_result)
                       );

  // Address routing: base 18 for f2, base 0 for f1
  wire [5:0] pi_addr = is_f2 ? (6'd18 + {1'b0, perm_round_idx}) : {1'b0, perm_round_idx};

  duet_pi_constants_768 perm_pi_rom(
      .addr(pi_addr),
      .PI(perm_pi_data)
  );

  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign ready        = ready_reg;
  assign digest       = {C0_reg, C1_reg, C2_reg, C3_reg, C4_reg, C5_reg, C6_reg, C7_reg, C8_reg, C9_reg, C10_reg, C11_reg};
  assign digest_valid = digest_valid_reg;


  //----------------------------------------------------------------
  // Round-index tracking
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin : round_idx_track
      if (!reset_n) begin
          perm_round_idx <= 5'h0;
      end else begin
          if (perm_start)
            perm_round_idx <= 5'h0;
          else if (perm_busy)
            perm_round_idx <= perm_round_idx + 1'b1;
      end
    end // round_idx_track


  //----------------------------------------------------------------
  // sigma_permutation
  //
  // sigma table (output index -> source word index in Mi), taken
  // directly from the C reference's sigma_permutation() for r=1088
  // (WORDS_r=17): [9, 2, 15, 0, 6, 12, 4, 16, 1, 10, 7, 14, 3, 11, 5, 13, 8]
  //----------------------------------------------------------------
  always @*
    begin : sigma_logic
      SM0_new = 64'h0; SM1_new = 64'h0; SM2_new = 64'h0; SM3_new = 64'h0; SM4_new = 64'h0; SM5_new = 64'h0;
      SM6_new = 64'h0; SM7_new = 64'h0; SM8_new = 64'h0; SM9_new = 64'h0; SM10_new = 64'h0; SM11_new = 64'h0;
      SM12_new = 64'h0; SM13_new = 64'h0; SM14_new = 64'h0; SM15_new = 64'h0; SM16_new = 64'h0;
      SM_we   = 1'b0;

      if (latch_sigma_m)
        begin
          SM0_new = block[511:448]; // in[9]
          SM1_new = block[959:896]; // in[2]
          SM2_new = block[127:64]; // in[15]
          SM3_new = block[1087:1024]; // in[0]
          SM4_new = block[703:640]; // in[6]
          SM5_new = block[319:256]; // in[12]
          SM6_new = block[831:768]; // in[4]
          SM7_new = block[63:0]; // in[16]
          SM8_new = block[1023:960]; // in[1]
          SM9_new = block[447:384]; // in[10]
          SM10_new = block[639:576]; // in[7]
          SM11_new = block[191:128]; // in[14]
          SM12_new = block[895:832]; // in[3]
          SM13_new = block[383:320]; // in[11]
          SM14_new = block[767:704]; // in[5]
          SM15_new = block[255:192]; // in[13]
          SM16_new = block[575:512]; // in[8]
          SM_we   = 1'b1;
        end
    end // sigma_logic


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin : reg_update
      if (!reset_n)
        begin
          A0_reg<=64'h0; A1_reg<=64'h0; A2_reg<=64'h0; A3_reg<=64'h0; A4_reg<=64'h0; A5_reg<=64'h0;
          A6_reg<=64'h0; A7_reg<=64'h0; A8_reg<=64'h0; A9_reg<=64'h0; A10_reg<=64'h0; A11_reg<=64'h0;
          A12_reg<=64'h0; A13_reg<=64'h0; A14_reg<=64'h0; A15_reg<=64'h0; A16_reg<=64'h0;
          B0_reg<=64'h0; B1_reg<=64'h0; B2_reg<=64'h0; B3_reg<=64'h0; B4_reg<=64'h0; B5_reg<=64'h0;
          B6_reg<=64'h0; B7_reg<=64'h0; B8_reg<=64'h0; B9_reg<=64'h0; B10_reg<=64'h0; B11_reg<=64'h0;
          B12_reg<=64'h0; B13_reg<=64'h0; B14_reg<=64'h0; B15_reg<=64'h0; B16_reg<=64'h0;
          C0_reg<=64'h0; C1_reg<=64'h0; C2_reg<=64'h0; C3_reg<=64'h0; C4_reg<=64'h0; C5_reg<=64'h0;
          C6_reg<=64'h0; C7_reg<=64'h0; C8_reg<=64'h0; C9_reg<=64'h0; C10_reg<=64'h0; C11_reg<=64'h0;
          C12_reg<=64'h0;
          CL0_reg<=64'h0; CL1_reg<=64'h0; CL2_reg<=64'h0; CL3_reg<=64'h0; CL4_reg<=64'h0; CL5_reg<=64'h0;
          CL6_reg<=64'h0; CL7_reg<=64'h0; CL8_reg<=64'h0; CL9_reg<=64'h0; CL10_reg<=64'h0; CL11_reg<=64'h0;
          CL12_reg<=64'h0;
          SM0_reg<=64'h0; SM1_reg<=64'h0; SM2_reg<=64'h0; SM3_reg<=64'h0; SM4_reg<=64'h0; SM5_reg<=64'h0;
          SM6_reg<=64'h0; SM7_reg<=64'h0; SM8_reg<=64'h0; SM9_reg<=64'h0; SM10_reg<=64'h0; SM11_reg<=64'h0;
          SM12_reg<=64'h0; SM13_reg<=64'h0; SM14_reg<=64'h0; SM15_reg<=64'h0; SM16_reg<=64'h0;
          ready_reg <= 1'b1;
          digest_valid_reg <= 1'b0;
          ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
          if (A_we) begin
              A0_reg<=A0_new; A1_reg<=A1_new; A2_reg<=A2_new; A3_reg<=A3_new; A4_reg<=A4_new;
              A5_reg<=A5_new; A6_reg<=A6_new; A7_reg<=A7_new; A8_reg<=A8_new; A9_reg<=A9_new;
              A10_reg<=A10_new; A11_reg<=A11_new; A12_reg<=A12_new; A13_reg<=A13_new; A14_reg<=A14_new;
              A15_reg<=A15_new; A16_reg<=A16_new;
          end
          if (B_we) begin
              B0_reg<=B0_new; B1_reg<=B1_new; B2_reg<=B2_new; B3_reg<=B3_new; B4_reg<=B4_new;
              B5_reg<=B5_new; B6_reg<=B6_new; B7_reg<=B7_new; B8_reg<=B8_new; B9_reg<=B9_new;
              B10_reg<=B10_new; B11_reg<=B11_new; B12_reg<=B12_new; B13_reg<=B13_new; B14_reg<=B14_new;
              B15_reg<=B15_new; B16_reg<=B16_new;
          end
          if (C_we) begin
              C0_reg<=C0_new; C1_reg<=C1_new; C2_reg<=C2_new; C3_reg<=C3_new; C4_reg<=C4_new;
              C5_reg<=C5_new; C6_reg<=C6_new; C7_reg<=C7_new; C8_reg<=C8_new; C9_reg<=C9_new;
              C10_reg<=C10_new; C11_reg<=C11_new; C12_reg<=C12_new;
          end
          if (CL_we) begin
              CL0_reg<=CL0_new; CL1_reg<=CL1_new; CL2_reg<=CL2_new; CL3_reg<=CL3_new; CL4_reg<=CL4_new;
              CL5_reg<=CL5_new; CL6_reg<=CL6_new; CL7_reg<=CL7_new; CL8_reg<=CL8_new; CL9_reg<=CL9_new;
              CL10_reg<=CL10_new; CL11_reg<=CL11_new; CL12_reg<=CL12_new;
          end
          if (SM_we) begin
              SM0_reg<=SM0_new; SM1_reg<=SM1_new; SM2_reg<=SM2_new; SM3_reg<=SM3_new; SM4_reg<=SM4_new;
              SM5_reg<=SM5_new; SM6_reg<=SM6_new; SM7_reg<=SM7_new; SM8_reg<=SM8_new; SM9_reg<=SM9_new;
              SM10_reg<=SM10_new; SM11_reg<=SM11_new; SM12_reg<=SM12_new; SM13_reg<=SM13_new; SM14_reg<=SM14_new;
              SM15_reg<=SM15_new; SM16_reg<=SM16_new;
          end
          if (ready_we)
            ready_reg <= ready_new;
          if (digest_valid_we)
            digest_valid_reg <= digest_valid_new;
          if (ctrl_we)
            ctrl_reg <= ctrl_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // chain_logic
  //----------------------------------------------------------------
  always @*
    begin : chain_logic
      A0_new=64'h0; A1_new=64'h0; A2_new=64'h0; A3_new=64'h0; A4_new=64'h0; A5_new=64'h0;
      A6_new=64'h0; A7_new=64'h0; A8_new=64'h0; A9_new=64'h0; A10_new=64'h0; A11_new=64'h0;
      A12_new=64'h0; A13_new=64'h0; A14_new=64'h0; A15_new=64'h0; A16_new=64'h0;
      B0_new=64'h0; B1_new=64'h0; B2_new=64'h0; B3_new=64'h0; B4_new=64'h0; B5_new=64'h0;
      B6_new=64'h0; B7_new=64'h0; B8_new=64'h0; B9_new=64'h0; B10_new=64'h0; B11_new=64'h0;
      B12_new=64'h0; B13_new=64'h0; B14_new=64'h0; B15_new=64'h0; B16_new=64'h0;
      C0_new=64'h0; C1_new=64'h0; C2_new=64'h0; C3_new=64'h0; C4_new=64'h0; C5_new=64'h0;
      C6_new=64'h0; C7_new=64'h0; C8_new=64'h0; C9_new=64'h0; C10_new=64'h0; C11_new=64'h0;
      C12_new=64'h0;
      CL0_new=64'h0; CL1_new=64'h0; CL2_new=64'h0; CL3_new=64'h0; CL4_new=64'h0; CL5_new=64'h0;
      CL6_new=64'h0; CL7_new=64'h0; CL8_new=64'h0; CL9_new=64'h0; CL10_new=64'h0; CL11_new=64'h0;
      CL12_new=64'h0;
      A_we=1'b0; B_we=1'b0; C_we=1'b0; CL_we=1'b0;

      if (chain_init)
        begin
          A_we=1'b1; B_we=1'b1; C_we=1'b1;
        end

      if (capture_f1)
        begin
          A0_new = perm_result[1919:1856]; A1_new = perm_result[1855:1792];
          A2_new = perm_result[1791:1728]; A3_new = perm_result[1727:1664];
          A4_new = perm_result[1663:1600]; A5_new = perm_result[1599:1536];
          A6_new = perm_result[1535:1472]; A7_new = perm_result[1471:1408];
          A8_new = perm_result[1407:1344]; A9_new = perm_result[1343:1280];
          A10_new = perm_result[1279:1216]; A11_new = perm_result[1215:1152];
          A12_new = perm_result[1151:1088]; A13_new = perm_result[1087:1024];
          A14_new = perm_result[1023:960]; A15_new = perm_result[959:896];
          A16_new = perm_result[895:832];
          A_we   = 1'b1;

          CL0_new = perm_result[831:768] ^ C0_reg;
          CL1_new = perm_result[767:704] ^ C1_reg;
          CL2_new = perm_result[703:640] ^ C2_reg;
          CL3_new = perm_result[639:576] ^ C3_reg;
          CL4_new = perm_result[575:512] ^ C4_reg;
          CL5_new = perm_result[511:448] ^ C5_reg;
          CL6_new = perm_result[447:384] ^ C6_reg;
          CL7_new = perm_result[383:320] ^ C7_reg;
          CL8_new = perm_result[319:256] ^ C8_reg;
          CL9_new = perm_result[255:192] ^ C9_reg;
          CL10_new = perm_result[191:128] ^ C10_reg;
          CL11_new = perm_result[127:64] ^ C11_reg;
          CL12_new = perm_result[63:0] ^ C12_reg;
          CL_we   = 1'b1;
        end

      if (capture_f2)
        begin
          B0_new = perm_result[1919:1856]; B1_new = perm_result[1855:1792];
          B2_new = perm_result[1791:1728]; B3_new = perm_result[1727:1664];
          B4_new = perm_result[1663:1600]; B5_new = perm_result[1599:1536];
          B6_new = perm_result[1535:1472]; B7_new = perm_result[1471:1408];
          B8_new = perm_result[1407:1344]; B9_new = perm_result[1343:1280];
          B10_new = perm_result[1279:1216]; B11_new = perm_result[1215:1152];
          B12_new = perm_result[1151:1088]; B13_new = perm_result[1087:1024];
          B14_new = perm_result[1023:960]; B15_new = perm_result[959:896];
          B16_new = perm_result[895:832];
          B_we   = 1'b1;

          C0_new = perm_result[831:768] ^ CL0_reg;
          C1_new = perm_result[767:704] ^ CL1_reg;
          C2_new = perm_result[703:640] ^ CL2_reg;
          C3_new = perm_result[639:576] ^ CL3_reg;
          C4_new = perm_result[575:512] ^ CL4_reg;
          C5_new = perm_result[511:448] ^ CL5_reg;
          C6_new = perm_result[447:384] ^ CL6_reg;
          C7_new = perm_result[383:320] ^ CL7_reg;
          C8_new = perm_result[319:256] ^ CL8_reg;
          C9_new = perm_result[255:192] ^ CL9_reg;
          C10_new = perm_result[191:128] ^ CL10_reg;
          C11_new = perm_result[127:64] ^ CL11_reg;
          C12_new = perm_result[63:0] ^ CL12_reg;
          C_we    = 1'b1;
        end
    end // chain_logic


  //----------------------------------------------------------------
  // Multiplexed Permutation Input
  //----------------------------------------------------------------
  always @*
    begin : perm_input_logic
      if (is_f2) begin
        perm_load_state = {
                           B0_reg ^ SM0_reg, B1_reg ^ SM1_reg, B2_reg ^ SM2_reg,
                           B3_reg ^ SM3_reg, B4_reg ^ SM4_reg, B5_reg ^ SM5_reg,
                           B6_reg ^ SM6_reg, B7_reg ^ SM7_reg, B8_reg ^ SM8_reg,
                           B9_reg ^ SM9_reg, B10_reg ^ SM10_reg, B11_reg ^ SM11_reg,
                           B12_reg ^ SM12_reg, B13_reg ^ SM13_reg, B14_reg ^ SM14_reg,
                           B15_reg ^ SM15_reg, B16_reg ^ SM16_reg,
                           perm_result[831:768] ^ C0_reg, perm_result[767:704] ^ C1_reg,
                           perm_result[703:640] ^ C2_reg, perm_result[639:576] ^ C3_reg,
                           perm_result[575:512] ^ C4_reg, perm_result[511:448] ^ C5_reg,
                           perm_result[447:384] ^ C6_reg, perm_result[383:320] ^ C7_reg,
                           perm_result[319:256] ^ C8_reg, perm_result[255:192] ^ C9_reg,
                           perm_result[191:128] ^ C10_reg, perm_result[127:64] ^ C11_reg,
                           perm_result[63:0] ^ C12_reg};
      end else begin
        perm_load_state = {
                           A0_reg ^ block[1087:1024], A1_reg ^ block[1023:960], A2_reg ^ block[959:896],
                           A3_reg ^ block[895:832], A4_reg ^ block[831:768], A5_reg ^ block[767:704],
                           A6_reg ^ block[703:640], A7_reg ^ block[639:576], A8_reg ^ block[575:512],
                           A9_reg ^ block[511:448], A10_reg ^ block[447:384], A11_reg ^ block[383:320],
                           A12_reg ^ block[319:256], A13_reg ^ block[255:192], A14_reg ^ block[191:128],
                           A15_reg ^ block[127:64], A16_reg ^ block[63:0],
                           C0_reg, C1_reg, C2_reg, C3_reg, C4_reg,
                           C5_reg, C6_reg, C7_reg, C8_reg, C9_reg,
                           C10_reg, C11_reg, C12_reg};
      end
    end // perm_input_logic


  //----------------------------------------------------------------
  // duet_ctrl_fsm
  //----------------------------------------------------------------
  always @*
    begin : duet_ctrl_fsm
      perm_start = 1'b0;
      capture_f1 = 1'b0; capture_f2 = 1'b0;
      latch_sigma_m = 1'b0;
      chain_init = 1'b0;
      ready_new = 1'b0; ready_we = 1'b0;
      digest_valid_new = 1'b0; digest_valid_we = 1'b0;
      ctrl_new = CTRL_IDLE; ctrl_we = 1'b0;

      case (ctrl_reg)
        CTRL_IDLE:
          begin
            if (init)
              begin
                chain_init = 1'b1;
                digest_valid_new = 1'b0; digest_valid_we = 1'b1;
              end
            else if (absorb)
              begin
                ready_new = 1'b0; ready_we = 1'b1;
                digest_valid_new = 1'b0; digest_valid_we = 1'b1;
                latch_sigma_m = 1'b1;
                perm_start = 1'b1;
                ctrl_new = CTRL_F1_RUN; ctrl_we = 1'b1;
              end
          end

        CTRL_F1_RUN:
          begin
            if (perm_done)
              begin
                ctrl_new = CTRL_F1_DONE; ctrl_we = 1'b1;
              end
          end

        CTRL_F1_DONE:
          begin
            capture_f1 = 1'b1;
            perm_start = 1'b1; // Launch the perm unit again immediately for f2
            ctrl_new = CTRL_F2_RUN; ctrl_we = 1'b1;
          end

        CTRL_F2_RUN:
          begin
            if (perm_done)
              begin
                ctrl_new = CTRL_F2_DONE; ctrl_we = 1'b1;
              end
          end

        CTRL_F2_DONE:
          begin
            capture_f2 = 1'b1;
            ready_new = 1'b1; ready_we = 1'b1;
            digest_valid_new = 1'b1; digest_valid_we = 1'b1;
            ctrl_new = CTRL_IDLE; ctrl_we = 1'b1;
          end

        default: ;
      endcase
    end // duet_ctrl_fsm

endmodule // duet_core_768

//======================================================================
// EOF duet_core_768.v
//======================================================================
