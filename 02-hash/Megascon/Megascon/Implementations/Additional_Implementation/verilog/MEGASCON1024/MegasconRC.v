module constant_layer (
    input  wire [2047:0] state_in,
    input  wire [3:0]    round_id,
    output wire [2047:0] state_out
);

    reg [63:0] rc;

    always @(*) begin
        case (round_id)
            4'd0:  rc = 64'he220a8397b1dcdaf;
            4'd1:  rc = 64'he4d971771b652c20;
            4'd2:  rc = 64'h975835de1c9756ce;
            4'd3:  rc = 64'h910a2dec89025cc1;
            4'd4:  rc = 64'hc164bb7b2b9b3e3a;
            4'd5:  rc = 64'h16b1cba95fc60262;
            4'd6:  rc = 64'hf3203e9039f4a821;
            4'd7:  rc = 64'hf75f04cbb5a1a1dd;
            4'd8:  rc = 64'h9e5651b0ef953636;
            4'd9:  rc = 64'h63cbe1e459320dd7;
            4'd10: rc = 64'h088712be8a582fca;
            4'd11: rc = 64'haeaf52febe706064;
            4'd12: rc = 64'h6e73e372e2338aca;
            4'd13: rc = 64'h1d0b14e4db018fed;
            4'd14: rc = 64'hbd64a5d9adefe000;
            4'd15: rc = 64'h63033b0ca389c35a;
            default: rc = 64'h0000000000000000;
        endcase
    end

    assign state_out = state_in ^ {1984'd0, rc};

endmodule