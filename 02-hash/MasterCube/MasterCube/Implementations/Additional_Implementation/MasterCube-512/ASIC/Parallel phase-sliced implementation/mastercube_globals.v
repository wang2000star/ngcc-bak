// MasterCube Hash Algorithm - Global Constants and Parameters
// Verilog-2001 implementation

// State dimensions
`define STATE_BITS   1536  // 12 * 8 * 16 = 1536 bits

// Round constants (16-bit values, little-endian from C)
`define RC0  16'h7344
`define RC1  16'h0370
`define RC2  16'h8A2E
`define RC3  16'h1319
`define RC4  16'h08D3
`define RC5  16'h85A3
`define RC6  16'h6A88
`define RC7  16'h243F

// Digest size encoding. Encoding 2'd0 is reserved and maps to 512-bit
// behavior in the top-level default case.
`define DIGEST_512   2'd1
`define DIGEST_768   2'd2
`define DIGEST_1024  2'd3

// Rate in 64-bit words
`define RATE_WORDS_512   15   // 960/64
`define RATE_WORDS_768   11   // 704/64
`define RATE_WORDS_1024  7    // 448/64

// Number of rounds
`define N_ROUNDS_HALF 9
