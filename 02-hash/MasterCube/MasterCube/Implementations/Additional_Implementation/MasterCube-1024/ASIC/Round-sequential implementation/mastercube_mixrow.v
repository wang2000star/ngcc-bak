// MasterCube mix_row transform.
// Pure combinational Verilog-2001.

`timescale 1 ns / 1 ps
`include "mastercube_globals.v"

module mastercube_mixrow (
    input  wire [`STATE_BITS-1:0] state_i,
    output wire [`STATE_BITS-1:0] state_o
);

function [127:0] mix_row;
    input [127:0] row_i;
    begin
        mix_row = {
            row_i[16*5 +: 16] ^ row_i[16*7 +: 16] ^ row_i[16*1 +: 16],
            row_i[16*4 +: 16] ^ row_i[16*6 +: 16] ^ row_i[16*0 +: 16],
            row_i[16*3 +: 16] ^ row_i[16*5 +: 16] ^ row_i[16*7 +: 16],
            row_i[16*2 +: 16] ^ row_i[16*4 +: 16] ^ row_i[16*6 +: 16],
            row_i[16*1 +: 16] ^ row_i[16*3 +: 16] ^ row_i[16*5 +: 16],
            row_i[16*0 +: 16] ^ row_i[16*2 +: 16] ^ row_i[16*4 +: 16],
            row_i[16*7 +: 16] ^ row_i[16*1 +: 16] ^ row_i[16*3 +: 16],
            row_i[16*6 +: 16] ^ row_i[16*0 +: 16] ^ row_i[16*2 +: 16]
        };
    end
endfunction

assign state_o[128*0  +: 128] = mix_row(state_i[128*0  +: 128]);
assign state_o[128*1  +: 128] = mix_row(state_i[128*1  +: 128]);
assign state_o[128*2  +: 128] = mix_row(state_i[128*2  +: 128]);
assign state_o[128*3  +: 128] = mix_row(state_i[128*3  +: 128]);
assign state_o[128*4  +: 128] = mix_row(state_i[128*4  +: 128]);
assign state_o[128*5  +: 128] = mix_row(state_i[128*5  +: 128]);
assign state_o[128*6  +: 128] = mix_row(state_i[128*6  +: 128]);
assign state_o[128*7  +: 128] = mix_row(state_i[128*7  +: 128]);
assign state_o[128*8  +: 128] = mix_row(state_i[128*8  +: 128]);
assign state_o[128*9  +: 128] = mix_row(state_i[128*9  +: 128]);
assign state_o[128*10 +: 128] = mix_row(state_i[128*10 +: 128]);
assign state_o[128*11 +: 128] = mix_row(state_i[128*11 +: 128]);

endmodule
