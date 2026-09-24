module shiftrow (
    input  wire [2047:0] state_in,
    input  wire [4:0]    round_id,
    output wire [2047:0] state_out
);

    function [127:0] rotr128;
        input [127:0] x;
        input [6:0]   sh;
        begin
            if (sh == 0)
                rotr128 = x;
            else
                rotr128 = (x >> sh) | (x << (128 - sh));
        end
    endfunction

    function [6:0] rho_amt;
        input [1:0] r;
        input [1:0] y;
        begin
            case ({r, y})
                // r = 0: {0, 14, 20, 22}
                4'b00_00: rho_amt = 7'd0;
                4'b00_01: rho_amt = 7'd14;
                4'b00_10: rho_amt = 7'd20;
                4'b00_11: rho_amt = 7'd22;

                // r = 1: {0, 13, 68, 91}
                4'b01_00: rho_amt = 7'd0;
                4'b01_01: rho_amt = 7'd13;
                4'b01_10: rho_amt = 7'd68;
                4'b01_11: rho_amt = 7'd91;

                // r = 2: {0, 27, 42, 106}
                4'b10_00: rho_amt = 7'd0;
                4'b10_01: rho_amt = 7'd27;
                4'b10_10: rho_amt = 7'd42;
                4'b10_11: rho_amt = 7'd106;

                // r = 3: {0, 32, 48, 80}
                4'b11_00: rho_amt = 7'd0;
                4'b11_01: rho_amt = 7'd32;
                4'b11_10: rho_amt = 7'd48;
                4'b11_11: rho_amt = 7'd80;

                default:  rho_amt = 7'd0;
            endcase
        end
    endfunction

    genvar x, y;

    generate
        for (x = 0; x < 4; x = x + 1) begin : sr_x
            for (y = 0; y < 4; y = y + 1) begin : sr_y
                assign state_out[128*(x*4 + y) +: 128] =
                    rotr128(
                        state_in[128*(x*4 + y) +: 128],
                        rho_amt(round_id[1:0], y[1:0])
                    );
            end
        end
    endgenerate

endmodule