// MasterCube Hash Algorithm - Forward Round Combinational Logic
// Verilog-2001 implementation.

`timescale 1 ns / 1 ps
`include "mastercube_globals.v"

module mastercube_round_fwd (
    input  wire [`STATE_BITS-1:0] state_in,
    input  wire [3:0]             round_idx,
    output wire [`STATE_BITS-1:0] state_out
);

wire [`STATE_BITS-1:0] fwd_out;
wire [`STATE_BITS-1:0] fwd_sr1;
wire [`STATE_BITS-1:0] fwd_sr2;
// ----------------------------------------------------------------
// FORWARD MODE
// ----------------------------------------------------------------
wire [`STATE_BITS-1:0] fwd_cm1;
wire [`STATE_BITS-1:0] fwd_ar1;
wire [`STATE_BITS-1:0] fwd_ar2;
wire [`STATE_BITS-1:0] fwd_ar3;
wire [`STATE_BITS-1:0] fwd_ar4;
wire [`STATE_BITS-1:0] fwd_ar5;
wire [`STATE_BITS-1:0] fwd_ar6;
wire [`STATE_BITS-1:0] fwd_cm2;
wire [`STATE_BITS-1:0] fwd_mc;
wire [`STATE_BITS-1:0] fwd_shift;
wire [`STATE_BITS-1:0] fwd_mr;
wire [`STATE_BITS-1:0] fwd_ac;
wire [127:0]           fwd_rc;
wire [127:0]           fwd_ri;

function [127:0] shiftrow_fwd_row;
    input [127:0] row_i;
    input [3:0]   row_idx_i;
    begin
        case (row_idx_i)
            4'd1  : shiftrow_fwd_row = {row_i[15:0],   row_i[127:16]};
            4'd2  : shiftrow_fwd_row = {row_i[31:0],   row_i[127:32]};
            4'd3  : shiftrow_fwd_row = {row_i[47:0],   row_i[127:48]};
            4'd4  : shiftrow_fwd_row = {row_i[63:0],   row_i[127:64]};
            4'd5  : shiftrow_fwd_row = {row_i[79:0],   row_i[127:80]};
            4'd7  : shiftrow_fwd_row = {row_i[111:0],  row_i[127:112]};
            4'd8  : shiftrow_fwd_row = {row_i[95:0],   row_i[127:96]};
            4'd9  : shiftrow_fwd_row = {row_i[79:0],   row_i[127:80]};
            4'd10 : shiftrow_fwd_row = {row_i[63:0],   row_i[127:64]};
            4'd11 : shiftrow_fwd_row = {row_i[47:0],   row_i[127:48]};
            default : shiftrow_fwd_row = row_i;
        endcase
    end
endfunction

mastercube_crossmix u_fwd_cross_1 (
    .state_i(state_in),
    .state_o(fwd_cm1)
);

assign fwd_sr1[128*0  +: 128] = fwd_cm1[128*0  +: 128];
assign fwd_sr1[128*1  +: 128] = fwd_cm1[128*1  +: 128];
assign fwd_sr1[128*2  +: 128] = fwd_cm1[128*2  +: 128];
assign fwd_sr1[128*3  +: 128] = fwd_cm1[128*3  +: 128];
assign fwd_sr1[128*4  +: 128] = fwd_cm1[128*4  +: 128];
assign fwd_sr1[128*5  +: 128] = fwd_cm1[128*5  +: 128];
assign fwd_sr1[128*6  +: 128] = fwd_cm1[128*7  +: 128];
assign fwd_sr1[128*7  +: 128] = fwd_cm1[128*6  +: 128];
assign fwd_sr1[128*8  +: 128] = fwd_cm1[128*9  +: 128];
assign fwd_sr1[128*9  +: 128] = fwd_cm1[128*8  +: 128];
assign fwd_sr1[128*10 +: 128] = fwd_cm1[128*11 +: 128];
assign fwd_sr1[128*11 +: 128] = fwd_cm1[128*10 +: 128];

genvar fwd_g1;
generate
    for (fwd_g1 = 0; fwd_g1 < 6; fwd_g1 = fwd_g1 + 1) begin : gen_fwd_ar1
        assign fwd_ar1[128*fwd_g1 +: 128] = fwd_sr1[128*fwd_g1 +: 128];
        mastercube_mandrx u_mandrx (
            .src_row_i(fwd_sr1[128*fwd_g1       +: 128]),
            .dst_row_i(fwd_sr1[128*(fwd_g1 + 6) +: 128]),
            .alpha_i  (4'd0),
            .beta_i   (4'd1),
            .gamma_i  (4'd8),
            .row_o    (fwd_ar1[128*(fwd_g1 + 6) +: 128])
        );
    end
endgenerate

genvar fwd_g2;
generate
    for (fwd_g2 = 0; fwd_g2 < 6; fwd_g2 = fwd_g2 + 1) begin : gen_fwd_ar2
        mastercube_mandrx u_mandrx (
            .src_row_i(fwd_ar1[128*(fwd_g2 + 6) +: 128]),
            .dst_row_i(fwd_ar1[128*fwd_g2       +: 128]),
            .alpha_i  (4'd14),
            .beta_i   (4'd5),
            .gamma_i  (4'd0),
            .row_o    (fwd_ar2[128*fwd_g2 +: 128])
        );
        assign fwd_ar2[128*(fwd_g2 + 6) +: 128] = fwd_ar1[128*(fwd_g2 + 6) +: 128];
    end
endgenerate

genvar fwd_g3;
generate
    for (fwd_g3 = 0; fwd_g3 < 6; fwd_g3 = fwd_g3 + 1) begin : gen_fwd_ar3
        assign fwd_ar3[128*fwd_g3 +: 128] = fwd_ar2[128*fwd_g3 +: 128];
        mastercube_mandrx u_mandrx (
            .src_row_i(fwd_ar2[128*fwd_g3       +: 128]),
            .dst_row_i(fwd_ar2[128*(fwd_g3 + 6) +: 128]),
            .alpha_i  (4'd9),
            .beta_i   (4'd12),
            .gamma_i  (4'd8),
            .row_o    (fwd_ar3[128*(fwd_g3 + 6) +: 128])
        );
    end
endgenerate

genvar fwd_g4;
generate
    for (fwd_g4 = 0; fwd_g4 < 6; fwd_g4 = fwd_g4 + 1) begin : gen_fwd_ar4
        mastercube_mandrx u_mandrx (
            .src_row_i(fwd_ar3[128*(fwd_g4 + 6) +: 128]),
            .dst_row_i(fwd_ar3[128*fwd_g4       +: 128]),
            .alpha_i  (4'd14),
            .beta_i   (4'd5),
            .gamma_i  (4'd0),
            .row_o    (fwd_ar4[128*fwd_g4 +: 128])
        );
        assign fwd_ar4[128*(fwd_g4 + 6) +: 128] = fwd_ar3[128*(fwd_g4 + 6) +: 128];
    end
endgenerate

genvar fwd_g5;
generate
    for (fwd_g5 = 0; fwd_g5 < 6; fwd_g5 = fwd_g5 + 1) begin : gen_fwd_ar5
        assign fwd_ar5[128*fwd_g5 +: 128] = fwd_ar4[128*fwd_g5 +: 128];
        mastercube_mandrx u_mandrx (
            .src_row_i(fwd_ar4[128*fwd_g5       +: 128]),
            .dst_row_i(fwd_ar4[128*(fwd_g5 + 6) +: 128]),
            .alpha_i  (4'd0),
            .beta_i   (4'd1),
            .gamma_i  (4'd8),
            .row_o    (fwd_ar5[128*(fwd_g5 + 6) +: 128])
        );
    end
endgenerate

genvar fwd_g6;
generate
    for (fwd_g6 = 0; fwd_g6 < 6; fwd_g6 = fwd_g6 + 1) begin : gen_fwd_ar6
        mastercube_mandrx u_mandrx (
            .src_row_i(fwd_ar5[128*(fwd_g6 + 6) +: 128]),
            .dst_row_i(fwd_ar5[128*fwd_g6       +: 128]),
            .alpha_i  (4'd8),
            .beta_i   (4'd9),
            .gamma_i  (4'd0),
            .row_o    (fwd_ar6[128*fwd_g6 +: 128])
        );
        assign fwd_ar6[128*(fwd_g6 + 6) +: 128] = fwd_ar5[128*(fwd_g6 + 6) +: 128];
    end
endgenerate

mastercube_crossmix u_fwd_cross_2 (
    .state_i(fwd_ar6),
    .state_o(fwd_cm2)
);

assign fwd_sr2[128*0  +: 128] = fwd_cm2[128*0  +: 128];
assign fwd_sr2[128*1  +: 128] = fwd_cm2[128*1  +: 128];
assign fwd_sr2[128*2  +: 128] = fwd_cm2[128*2  +: 128];
assign fwd_sr2[128*3  +: 128] = fwd_cm2[128*3  +: 128];
assign fwd_sr2[128*4  +: 128] = fwd_cm2[128*4  +: 128];
assign fwd_sr2[128*5  +: 128] = fwd_cm2[128*5  +: 128];
assign fwd_sr2[128*6  +: 128] = fwd_cm2[128*7  +: 128];
assign fwd_sr2[128*7  +: 128] = fwd_cm2[128*6  +: 128];
assign fwd_sr2[128*8  +: 128] = fwd_cm2[128*9  +: 128];
assign fwd_sr2[128*9  +: 128] = fwd_cm2[128*8  +: 128];
assign fwd_sr2[128*10 +: 128] = fwd_cm2[128*11 +: 128];
assign fwd_sr2[128*11 +: 128] = fwd_cm2[128*10 +: 128];

mastercube_mixcolumn u_fwd_mixcolumn (
    .state_i(fwd_sr2),
    .state_o(fwd_mc)
);

assign fwd_shift[128*0  +: 128] = shiftrow_fwd_row(fwd_mc[128*0  +: 128], 4'd0);
assign fwd_shift[128*1  +: 128] = shiftrow_fwd_row(fwd_mc[128*1  +: 128], 4'd1);
assign fwd_shift[128*2  +: 128] = shiftrow_fwd_row(fwd_mc[128*2  +: 128], 4'd2);
assign fwd_shift[128*3  +: 128] = shiftrow_fwd_row(fwd_mc[128*3  +: 128], 4'd3);
assign fwd_shift[128*4  +: 128] = shiftrow_fwd_row(fwd_mc[128*4  +: 128], 4'd4);
assign fwd_shift[128*5  +: 128] = shiftrow_fwd_row(fwd_mc[128*5  +: 128], 4'd5);
assign fwd_shift[128*6  +: 128] = shiftrow_fwd_row(fwd_mc[128*6  +: 128], 4'd6);
assign fwd_shift[128*7  +: 128] = shiftrow_fwd_row(fwd_mc[128*7  +: 128], 4'd7);
assign fwd_shift[128*8  +: 128] = shiftrow_fwd_row(fwd_mc[128*8  +: 128], 4'd8);
assign fwd_shift[128*9  +: 128] = shiftrow_fwd_row(fwd_mc[128*9  +: 128], 4'd9);
assign fwd_shift[128*10 +: 128] = shiftrow_fwd_row(fwd_mc[128*10 +: 128], 4'd10);
assign fwd_shift[128*11 +: 128] = shiftrow_fwd_row(fwd_mc[128*11 +: 128], 4'd11);

mastercube_mixrow u_fwd_mixrow (
    .state_i(fwd_shift),
    .state_o(fwd_mr)
);

assign fwd_rc = {`RC7, `RC6, `RC5, `RC4, `RC3, `RC2, `RC1, `RC0};
assign fwd_ri = {8{12'b0, round_idx}};
assign fwd_ac = fwd_mr;
assign fwd_out[128*0  +: 128] = fwd_mr[128*0 +: 128] ^ fwd_rc ^ fwd_ri;
assign fwd_out[128*1  +: 128] = fwd_ac[128*1  +: 128];
assign fwd_out[128*2  +: 128] = fwd_ac[128*2  +: 128];
assign fwd_out[128*3  +: 128] = fwd_ac[128*3  +: 128];
assign fwd_out[128*4  +: 128] = fwd_ac[128*4  +: 128];
assign fwd_out[128*5  +: 128] = fwd_ac[128*5  +: 128];
assign fwd_out[128*6  +: 128] = fwd_ac[128*6  +: 128];
assign fwd_out[128*7  +: 128] = fwd_ac[128*7  +: 128];
assign fwd_out[128*8  +: 128] = fwd_ac[128*8  +: 128];
assign fwd_out[128*9  +: 128] = fwd_ac[128*9  +: 128];
assign fwd_out[128*10 +: 128] = fwd_ac[128*10 +: 128];
assign fwd_out[128*11 +: 128] = fwd_ac[128*11 +: 128];


assign state_out = fwd_out;

endmodule

module mastercube_round_fwd_stage0 (
    input  wire [`STATE_BITS-1:0] state_in,
    output wire [`STATE_BITS-1:0] state_mid
);

wire [`STATE_BITS-1:0] fwd_cm1;
wire [`STATE_BITS-1:0] fwd_sr1;
wire [`STATE_BITS-1:0] fwd_ar1;
wire [`STATE_BITS-1:0] fwd_ar2;
wire [`STATE_BITS-1:0] fwd_ar3;

