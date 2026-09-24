// MasterCube global constants for full-state round-level datapath.
// The command/top-level digest selection logic is kept in mastercube.v.

`ifndef MASTERCUBE_GLOBALS_V
`define MASTERCUBE_GLOBALS_V

`define STATE_BITS   1536

`define RC0  16'h7344
`define RC1  16'h0370
`define RC2  16'h8A2E
`define RC3  16'h1319
`define RC4  16'h08D3
`define RC5  16'h85A3
`define RC6  16'h6A88
`define RC7  16'h243F

`define DIGEST_512   2'd1
`define DIGEST_768   2'd2
`define DIGEST_1024  2'd3

`define RATE_WORDS_512   15
`define RATE_WORDS_768   11
`define RATE_WORDS_1024  7

`define N_ROUNDS_HALF 9

`endif
