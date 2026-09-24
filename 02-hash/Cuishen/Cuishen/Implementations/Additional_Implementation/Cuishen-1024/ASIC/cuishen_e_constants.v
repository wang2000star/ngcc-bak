//======================================================================
//
// cuishen_e_constants.v
// ----------------------
// The table E_CONST with round constants for the Cuishen-1024 block
// cipher round function (fractional part of the natural log base e).
// 64 entries (ROUNDS=64), per CryptHash_Cuishen-1024v5.c. Modelled
// after the 512-bit design's cuishen_pi_constants.v: a simple
// combinational ROM addressed by the round counter.
//
//======================================================================

`default_nettype none

module cuishen_e_constants(
                           input wire  [6 : 0]  addr,
                           output wire [63 : 0] E_CONST
                          );

  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [63 : 0] tmp_E;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign E_CONST = tmp_E;


  //----------------------------------------------------------------
  // addr_mux
  //----------------------------------------------------------------
  always @*
    begin : addr_mux
      case(addr)
        0: tmp_E = 64'hb7e151628aed2a6a;
        1: tmp_E = 64'hbf7158809cf4f3c7;
        2: tmp_E = 64'h62e7160f38b4da56;
        3: tmp_E = 64'ha784d9045190cfef;
        4: tmp_E = 64'h324e7738926cfbe5;
        5: tmp_E = 64'hf4bf8d8d8c31d763;
        6: tmp_E = 64'hda06c80abb1185eb;
        7: tmp_E = 64'h4f7c7b5757f59584;
        8: tmp_E = 64'h90cfd47d7c19bb42;
        9: tmp_E = 64'h158d9554f7b46bce;
        10: tmp_E = 64'hd55c4d79fd5f24d6;
        11: tmp_E = 64'h613c31c3839a2ddf;
        12: tmp_E = 64'h8a9a276bcfbfa1c8;
        13: tmp_E = 64'h77c56284dab79cd4;
        14: tmp_E = 64'hc2b3293d20e9e5ea;
        15: tmp_E = 64'hf02ac60acc93ed87;
        16: tmp_E = 64'h4422a52ecb238fee;
        17: tmp_E = 64'he5ab6add835fd1a0;
        18: tmp_E = 64'h753d0a8f78e537d2;
        19: tmp_E = 64'hb95bb79d8dcaec64;
        20: tmp_E = 64'h2c1e9f23b829b5c2;
        21: tmp_E = 64'h780bf38737df8bb3;
        22: tmp_E = 64'h00d01334a0d0bd86;
        23: tmp_E = 64'h45cbfa73a6160ffe;
        24: tmp_E = 64'h393c48cbbbca060f;
        25: tmp_E = 64'h0ff8ec6d31beb5cc;
        26: tmp_E = 64'heed7f2f0bb088017;
        27: tmp_E = 64'h163bc60df45a0ecb;
        28: tmp_E = 64'h1bcd289b06cbbfea;
        29: tmp_E = 64'h21ad08e1847f3f73;
        30: tmp_E = 64'h78d56ced94640d6e;
        31: tmp_E = 64'hf0d3d37be67008e1;
        32: tmp_E = 64'h86d1bf275b9b241d;
        33: tmp_E = 64'heb64749a47dfdfb9;
        34: tmp_E = 64'h6632c3eb061b6472;
        35: tmp_E = 64'hbbf84c26144e49c2;
        36: tmp_E = 64'hd04c324ef10de513;
        37: tmp_E = 64'hd3f5114b8b5d374d;
        38: tmp_E = 64'h93cb8879c7d52ffd;
        39: tmp_E = 64'h72ba0aae7277da7b;
        40: tmp_E = 64'ha1b4af1488d8e836;
        41: tmp_E = 64'haf14865e6c37ab68;
        42: tmp_E = 64'h76fe690b57112138;
        43: tmp_E = 64'h2af341afe94f77bc;
        44: tmp_E = 64'hf06c83b8ff5675f0;
        45: tmp_E = 64'h979074ad9a787bc5;
        46: tmp_E = 64'hb9bd4b0c5937d3ed;
        47: tmp_E = 64'he4c3a79396215eda;
        48: tmp_E = 64'hb1f57d0b5a7db461;
        49: tmp_E = 64'hdd8f3c75540d0012;
        50: tmp_E = 64'h1fd56e95f8c731e9;
        51: tmp_E = 64'hc4d7221bbed0c62b;
        52: tmp_E = 64'hb5a87804b679a0ca;
        53: tmp_E = 64'ha41d802a4604c311;
        54: tmp_E = 64'hb71de3e5c6b400e0;
        55: tmp_E = 64'h24a6668ccf2e2de8;
        56: tmp_E = 64'h6876e4f5c50000f0;
        57: tmp_E = 64'ha93b3aa7e6342b30;
        58: tmp_E = 64'h2a0a47373b25f73e;
        59: tmp_E = 64'h3b26d569fe2291ad;
        60: tmp_E = 64'h36d6a147d1060b87;
        61: tmp_E = 64'h1a2801f978376408;
        62: tmp_E = 64'h2ff592d9140db1e9;
        63: tmp_E = 64'h399df4b0e14ca8e8;

        default:
          tmp_E = 64'h0;
      endcase // case (addr)
    end // block: addr_mux
endmodule // cuishen_e_constants

//======================================================================
// EOF cuishen_e_constants.v
//======================================================================