mastercube_crossmix u_fwd_s0_cross_1 (
    .state_i(state_in),
    .state_o(fwd_cm1)
);

assign fwd_sr1[128*0  +: 128] = fwd_cm1[128*0  +: 128];
assign fwd_sr1[128*1  +: 128] = fwd_cm1[128*1  +: 128];
assign fwd_sr1[128*2  +: 128] = fwd_cm1[128*2  +: 128];
assign fwd_sr1[128*3  +: 128] = fwd_cm1[128*3  +: 128];
assign fwd_sr1[128*4  +: 128] = fwd_cm1[128*4  +: 128];
assign fwd_sr1[128*5  +: 128] = fwd_cm1[128*5  +: 128];
assign fwd_sr1[128*6  +: 128] = fwd_cm1[128*7  +: 128];
assign fwd_sr1[128*7  +: 128] = fwd_cm1[128*6  +: 128];
assign fwd_sr1[128*8  +: 128] = fwd_cm1[128*9  +: 128];
assign fwd_sr1[128*9  +: 128] = fwd_cm1[128*8  +: 128];
assign fwd_sr1[128*10 +: 128] = fwd_cm1[128*11 +: 128];
assign fwd_sr1[128*11 +: 128] = fwd_cm1[128*10 +: 128];

genvar fwd_s0_g1;
generate
    for (fwd_s0_g1 = 0; fwd_s0_g1 < 6; fwd_s0_g1 = fwd_s0_g1 + 1) begin : gen_fwd_s0_ar1
        assign fwd_ar1[128*fwd_s0_g1 +: 128] = fwd_sr1[128*fwd_s0_g1 +: 128];
        mastercube_mandrx_const #(
            .ALPHA(4'd0),
            .BETA (4'd1),
            .GAMMA(4'd8)
        ) u_mandrx (
            .src_row_i(fwd_sr1[128*fwd_s0_g1       +: 128]),
            .dst_row_i(fwd_sr1[128*(fwd_s0_g1 + 6) +: 128]),
            .row_o    (fwd_ar1[128*(fwd_s0_g1 + 6) +: 128])
        );
    end
endgenerate

genvar fwd_s0_g2;
generate
    for (fwd_s0_g2 = 0; fwd_s0_g2 < 6; fwd_s0_g2 = fwd_s0_g2 + 1) begin : gen_fwd_s0_ar2
        mastercube_mandrx_const #(
            .ALPHA(4'd14),
            .BETA (4'd5),
            .GAMMA(4'd0)
        ) u_mandrx (
            .src_row_i(fwd_ar1[128*(fwd_s0_g2 + 6) +: 128]),
            .dst_row_i(fwd_ar1[128*fwd_s0_g2       +: 128]),
            .row_o    (fwd_ar2[128*fwd_s0_g2 +: 128])
        );
        assign fwd_ar2[128*(fwd_s0_g2 + 6) +: 128] = fwd_ar1[128*(fwd_s0_g2 + 6) +: 128];
    end
endgenerate

genvar fwd_s0_g3;
generate
    for (fwd_s0_g3 = 0; fwd_s0_g3 < 6; fwd_s0_g3 = fwd_s0_g3 + 1) begin : gen_fwd_s0_ar3
        assign fwd_ar3[128*fwd_s0_g3 +: 128] = fwd_ar2[128*fwd_s0_g3 +: 128];
        mastercube_mandrx_const #(
            .ALPHA(4'd9),
            .BETA (4'd12),
            .GAMMA(4'd8)
        ) u_mandrx (
            .src_row_i(fwd_ar2[128*fwd_s0_g3       +: 128]),
            .dst_row_i(fwd_ar2[128*(fwd_s0_g3 + 6) +: 128]),
            .row_o    (fwd_ar3[128*(fwd_s0_g3 + 6) +: 128])
        );
    end
endgenerate

assign state_mid = fwd_ar3;

endmodule

module mastercube_round_fwd_stage1 (
    input  wire [`STATE_BITS-1:0] state_mid,
    input  wire [3:0]             round_idx,
    output wire [`STATE_BITS-1:0] state_out
);

wire [`STATE_BITS-1:0] fwd_ar4;
wire [`STATE_BITS-1:0] fwd_ar5;
wire [`STATE_BITS-1:0] fwd_ar6;
wire [`STATE_BITS-1:0] fwd_cm2;
wire [`STATE_BITS-1:0] fwd_sr2;
wire [`STATE_BITS-1:0] fwd_mc;
wire [`STATE_BITS-1:0] fwd_shift;
wire [`STATE_BITS-1:0] fwd_mr;
wire [`STATE_BITS-1:0] fwd_out;
wire [127:0]           fwd_rc;
wire [127:0]           fwd_ri;

function [127:0] shiftrow_fwd_row_s1;
    input [127:0] row_i;
    input [3:0]   row_idx_i;
    begin
        case (row_idx_i)
            4'd1  : shiftrow_fwd_row_s1 = {row_i[15:0],   row_i[127:16]};
            4'd2  : shiftrow_fwd_row_s1 = {row_i[31:0],   row_i[127:32]};
            4'd3  : shiftrow_fwd_row_s1 = {row_i[47:0],   row_i[127:48]};
            4'd4  : shiftrow_fwd_row_s1 = {row_i[63:0],   row_i[127:64]};
            4'd5  : shiftrow_fwd_row_s1 = {row_i[79:0],   row_i[127:80]};
            4'd7  : shiftrow_fwd_row_s1 = {row_i[111:0],  row_i[127:112]};
            4'd8  : shiftrow_fwd_row_s1 = {row_i[95:0],   row_i[127:96]};
            4'd9  : shiftrow_fwd_row_s1 = {row_i[79:0],   row_i[127:80]};
            4'd10 : shiftrow_fwd_row_s1 = {row_i[63:0],   row_i[127:64]};
            4'd11 : shiftrow_fwd_row_s1 = {row_i[47:0],   row_i[127:48]};
            default : shiftrow_fwd_row_s1 = row_i;
        endcase
    end
endfunction

genvar fwd_s1_g4;
generate
    for (fwd_s1_g4 = 0; fwd_s1_g4 < 6; fwd_s1_g4 = fwd_s1_g4 + 1) begin : gen_fwd_s1_ar4
        mastercube_mandrx_const #(
            .ALPHA(4'd14),
            .BETA (4'd5),
            .GAMMA(4'd0)
        ) u_mandrx (
            .src_row_i(state_mid[128*(fwd_s1_g4 + 6) +: 128]),
            .dst_row_i(state_mid[128*fwd_s1_g4       +: 128]),
            .row_o    (fwd_ar4[128*fwd_s1_g4 +: 128])
        );
        assign fwd_ar4[128*(fwd_s1_g4 + 6) +: 128] = state_mid[128*(fwd_s1_g4 + 6) +: 128];
    end
endgenerate

genvar fwd_s1_g5;
generate
    for (fwd_s1_g5 = 0; fwd_s1_g5 < 6; fwd_s1_g5 = fwd_s1_g5 + 1) begin : gen_fwd_s1_ar5
        assign fwd_ar5[128*fwd_s1_g5 +: 128] = fwd_ar4[128*fwd_s1_g5 +: 128];
        mastercube_mandrx_const #(
            .ALPHA(4'd0),
            .BETA (4'd1),
            .GAMMA(4'd8)
        ) u_mandrx (
            .src_row_i(fwd_ar4[128*fwd_s1_g5       +: 128]),
            .dst_row_i(fwd_ar4[128*(fwd_s1_g5 + 6) +: 128]),
            .row_o    (fwd_ar5[128*(fwd_s1_g5 + 6) +: 128])
        );
    end
endgenerate

genvar fwd_s1_g6;
generate
    for (fwd_s1_g6 = 0; fwd_s1_g6 < 6; fwd_s1_g6 = fwd_s1_g6 + 1) begin : gen_fwd_s1_ar6
        mastercube_mandrx_const #(
            .ALPHA(4'd8),
            .BETA (4'd9),
            .GAMMA(4'd0)
        ) u_mandrx (
            .src_row_i(fwd_ar5[128*(fwd_s1_g6 + 6) +: 128]),
            .dst_row_i(fwd_ar5[128*fwd_s1_g6       +: 128]),
            .row_o    (fwd_ar6[128*fwd_s1_g6 +: 128])
        );
        assign fwd_ar6[128*(fwd_s1_g6 + 6) +: 128] = fwd_ar5[128*(fwd_s1_g6 + 6) +: 128];
    end
endgenerate

mastercube_crossmix u_fwd_s1_cross_2 (
    .state_i(fwd_ar6),
    .state_o(fwd_cm2)
);

assign fwd_sr2[128*0  +: 128] = fwd_cm2[128*0  +: 128];
assign fwd_sr2[128*1  +: 128] = fwd_cm2[128*1  +: 128];
assign fwd_sr2[128*2  +: 128] = fwd_cm2[128*2  +: 128];
assign fwd_sr2[128*3  +: 128] = fwd_cm2[128*3  +: 128];
assign fwd_sr2[128*4  +: 128] = fwd_cm2[128*4  +: 128];
assign fwd_sr2[128*5  +: 128] = fwd_cm2[128*5  +: 128];
assign fwd_sr2[128*6  +: 128] = fwd_cm2[128*7  +: 128];
assign fwd_sr2[128*7  +: 128] = fwd_cm2[128*6  +: 128];
assign fwd_sr2[128*8  +: 128] = fwd_cm2[128*9  +: 128];
assign fwd_sr2[128*9  +: 128] = fwd_cm2[128*8  +: 128];
assign fwd_sr2[128*10 +: 128] = fwd_cm2[128*11 +: 128];
assign fwd_sr2[128*11 +: 128] = fwd_cm2[128*10 +: 128];

mastercube_mixcolumn u_fwd_s1_mixcolumn (
    .state_i(fwd_sr2),
    .state_o(fwd_mc)
);

assign fwd_shift[128*0  +: 128] = shiftrow_fwd_row_s1(fwd_mc[128*0  +: 128], 4'd0);
assign fwd_shift[128*1  +: 128] = shiftrow_fwd_row_s1(fwd_mc[128*1  +: 128], 4'd1);
assign fwd_shift[128*2  +: 128] = shiftrow_fwd_row_s1(fwd_mc[128*2  +: 128], 4'd2);
assign fwd_shift[128*3  +: 128] = shiftrow_fwd_row_s1(fwd_mc[128*3  +: 128], 4'd3);
assign fwd_shift[128*4  +: 128] = shiftrow_fwd_row_s1(fwd_mc[128*4  +: 128], 4'd4);
assign fwd_shift[128*5  +: 128] = shiftrow_fwd_row_s1(fwd_mc[128*5  +: 128], 4'd5);
assign fwd_shift[128*6  +: 128] = shiftrow_fwd_row_s1(fwd_mc[128*6  +: 128], 4'd6);
assign fwd_shift[128*7  +: 128] = shiftrow_fwd_row_s1(fwd_mc[128*7  +: 128], 4'd7);
assign fwd_shift[128*8  +: 128] = shiftrow_fwd_row_s1(fwd_mc[128*8  +: 128], 4'd8);
assign fwd_shift[128*9  +: 128] = shiftrow_fwd_row_s1(fwd_mc[128*9  +: 128], 4'd9);
assign fwd_shift[128*10 +: 128] = shiftrow_fwd_row_s1(fwd_mc[128*10 +: 128], 4'd10);
assign fwd_shift[128*11 +: 128] = shiftrow_fwd_row_s1(fwd_mc[128*11 +: 128], 4'd11);

mastercube_mixrow u_fwd_s1_mixrow (
    .state_i(fwd_shift),
    .state_o(fwd_mr)
);

assign fwd_rc = {`RC7, `RC6, `RC5, `RC4, `RC3, `RC2, `RC1, `RC0};
assign fwd_ri = {8{12'b0, round_idx}};
assign fwd_out[128*0  +: 128] = fwd_mr[128*0 +: 128] ^ fwd_rc ^ fwd_ri;
assign fwd_out[128*1  +: 128] = fwd_mr[128*1  +: 128];
assign fwd_out[128*2  +: 128] = fwd_mr[128*2  +: 128];
assign fwd_out[128*3  +: 128] = fwd_mr[128*3  +: 128];
assign fwd_out[128*4  +: 128] = fwd_mr[128*4  +: 128];
assign fwd_out[128*5  +: 128] = fwd_mr[128*5  +: 128];
assign fwd_out[128*6  +: 128] = fwd_mr[128*6  +: 128];
assign fwd_out[128*7  +: 128] = fwd_mr[128*7  +: 128];
assign fwd_out[128*8  +: 128] = fwd_mr[128*8  +: 128];
assign fwd_out[128*9  +: 128] = fwd_mr[128*9  +: 128];
assign fwd_out[128*10 +: 128] = fwd_mr[128*10 +: 128];
assign fwd_out[128*11 +: 128] = fwd_mr[128*11 +: 128];

assign state_out = fwd_out;

endmodule
