module mc_layer (
    input  wire [2047:0] state_in,
    output wire [2047:0] state_out
);

    function [511:0] MUL4;
        input [511:0] in;
        reg [127:0] x0, x1, x2, x3;
        begin
            x0 = in[127:0];
            x1 = in[255:128];
            x2 = in[383:256];
            x3 = in[511:384];

            // C code:
            // tmp = x3;
            // x3 = x2;
            // x2 = x1;
            // x1 = x0;
            // x0 = tmp;
            // x1 ^= x0;
            //
            // new x0 = old x3
            // new x1 = old x0 ^ old x3
            // new x2 = old x1
            // new x3 = old x2
            MUL4 = {
                x2,        // new x3
                x1,        // new x2
                x0 ^ x3,   // new x1
                x3         // new x0
            };
        end
    endfunction

    function [2047:0] bitSliceMDS128;
        input [2047:0] s;

        reg [127:0] x0, x1, x2, x3;
        reg [127:0] x4, x5, x6, x7;
        reg [127:0] x8, x9, xa, xb;
        reg [127:0] xc, xd, xe, xf;

        reg [511:0] tmp;
        reg [2047:0] out;

        begin
            // x0..xf follow the C argument order:
            // C[0][0], C[1][0], C[2][0], C[3][0],
            // C[0][1], C[1][1], C[2][1], C[3][1],
            // C[0][2], C[1][2], C[2][2], C[3][2],
            // C[0][3], C[1][3], C[2][3], C[3][3]

            x0 = s[128*(0*4 + 0) +: 128]; // C[0][0]
            x1 = s[128*(1*4 + 0) +: 128]; // C[1][0]
            x2 = s[128*(2*4 + 0) +: 128]; // C[2][0]
            x3 = s[128*(3*4 + 0) +: 128]; // C[3][0]

            x4 = s[128*(0*4 + 1) +: 128]; // C[0][1]
            x5 = s[128*(1*4 + 1) +: 128]; // C[1][1]
            x6 = s[128*(2*4 + 1) +: 128]; // C[2][1]
            x7 = s[128*(3*4 + 1) +: 128]; // C[3][1]

            x8 = s[128*(0*4 + 2) +: 128]; // C[0][2]
            x9 = s[128*(1*4 + 2) +: 128]; // C[1][2]
            xa = s[128*(2*4 + 2) +: 128]; // C[2][2]
            xb = s[128*(3*4 + 2) +: 128]; // C[3][2]

            xc = s[128*(0*4 + 3) +: 128]; // C[0][3]
            xd = s[128*(1*4 + 3) +: 128]; // C[1][3]
            xe = s[128*(2*4 + 3) +: 128]; // C[2][3]
            xf = s[128*(3*4 + 3) +: 128]; // C[3][3]

            x8 = x8 ^ xc;  x9 = x9 ^ xd;  xa = xa ^ xe;  xb = xb ^ xf;
            x0 = x0 ^ x4;  x1 = x1 ^ x5;  x2 = x2 ^ x6;  x3 = x3 ^ x7;

            tmp = MUL4({x7, x6, x5, x4});
            x4 = tmp[127:0]; x5 = tmp[255:128]; x6 = tmp[383:256]; x7 = tmp[511:384];

            tmp = MUL4({xf, xe, xd, xc});
            xc = tmp[127:0]; xd = tmp[255:128]; xe = tmp[383:256]; xf = tmp[511:384];

            x4 = x4 ^ x8;  x5 = x5 ^ x9;  x6 = x6 ^ xa;  x7 = x7 ^ xb;
            xc = xc ^ x0;  xd = xd ^ x1;  xe = xe ^ x2;  xf = xf ^ x3;

            tmp = MUL4({x3, x2, x1, x0});
            x0 = tmp[127:0]; x1 = tmp[255:128]; x2 = tmp[383:256]; x3 = tmp[511:384];

            tmp = MUL4({x3, x2, x1, x0});
            x0 = tmp[127:0]; x1 = tmp[255:128]; x2 = tmp[383:256]; x3 = tmp[511:384];

            tmp = MUL4({xb, xa, x9, x8});
            x8 = tmp[127:0]; x9 = tmp[255:128]; xa = tmp[383:256]; xb = tmp[511:384];

            tmp = MUL4({xb, xa, x9, x8});
            x8 = tmp[127:0]; x9 = tmp[255:128]; xa = tmp[383:256]; xb = tmp[511:384];

            x8 = x8 ^ xc;  x9 = x9 ^ xd;  xa = xa ^ xe;  xb = xb ^ xf;
            x0 = x0 ^ x4;  x1 = x1 ^ x5;  x2 = x2 ^ x6;  x3 = x3 ^ x7;
            x4 = x4 ^ x8;  x5 = x5 ^ x9;  x6 = x6 ^ xa;  x7 = x7 ^ xb;
            xc = xc ^ x0;  xd = xd ^ x1;  xe = xe ^ x2;  xf = xf ^ x3;

            // Write back with the C-compatible layout:
            // state[128*(x*4+y)+:128] <=> C[x][y]
            out = 2048'd0;

            out[128*(0*4 + 0) +: 128] = x0;
            out[128*(1*4 + 0) +: 128] = x1;
            out[128*(2*4 + 0) +: 128] = x2;
            out[128*(3*4 + 0) +: 128] = x3;

            out[128*(0*4 + 1) +: 128] = x4;
            out[128*(1*4 + 1) +: 128] = x5;
            out[128*(2*4 + 1) +: 128] = x6;
            out[128*(3*4 + 1) +: 128] = x7;

            out[128*(0*4 + 2) +: 128] = x8;
            out[128*(1*4 + 2) +: 128] = x9;
            out[128*(2*4 + 2) +: 128] = xa;
            out[128*(3*4 + 2) +: 128] = xb;

            out[128*(0*4 + 3) +: 128] = xc;
            out[128*(1*4 + 3) +: 128] = xd;
            out[128*(2*4 + 3) +: 128] = xe;
            out[128*(3*4 + 3) +: 128] = xf;

            bitSliceMDS128 = out;
        end
    endfunction

    assign state_out = bitSliceMDS128(state_in);

endmodule