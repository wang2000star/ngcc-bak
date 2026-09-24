// MasterCube and_rx row transform with 16-bit rotate helpers.
// Pure combinational Verilog-2001.

`timescale 1 ns / 1 ps

module mastercube_mandrx (
    input  wire [127:0] src_row_i,
    input  wire [127:0] dst_row_i,
    input  wire [3:0]   alpha_i,
    input  wire [3:0]   beta_i,
    input  wire [3:0]   gamma_i,
    output wire [127:0] row_o
);

function [15:0] ror16;
    input [15:0] value_i;
    input [3:0]  amount_i;
    begin
        case (amount_i)
            4'd0  : ror16 = value_i;
            4'd1  : ror16 = {value_i[0],    value_i[15:1]};
            4'd2  : ror16 = {value_i[1:0],  value_i[15:2]};
            4'd3  : ror16 = {value_i[2:0],  value_i[15:3]};
            4'd4  : ror16 = {value_i[3:0],  value_i[15:4]};
            4'd5  : ror16 = {value_i[4:0],  value_i[15:5]};
            4'd6  : ror16 = {value_i[5:0],  value_i[15:6]};
            4'd7  : ror16 = {value_i[6:0],  value_i[15:7]};
            4'd8  : ror16 = {value_i[7:0],  value_i[15:8]};
            4'd9  : ror16 = {value_i[8:0],  value_i[15:9]};
            4'd10 : ror16 = {value_i[9:0],  value_i[15:10]};
            4'd11 : ror16 = {value_i[10:0], value_i[15:11]};
            4'd12 : ror16 = {value_i[11:0], value_i[15:12]};
            4'd13 : ror16 = {value_i[12:0], value_i[15:13]};
            4'd14 : ror16 = {value_i[13:0], value_i[15:14]};
            default : ror16 = {value_i[14:0], value_i[15]};
        endcase
    end
endfunction

function [15:0] andrx_cell;
    input [15:0] src_i;
    input [15:0] dst_i;
    begin
        andrx_cell = (ror16(src_i, alpha_i) & ror16(src_i, beta_i)) ^
                     ror16(src_i, gamma_i) ^ dst_i;
    end
endfunction

assign row_o[16*0 +: 16] = andrx_cell(src_row_i[16*0 +: 16], dst_row_i[16*0 +: 16]);
assign row_o[16*1 +: 16] = andrx_cell(src_row_i[16*1 +: 16], dst_row_i[16*1 +: 16]);
assign row_o[16*2 +: 16] = andrx_cell(src_row_i[16*2 +: 16], dst_row_i[16*2 +: 16]);
assign row_o[16*3 +: 16] = andrx_cell(src_row_i[16*3 +: 16], dst_row_i[16*3 +: 16]);
assign row_o[16*4 +: 16] = andrx_cell(src_row_i[16*4 +: 16], dst_row_i[16*4 +: 16]);
assign row_o[16*5 +: 16] = andrx_cell(src_row_i[16*5 +: 16], dst_row_i[16*5 +: 16]);
assign row_o[16*6 +: 16] = andrx_cell(src_row_i[16*6 +: 16], dst_row_i[16*6 +: 16]);
assign row_o[16*7 +: 16] = andrx_cell(src_row_i[16*7 +: 16], dst_row_i[16*7 +: 16]);

endmodule

module mastercube_mandrx_const #(
    parameter [3:0] ALPHA = 4'd0,
    parameter [3:0] BETA  = 4'd1,
    parameter [3:0] GAMMA = 4'd8
) (
    input  wire [127:0] src_row_i,
    input  wire [127:0] dst_row_i,
    output wire [127:0] row_o
);

function [15:0] ror16_const;
    input [15:0] value_i;
    input [3:0]  amount_i;
    begin
        case (amount_i)
            4'd0  : ror16_const = value_i;
            4'd1  : ror16_const = {value_i[0],    value_i[15:1]};
            4'd2  : ror16_const = {value_i[1:0],  value_i[15:2]};
            4'd3  : ror16_const = {value_i[2:0],  value_i[15:3]};
            4'd4  : ror16_const = {value_i[3:0],  value_i[15:4]};
            4'd5  : ror16_const = {value_i[4:0],  value_i[15:5]};
            4'd6  : ror16_const = {value_i[5:0],  value_i[15:6]};
            4'd7  : ror16_const = {value_i[6:0],  value_i[15:7]};
            4'd8  : ror16_const = {value_i[7:0],  value_i[15:8]};
            4'd9  : ror16_const = {value_i[8:0],  value_i[15:9]};
            4'd10 : ror16_const = {value_i[9:0],  value_i[15:10]};
            4'd11 : ror16_const = {value_i[10:0], value_i[15:11]};
            4'd12 : ror16_const = {value_i[11:0], value_i[15:12]};
            4'd13 : ror16_const = {value_i[12:0], value_i[15:13]};
            4'd14 : ror16_const = {value_i[13:0], value_i[15:14]};
            default : ror16_const = {value_i[14:0], value_i[15]};
        endcase
    end
endfunction

function [15:0] andrx_cell_const;
    input [15:0] src_i;
    input [15:0] dst_i;
    begin
        andrx_cell_const = (ror16_const(src_i, ALPHA) & ror16_const(src_i, BETA)) ^
                           ror16_const(src_i, GAMMA) ^ dst_i;
    end
endfunction

assign row_o[16*0 +: 16] = andrx_cell_const(src_row_i[16*0 +: 16], dst_row_i[16*0 +: 16]);
assign row_o[16*1 +: 16] = andrx_cell_const(src_row_i[16*1 +: 16], dst_row_i[16*1 +: 16]);
assign row_o[16*2 +: 16] = andrx_cell_const(src_row_i[16*2 +: 16], dst_row_i[16*2 +: 16]);
assign row_o[16*3 +: 16] = andrx_cell_const(src_row_i[16*3 +: 16], dst_row_i[16*3 +: 16]);
assign row_o[16*4 +: 16] = andrx_cell_const(src_row_i[16*4 +: 16], dst_row_i[16*4 +: 16]);
assign row_o[16*5 +: 16] = andrx_cell_const(src_row_i[16*5 +: 16], dst_row_i[16*5 +: 16]);
assign row_o[16*6 +: 16] = andrx_cell_const(src_row_i[16*6 +: 16], dst_row_i[16*6 +: 16]);
assign row_o[16*7 +: 16] = andrx_cell_const(src_row_i[16*7 +: 16], dst_row_i[16*7 +: 16]);

endmodule
