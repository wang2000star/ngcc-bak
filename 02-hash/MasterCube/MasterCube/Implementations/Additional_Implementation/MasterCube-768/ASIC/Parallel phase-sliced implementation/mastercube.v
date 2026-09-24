// MasterCube Hash Algorithm - Top Module
// Performance-oriented Verilog-2001 implementation.

`timescale 1 ns / 1 ps
`include "mastercube_globals.v"

module mastercube #(
    parameter integer MAX_MSG_BYTES = 256
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [63:0] din,
    input  wire        din_valid,
    output wire        buffer_full,
    input  wire        last_block,
    input  wire [63:0] msg_bit_len,
    output reg         ready,
    output reg  [63:0] dout,
    output reg         dout_valid,
    input  wire [1:0]  digest_sel       // 1=512, 2=768, 3=1024 bits; other values default to 512
);

localparam IDLE            = 4'd0;
localparam ABSORB          = 4'd1;
localparam PERM_ABSORB     = 4'd2;
localparam PERM_PAD        = 4'd3;
localparam PERM_SQUEEZE    = 4'd4;
localparam APPLY_PAD_BLOCK = 4'd5;
localparam SQUEEZE         = 4'd6;
localparam DONE            = 4'd7;

reg [3:0] fsm_state;
reg [1:0] digest_sel_q;

reg [`STATE_BITS-1:0] state;
reg [`STATE_BITS-1:0] state_copy;

reg [3:0] round_cnt;
reg       round_phase;
reg [4:0] buffer_cnt;
reg [4:0] dout_cnt;

wire [4:0] digest_words_w;
wire [4:0] rate_words_w;
wire [4:0] rate_last_word_w;
wire       block_full_word_w;
wire [4:0] dout_word_w;
wire [4:0] dout_cnt_next_w;
wire       squeeze_rate_last_w;
wire       squeeze_more_w;

wire [`STATE_BITS-1:0] fwd_round_next;
wire [`STATE_BITS-1:0] inv_round_next;

assign rate_words_w      = (digest_sel_q == `DIGEST_768)  ? 5'd11 :
                           (digest_sel_q == `DIGEST_1024) ? 5'd7 :
                                                             5'd15;
assign digest_words_w    = (digest_sel_q == `DIGEST_768)  ? 5'd12 :
                           (digest_sel_q == `DIGEST_1024) ? 5'd16 :
                                                             5'd8;
assign rate_last_word_w  = rate_words_w - 5'd1;
assign block_full_word_w = (buffer_cnt == rate_last_word_w);
assign dout_word_w       = (digest_sel_q == `DIGEST_1024) ?
                           ((dout_cnt >= 5'd14) ? (dout_cnt - 5'd14) :
                            (dout_cnt >= 5'd7)  ? (dout_cnt - 5'd7)  :
                                                   dout_cnt) :
                           (digest_sel_q == `DIGEST_768) ?
                           ((dout_cnt >= 5'd11) ? (dout_cnt - 5'd11) :
                                                    dout_cnt) :
                                                    dout_cnt;
assign dout_cnt_next_w   = dout_cnt + 5'd1;
assign squeeze_rate_last_w = (dout_word_w == rate_last_word_w);
assign squeeze_more_w      = (dout_cnt_next_w < digest_words_w);
assign buffer_full       = (fsm_state == PERM_ABSORB) ||
                           (fsm_state == PERM_PAD) ||
                           (fsm_state == PERM_SQUEEZE) ||
                           (fsm_state == APPLY_PAD_BLOCK) ||
                           (fsm_state == SQUEEZE);

mastercube_round_fwd_phase u_round_fwd_phase (
    .state_in (state),
    .round_idx(round_cnt),
    .phase    (round_phase),
    .state_out(fwd_round_next)
);

mastercube_round_inv_phase u_round_inv_phase (
    .state_in (state_copy),
    .round_idx(round_cnt),
    .phase    (round_phase),
    .state_out(inv_round_next)
);

