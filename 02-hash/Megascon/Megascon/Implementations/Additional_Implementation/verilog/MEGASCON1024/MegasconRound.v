module round (
    input  wire [2047:0] state_in,
    input  wire [3:0]    round_id,
    output wire [2047:0] state_out
);

wire [2047:0] state_after_sbox;
wire [2047:0] state_after_pi;
wire [2047:0] state_after_l;

/* S-box layer */
sbox_layer u_sbox_layer (
    .state_in  (state_in),
    .state_out (state_after_sbox)
);

/* PI layer */
pi_layer u_pi_layer (
    .state_in  (state_after_sbox),
    .state_out (state_after_pi)
);

/* L layer */
l_layer u_L (
    .state_in  (state_after_pi),
    .state_out (state_after_l)
);

/* AddConstant */
constant_layer u_constant_layer (
    .state_in  (state_after_l),
    .round_id  (round_id),
    .state_out (state_out)
);

endmodule