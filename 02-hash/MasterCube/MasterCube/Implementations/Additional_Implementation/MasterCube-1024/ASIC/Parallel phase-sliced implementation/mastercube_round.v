// MasterCube round command wrapper.
// Keeps the legacy byte command interface while using the high-speed
// split-stage round datapath.

`timescale 1 ns / 1 ps
`include "mastercube_globals.v"

module mastercube_round (
    input  wire       clk_i,
    input  wire       rst_ni,
    input  wire       cmd_valid_i,
    input  wire [1:0] cmd_i,
    input  wire [7:0] byte_addr_i,
    input  wire [7:0] byte_data_i,
    output wire       ready_o,
    output reg        done_o,
    output reg  [7:0] byte_data_o
);

localparam [1:0] CMD_CLEAR     = 2'd0;
localparam [1:0] CMD_XOR_BYTE  = 2'd1;
localparam [1:0] CMD_READ_BYTE = 2'd2;
localparam [1:0] CMD_PERMUTE   = 2'd3;

localparam [1:0] ST_IDLE       = 2'd0;
localparam [1:0] ST_PERMUTE    = 2'd1;

reg [1:0]              fsm_state;
reg [`STATE_BITS-1:0]  state_q;
reg [`STATE_BITS-1:0]  state_copy_q;
reg [3:0]              round_cnt_q;
reg                    round_phase_q;

wire [10:0] byte_bit_addr_w;
wire [`STATE_BITS-1:0] fwd_round_next_w;
wire [`STATE_BITS-1:0] inv_round_next_w;

assign ready_o = (fsm_state == ST_IDLE);
assign byte_bit_addr_w = {byte_addr_i, 3'b000};

mastercube_round_fwd_phase u_round_fwd_phase (
    .state_in (state_q),
    .round_idx(round_cnt_q),
    .phase    (round_phase_q),
    .state_out(fwd_round_next_w)
);

mastercube_round_inv_phase u_round_inv_phase (
    .state_in (state_copy_q),
    .round_idx(round_cnt_q),
    .phase    (round_phase_q),
    .state_out(inv_round_next_w)
);

always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        fsm_state     <= ST_IDLE;
        state_q       <= {`STATE_BITS{1'b0}};
        state_copy_q  <= {`STATE_BITS{1'b0}};
        round_cnt_q   <= 4'd0;
        round_phase_q <= 1'b0;
        done_o        <= 1'b0;
        byte_data_o   <= 8'd0;
    end
    else begin
        done_o <= 1'b0;

        case (fsm_state)
            ST_IDLE: begin
                round_phase_q <= 1'b0;

                if (cmd_valid_i) begin
                    case (cmd_i)
                        CMD_CLEAR: begin
                            state_q     <= {`STATE_BITS{1'b0}};
                            state_copy_q <= {`STATE_BITS{1'b0}};
                            byte_data_o <= 8'd0;
                            done_o      <= 1'b1;
                        end

                        CMD_XOR_BYTE: begin
                            state_q[byte_bit_addr_w +: 8] <=
                                state_q[byte_bit_addr_w +: 8] ^ byte_data_i;
                            done_o <= 1'b1;
                        end

                        CMD_READ_BYTE: begin
                            byte_data_o <= state_q[byte_bit_addr_w +: 8];
                            done_o      <= 1'b1;
                        end

                        default: begin
                            state_copy_q  <= state_q;
                            round_cnt_q   <= 4'd0;
                            round_phase_q <= 1'b0;
                            fsm_state     <= ST_PERMUTE;
                        end
                    endcase
                end
            end

            ST_PERMUTE: begin
                if (round_cnt_q < `N_ROUNDS_HALF) begin
                    if (!round_phase_q) begin
                        state_q       <= fwd_round_next_w;
                        state_copy_q  <= inv_round_next_w;
                        round_phase_q <= 1'b1;
                    end
                    else begin
                        state_q       <= fwd_round_next_w;
                        state_copy_q  <= inv_round_next_w;
                        round_cnt_q   <= round_cnt_q + 4'd1;
                        round_phase_q <= 1'b0;
                    end
                end
                else begin
                    state_q       <= state_q ^ state_copy_q;
                    state_copy_q  <= {`STATE_BITS{1'b0}};
                    round_cnt_q   <= 4'd0;
                    round_phase_q <= 1'b0;
                    done_o        <= 1'b1;
                    fsm_state     <= ST_IDLE;
                end
            end

            default: begin
                fsm_state <= ST_IDLE;
            end
        endcase
    end
end

endmodule
