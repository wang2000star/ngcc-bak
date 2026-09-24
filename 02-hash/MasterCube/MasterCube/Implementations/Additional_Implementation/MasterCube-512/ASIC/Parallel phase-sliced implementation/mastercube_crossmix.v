// MasterCube cross_mix over all 12 state rows.
// Pure combinational Verilog-2001.

`timescale 1 ns / 1 ps
`include "mastercube_globals.v"

module mastercube_crossmix (
    input  wire [`STATE_BITS-1:0] state_i,
    output wire [`STATE_BITS-1:0] state_o
);

wire [127:0] row0  = state_i[128*0  +: 128];
wire [127:0] row1  = state_i[128*1  +: 128];
wire [127:0] row2  = state_i[128*2  +: 128];
wire [127:0] row3  = state_i[128*3  +: 128];
wire [127:0] row4  = state_i[128*4  +: 128];
wire [127:0] row5  = state_i[128*5  +: 128];
wire [127:0] row6  = state_i[128*6  +: 128];
wire [127:0] row7  = state_i[128*7  +: 128];
wire [127:0] row8  = state_i[128*8  +: 128];
wire [127:0] row9  = state_i[128*9  +: 128];
wire [127:0] row10 = state_i[128*10 +: 128];
wire [127:0] row11 = state_i[128*11 +: 128];

wire [127:0] row2_xor_row8   = row2  ^ row8;
wire [127:0] row3_xor_row9   = row3  ^ row9;
wire [127:0] row4_xor_row10  = row4  ^ row10;
wire [127:0] row5_xor_row11  = row5  ^ row11;
wire [127:0] row0_xor_row6   = row0  ^ row6;
wire [127:0] row1_xor_row7   = row1  ^ row7;

assign state_o[128*0  +: 128] = row0  ^ row2_xor_row8;
assign state_o[128*1  +: 128] = row1  ^ row3_xor_row9;
assign state_o[128*2  +: 128] = row2  ^ row4_xor_row10;
assign state_o[128*3  +: 128] = row3  ^ row5_xor_row11;
assign state_o[128*4  +: 128] = row4  ^ row0_xor_row6;
assign state_o[128*5  +: 128] = row5  ^ row1_xor_row7;
assign state_o[128*6  +: 128] = row6  ^ row2_xor_row8;
assign state_o[128*7  +: 128] = row7  ^ row3_xor_row9;
assign state_o[128*8  +: 128] = row8  ^ row4_xor_row10;
assign state_o[128*9  +: 128] = row9  ^ row5_xor_row11;
assign state_o[128*10 +: 128] = row10 ^ row0_xor_row6;
assign state_o[128*11 +: 128] = row11 ^ row1_xor_row7;

endmodule

module mastercube_crossmix_fwd_rowswap (
    input  wire [`STATE_BITS-1:0] state_i,
    output wire [`STATE_BITS-1:0] state_o
);

wire [127:0] row0  = state_i[128*0  +: 128];
wire [127:0] row1  = state_i[128*1  +: 128];
wire [127:0] row2  = state_i[128*2  +: 128];
wire [127:0] row3  = state_i[128*3  +: 128];
wire [127:0] row4  = state_i[128*4  +: 128];
wire [127:0] row5  = state_i[128*5  +: 128];
wire [127:0] row6  = state_i[128*6  +: 128];
wire [127:0] row7  = state_i[128*7  +: 128];
wire [127:0] row8  = state_i[128*8  +: 128];
wire [127:0] row9  = state_i[128*9  +: 128];
wire [127:0] row10 = state_i[128*10 +: 128];
wire [127:0] row11 = state_i[128*11 +: 128];

wire [127:0] row2_xor_row8   = row2  ^ row8;
wire [127:0] row3_xor_row9   = row3  ^ row9;
wire [127:0] row4_xor_row10  = row4  ^ row10;
wire [127:0] row5_xor_row11  = row5  ^ row11;
wire [127:0] row0_xor_row6   = row0  ^ row6;
wire [127:0] row1_xor_row7   = row1  ^ row7;

assign state_o[128*0  +: 128] = row0  ^ row2_xor_row8;
assign state_o[128*1  +: 128] = row1  ^ row3_xor_row9;
assign state_o[128*2  +: 128] = row2  ^ row4_xor_row10;
assign state_o[128*3  +: 128] = row3  ^ row5_xor_row11;
assign state_o[128*4  +: 128] = row4  ^ row0_xor_row6;
assign state_o[128*5  +: 128] = row5  ^ row1_xor_row7;
assign state_o[128*6  +: 128] = row7  ^ row3_xor_row9;
assign state_o[128*7  +: 128] = row6  ^ row2_xor_row8;
assign state_o[128*8  +: 128] = row9  ^ row5_xor_row11;
assign state_o[128*9  +: 128] = row8  ^ row4_xor_row10;
assign state_o[128*10 +: 128] = row11 ^ row1_xor_row7;
assign state_o[128*11 +: 128] = row10 ^ row0_xor_row6;

endmodule

module mastercube_crossmix_after_inv_final_swaps (
    input  wire [`STATE_BITS-1:0] state_i,
    output wire [`STATE_BITS-1:0] state_o
);

wire [127:0] row0  = state_i[128*0  +: 128];
wire [127:0] row1  = state_i[128*1  +: 128];
wire [127:0] row2  = state_i[128*2  +: 128];
wire [127:0] row3  = state_i[128*3  +: 128];
wire [127:0] row4  = state_i[128*4  +: 128];
wire [127:0] row5  = state_i[128*5  +: 128];
wire [127:0] row6  = state_i[128*6  +: 128];
wire [127:0] row7  = state_i[128*7  +: 128];
wire [127:0] row8  = state_i[128*8  +: 128];
wire [127:0] row9  = state_i[128*9  +: 128];
wire [127:0] row10 = state_i[128*10 +: 128];
wire [127:0] row11 = state_i[128*11 +: 128];

wire [127:0] row3_xor_row8   = row3  ^ row8;
wire [127:0] row2_xor_row9   = row2  ^ row9;
wire [127:0] row5_xor_row10  = row5  ^ row10;
wire [127:0] row4_xor_row11  = row4  ^ row11;
wire [127:0] row1_xor_row6   = row1  ^ row6;
wire [127:0] row0_xor_row7   = row0  ^ row7;

assign state_o[128*0  +: 128] = row6  ^ row3_xor_row8;
assign state_o[128*1  +: 128] = row7  ^ row2_xor_row9;
assign state_o[128*2  +: 128] = row8  ^ row5_xor_row10;
assign state_o[128*3  +: 128] = row9  ^ row4_xor_row11;
assign state_o[128*4  +: 128] = row10 ^ row1_xor_row6;
assign state_o[128*5  +: 128] = row11 ^ row0_xor_row7;
assign state_o[128*6  +: 128] = row1  ^ row3_xor_row8;
assign state_o[128*7  +: 128] = row0  ^ row2_xor_row9;
assign state_o[128*8  +: 128] = row3  ^ row5_xor_row10;
assign state_o[128*9  +: 128] = row2  ^ row4_xor_row11;
assign state_o[128*10 +: 128] = row5  ^ row1_xor_row6;
assign state_o[128*11 +: 128] = row4  ^ row0_xor_row7;

endmodule
