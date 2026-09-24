//======================================================================
//
// cuishen_iv_constants.v
// ----------------------
// The initial chaining values for the Cuishen-1024 hash. t (upper) is
// initialised from IV_1, b (lower) from IV_2 -- two DISTINCT 512-bit
// constants, per CryptHash_Cuishen-1024v5.c (copy_words_512(t, IV_1);
// copy_words_512(b, IV_2);). Modelled after the 512-bit design's
// cuishen_iv_constants.v: a purely combinational constant provider.
//
//======================================================================

`default_nettype none

module cuishen_iv_constants(
                            // t = IV_1 (top / upper chaining value, 512 bit)
                            output wire [63 : 0] T0,
                            output wire [63 : 0] T1,
                            output wire [63 : 0] T2,
                            output wire [63 : 0] T3,
                            output wire [63 : 0] T4,
                            output wire [63 : 0] T5,
                            output wire [63 : 0] T6,
                            output wire [63 : 0] T7,
                            // b = IV_2 (bottom / lower chaining value, 512 bit)
                            output wire [63 : 0] B0,
                            output wire [63 : 0] B1,
                            output wire [63 : 0] B2,
                            output wire [63 : 0] B3,
                            output wire [63 : 0] B4,
                            output wire [63 : 0] B5,
                            output wire [63 : 0] B6,
                            output wire [63 : 0] B7
                           );

  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign T0 = 64'hc3578c15393dbe7b;
  assign T1 = 64'h1e039f40ee65e7f5;
  assign T2 = 64'h857b7bee690d3012;
  assign T3 = 64'ha29bf2defe493534;
  assign T4 = 64'hcdf34e803fd487d1;
  assign T5 = 64'h5b89092b8fbef3e8;
  assign T6 = 64'ha0c06a13c70b322b;
  assign T7 = 64'hc9cda6892035228a;

  assign B0 = 64'hf281f2397b1d4610;
  assign B1 = 64'h77c9c2114e14fd92;
  assign B2 = 64'hb91bf663f039c764;
  assign B3 = 64'h066560954a8e8129;
  assign B4 = 64'h39479381ecbce703;
  assign B5 = 64'h7830769755fe0b0a;
  assign B6 = 64'hc2b2b7559233f645;
  assign B7 = 64'h0c2d3b4be1707aba;

endmodule // cuishen_iv_constants

//======================================================================
// EOF cuishen_iv_constants.v
//======================================================================
