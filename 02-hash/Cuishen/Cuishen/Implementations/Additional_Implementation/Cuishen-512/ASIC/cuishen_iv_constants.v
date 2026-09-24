//======================================================================
//
// cuishen_iv_constants.v
// ----------------------
// The initial chaining values IV_1 (-> t) and IV_2 (-> b) for the
// Cuishen-512 hash. Modelled after sha512_h_constants.v: a purely
// combinational constant provider. Cuishen has a single mode, so the
// outputs are fixed.
//
//======================================================================

`default_nettype none

module cuishen_iv_constants(
                            // t = IV_1 (top / upper chaining value, 256 bit)
                            output wire [63 : 0] T0,
                            output wire [63 : 0] T1,
                            output wire [63 : 0] T2,
                            output wire [63 : 0] T3,
                            // b = IV_2 (bottom / lower chaining value, 256 bit)
                            output wire [63 : 0] B0,
                            output wire [63 : 0] B1,
                            output wire [63 : 0] B2,
                            output wire [63 : 0] B3
                           );

  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign T0 = 64'h0cc4a61194f81760;
  assign T1 = 64'h5815a7be0543c11c;
  assign T2 = 64'h70b7ed67fc9b5c42;
  assign T3 = 64'ha1513c69681ad6d4;

  assign B0 = 64'h44f9363580e83d02;
  assign B1 = 64'h720dcdfd9dba5b44;
  assign B2 = 64'hb467369e08efd70e;
  assign B3 = 64'hca320b75e2b634f9;

endmodule // cuishen_iv_constants

//======================================================================
// EOF cuishen_iv_constants.v
//======================================================================
