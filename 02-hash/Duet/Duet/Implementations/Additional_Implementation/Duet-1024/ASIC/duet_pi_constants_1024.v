//======================================================================
//
// duet_pi_constants_768.v
// ------------------------
// The table E with round constants for the Duet-768/1024 permutation1920
// round function (fractional part of e). 36 entries: E[0..17] are used
// by f1, E[18..35] by f2. Modelled after the Duet-512 style
// duet_pi_constants.v: a simple combinational ROM addressed by an
// absolute index (round + base, where base = 0 for f1, 18 for f2).
//
//======================================================================

`default_nettype none

module duet_pi_constants_768(
                             input wire  [5 : 0]  addr,
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
        0: tmp_PI = 64'hb7e151628aed2a6a;
        1: tmp_PI = 64'hbf7158809cf4f3c7;
        2: tmp_PI = 64'h62e7160f38b4da56;
        3: tmp_PI = 64'ha784d9045190cfef;
        4: tmp_PI = 64'h324e7738926cfbe5;
        5: tmp_PI = 64'hf4bf8d8d8c31d763;
        6: tmp_PI = 64'hda06c80abb1185eb;
        7: tmp_PI = 64'h4f7c7b5757f59584;
        8: tmp_PI = 64'h90cfd47d7c19bb42;
        9: tmp_PI = 64'h158d9554f7b46bce;
        10: tmp_PI = 64'hd55c4d79fd5f24d6;
        11: tmp_PI = 64'h613c31c3839a2ddf;
        12: tmp_PI = 64'h8a9a276bcfbfa1c8;
        13: tmp_PI = 64'h77c56284dab79cd4;
        14: tmp_PI = 64'hc2b3293d20e9e5ea;
        15: tmp_PI = 64'hf02ac60acc93ed87;
        16: tmp_PI = 64'h4422a52ecb238fee;
        17: tmp_PI = 64'he5ab6add835fd1a0;
        18: tmp_PI = 64'h753d0a8f78e537d2;
        19: tmp_PI = 64'hb95bb79d8dcaec64;
        20: tmp_PI = 64'h2c1e9f23b829b5c2;
        21: tmp_PI = 64'h780bf38737df8bb3;
        22: tmp_PI = 64'h00d01334a0d0bd86;
        23: tmp_PI = 64'h45cbfa73a6160ffe;
        24: tmp_PI = 64'h393c48cbbbca060f;
        25: tmp_PI = 64'h0ff8ec6d31beb5cc;
        26: tmp_PI = 64'heed7f2f0bb088017;
        27: tmp_PI = 64'h163bc60df45a0ecb;
        28: tmp_PI = 64'h1bcd289b06cbbfea;
        29: tmp_PI = 64'h21ad08e1847f3f73;
        30: tmp_PI = 64'h78d56ced94640d6e;
        31: tmp_PI = 64'hf0d3d37be67008e1;
        32: tmp_PI = 64'h86d1bf275b9b241d;
        33: tmp_PI = 64'heb64749a47dfdfb9;
        34: tmp_PI = 64'h6632c3eb061b6472;
        35: tmp_PI = 64'hbbf84c26144e49c2;

        default:
          tmp_PI = 64'h0;
      endcase // case (addr)
    end // block: addr_mux
endmodule // duet_pi_constants_768

//======================================================================
// EOF duet_pi_constants_768.v
//======================================================================
