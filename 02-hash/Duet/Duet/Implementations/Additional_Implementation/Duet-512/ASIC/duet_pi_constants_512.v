//======================================================================
//
// duet_pi_constants_512.v
// --------------------
// The table PI with round constants for the Duet-512 permutation960
// round function (fractional part of pi). 24 entries: PI[0..11] are
// used by f1, PI[12..23] by f2. Modelled after the SHA-512/Cuishen
// style sha512_k_constants.v: a simple combinational ROM addressed by
// an absolute index (round + base, where base = 0 for f1, 12 for f2).
//
//======================================================================

`default_nettype none

module duet_pi_constants(
                         input wire  [4 : 0]  addr,
                         output wire [63 : 0] PI
                        );

  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [63 : 0] tmp_PI;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign PI = tmp_PI;


  //----------------------------------------------------------------
  // addr_mux
  //----------------------------------------------------------------
  always @*
    begin : addr_mux
      case(addr)
        0: tmp_PI = 64'h243f6a8885a308d3;
        1: tmp_PI = 64'h13198a2e03707344;
        2: tmp_PI = 64'ha4093822299f31d0;
        3: tmp_PI = 64'h082efa98ec4e6c89;
        4: tmp_PI = 64'h452821e638d01377;
        5: tmp_PI = 64'hbe5466cf34e90c6c;
        6: tmp_PI = 64'hc0ac29b7c97c50dd;
        7: tmp_PI = 64'h3f84d5b5b5470917;
        8: tmp_PI = 64'h9216d5d98979fb1b;
        9: tmp_PI = 64'hd1310ba698dfb5ac;
        10: tmp_PI = 64'h2ffd72dbd01adfb7;
        11: tmp_PI = 64'hb8e1afed6a267e96;
        12: tmp_PI = 64'hba7c9045f12c7f99;
        13: tmp_PI = 64'h24a19947b3916cf7;
        14: tmp_PI = 64'h0801f2e2858efc16;
        15: tmp_PI = 64'h636920d871574e69;
        16: tmp_PI = 64'ha458fea3f4933d7e;
        17: tmp_PI = 64'h0d95748f728eb658;
        18: tmp_PI = 64'h718bcd5882154aee;
        19: tmp_PI = 64'h7b54a41dc25a59b5;
        20: tmp_PI = 64'h9c30d5392af26013;
        21: tmp_PI = 64'hc5d1b023286085f0;
        22: tmp_PI = 64'hca417918b8db38ef;
        23: tmp_PI = 64'h8e79dcb0603a180e;

        default:
          tmp_PI = 64'h0;
      endcase // case (addr)
    end // block: addr_mux
endmodule // duet_pi_constants

//======================================================================
// EOF duet_pi_constants.v
//======================================================================
