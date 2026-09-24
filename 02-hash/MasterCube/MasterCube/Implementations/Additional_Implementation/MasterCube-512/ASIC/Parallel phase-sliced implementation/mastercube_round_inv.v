// MasterCube Hash Algorithm - Inverse Round Combinational Logic
// Verilog-2001 implementation.

`timescale 1 ns / 1 ps
`include "mastercube_globals.v"

module mastercube_round_inv (
    input  wire [`STATE_BITS-1:0] state_in,
    input  wire [3:0]             round_idx,
    output wire [`STATE_BITS-1:0] state_out
);

wire [`STATE_BITS-1:0] inv_out;
wire [`STATE_BITS-1:0] inv_sr1;
// ----------------------------------------------------------------
// INVERSE MODE
// ----------------------------------------------------------------
wire [`STATE_BITS-1:0] inv_ac;
wire [`STATE_BITS-1:0] inv_mr;
wire [`STATE_BITS-1:0] inv_cm1;
wire [`STATE_BITS-1:0] inv_ar1;
wire [`STATE_BITS-1:0] inv_ar2;
wire [`STATE_BITS-1:0] inv_ar3;
wire [`STATE_BITS-1:0] inv_ar4;
wire [`STATE_BITS-1:0] inv_ar5;
wire [`STATE_BITS-1:0] inv_ar6;
wire [127:0]           inv_rc;
wire [4:0]             inv_round_const;
wire [127:0]           inv_ri;

assign inv_rc = {`RC7, `RC6, `RC5, `RC4, `RC3, `RC2, `RC1, `RC0};
assign inv_round_const = 5'd17 - round_idx;
assign inv_ri = {8{11'b0, inv_round_const}};
assign inv_ac[128*0  +: 128] = state_in[128*0 +: 128] ^ inv_rc ^ inv_ri;
assign inv_ac[128*1  +: 128] = state_in[128*1  +: 128];
assign inv_ac[128*2  +: 128] = state_in[128*2  +: 128];
assign inv_ac[128*3  +: 128] = state_in[128*3  +: 128];
assign inv_ac[128*4  +: 128] = state_in[128*4  +: 128];
assign inv_ac[128*5  +: 128] = state_in[128*5  +: 128];
assign inv_ac[128*6  +: 128] = state_in[128*6  +: 128];
assign inv_ac[128*7  +: 128] = state_in[128*7  +: 128];
assign inv_ac[128*8  +: 128] = state_in[128*8  +: 128];
assign inv_ac[128*9  +: 128] = state_in[128*9  +: 128];
assign inv_ac[128*10 +: 128] = state_in[128*10 +: 128];
assign inv_ac[128*11 +: 128] = state_in[128*11 +: 128];

mastercube_mixrow u_inv_mixrow (
    .state_i(inv_ac),
    .state_o(inv_mr)
);

mastercube_mixcolumn_after_inv_shiftrow_rowswap u_inv_mixcolumn (
    .state_i(inv_mr),
    .state_o(inv_sr1)
);

mastercube_crossmix u_inv_cross_1 (
    .state_i(inv_sr1),
    .state_o(inv_cm1)
);

genvar inv_g1;
generate
    for (inv_g1 = 0; inv_g1 < 6; inv_g1 = inv_g1 + 1) begin : gen_inv_ar1
        mastercube_mandrx u_mandrx (
            .src_row_i(inv_cm1[128*(inv_g1 + 6) +: 128]),
            .dst_row_i(inv_cm1[128*inv_g1       +: 128]),
            .alpha_i  (4'd8),
            .beta_i   (4'd9),
            .gamma_i  (4'd0),
            .row_o    (inv_ar1[128*inv_g1 +: 128])
        );
        assign inv_ar1[128*(inv_g1 + 6) +: 128] = inv_cm1[128*(inv_g1 + 6) +: 128];
    end
endgenerate

genvar inv_g2;
generate
    for (inv_g2 = 0; inv_g2 < 6; inv_g2 = inv_g2 + 1) begin : gen_inv_ar2
        assign inv_ar2[128*inv_g2 +: 128] = inv_ar1[128*inv_g2 +: 128];
        mastercube_mandrx u_mandrx (
            .src_row_i(inv_ar1[128*inv_g2       +: 128]),
            .dst_row_i(inv_ar1[128*(inv_g2 + 6) +: 128]),
            .alpha_i  (4'd0),
            .beta_i   (4'd1),
            .gamma_i  (4'd8),
            .row_o    (inv_ar2[128*(inv_g2 + 6) +: 128])
        );
    end
endgenerate

genvar inv_g3;
generate
    for (inv_g3 = 0; inv_g3 < 6; inv_g3 = inv_g3 + 1) begin : gen_inv_ar3
        mastercube_mandrx u_mandrx (
            .src_row_i(inv_ar2[128*(inv_g3 + 6) +: 128]),
            .dst_row_i(inv_ar2[128*inv_g3       +: 128]),
            .alpha_i  (4'd14),
            .beta_i   (4'd5),
            .gamma_i  (4'd0),
            .row_o    (inv_ar3[128*inv_g3 +: 128])
        );
        assign inv_ar3[128*(inv_g3 + 6) +: 128] = inv_ar2[128*(inv_g3 + 6) +: 128];
    end
endgenerate

genvar inv_g4;
generate
    for (inv_g4 = 0; inv_g4 < 6; inv_g4 = inv_g4 + 1) begin : gen_inv_ar4
        assign inv_ar4[128*inv_g4 +: 128] = inv_ar3[128*inv_g4 +: 128];
        mastercube_mandrx u_mandrx (
            .src_row_i(inv_ar3[128*inv_g4       +: 128]),
            .dst_row_i(inv_ar3[128*(inv_g4 + 6) +: 128]),
            .alpha_i  (4'd9),
            .beta_i   (4'd12),
            .gamma_i  (4'd8),
            .row_o    (inv_ar4[128*(inv_g4 + 6) +: 128])
        );
    end
endgenerate

genvar inv_g5;
generate
    for (inv_g5 = 0; inv_g5 < 6; inv_g5 = inv_g5 + 1) begin : gen_inv_ar5
        mastercube_mandrx u_mandrx (
            .src_row_i(inv_ar4[128*(inv_g5 + 6) +: 128]),
            .dst_row_i(inv_ar4[128*inv_g5       +: 128]),
            .alpha_i  (4'd14),
            .beta_i   (4'd5),
            .gamma_i  (4'd0),
            .row_o    (inv_ar5[128*inv_g5 +: 128])
        );
        assign inv_ar5[128*(inv_g5 + 6) +: 128] = inv_ar4[128*(inv_g5 + 6) +: 128];
    end
endgenerate

genvar inv_g6;
generate
    for (inv_g6 = 0; inv_g6 < 6; inv_g6 = inv_g6 + 1) begin : gen_inv_ar6
        assign inv_ar6[128*inv_g6 +: 128] = inv_ar5[128*inv_g6 +: 128];
        mastercube_mandrx u_mandrx (
            .src_row_i(inv_ar5[128*inv_g6       +: 128]),
            .dst_row_i(inv_ar5[128*(inv_g6 + 6) +: 128]),
            .alpha_i  (4'd0),
            .beta_i   (4'd1),
            .gamma_i  (4'd8),
            .row_o    (inv_ar6[128*(inv_g6 + 6) +: 128])
        );
    end
endgenerate

mastercube_crossmix_after_inv_final_swaps u_inv_cross_2 (
    .state_i(inv_ar6),
    .state_o(inv_out)
);


assign state_out = inv_out;

endmodule

module mastercube_round_inv_phase (
    input  wire [`STATE_BITS-1:0] state_in,
    input  wire [3:0]             round_idx,
    input  wire                   phase,
    output wire [`STATE_BITS-1:0] state_out
);

wire [`STATE_BITS-1:0] inv_ac;
wire [`STATE_BITS-1:0] inv_mr;
wire [`STATE_BITS-1:0] inv_sr1;
wire [`STATE_BITS-1:0] inv_cm1;
wire [`STATE_BITS-1:0] inv_pre;
wire [`STATE_BITS-1:0] inv_ar1;
wire [`STATE_BITS-1:0] inv_ar2;
wire [`STATE_BITS-1:0] inv_ar3;
wire [`STATE_BITS-1:0] inv_post;
wire [127:0]           inv_rc;
wire [4:0]             inv_round_const;
wire [127:0]           inv_ri;