function [63:0] state_word64;
    input [`STATE_BITS-1:0] state_i;
    input [4:0]             word_i;
    begin
        case (word_i)
            5'd0  : state_word64 = state_i[64*0  +: 64];
            5'd1  : state_word64 = state_i[64*1  +: 64];
            5'd2  : state_word64 = state_i[64*2  +: 64];
            5'd3  : state_word64 = state_i[64*3  +: 64];
            5'd4  : state_word64 = state_i[64*4  +: 64];
            5'd5  : state_word64 = state_i[64*5  +: 64];
            5'd6  : state_word64 = state_i[64*6  +: 64];
            5'd7  : state_word64 = state_i[64*7  +: 64];
            5'd8  : state_word64 = state_i[64*8  +: 64];
            5'd9  : state_word64 = state_i[64*9  +: 64];
            5'd10 : state_word64 = state_i[64*10 +: 64];
            5'd11 : state_word64 = state_i[64*11 +: 64];
            5'd12 : state_word64 = state_i[64*12 +: 64];
            5'd13 : state_word64 = state_i[64*13 +: 64];
            5'd14 : state_word64 = state_i[64*14 +: 64];
            5'd15 : state_word64 = state_i[64*15 +: 64];
            5'd16 : state_word64 = state_i[64*16 +: 64];
            5'd17 : state_word64 = state_i[64*17 +: 64];
            5'd18 : state_word64 = state_i[64*18 +: 64];
            5'd19 : state_word64 = state_i[64*19 +: 64];
            5'd20 : state_word64 = state_i[64*20 +: 64];
            5'd21 : state_word64 = state_i[64*21 +: 64];
            5'd22 : state_word64 = state_i[64*22 +: 64];
            default : state_word64 = state_i[64*23 +: 64];
        endcase
    end
endfunction

function [`STATE_BITS-1:0] write_word64;
    input [`STATE_BITS-1:0] state_i;
    input [4:0]             word_i;
    input [63:0]            data_i;
    reg [`STATE_BITS-1:0] result;
    begin
        result = state_i;
        case (word_i)
            5'd0  : result[64*0  +: 64] = data_i;
            5'd1  : result[64*1  +: 64] = data_i;
            5'd2  : result[64*2  +: 64] = data_i;
            5'd3  : result[64*3  +: 64] = data_i;
            5'd4  : result[64*4  +: 64] = data_i;
            5'd5  : result[64*5  +: 64] = data_i;
            5'd6  : result[64*6  +: 64] = data_i;
            5'd7  : result[64*7  +: 64] = data_i;
            5'd8  : result[64*8  +: 64] = data_i;
            5'd9  : result[64*9  +: 64] = data_i;
            5'd10 : result[64*10 +: 64] = data_i;
            5'd11 : result[64*11 +: 64] = data_i;
            5'd12 : result[64*12 +: 64] = data_i;
            5'd13 : result[64*13 +: 64] = data_i;
            5'd14 : result[64*14 +: 64] = data_i;
            5'd15 : result[64*15 +: 64] = data_i;
            5'd16 : result[64*16 +: 64] = data_i;
            5'd17 : result[64*17 +: 64] = data_i;
            5'd18 : result[64*18 +: 64] = data_i;
            5'd19 : result[64*19 +: 64] = data_i;
            5'd20 : result[64*20 +: 64] = data_i;
            5'd21 : result[64*21 +: 64] = data_i;
            5'd22 : result[64*22 +: 64] = data_i;
            default : result[64*23 +: 64] = data_i;
        endcase
        write_word64 = result;
    end
endfunction

