module sbox_layer (
    input  wire [2047:0] state_in,
    output wire [2047:0] state_out
);

    genvar j;

    generate
        for (j = 0; j < 256; j = j + 1) begin : gen_sbox
            wire u0, u1, u2, u3, u4, u5, u6, u7;

            assign u0 = state_in[0*256 + j];
            assign u1 = state_in[1*256 + j];
            assign u2 = state_in[2*256 + j];
            assign u3 = state_in[3*256 + j];
            assign u4 = state_in[4*256 + j];
            assign u5 = state_in[5*256 + j];
            assign u6 = state_in[6*256 + j];
            assign u7 = state_in[7*256 + j];

            assign state_out[0*256 + j] = u0 ^ ((~u1) & u2);
            assign state_out[1*256 + j] = u4 ^ ((~u2) & u0);
            assign state_out[2*256 + j] = u3 ^ ((~u0) & u1);
            assign state_out[3*256 + j] = (~u1) ^ ((~u4) & (~u5));
            assign state_out[4*256 + j] = u2 ^ ((~u5) & u6);
            assign state_out[5*256 + j] = u5 ^ ((~u6) & u7);
            assign state_out[6*256 + j] = u6 ^ ((~u7) & u3);
            assign state_out[7*256 + j] = u7 ^ ((~u3) & u4);
        end
    endgenerate

endmodule