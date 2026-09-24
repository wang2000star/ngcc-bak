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

wire [127:0] col024_xor = row0 ^ row2 ^ row4;
wire [127:0] col135_xor = row1 ^ row3 ^ row5;
wire [127:0] col68a_xor = row6 ^ row8 ^ row10;
wire [127:0] col79b_xor = row7 ^ row9 ^ row11;

assign state_o[128*0  +: 128] = col024_xor ^ row0;
assign state_o[128*2  +: 128] = col024_xor ^ row2;
assign state_o[128*4  +: 128] = col024_xor;
assign state_o[128*1  +: 128] = col135_xor ^ row1;
assign state_o[128*3  +: 128] = col135_xor ^ row3;
assign state_o[128*5  +: 128] = col135_xor;

assign state_o[128*6  +: 128] = col68a_xor ^ row8;
assign state_o[128*8  +: 128] = col68a_xor ^ row6;
assign state_o[128*10 +: 128] = col68a_xor;
assign state_o[128*7  +: 128] = col79b_xor ^ row9;
assign state_o[128*9  +: 128] = col79b_xor ^ row7;
assign state_o[128*11 +: 128] = col79b_xor;

endmodule

module mastercube_mixcolumn_after_rowswap (
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

wire [127:0] col024_xor = row0 ^ row2 ^ row4;
wire [127:0] col135_xor = row1 ^ row3 ^ row5;
wire [127:0] col79b_xor = row7 ^ row9 ^ row11;
wire [127:0] col68a_xor = row6 ^ row8 ^ row10;

assign state_o[128*0  +: 128] = col024_xor ^ row0;
assign state_o[128*2  +: 128] = col024_xor ^ row2;
assign state_o[128*4  +: 128] = col024_xor;
assign state_o[128*1  +: 128] = col135_xor ^ row1;
assign state_o[128*3  +: 128] = col135_xor ^ row3;
assign state_o[128*5  +: 128] = col135_xor;

assign state_o[128*6  +: 128] = col79b_xor ^ row9;
assign state_o[128*8  +: 128] = col79b_xor ^ row7;
assign state_o[128*10 +: 128] = col79b_xor;
assign state_o[128*7  +: 128] = col68a_xor ^ row8;
assign state_o[128*9  +: 128] = col68a_xor ^ row6;
assign state_o[128*11 +: 128] = col68a_xor;

endmodule

module mastercube_mixcolumn_after_inv_shiftrow_rowswap (
    input  wire [`STATE_BITS-1:0] state_i,
    output wire [`STATE_BITS-1:0] state_o
);

function [127:0] inv_shift0;
    input [127:0] row_i;
    begin
        inv_shift0 = row_i;
    end
endfunction

function [127:0] inv_shift1;
    input [127:0] row_i;
    begin
        inv_shift1 = {row_i[111:0], row_i[127:112]};
    end
endfunction

function [127:0] inv_shift2;
    input [127:0] row_i;
    begin
        inv_shift2 = {row_i[95:0], row_i[127:96]};
    end
endfunction

function [127:0] inv_shift3;
    input [127:0] row_i;
    begin
        inv_shift3 = {row_i[79:0], row_i[127:80]};
    end
endfunction

function [127:0] inv_shift4;
    input [127:0] row_i;
    begin
        inv_shift4 = {row_i[63:0], row_i[127:64]};
    end
endfunction

function [127:0] inv_shift5;
    input [127:0] row_i;
    begin
        inv_shift5 = {row_i[47:0], row_i[127:48]};
    end
endfunction

function [127:0] inv_shift7;
    input [127:0] row_i;
    begin
        inv_shift7 = {row_i[15:0], row_i[127:16]};
    end
endfunction

function [127:0] inv_shift8;
    input [127:0] row_i;
    begin
        inv_shift8 = {row_i[31:0], row_i[127:32]};
    end
endfunction

function [127:0] inv_shift9;
    input [127:0] row_i;
    begin
        inv_shift9 = {row_i[47:0], row_i[127:48]};
    end
endfunction

function [127:0] inv_shift10;
    input [127:0] row_i;
    begin
        inv_shift10 = {row_i[63:0], row_i[127:64]};
    end
endfunction

function [127:0] inv_shift11;
    input [127:0] row_i;
    begin
        inv_shift11 = {row_i[79:0], row_i[127:80]};
    end
endfunction

wire [127:0] row0  = inv_shift0(state_i[128*0 +: 128]);
wire [127:0] row1  = inv_shift1(state_i[128*1 +: 128]);
wire [127:0] row2  = inv_shift2(state_i[128*2 +: 128]);
wire [127:0] row3  = inv_shift3(state_i[128*3 +: 128]);
wire [127:0] row4  = inv_shift4(state_i[128*4 +: 128]);
wire [127:0] row5  = inv_shift5(state_i[128*5 +: 128]);
wire [127:0] row6  = state_i[128*6 +: 128];
wire [127:0] row7  = inv_shift7(state_i[128*7 +: 128]);
wire [127:0] row8  = inv_shift8(state_i[128*8 +: 128]);
wire [127:0] row9  = inv_shift9(state_i[128*9 +: 128]);
wire [127:0] row10 = inv_shift10(state_i[128*10 +: 128]);
wire [127:0] row11 = inv_shift11(state_i[128*11 +: 128]);

wire [127:0] col024_xor = row0 ^ row2 ^ row4;
wire [127:0] col135_xor = row1 ^ row3 ^ row5;
wire [127:0] col79b_xor = row7 ^ row9 ^ row11;
wire [127:0] col68a_xor = row6 ^ row8 ^ row10;

assign state_o[128*0  +: 128] = col024_xor ^ row0;
assign state_o[128*1  +: 128] = col135_xor ^ row1;
assign state_o[128*2  +: 128] = col024_xor ^ row2;
assign state_o[128*3  +: 128] = col135_xor ^ row3;
assign state_o[128*4  +: 128] = col024_xor;
assign state_o[128*5  +: 128] = col135_xor;
assign state_o[128*6  +: 128] = col79b_xor ^ row9;
assign state_o[128*7  +: 128] = col68a_xor ^ row8;
assign state_o[128*8  +: 128] = col79b_xor ^ row7;
assign state_o[128*9  +: 128] = col68a_xor ^ row6;
assign state_o[128*10 +: 128] = col79b_xor;
assign state_o[128*11 +: 128] = col68a_xor;

endmodule
