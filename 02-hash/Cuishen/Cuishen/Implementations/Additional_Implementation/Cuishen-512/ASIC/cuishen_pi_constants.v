//======================================================================
//
// cuishen_pi_constants.v
// ----------------------
// The table PI with round constants for the Cuishen-512 block cipher
// round function. Modelled after sha512_k_constants.v: a simple
// combinational ROM addressed by the round counter.
//
//======================================================================

`default_nettype none

module cuishen_pi_constants(
                            input wire  [6 : 0]  addr,
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
        0:  tmp_PI = 64'h243f6a8885a308d3;
        1:  tmp_PI = 64'h13198a2e03707344;
        2:  tmp_PI = 64'ha4093822299f31d0;
        3:  tmp_PI = 64'h082efa98ec4e6c89;
        4:  tmp_PI = 64'h452821e638d01377;
        5:  tmp_PI = 64'hbe5466cf34e90c6c;
        6:  tmp_PI = 64'hc0ac29b7c97c50dd;
        7:  tmp_PI = 64'h3f84d5b5b5470917;
        8:  tmp_PI = 64'h9216d5d98979fb1b;
        9:  tmp_PI = 64'hd1310ba698dfb5ac;
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
        24: tmp_PI = 64'h6c9e0e8bb01e8a3e;
        25: tmp_PI = 64'hd71577c1bd314b27;
        26: tmp_PI = 64'h78af2fda55605c60;
        27: tmp_PI = 64'he65525f3aa55ab94;
        28: tmp_PI = 64'h5748986263e81440;
        29: tmp_PI = 64'h55ca396a2aab10b6;
        30: tmp_PI = 64'hb4cc5c341141e8ce;
        31: tmp_PI = 64'ha15486af7c72e993;
        32: tmp_PI = 64'hb3ee1411636fbc2a;
        33: tmp_PI = 64'h2ba9c55d741831f6;
        34: tmp_PI = 64'hce5c3e169b87931e;
        35: tmp_PI = 64'hafd6ba336c24cf5c;
        36: tmp_PI = 64'h7a32538128958677;
        37: tmp_PI = 64'h3b8f48986b4bb9af;
        38: tmp_PI = 64'hc4bfe81b66282193;
        39: tmp_PI = 64'h61d809ccfb21a991;
        40: tmp_PI = 64'h487cac605dec8032;
        41: tmp_PI = 64'hef845d5de98575b1;
        42: tmp_PI = 64'hdc262302eb651b88;
        43: tmp_PI = 64'h23893e81d396acc5;
        44: tmp_PI = 64'h0f6d6ff383f44239;
        45: tmp_PI = 64'h2e0b4482a4842004;
        46: tmp_PI = 64'h69c8f04a9e1f9b5e;
        47: tmp_PI = 64'h21c66842f6e96c9a;
        48: tmp_PI = 64'h670c9c61abd388f0;
        49: tmp_PI = 64'h6a51a0d2d8542f68;
        50: tmp_PI = 64'h960fa728ab5133a3;
        51: tmp_PI = 64'h6eef0b6c137a3be4;
        52: tmp_PI = 64'hba3bf0507efb2a98;
        53: tmp_PI = 64'ha1f1651d39af0176;
        54: tmp_PI = 64'h66ca593e82430e88;
        55: tmp_PI = 64'h8cee8619456f9fb4;
        56: tmp_PI = 64'h7d84a5c33b8b5ebe;
        57: tmp_PI = 64'he06f75d885c12073;
        58: tmp_PI = 64'h401a449f56c16aa6;
        59: tmp_PI = 64'h4ed3aa62363f7706;
        60: tmp_PI = 64'h1bfedf72429b023d;
        61: tmp_PI = 64'h37d0d724d00a1248;
        62: tmp_PI = 64'hdb0fead349f1c09b;
        63: tmp_PI = 64'h075372c980991b7b;

        default:
          tmp_PI = 64'h0;
      endcase // case (addr)
    end // block: addr_mux
endmodule // cuishen_pi_constants

//======================================================================
// EOF cuishen_pi_constants.v
//======================================================================
