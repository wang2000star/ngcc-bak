module sbox_layer (
    input  wire [2047:0] state_in,
    output wire [2047:0] state_out
);

genvar y;

generate;
    for (y = 0; y < 4; y = y + 1) begin : sbox_layer
        wire [127:0] b3;
        wire [127:0] b1;
    
        assign b3 = (state_in[128*(3*4 + y) +: 128] &
                     state_in[128*(2*4 + y) +: 128]) ^
                     state_in[128*(1*4 + y) +: 128];
    
        assign b1 = (state_in[128*(2*4 + y) +: 128] |
                     state_in[128*(1*4 + y) +: 128]) ^
                     state_in[128*(0*4 + y) +: 128];
    
        assign state_out[128*(3*4 + y) +: 128] = b3;
        assign state_out[128*(1*4 + y) +: 128] = b1;
    
        assign state_out[128*(0*4 + y) +: 128] =
               (b3 & state_in[128*(0*4 + y) +: 128]) ^
                     state_in[128*(3*4 + y) +: 128];
    
        assign state_out[128*(2*4 + y) +: 128] =
               (b1 & state_in[128*(3*4 + y) +: 128]) ^
                     state_in[128*(2*4 + y) +: 128];
    end
    
endgenerate

endmodule