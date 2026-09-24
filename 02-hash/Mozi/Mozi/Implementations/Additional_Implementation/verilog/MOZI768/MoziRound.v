module round (
    input  wire [2047:0] state_in,
    input  wire [4:0]    round_id,
    output wire [2047:0] state_out
);

wire [2047:0] state_after_sbox;
wire [2047:0] state_after_mc;
wire [2047:0] state_after_sr;
wire [7:0] rc;

/* S-box layer */
sbox_layer u_sbox_layer (
    .state_in  (state_in),
    .state_out (state_after_sbox)
);

/* MixColumn layer */
mc_layer u_mc_layer (
    .state_in  (state_after_sbox),
    .state_out (state_after_mc)
);

/* ShiftRow layer */
shiftrow u_shiftrow (
    .state_in  (state_after_mc),
    .round_id  (round_id),
    .state_out (state_after_sr)
);

/* Round constant generation */
round_constant u_round_constant (
    .round_id (round_id),
    .rc       (rc)
);

reg [2047:0] ac_out;

always @(*) begin
    ac_out = state_after_sr;
    ac_out[1927:1920] = state_after_sr[1927:1920] ^ rc;
end

/* AddConstant */
assign state_out = ac_out;

endmodule