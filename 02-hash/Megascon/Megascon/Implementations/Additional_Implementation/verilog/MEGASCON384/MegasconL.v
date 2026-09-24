module l_layer (
    input  wire [2047:0] state_in,
    output wire [2047:0] state_out
);

    function [63:0] rotl64;
        input [63:0] x;
        input integer n;
        begin
            rotl64 = (x << n) | (x >> (64 - n));
        end
    endfunction

    function [255:0] L_row;
        input [255:0] x;
        input integer a;
        input integer b;
        input integer c;
        input integer d;

        reg [63:0] x0, x1, x2, x3;
        reg [63:0] y0, y1, y2, y3;

        begin
            x0 = x[0*64 +: 64];
            x1 = x[1*64 +: 64];
            x2 = x[2*64 +: 64];
            x3 = x[3*64 +: 64];

            y0 = x0 ^ rotl64(x1, a) ^ rotl64(x2, b) ^ rotl64(x3, c) ^ rotl64(x0, d);
            y1 = x1 ^ rotl64(x2, a) ^ rotl64(x3, b) ^ rotl64(x0, c) ^ rotl64(x1, d);
            y2 = x2 ^ rotl64(x3, a) ^ rotl64(x0, b) ^ rotl64(x1, c) ^ rotl64(x2, d);
            y3 = x3 ^ rotl64(x0, a) ^ rotl64(x1, b) ^ rotl64(x2, c) ^ rotl64(x3, d);

            L_row = {y3, y2, y1, y0};
        end
    endfunction

    assign state_out[0*256 +: 256] = L_row(state_in[0*256 +: 256], 1,  3,  14, 36);
    assign state_out[1*256 +: 256] = L_row(state_in[1*256 +: 256], 2,  5,  23, 60);
    assign state_out[2*256 +: 256] = L_row(state_in[2*256 +: 256], 4,  15, 17, 24);
    assign state_out[3*256 +: 256] = L_row(state_in[3*256 +: 256], 7,  9,  12, 40);
    assign state_out[4*256 +: 256] = L_row(state_in[4*256 +: 256], 26, 46, 13, 37);
    assign state_out[5*256 +: 256] = L_row(state_in[5*256 +: 256], 49, 6,  50, 25);
    assign state_out[6*256 +: 256] = L_row(state_in[6*256 +: 256], 55, 19, 56, 57);
    assign state_out[7*256 +: 256] = L_row(state_in[7*256 +: 256], 58, 47, 61, 28);

endmodule