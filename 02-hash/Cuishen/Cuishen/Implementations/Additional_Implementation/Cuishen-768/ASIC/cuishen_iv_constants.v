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
  assign T0 = 64'h34e0d42e61a33f99;
  assign T1 = 64'h87abb9f2087207ed;
  assign T2 = 64'hec3fc3f38a10ea02;
  assign T3 = 64'h610bebf29db2faf5;
  assign T4 = 64'h7420b49edc5a21ee;
  assign T5 = 64'hd1fd8a3396bdeee8;
  assign T6 = 64'h092197f60194adc1;
  assign T7 = 64'h1b530c95f8b3def8;

  assign B0 = 64'h869d6342f6d22822;
  assign B1 = 64'h11076689f6aff6b0;
  assign B2 = 64'h43ab9fb62162bb7f;
  assign B3 = 64'h75a9f91d5813e9e8;
  assign B4 = 64'hd7cd8173f479197a;
  assign B5 = 64'h07fe00ff606fac41;
  assign B6 = 64'h379f513f856fc7a9;
  assign B7 = 64'h66b651a8ab0e883b;

endmodule // cuishen_iv_constants

//======================================================================
// EOF cuishen_iv_constants.v
//======================================================================
