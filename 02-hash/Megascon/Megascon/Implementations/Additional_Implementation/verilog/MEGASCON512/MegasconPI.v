module pi_layer (
    input  wire [2047:0] state_in,
    output wire [2047:0] state_out
);

    assign state_out[1*256 +: 256] = state_in[0*256 +: 256];
    assign state_out[7*256 +: 256] = state_in[1*256 +: 256];
    assign state_out[5*256 +: 256] = state_in[2*256 +: 256];
    assign state_out[2*256 +: 256] = state_in[3*256 +: 256];
    assign state_out[4*256 +: 256] = state_in[4*256 +: 256];
    assign state_out[6*256 +: 256] = state_in[5*256 +: 256];
    assign state_out[0*256 +: 256] = state_in[6*256 +: 256];
    assign state_out[3*256 +: 256] = state_in[7*256 +: 256];

endmodule