function [`STATE_BITS-1:0] absorb_next_state;
    input [`STATE_BITS-1:0] cur_state_i;
    input [4:0]             buffer_cnt_i;
    input [63:0]            din_i;
    input                   din_valid_i;
    input                   do_pad_i;
    input [4:0]             pad_word_i;
    input [5:0]             pad_bit_i;
    input [4:0]             rate_last_word_i;
    reg [`STATE_BITS-1:0] result;
    reg [63:0]             pad_mask;
    reg [63:0]             din_mask;
    reg [63:0]             pad_update_mask;
    begin
        result = cur_state_i;
        pad_mask = 64'd0;
        pad_mask[pad_bit_i] = 1'b1;

        if (din_valid_i) begin
            din_mask = din_i;
            if (do_pad_i && (pad_word_i == buffer_cnt_i))
                din_mask = din_mask ^ pad_mask;
            if (do_pad_i && (rate_last_word_i == buffer_cnt_i))
                din_mask = din_mask ^ 64'h0100_0000_0000_0000;

            result = write_word64(result, buffer_cnt_i,
                                  state_word64(cur_state_i, buffer_cnt_i) ^ din_mask);
        end

        if (do_pad_i && (!din_valid_i || (pad_word_i != buffer_cnt_i))) begin
            pad_update_mask = pad_mask;
            if (rate_last_word_i == pad_word_i)
                pad_update_mask = pad_update_mask ^ 64'h0100_0000_0000_0000;

            result = write_word64(result, pad_word_i,
                                  state_word64(cur_state_i, pad_word_i) ^ pad_update_mask);
        end

        if (do_pad_i && (rate_last_word_i != pad_word_i) &&
            (!din_valid_i || (rate_last_word_i != buffer_cnt_i))) begin
            result = write_word64(result, rate_last_word_i,
                                  state_word64(cur_state_i, rate_last_word_i) ^
                                  64'h0100_0000_0000_0000);
        end

        absorb_next_state = result;
    end
endfunction

function [`STATE_BITS-1:0] pad_block_next_state;
    input [`STATE_BITS-1:0] cur_state_i;
    input [4:0]             rate_last_word_i;
    reg [`STATE_BITS-1:0] result;
    begin
        result = cur_state_i;
        if (rate_last_word_i == 5'd0) begin
            result[63:0] = cur_state_i[63:0] ^
                           64'h0100_0000_0000_0000 ^
                           64'h0000_0000_0000_0080;
        end
        else begin
            result[7] = cur_state_i[7] ^ 1'b1;
            result = write_word64(result, rate_last_word_i,
                                  state_word64(cur_state_i, rate_last_word_i) ^
                                  64'h0100_0000_0000_0000);
        end
        pad_block_next_state = result;
    end
endfunction

always @(posedge clk or negedge rst_n) begin : p_mastercube_seq
    reg       msg_word_boundary_v;
    reg       pad_in_next_block_v;
    reg [4:0] pad_word_v;
    reg [5:0] pad_bit_idx_v;
    reg       absorb_do_pad_v;
    reg [`STATE_BITS-1:0] absorb_state_v;
    reg [`STATE_BITS-1:0] pad_block_state_v;

    if (!rst_n) begin
        fsm_state    <= IDLE;
        digest_sel_q <= `DIGEST_768;
        state        <= {`STATE_BITS{1'b0}};
        state_copy   <= {`STATE_BITS{1'b0}};
        round_cnt    <= 4'd0;
        round_phase  <= 1'b0;
        buffer_cnt   <= 5'd0;
        dout_cnt     <= 5'd0;
        ready        <= 1'b0;
        dout         <= 64'd0;
        dout_valid   <= 1'b0;
    end
    else begin
        dout_valid <= 1'b0;

        case (fsm_state)
            IDLE: begin
                ready <= 1'b0;

                if (start) begin
                    digest_sel_q <= `DIGEST_768;
                    state        <= {`STATE_BITS{1'b0}};
                    state_copy   <= {`STATE_BITS{1'b0}};
                    round_cnt    <= 4'd0;
                    round_phase  <= 1'b0;
                    buffer_cnt   <= 5'd0;
                    dout_cnt     <= 5'd0;
                    dout         <= 64'd0;
                    fsm_state    <= ABSORB;
                end
            end

            ABSORB: begin
                ready <= 1'b0;

                msg_word_boundary_v = (msg_bit_len[5:0] == 6'd0);
                pad_in_next_block_v = din_valid && (msg_bit_len != 64'd0) &&
                                      msg_word_boundary_v && block_full_word_w;
                pad_word_v          = (!din_valid)           ? 5'd0 :
                                      msg_word_boundary_v     ? (buffer_cnt + 5'd1) :
                                                                buffer_cnt;
                pad_bit_idx_v       = {msg_bit_len[5:3], 3'b000} +
                                      {3'b000, (3'd7 - msg_bit_len[2:0])};
                absorb_do_pad_v     = last_block && (!din_valid || !pad_in_next_block_v);
                absorb_state_v      = absorb_next_state(state, buffer_cnt, din, din_valid,
                                                        absorb_do_pad_v, pad_word_v,
                                                        pad_bit_idx_v, rate_last_word_w);

                if (last_block && !din_valid && (buffer_cnt == 5'd0)) begin
                    state          <= absorb_state_v;
                    state_copy     <= absorb_state_v;
                    round_cnt      <= 4'd0;
                    round_phase    <= 1'b0;
                    buffer_cnt     <= 5'd0;
                    dout_cnt       <= 5'd0;
                    fsm_state      <= PERM_SQUEEZE;
                end
                else if (din_valid) begin
                    state <= absorb_state_v;

                    if (last_block) begin
                        state_copy     <= absorb_state_v;
                        round_cnt      <= 4'd0;
                        round_phase    <= 1'b0;
                        buffer_cnt     <= 5'd0;
                        dout_cnt       <= 5'd0;
                        fsm_state      <= pad_in_next_block_v ? PERM_PAD : PERM_SQUEEZE;
                    end
                    else if (block_full_word_w) begin
                        state_copy     <= absorb_state_v;
                        round_cnt      <= 4'd0;
                        round_phase    <= 1'b0;
                        buffer_cnt     <= 5'd0;
                        fsm_state      <= PERM_ABSORB;
                    end
                    else begin
                        buffer_cnt <= buffer_cnt + 5'd1;
                    end
                end
            end

            PERM_ABSORB,
            PERM_PAD,
            PERM_SQUEEZE: begin
                ready <= 1'b0;

                if (round_cnt < `N_ROUNDS_HALF) begin
                    if (!round_phase) begin
                        state       <= fwd_round_next;
                        state_copy  <= inv_round_next;
                        round_phase <= 1'b1;
                    end
                    else begin
                        state       <= fwd_round_next;
                        state_copy  <= inv_round_next;
                        round_cnt   <= round_cnt + 4'd1;
                        round_phase <= 1'b0;
                    end
                end
                else begin
                    state       <= state ^ state_copy;
                    round_cnt   <= 4'd0;
                    round_phase <= 1'b0;

                    case (fsm_state)
                        PERM_ABSORB: begin
                            buffer_cnt <= 5'd0;
                            fsm_state  <= ABSORB;
                        end

                        PERM_PAD: begin
                            buffer_cnt <= 5'd0;
                            fsm_state  <= APPLY_PAD_BLOCK;
                        end

                        default: begin
                            fsm_state <= SQUEEZE;
                        end
                    endcase
                end
            end

            APPLY_PAD_BLOCK: begin
                pad_block_state_v = pad_block_next_state(state, rate_last_word_w);

                ready          <= 1'b0;
                state          <= pad_block_state_v;
                state_copy     <= pad_block_state_v;
                round_cnt      <= 4'd0;
                round_phase    <= 1'b0;
                dout_cnt       <= 5'd0;
                fsm_state      <= PERM_SQUEEZE;
            end

            SQUEEZE: begin
                ready <= 1'b0;

                if (dout_cnt < digest_words_w) begin
                    dout       <= state[(dout_word_w * 64) +: 64];
                    dout_valid <= 1'b1;
                    dout_cnt   <= dout_cnt + 5'd1;

                    if (squeeze_rate_last_w && squeeze_more_w) begin
                        state_copy <= state;
                        round_cnt  <= 4'd0;
                        round_phase <= 1'b0;
                        fsm_state  <= PERM_SQUEEZE;
                    end
                end
                else begin
                    fsm_state <= DONE;
                end
            end

            DONE: begin
                ready <= 1'b1;

                if (start) begin
                    digest_sel_q <= `DIGEST_768;
                    state        <= {`STATE_BITS{1'b0}};
                    state_copy   <= {`STATE_BITS{1'b0}};
                    round_cnt    <= 4'd0;
                    round_phase  <= 1'b0;
                    buffer_cnt   <= 5'd0;
                    dout_cnt     <= 5'd0;
                    ready        <= 1'b0;
                    dout         <= 64'd0;
                    fsm_state    <= ABSORB;
                end
            end

            default: begin
                fsm_state <= IDLE;
            end
        endcase
    end
end

endmodule


