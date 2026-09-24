module round_constant (
    input  wire [4:0] round_id,
    output reg  [7:0] rc
);

always @(*) begin
    case (round_id)
        5'd0:  rc = 8'h24;
        5'd1:  rc = 8'h3f;
        5'd2:  rc = 8'h6a;
        5'd3:  rc = 8'h88;
        5'd4:  rc = 8'h85;
        5'd5:  rc = 8'ha3;
        5'd6:  rc = 8'h08;
        5'd7:  rc = 8'hd3;
        5'd8:  rc = 8'h13;
        5'd9:  rc = 8'h19;
        5'd10: rc = 8'h8a;
        5'd11: rc = 8'h2e;
        5'd12: rc = 8'h03;
        5'd13: rc = 8'h70;
        5'd14: rc = 8'h73;
        5'd15: rc = 8'h44;
        5'd16: rc = 8'ha4;
        5'd17: rc = 8'h09;
        5'd18: rc = 8'h38;
        5'd19: rc = 8'h22;
        5'd20: rc = 8'h29;
        5'd21: rc = 8'h9f;
        5'd22: rc = 8'h31;
        5'd23: rc = 8'hd0;
        default: rc = 8'h00;
    endcase
end

endmodule