assign inv_rc = {`RC7, `RC6, `RC5, `RC4, `RC3, `RC2, `RC1, `RC0};
assign inv_round_const = 5'd17 - round_idx;
assign inv_ri = {8{11'b0, inv_round_const}};
assign inv_ac[128*0  +: 128] = state_in[128*0 +: 128] ^ inv_rc ^ inv_ri;
assign inv_ac[128*1  +: 128] = state_in[128*1  +: 128];
assign inv_ac[128*2  +: 128] = state_in[128*2  +: 128];
assign inv_ac[128*3  +: 128] = state_in[128*3  +: 128];
assign inv_ac[128*4  +: 128] = state_in[128*4  +: 128];
assign inv_ac[128*5  +: 128] = state_in[128*5  +: 128];
assign inv_ac[128*6  +: 128] = state_in[128*6  +: 128];
assign inv_ac[128*7  +: 128] = state_in[128*7  +: 128];
assign inv_ac[128*8  +: 128] = state_in[128*8  +: 128];
assign inv_ac[128*9  +: 128] = state_in[128*9  +: 128];
assign inv_ac[128*10 +: 128] = state_in[128*10 +: 128];
assign inv_ac[128*11 +: 128] = state_in[128*11 +: 128];

mastercube_mixrow u_inv_phase_mixrow (
    .state_i(inv_ac),
    .state_o(inv_mr)
);

mastercube_mixcolumn_after_inv_shiftrow_rowswap u_inv_phase_mixcolumn (
    .state_i(inv_mr),
    .state_o(inv_sr1)
);

mastercube_crossmix u_inv_phase_cross_1 (
    .state_i(inv_sr1),
    .state_o(inv_cm1)
);

assign inv_pre = phase ? state_in : inv_cm1;

genvar inv_p_g1;
generate
    for (inv_p_g1 = 0; inv_p_g1 < 6; inv_p_g1 = inv_p_g1 + 1) begin : gen_inv_phase_ar1
        wire [127:0] row_w;
        mastercube_mandrx_const2 #(
            .ALPHA0(4'd8),
            .BETA0 (4'd9),
            .GAMMA0(4'd0),
            .ALPHA1(4'd9),
            .BETA1 (4'd12),
            .GAMMA1(4'd8)
        ) u_mandrx (
            .src_row_i(phase ? inv_pre[128*inv_p_g1       +: 128] :
                               inv_pre[128*(inv_p_g1 + 6) +: 128]),
            .dst_row_i(phase ? inv_pre[128*(inv_p_g1 + 6) +: 128] :
                               inv_pre[128*inv_p_g1       +: 128]),
            .phase_i  (phase),
            .row_o    (row_w)
        );
        assign inv_ar1[128*inv_p_g1       +: 128] = phase ? inv_pre[128*inv_p_g1 +: 128] : row_w;
        assign inv_ar1[128*(inv_p_g1 + 6) +: 128] = phase ? row_w : inv_pre[128*(inv_p_g1 + 6) +: 128];
    end
endgenerate

genvar inv_p_g2;
generate
    for (inv_p_g2 = 0; inv_p_g2 < 6; inv_p_g2 = inv_p_g2 + 1) begin : gen_inv_phase_ar2
        wire [127:0] row_w;
        mastercube_mandrx_const2 #(
            .ALPHA0(4'd0),
            .BETA0 (4'd1),
            .GAMMA0(4'd8),
            .ALPHA1(4'd14),
            .BETA1 (4'd5),
            .GAMMA1(4'd0)
        ) u_mandrx (
            .src_row_i(phase ? inv_ar1[128*(inv_p_g2 + 6) +: 128] :
                               inv_ar1[128*inv_p_g2       +: 128]),
            .dst_row_i(phase ? inv_ar1[128*inv_p_g2       +: 128] :
                               inv_ar1[128*(inv_p_g2 + 6) +: 128]),
            .phase_i  (phase),
            .row_o    (row_w)
        );
        assign inv_ar2[128*inv_p_g2       +: 128] = phase ? row_w : inv_ar1[128*inv_p_g2 +: 128];
        assign inv_ar2[128*(inv_p_g2 + 6) +: 128] = phase ? inv_ar1[128*(inv_p_g2 + 6) +: 128] : row_w;
    end
endgenerate

genvar inv_p_g3;
generate
    for (inv_p_g3 = 0; inv_p_g3 < 6; inv_p_g3 = inv_p_g3 + 1) begin : gen_inv_phase_ar3
        wire [127:0] row_w;
        mastercube_mandrx_const2 #(
            .ALPHA0(4'd14),
            .BETA0 (4'd5),
            .GAMMA0(4'd0),
            .ALPHA1(4'd0),
            .BETA1 (4'd1),
            .GAMMA1(4'd8)
        ) u_mandrx (
            .src_row_i(phase ? inv_ar2[128*inv_p_g3       +: 128] :
                               inv_ar2[128*(inv_p_g3 + 6) +: 128]),
            .dst_row_i(phase ? inv_ar2[128*(inv_p_g3 + 6) +: 128] :
                               inv_ar2[128*inv_p_g3       +: 128]),
            .phase_i  (phase),
            .row_o    (row_w)
        );
        assign inv_ar3[128*inv_p_g3       +: 128] = phase ? inv_ar2[128*inv_p_g3 +: 128] : row_w;
        assign inv_ar3[128*(inv_p_g3 + 6) +: 128] = phase ? row_w : inv_ar2[128*(inv_p_g3 + 6) +: 128];
    end
endgenerate

mastercube_crossmix_after_inv_final_swaps u_inv_phase_cross_2 (
    .state_i(inv_ar3),
    .state_o(inv_post)
);

assign state_out = phase ? inv_post : inv_ar3;

endmodule

module mastercube_round_inv_stage0 (
    input  wire [`STATE_BITS-1:0] state_in,
    input  wire [3:0]             round_idx,
    output wire [`STATE_BITS-1:0] state_mid
);

wire [`STATE_BITS-1:0] inv_ac;
wire [`STATE_BITS-1:0] inv_mr;
wire [`STATE_BITS-1:0] inv_sr1;
wire [`STATE_BITS-1:0] inv_cm1;
wire [`STATE_BITS-1:0] inv_ar1;
wire [`STATE_BITS-1:0] inv_ar2;
wire [`STATE_BITS-1:0] inv_ar3;
wire [127:0]           inv_rc;
wire [4:0]             inv_round_const;
wire [127:0]           inv_ri;

assign inv_rc = {`RC7, `RC6, `RC5, `RC4, `RC3, `RC2, `RC1, `RC0};
assign inv_round_const = 5'd17 - round_idx;
assign inv_ri = {8{11'b0, inv_round_const}};
assign inv_ac[128*0  +: 128] = state_in[128*0 +: 128] ^ inv_rc ^ inv_ri;
assign inv_ac[128*1  +: 128] = state_in[128*1  +: 128];
assign inv_ac[128*2  +: 128] = state_in[128*2  +: 128];
assign inv_ac[128*3  +: 128] = state_in[128*3  +: 128];
assign inv_ac[128*4  +: 128] = state_in[128*4  +: 128];
assign inv_ac[128*5  +: 128] = state_in[128*5  +: 128];
assign inv_ac[128*6  +: 128] = state_in[128*6  +: 128];
assign inv_ac[128*7  +: 128] = state_in[128*7  +: 128];
assign inv_ac[128*8  +: 128] = state_in[128*8  +: 128];
assign inv_ac[128*9  +: 128] = state_in[128*9  +: 128];
assign inv_ac[128*10 +: 128] = state_in[128*10 +: 128];
assign inv_ac[128*11 +: 128] = state_in[128*11 +: 128];

mastercube_mixrow u_inv_s0_mixrow (
    .state_i(inv_ac),
    .state_o(inv_mr)
);

mastercube_mixcolumn_after_inv_shiftrow_rowswap u_inv_s0_mixcolumn (
    .state_i(inv_mr),
    .state_o(inv_sr1)
);

mastercube_crossmix u_inv_s0_cross_1 (
    .state_i(inv_sr1),
    .state_o(inv_cm1)
);

genvar inv_s0_g1;
generate
    for (inv_s0_g1 = 0; inv_s0_g1 < 6; inv_s0_g1 = inv_s0_g1 + 1) begin : gen_inv_s0_ar1
        mastercube_mandrx_const #(
            .ALPHA(4'd8),
            .BETA (4'd9),
            .GAMMA(4'd0)
        ) u_mandrx (
            .src_row_i(inv_cm1[128*(inv_s0_g1 + 6) +: 128]),
            .dst_row_i(inv_cm1[128*inv_s0_g1       +: 128]),
            .row_o    (inv_ar1[128*inv_s0_g1 +: 128])
        );
        assign inv_ar1[128*(inv_s0_g1 + 6) +: 128] = inv_cm1[128*(inv_s0_g1 + 6) +: 128];
    end
endgenerate

genvar inv_s0_g2;
generate
    for (inv_s0_g2 = 0; inv_s0_g2 < 6; inv_s0_g2 = inv_s0_g2 + 1) begin : gen_inv_s0_ar2
        assign inv_ar2[128*inv_s0_g2 +: 128] = inv_ar1[128*inv_s0_g2 +: 128];
        mastercube_mandrx_const #(
            .ALPHA(4'd0),
            .BETA (4'd1),
            .GAMMA(4'd8)
        ) u_mandrx (
            .src_row_i(inv_ar1[128*inv_s0_g2       +: 128]),
            .dst_row_i(inv_ar1[128*(inv_s0_g2 + 6) +: 128]),
            .row_o    (inv_ar2[128*(inv_s0_g2 + 6) +: 128])
        );
    end
endgenerate

genvar inv_s0_g3;
generate
    for (inv_s0_g3 = 0; inv_s0_g3 < 6; inv_s0_g3 = inv_s0_g3 + 1) begin : gen_inv_s0_ar3
        mastercube_mandrx_const #(
            .ALPHA(4'd14),
            .BETA (4'd5),
            .GAMMA(4'd0)
        ) u_mandrx (
            .src_row_i(inv_ar2[128*(inv_s0_g3 + 6) +: 128]),
            .dst_row_i(inv_ar2[128*inv_s0_g3       +: 128]),
            .row_o    (inv_ar3[128*inv_s0_g3 +: 128])
        );
        assign inv_ar3[128*(inv_s0_g3 + 6) +: 128] = inv_ar2[128*(inv_s0_g3 + 6) +: 128];
    end
endgenerate

assign state_mid = inv_ar3;

endmodule

module mastercube_round_inv_stage1 (
    input  wire [`STATE_BITS-1:0] state_mid,
    output wire [`STATE_BITS-1:0] state_out
);

wire [`STATE_BITS-1:0] inv_ar4;
wire [`STATE_BITS-1:0] inv_ar5;
wire [`STATE_BITS-1:0] inv_ar6;

genvar inv_s1_g4;
generate
    for (inv_s1_g4 = 0; inv_s1_g4 < 6; inv_s1_g4 = inv_s1_g4 + 1) begin : gen_inv_s1_ar4
        assign inv_ar4[128*inv_s1_g4 +: 128] = state_mid[128*inv_s1_g4 +: 128];
        mastercube_mandrx_const #(
            .ALPHA(4'd9),
            .BETA (4'd12),
            .GAMMA(4'd8)
        ) u_mandrx (
            .src_row_i(state_mid[128*inv_s1_g4       +: 128]),
            .dst_row_i(state_mid[128*(inv_s1_g4 + 6) +: 128]),
            .row_o    (inv_ar4[128*(inv_s1_g4 + 6) +: 128])
        );
    end
endgenerate

genvar inv_s1_g5;
generate
    for (inv_s1_g5 = 0; inv_s1_g5 < 6; inv_s1_g5 = inv_s1_g5 + 1) begin : gen_inv_s1_ar5
        mastercube_mandrx_const #(
            .ALPHA(4'd14),
            .BETA (4'd5),
            .GAMMA(4'd0)
        ) u_mandrx (
            .src_row_i(inv_ar4[128*(inv_s1_g5 + 6) +: 128]),
            .dst_row_i(inv_ar4[128*inv_s1_g5       +: 128]),
            .row_o    (inv_ar5[128*inv_s1_g5 +: 128])
        );
        assign inv_ar5[128*(inv_s1_g5 + 6) +: 128] = inv_ar4[128*(inv_s1_g5 + 6) +: 128];
    end
endgenerate

genvar inv_s1_g6;
generate
    for (inv_s1_g6 = 0; inv_s1_g6 < 6; inv_s1_g6 = inv_s1_g6 + 1) begin : gen_inv_s1_ar6
        assign inv_ar6[128*inv_s1_g6 +: 128] = inv_ar5[128*inv_s1_g6 +: 128];
        mastercube_mandrx_const #(
            .ALPHA(4'd0),
            .BETA (4'd1),
            .GAMMA(4'd8)
        ) u_mandrx (
            .src_row_i(inv_ar5[128*inv_s1_g6       +: 128]),
            .dst_row_i(inv_ar5[128*(inv_s1_g6 + 6) +: 128]),
            .row_o    (inv_ar6[128*(inv_s1_g6 + 6) +: 128])
        );
    end
endgenerate

mastercube_crossmix_after_inv_final_swaps u_inv_s1_cross_2 (
    .state_i(inv_ar6),
    .state_o(state_out)
);

endmodule
