package zen_ntt_const_pkg;

  function automatic logic signed [15:0] get_f(input int idx);
    case (idx)
      0: get_f=16'sd171; 1: get_f=16'sd605; 2: get_f=16'sd688; 3: get_f=16'sd361;
      4: get_f=16'sd186; 5: get_f=16'sd766; 6: get_f=16'sd519; 7: get_f=16'sd649;
      8: get_f=16'sd461; 9: get_f=16'sd129; 10: get_f=16'sd753; 11: get_f=16'sd546;
      12: get_f=16'sd407; 13: get_f=16'sd626; 14: get_f=16'sd131; 15: get_f=16'sd432;
      16: get_f=16'sd693; 17: get_f=16'sd671; 18: get_f=16'sd36; 19: get_f=16'sd694;
      20: get_f=16'sd430; 21: get_f=16'sd514; 22: get_f=16'sd282; 23: get_f=16'sd566;
      24: get_f=16'sd735; 25: get_f=16'sd199; 26: get_f=16'sd178; 27: get_f=16'sd270;
      28: get_f=16'sd759; 29: get_f=16'sd149; 30: get_f=16'sd369; 31: get_f=16'sd577;
      32: get_f=16'sd147; 33: get_f=16'sd655; 34: get_f=16'sd497; 35: get_f=16'sd54;
      36: get_f=16'sd767; 37: get_f=16'sd645; 38: get_f=16'sd689; 39: get_f=16'sd423;
      40: get_f=16'sd86; 41: get_f=16'sd718; 42: get_f=16'sd364; 43: get_f=16'sd267;
      44: get_f=16'sd161; 45: get_f=16'sd754; 46: get_f=16'sd288; 47: get_f=16'sd169;
      48: get_f=16'sd191; 49: get_f=16'sd307; 50: get_f=16'sd719; 51: get_f=16'sd745;
      52: get_f=16'sd599; 53: get_f=16'sd226; 54: get_f=16'sd121; 55: get_f=16'sd581;
      56: get_f=16'sd389; 57: get_f=16'sd279; 58: get_f=16'sd180; 59: get_f=16'sd394;
      60: get_f=16'sd612; 61: get_f=16'sd263; 62: get_f=16'sd641; 63: get_f=16'sd523;
      64: get_f=16'sd746; 65: get_f=16'sd112; 66: get_f=16'sd618; 67: get_f=16'sd635;
      68: get_f=16'sd717; 69: get_f=16'sd621; 70: get_f=16'sd227; 71: get_f=16'sd232;
      72: get_f=16'sd698; 73: get_f=16'sd212; 74: get_f=16'sd236; 75: get_f=16'sd21;
      76: get_f=16'sd341; 77: get_f=16'sd379; 78: get_f=16'sd567; 79: get_f=16'sd549;
      80: get_f=16'sd352; 81: get_f=16'sd292; 82: get_f=16'sd238; 83: get_f=16'sd145;
      84: get_f=16'sd194; 85: get_f=16'sd493; 86: get_f=16'sd70; 87: get_f=16'sd495;
      88: get_f=16'sd117; 89: get_f=16'sd333; 90: get_f=16'sd66; 91: get_f=16'sd247;
      92: get_f=16'sd532; 93: get_f=16'sd686; 94: get_f=16'sd517; 95: get_f=16'sd525;
      96: get_f=16'sd331; 97: get_f=16'sd528; 98: get_f=16'sd167; 99: get_f=16'sd357;
      100: get_f=16'sd414; 101: get_f=16'sd291; 102: get_f=16'sd411; 103: get_f=16'sd105;
      104: get_f=16'sd654; 105: get_f=16'sd560; 106: get_f=16'sd14; 107: get_f=16'sd99;
      108: get_f=16'sd509; 109: get_f=16'sd29; 110: get_f=16'sd366; 111: get_f=16'sd391;
      112: get_f=16'sd451; 113: get_f=16'sd278; 114: get_f=16'sd353; 115: get_f=16'sd354;
      116: get_f=16'sd585; 117: get_f=16'sd127; 118: get_f=16'sd330; 119: get_f=16'sd466;
      120: get_f=16'sd222; 121: get_f=16'sd691; 122: get_f=16'sd421; 123: get_f=16'sd725;
      124: get_f=16'sd201; 125: get_f=16'sd158; 126: get_f=16'sd350; 127: get_f=16'sd168;
      default: get_f = 16'sd0;
    endcase
  endfunction

  function automatic logic signed [15:0] get_fn(input int idx);
    case (idx)
      0: get_fn=16'sd601; 1: get_fn=16'sd419; 2: get_fn=16'sd611; 3: get_fn=16'sd568;
      4: get_fn=16'sd44; 5: get_fn=16'sd348; 6: get_fn=16'sd78; 7: get_fn=16'sd547;
      8: get_fn=16'sd303; 9: get_fn=16'sd439; 10: get_fn=16'sd642; 11: get_fn=16'sd184;
      12: get_fn=16'sd415; 13: get_fn=16'sd416; 14: get_fn=16'sd491; 15: get_fn=16'sd318;
      16: get_fn=16'sd378; 17: get_fn=16'sd403; 18: get_fn=16'sd740; 19: get_fn=16'sd260;
      20: get_fn=16'sd670; 21: get_fn=16'sd755; 22: get_fn=16'sd209; 23: get_fn=16'sd115;
      24: get_fn=16'sd664; 25: get_fn=16'sd358; 26: get_fn=16'sd478; 27: get_fn=16'sd355;
      28: get_fn=16'sd412; 29: get_fn=16'sd602; 30: get_fn=16'sd241; 31: get_fn=16'sd438;
      32: get_fn=16'sd244; 33: get_fn=16'sd252; 34: get_fn=16'sd83; 35: get_fn=16'sd237;
      36: get_fn=16'sd522; 37: get_fn=16'sd703; 38: get_fn=16'sd436; 39: get_fn=16'sd652;
      40: get_fn=16'sd274; 41: get_fn=16'sd699; 42: get_fn=16'sd276; 43: get_fn=16'sd575;
      44: get_fn=16'sd624; 45: get_fn=16'sd531; 46: get_fn=16'sd477; 47: get_fn=16'sd417;
      48: get_fn=16'sd220; 49: get_fn=16'sd202; 50: get_fn=16'sd390; 51: get_fn=16'sd428;
      52: get_fn=16'sd748; 53: get_fn=16'sd533; 54: get_fn=16'sd557; 55: get_fn=16'sd71;
      56: get_fn=16'sd537; 57: get_fn=16'sd542; 58: get_fn=16'sd148; 59: get_fn=16'sd52;
      60: get_fn=16'sd134; 61: get_fn=16'sd151; 62: get_fn=16'sd657; 63: get_fn=16'sd23;
      64: get_fn=16'sd246; 65: get_fn=16'sd128; 66: get_fn=16'sd506; 67: get_fn=16'sd157;
      68: get_fn=16'sd375; 69: get_fn=16'sd589; 70: get_fn=16'sd490; 71: get_fn=16'sd380;
      72: get_fn=16'sd188; 73: get_fn=16'sd648; 74: get_fn=16'sd543; 75: get_fn=16'sd170;
      76: get_fn=16'sd24; 77: get_fn=16'sd50; 78: get_fn=16'sd462; 79: get_fn=16'sd578;
      80: get_fn=16'sd600; 81: get_fn=16'sd481; 82: get_fn=16'sd15; 83: get_fn=16'sd608;
      84: get_fn=16'sd502; 85: get_fn=16'sd405; 86: get_fn=16'sd51; 87: get_fn=16'sd683;
      88: get_fn=16'sd346; 89: get_fn=16'sd80; 90: get_fn=16'sd124; 91: get_fn=16'sd2;
      92: get_fn=16'sd715; 93: get_fn=16'sd272; 94: get_fn=16'sd114; 95: get_fn=16'sd622;
      96: get_fn=16'sd192; 97: get_fn=16'sd400; 98: get_fn=16'sd620; 99: get_fn=16'sd10;
      100: get_fn=16'sd499; 101: get_fn=16'sd591; 102: get_fn=16'sd570; 103: get_fn=16'sd34;
      104: get_fn=16'sd203; 105: get_fn=16'sd487; 106: get_fn=16'sd255; 107: get_fn=16'sd339;
      108: get_fn=16'sd75; 109: get_fn=16'sd733; 110: get_fn=16'sd98; 111: get_fn=16'sd76;
      112: get_fn=16'sd337; 113: get_fn=16'sd638; 114: get_fn=16'sd143; 115: get_fn=16'sd362;
      116: get_fn=16'sd223; 117: get_fn=16'sd16; 118: get_fn=16'sd640; 119: get_fn=16'sd308;
      120: get_fn=16'sd120; 121: get_fn=16'sd250; 122: get_fn=16'sd3; 123: get_fn=16'sd583;
      124: get_fn=16'sd408; 125: get_fn=16'sd81; 126: get_fn=16'sd164; 127: get_fn=16'sd655;
      default: get_fn = 16'sd0;
    endcase
  endfunction

  function automatic logic signed [15:0] montgomery_reduce(input logic signed [31:0] a);
    logic signed [15:0] u;
    logic signed [31:0] t;
    begin
      u = a * (-16'sd767);
      t = a - (u * 16'sd769);
      montgomery_reduce = t >>> 16;
    end
  endfunction

  function automatic logic signed [15:0] fqmul(input logic signed [15:0] a, input logic signed [15:0] b);
    begin
      fqmul = montgomery_reduce(a * b);
    end
  endfunction

  function automatic logic signed [15:0] norm_q(input logic signed [15:0] a);
    logic signed [15:0] t;
    begin
      t = a;
      norm_q = t + ((t >>> 15) & 16'sd769);
    end
  endfunction

  function automatic logic [15:0] inv_mod_q(input integer x);
    integer k;
    begin
      inv_mod_q = 16'd0;
      if (x != 0) begin
        for (k = 1; k < 769; k = k + 1) begin
          if (((x * k) % 769) == 1) begin
            inv_mod_q = k[15:0];
          end
        end
      end
    end
  endfunction

endpackage
