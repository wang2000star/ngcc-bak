//======================================================================
//
// duet_core_512.v
// -----------
// Verilog 2001 implementation of the Duet-512 hash core.
//
// ARCHITECTURE UPDATE: Single duet_perm_unit instantiated to save area.
// f1 and f2 are multiplexed onto the same physical 960-bit datapath
// since they run strictly sequentially.
//
//======================================================================

`default_nettype none

module duet_core(
                 input wire             clk,
                 input wire             reset_n,

                 input wire             init,   // clear A,B,C to zero
                 input wire             absorb, // absorb one padded 384-bit block

                 input wire [383 : 0]   block,  // Mi, MSB word first (6 x 64-bit)

                 output wire            ready,
                 output wire [511 : 0]  digest,
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
  reg [63 : 0] A0_new, A1_new, A2_new, A3_new, A4_new, A5_new;
  reg          A_we;

  reg [63 : 0] B0_reg, B1_reg, B2_reg, B3_reg, B4_reg, B5_reg;
  reg [63 : 0] B0_new, B1_new, B2_new, B3_new, B4_new, B5_new;
  reg          B_we;

  reg [63 : 0] C0_reg, C1_reg, C2_reg, C3_reg, C4_reg, C5_reg, C6_reg, C7_reg, C8_reg;
  reg [63 : 0] C0_new, C1_new, C2_new, C3_new, C4_new, C5_new, C6_new, C7_new, C8_new;
  reg          C_we;

  reg [63 : 0] CL0_reg, CL1_reg, CL2_reg, CL3_reg, CL4_reg, CL5_reg, CL6_reg, CL7_reg, CL8_reg;
  reg [63 : 0] CL0_new, CL1_new, CL2_new, CL3_new, CL4_new, CL5_new, CL6_new, CL7_new, CL8_new;
  reg          CL_we;

  reg [63 : 0] SM0_reg, SM1_reg, SM2_reg, SM3_reg, SM4_reg, SM5_reg;
  reg [63 : 0] SM0_new, SM1_new, SM2_new, SM3_new, SM4_new, SM5_new;
  reg          SM_we;

  reg          ready_reg, ready_new, ready_we;
  reg          digest_valid_reg, digest_valid_new, digest_valid_we;

  reg [2 : 0]  ctrl_reg, ctrl_new;
  reg          ctrl_we;


  //----------------------------------------------------------------
  // Wires (Unified for single permutation unit).
  //----------------------------------------------------------------
  reg          perm_start;
  reg [959:0]  perm_load_state;
  wire         perm_busy, perm_done;
  wire [959:0] perm_result;
  wire [63:0]  perm_pi_data;
  reg  [3:0]   perm_round_idx;

  reg capture_f1, capture_f2;
  reg latch_sigma_m;
  reg chain_init;

  // Signal indicating whether the permutation unit is executing f2
  wire is_f2 = (ctrl_reg == CTRL_F1_DONE) || (ctrl_reg == CTRL_F2_RUN);


  //----------------------------------------------------------------
  // Single Module instantiation.
  //----------------------------------------------------------------
  duet_perm_unit perm_inst(
                        .clk(clk),
                        .reset_n(reset_n),
                        .start(perm_start),
                        .load_state(perm_load_state),
                        .pi_data(perm_pi_data),
                        .busy(perm_busy),
                        .done(perm_done),
                        .result_state(perm_result)
                       );

  // Address routing: base 12 for f2, base 0 for f1
  wire [4:0] pi_addr = is_f2 ? (5'd12 + {1'b0, perm_round_idx}) : {1'b0, perm_round_idx};

  duet_pi_constants perm_pi_rom(
      .addr(pi_addr),
      .PI(perm_pi_data)
  );

  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign ready        = ready_reg;
  assign digest       = {C0_reg, C1_reg, C2_reg, C3_reg, C4_reg, C5_reg, C6_reg, C7_reg};
  assign digest_valid = digest_valid_reg;

  //----------------------------------------------------------------
  // Round-index tracking
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin : round_idx_track
      if (!reset_n) begin
          perm_round_idx <= 4'h0;
      end else begin
          if (perm_start)
            perm_round_idx <= 4'h0;
          else if (perm_busy)
            perm_round_idx <= perm_round_idx + 1'b1;
      end
    end // round_idx_track


  //----------------------------------------------------------------
  // sigma_permutation
  //----------------------------------------------------------------
  always @*
    begin : sigma_logic
      SM0_new = block[63:0];
      SM1_new = 64'h0; SM2_new = 64'h0; SM3_new = 64'h0;
      SM4_new = 64'h0; SM5_new = 64'h0;
      SM_we   = 1'b0;

      if (latch_sigma_m)
        begin
          SM0_new = block[191:128]; // in[3]
          SM1_new = block[383:320]; // in[0]
          SM2_new = block[63:0];    // in[5]
          SM3_new = block[319:256]; // in[1]
          SM4_new = block[127:64];  // in[4]
          SM5_new = block[255:192]; // in[2]
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
          B0_reg<=64'h0; B1_reg<=64'h0; B2_reg<=64'h0; B3_reg<=64'h0; B4_reg<=64'h0; B5_reg<=64'h0;
          C0_reg<=64'h0; C1_reg<=64'h0; C2_reg<=64'h0; C3_reg<=64'h0; C4_reg<=64'h0;
          C5_reg<=64'h0; C6_reg<=64'h0; C7_reg<=64'h0; C8_reg<=64'h0;
          CL0_reg<=64'h0; CL1_reg<=64'h0; CL2_reg<=64'h0; CL3_reg<=64'h0; CL4_reg<=64'h0;
          CL5_reg<=64'h0; CL6_reg<=64'h0; CL7_reg<=64'h0; CL8_reg<=64'h0;
          SM0_reg<=64'h0; SM1_reg<=64'h0; SM2_reg<=64'h0; SM3_reg<=64'h0; SM4_reg<=64'h0; SM5_reg<=64'h0;
          ready_reg <= 1'b1;
          digest_valid_reg <= 1'b0;
          ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
          if (A_we) begin
              A0_reg<=A0_new; A1_reg<=A1_new; A2_reg<=A2_new;
              A3_reg<=A3_new; A4_reg<=A4_new; A5_reg<=A5_new;
          end
          if (B_we) begin
              B0_reg<=B0_new; B1_reg<=B1_new; B2_reg<=B2_new;
              B3_reg<=B3_new; B4_reg<=B4_new; B5_reg<=B5_new;
          end
          if (C_we) begin
              C0_reg<=C0_new; C1_reg<=C1_new; C2_reg<=C2_new; C3_reg<=C3_new; C4_reg<=C4_new;
              C5_reg<=C5_new; C6_reg<=C6_new; C7_reg<=C7_new; C8_reg<=C8_new;
          end
          if (CL_we) begin
              CL0_reg<=CL0_new; CL1_reg<=CL1_new; CL2_reg<=CL2_new; CL3_reg<=CL3_new; CL4_reg<=CL4_new;
              CL5_reg<=CL5_new; CL6_reg<=CL6_new; CL7_reg<=CL7_new; CL8_reg<=CL8_new;
          end
          if (SM_we) begin
              SM0_reg<=SM0_new; SM1_reg<=SM1_new; SM2_reg<=SM2_new;
              SM3_reg<=SM3_new; SM4_reg<=SM4_new; SM5_reg<=SM5_new;
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
      B0_new=64'h0; B1_new=64'h0; B2_new=64'h0; B3_new=64'h0; B4_new=64'h0; B5_new=64'h0;
      C0_new=64'h0; C1_new=64'h0; C2_new=64'h0; C3_new=64'h0; C4_new=64'h0;
      C5_new=64'h0; C6_new=64'h0; C7_new=64'h0; C8_new=64'h0;
      CL0_new=64'h0; CL1_new=64'h0; CL2_new=64'h0; CL3_new=64'h0; CL4_new=64'h0;
      CL5_new=64'h0; CL6_new=64'h0; CL7_new=64'h0; CL8_new=64'h0;
      A_we=1'b0; B_we=1'b0; C_we=1'b0; CL_we=1'b0;

      if (chain_init)
        begin
          A_we=1'b1; B_we=1'b1; C_we=1'b1;
        end

      if (capture_f1)
        begin
          A0_new = perm_result[959:896]; A1_new = perm_result[895:832];
          A2_new = perm_result[831:768]; A3_new = perm_result[767:704];
          A4_new = perm_result[703:640]; A5_new = perm_result[639:576];
          A_we   = 1'b1;

          CL0_new = perm_result[575:512] ^ C0_reg;
          CL1_new = perm_result[511:448] ^ C1_reg;
          CL2_new = perm_result[447:384] ^ C2_reg;
          CL3_new = perm_result[383:320] ^ C3_reg;
          CL4_new = perm_result[319:256] ^ C4_reg;
          CL5_new = perm_result[255:192] ^ C5_reg;
          CL6_new = perm_result[191:128] ^ C6_reg;
          CL7_new = perm_result[127:64]  ^ C7_reg;
          CL8_new = perm_result[63:0]    ^ C8_reg;
          CL_we   = 1'b1;
        end

      if (capture_f2)
        begin
          B0_new = perm_result[959:896]; B1_new = perm_result[895:832];
          B2_new = perm_result[831:768]; B3_new = perm_result[767:704];
          B4_new = perm_result[703:640]; B5_new = perm_result[639:576];
          B_we   = 1'b1;

          C0_new = perm_result[575:512] ^ CL0_reg;
          C1_new = perm_result[511:448] ^ CL1_reg;
          C2_new = perm_result[447:384] ^ CL2_reg;
          C3_new = perm_result[383:320] ^ CL3_reg;
          C4_new = perm_result[319:256] ^ CL4_reg;
          C5_new = perm_result[255:192] ^ CL5_reg;
          C6_new = perm_result[191:128] ^ CL6_reg;
          C7_new = perm_result[127:64]  ^ CL7_reg;
          C8_new = perm_result[63:0]    ^ CL8_reg;
          C_we    = 1'b1;
        end
    end // chain_logic


  //----------------------------------------------------------------
  // Multiplexed Permutation Input
  //----------------------------------------------------------------
  always @*
    begin : perm_input_logic
      if (is_f2) begin
        perm_load_state = {B0_reg ^ SM0_reg, B1_reg ^ SM1_reg, B2_reg ^ SM2_reg,
                           B3_reg ^ SM3_reg, B4_reg ^ SM4_reg, B5_reg ^ SM5_reg,
                           perm_result[575:512] ^ C0_reg, perm_result[511:448] ^ C1_reg,
                           perm_result[447:384] ^ C2_reg, perm_result[383:320] ^ C3_reg,
                           perm_result[319:256] ^ C4_reg, perm_result[255:192] ^ C5_reg,
                           perm_result[191:128] ^ C6_reg, perm_result[127:64]  ^ C7_reg,
                           perm_result[63:0]    ^ C8_reg};
      end else begin
        perm_load_state = {A0_reg ^ block[383:320], A1_reg ^ block[319:256], A2_reg ^ block[255:192],
                           A3_reg ^ block[191:128],  A4_reg ^ block[127:64],  A5_reg ^ block[63:0],
                           C0_reg, C1_reg, C2_reg, C3_reg, C4_reg, C5_reg, C6_reg, C7_reg, C8_reg};
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

endmodule // duet_core