// MasterCube mix_column over all 12 state rows.
// Pure combinational Verilog-2001.

`timescale 1 ns / 1 ps
`include "mastercube_globals.v"

module mastercube_mixcolumn (
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

assign state_o[128*0  +: 128] = row2 ^ row4;
assign state_o[128*2  +: 128] = row0 ^ row4;
assign state_o[128*4  +: 128] = row0 ^ row2 ^ row4;
assign state_o[128*1  +: 128] = row3 ^ row5;
assign state_o[128*3  +: 128] = row1 ^ row5;
assign state_o[128*5  +: 128] = row1 ^ row3 ^ row5;

assign state_o[128*6  +: 128] = row6 ^ row10;
assign state_o[128*8  +: 128] = row8 ^ row10;
assign state_o[128*10 +: 128] = row8 ^ row6 ^ row10;
assign state_o[128*7  +: 128] = row7 ^ row11;
assign state_o[128*9  +: 128] = row9 ^ row11;
assign state_o[128*11 +: 128] = row9 ^ row7 ^ row11;

endmodule
