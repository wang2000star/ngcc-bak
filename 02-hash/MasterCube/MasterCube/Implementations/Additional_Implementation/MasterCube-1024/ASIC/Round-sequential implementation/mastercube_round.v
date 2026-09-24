// MasterCube round-level FSM command wrapper.
// This version removes the word/row/stage micro-FSM and state memory.
// One complete forward or inverse round is evaluated combinationally per clock.

`timescale 1 ns / 1 ps
`include "mastercube_globals.v"

module mastercube_round (
  input  wire       clk_i,
  input  wire       rst_ni,
  input  wire       cmd_valid_i,
  input  wire [1:0] cmd_i,
  input  wire [7:0] byte_addr_i,
  input  wire [7:0] byte_data_i,
  input  wire       word64_valid_i,
  input  wire [63:0] word_data_i,
  output wire       ready_o,
  output reg        done_o,
  output reg  [7:0] byte_data_o
);
  localparam [1:0] CMD_CLEAR     = 2'd0;
  localparam [1:0] CMD_XOR_BYTE  = 2'd1;
  localparam [1:0] CMD_READ_BYTE = 2'd2;
  localparam [1:0] CMD_PERMUTE   = 2'd3;

  localparam [4:0] ROUND_0       = 5'd0;
  localparam [4:0] ROUND_1       = 5'd1;
  localparam [4:0] ROUND_2       = 5'd2;
  localparam [4:0] ROUND_3       = 5'd3;
  localparam [4:0] ROUND_4       = 5'd4;
  localparam [4:0] ROUND_5       = 5'd5;
  localparam [4:0] ROUND_6       = 5'd6;
  localparam [4:0] ROUND_7       = 5'd7;
  localparam [4:0] ROUND_8       = 5'd8;
  localparam [4:0] ROUND_9       = 5'd9;
  localparam [4:0] ROUND_10      = 5'd10;
  localparam [4:0] ROUND_11      = 5'd11;
  localparam [4:0] ROUND_12      = 5'd12;
  localparam [4:0] ROUND_13      = 5'd13;
  localparam [4:0] ROUND_14      = 5'd14;
  localparam [4:0] ROUND_15      = 5'd15;
  localparam [4:0] ROUND_16      = 5'd16;
  localparam [4:0] ROUND_17      = 5'd17;

  reg                   busy_q;
  reg [4:0]             round_state_q;
  reg [`STATE_BITS-1:0] state_q_full;
  reg [`STATE_BITS-1:0] feed_q_full;

  wire [10:0]           byte_bit_addr_w;
  wire [4:0]            fwd_round_idx_ext_w;
  wire [4:0]            inv_round_idx_ext_w;
  wire [3:0]            fwd_round_idx_w;
  wire [3:0]            inv_round_idx_w;
  wire [`STATE_BITS-1:0] fwd_round_w;
  wire [`STATE_BITS-1:0] inv_round_w;

  assign ready_o         = !busy_q;
  assign byte_bit_addr_w = {byte_addr_i, 3'b000};
  assign fwd_round_idx_ext_w = round_state_q - ROUND_0;
  assign inv_round_idx_ext_w = round_state_q - ROUND_9;
  assign fwd_round_idx_w = fwd_round_idx_ext_w[3:0];
  assign inv_round_idx_w = inv_round_idx_ext_w[3:0];

  mastercube_round_fwd u_round_fwd (
    .state_in (state_q_full),
    .round_idx(fwd_round_idx_w),
    .state_out(fwd_round_w)
  );

  mastercube_round_inv u_round_inv (
    .state_in (feed_q_full),
    .round_idx(inv_round_idx_w),
    .state_out(inv_round_w)
  );

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      busy_q      <= 1'b0;
      round_state_q <= ROUND_0;
      state_q_full <= {`STATE_BITS{1'b0}};
      feed_q_full <= {`STATE_BITS{1'b0}};
      done_o      <= 1'b0;
      byte_data_o <= 8'd0;
    end
    else begin
      done_o <= 1'b0;

      if (!busy_q) begin
          if (cmd_valid_i) begin
            case (cmd_i)
              CMD_CLEAR : begin
                state_q_full <= {`STATE_BITS{1'b0}};
                feed_q_full  <= {`STATE_BITS{1'b0}};
                byte_data_o  <= 8'd0;
                done_o       <= 1'b1;
              end

              CMD_XOR_BYTE : begin
                if (word64_valid_i) begin
                  case (byte_addr_i[7:3])
                    5'd0  : state_q_full[64*0  +: 64] <= state_q_full[64*0  +: 64] ^ word_data_i;
                    5'd1  : state_q_full[64*1  +: 64] <= state_q_full[64*1  +: 64] ^ word_data_i;
                    5'd2  : state_q_full[64*2  +: 64] <= state_q_full[64*2  +: 64] ^ word_data_i;
                    5'd3  : state_q_full[64*3  +: 64] <= state_q_full[64*3  +: 64] ^ word_data_i;
                    5'd4  : state_q_full[64*4  +: 64] <= state_q_full[64*4  +: 64] ^ word_data_i;
                    5'd5  : state_q_full[64*5  +: 64] <= state_q_full[64*5  +: 64] ^ word_data_i;
                    5'd6  : state_q_full[64*6  +: 64] <= state_q_full[64*6  +: 64] ^ word_data_i;
                    5'd7  : state_q_full[64*7  +: 64] <= state_q_full[64*7  +: 64] ^ word_data_i;
                    5'd8  : state_q_full[64*8  +: 64] <= state_q_full[64*8  +: 64] ^ word_data_i;
                    5'd9  : state_q_full[64*9  +: 64] <= state_q_full[64*9  +: 64] ^ word_data_i;
                    5'd10 : state_q_full[64*10 +: 64] <= state_q_full[64*10 +: 64] ^ word_data_i;
                    5'd11 : state_q_full[64*11 +: 64] <= state_q_full[64*11 +: 64] ^ word_data_i;
                    5'd12 : state_q_full[64*12 +: 64] <= state_q_full[64*12 +: 64] ^ word_data_i;
                    5'd13 : state_q_full[64*13 +: 64] <= state_q_full[64*13 +: 64] ^ word_data_i;
                    5'd14 : state_q_full[64*14 +: 64] <= state_q_full[64*14 +: 64] ^ word_data_i;
                    5'd15 : state_q_full[64*15 +: 64] <= state_q_full[64*15 +: 64] ^ word_data_i;
                    5'd16 : state_q_full[64*16 +: 64] <= state_q_full[64*16 +: 64] ^ word_data_i;
                    5'd17 : state_q_full[64*17 +: 64] <= state_q_full[64*17 +: 64] ^ word_data_i;
                    5'd18 : state_q_full[64*18 +: 64] <= state_q_full[64*18 +: 64] ^ word_data_i;
                    5'd19 : state_q_full[64*19 +: 64] <= state_q_full[64*19 +: 64] ^ word_data_i;
                    5'd20 : state_q_full[64*20 +: 64] <= state_q_full[64*20 +: 64] ^ word_data_i;
                    5'd21 : state_q_full[64*21 +: 64] <= state_q_full[64*21 +: 64] ^ word_data_i;
                    5'd22 : state_q_full[64*22 +: 64] <= state_q_full[64*22 +: 64] ^ word_data_i;
                    default : state_q_full[64*23 +: 64] <= state_q_full[64*23 +: 64] ^ word_data_i;
                  endcase
                end
                else begin
                  state_q_full[byte_bit_addr_w +: 8] <=
                    state_q_full[byte_bit_addr_w +: 8] ^ byte_data_i;
                end
                done_o <= 1'b1;
              end

              CMD_READ_BYTE : begin
                byte_data_o <= state_q_full[byte_bit_addr_w +: 8];
                done_o      <= 1'b1;
              end

              CMD_PERMUTE : begin
                feed_q_full <= state_q_full;
                round_state_q <= ROUND_0;
                busy_q      <= 1'b1;
              end

              default : begin
              end
            endcase
          end
      end
      else begin
        case (round_state_q)
        ROUND_0,
        ROUND_1,
        ROUND_2,
        ROUND_3,
        ROUND_4,
        ROUND_5,
        ROUND_6,
        ROUND_7 : begin
          state_q_full <= fwd_round_w;
          round_state_q <= round_state_q + 5'd1;
        end

        ROUND_8 : begin
          state_q_full <= fwd_round_w;
          round_state_q <= ROUND_9;
        end

        ROUND_9,
        ROUND_10,
        ROUND_11,
        ROUND_12,
        ROUND_13,
        ROUND_14,
        ROUND_15,
        ROUND_16 : begin
          feed_q_full <= inv_round_w;
          round_state_q <= round_state_q + 5'd1;
        end

        ROUND_17 : begin
          state_q_full <= state_q_full ^ inv_round_w;
          feed_q_full  <= {`STATE_BITS{1'b0}};
          round_state_q <= ROUND_0;
          busy_q       <= 1'b0;
          done_o       <= 1'b1;
        end

        default : begin
          round_state_q <= ROUND_0;
          busy_q       <= 1'b0;
        end
      endcase
      end
    end
  end
endmodule
