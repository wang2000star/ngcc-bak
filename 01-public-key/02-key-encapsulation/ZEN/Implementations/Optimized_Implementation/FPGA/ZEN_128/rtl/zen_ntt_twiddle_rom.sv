module zen_ntt_twiddle_rom (
  input  logic        inverse,
  input  logic [6:0]  addr,
  output logic [15:0] twiddle
);

  logic [15:0] f_rom [0:127];
  logic [15:0] fn_rom [0:127];

  initial begin
    f_rom[0]=16'd171; f_rom[1]=16'd605; f_rom[2]=16'd688; f_rom[3]=16'd361;
    f_rom[4]=16'd186; f_rom[5]=16'd766; f_rom[6]=16'd519; f_rom[7]=16'd649;
    f_rom[8]=16'd461; f_rom[9]=16'd129; f_rom[10]=16'd753; f_rom[11]=16'd546;
    f_rom[12]=16'd407; f_rom[13]=16'd626; f_rom[14]=16'd131; f_rom[15]=16'd432;
    f_rom[16]=16'd693; f_rom[17]=16'd671; f_rom[18]=16'd36; f_rom[19]=16'd694;
    f_rom[20]=16'd430; f_rom[21]=16'd514; f_rom[22]=16'd282; f_rom[23]=16'd566;
    f_rom[24]=16'd735; f_rom[25]=16'd199; f_rom[26]=16'd178; f_rom[27]=16'd270;
    f_rom[28]=16'd759; f_rom[29]=16'd149; f_rom[30]=16'd369; f_rom[31]=16'd577;
    f_rom[32]=16'd147; f_rom[33]=16'd655; f_rom[34]=16'd497; f_rom[35]=16'd54;
    f_rom[36]=16'd767; f_rom[37]=16'd645; f_rom[38]=16'd689; f_rom[39]=16'd423;
    f_rom[40]=16'd86; f_rom[41]=16'd718; f_rom[42]=16'd364; f_rom[43]=16'd267;
    f_rom[44]=16'd161; f_rom[45]=16'd754; f_rom[46]=16'd288; f_rom[47]=16'd169;
    f_rom[48]=16'd191; f_rom[49]=16'd307; f_rom[50]=16'd719; f_rom[51]=16'd745;
    f_rom[52]=16'd599; f_rom[53]=16'd226; f_rom[54]=16'd121; f_rom[55]=16'd581;
    f_rom[56]=16'd389; f_rom[57]=16'd279; f_rom[58]=16'd180; f_rom[59]=16'd394;
    f_rom[60]=16'd612; f_rom[61]=16'd263; f_rom[62]=16'd641; f_rom[63]=16'd523;
    f_rom[64]=16'd746; f_rom[65]=16'd112; f_rom[66]=16'd618; f_rom[67]=16'd635;
    f_rom[68]=16'd717; f_rom[69]=16'd621; f_rom[70]=16'd227; f_rom[71]=16'd232;
    f_rom[72]=16'd698; f_rom[73]=16'd212; f_rom[74]=16'd236; f_rom[75]=16'd21;
    f_rom[76]=16'd341; f_rom[77]=16'd379; f_rom[78]=16'd567; f_rom[79]=16'd549;
    f_rom[80]=16'd352; f_rom[81]=16'd292; f_rom[82]=16'd238; f_rom[83]=16'd145;
    f_rom[84]=16'd194; f_rom[85]=16'd493; f_rom[86]=16'd70; f_rom[87]=16'd495;
    f_rom[88]=16'd117; f_rom[89]=16'd333; f_rom[90]=16'd66; f_rom[91]=16'd247;
    f_rom[92]=16'd532; f_rom[93]=16'd686; f_rom[94]=16'd517; f_rom[95]=16'd525;
    f_rom[96]=16'd331; f_rom[97]=16'd528; f_rom[98]=16'd167; f_rom[99]=16'd357;
    f_rom[100]=16'd414; f_rom[101]=16'd291; f_rom[102]=16'd411; f_rom[103]=16'd105;
    f_rom[104]=16'd654; f_rom[105]=16'd560; f_rom[106]=16'd14; f_rom[107]=16'd99;
    f_rom[108]=16'd509; f_rom[109]=16'd29; f_rom[110]=16'd366; f_rom[111]=16'd391;
    f_rom[112]=16'd451; f_rom[113]=16'd278; f_rom[114]=16'd353; f_rom[115]=16'd354;
    f_rom[116]=16'd585; f_rom[117]=16'd127; f_rom[118]=16'd330; f_rom[119]=16'd466;
    f_rom[120]=16'd222; f_rom[121]=16'd691; f_rom[122]=16'd421; f_rom[123]=16'd725;
    f_rom[124]=16'd201; f_rom[125]=16'd158; f_rom[126]=16'd350; f_rom[127]=16'd168;

    fn_rom[0]=16'd601; fn_rom[1]=16'd419; fn_rom[2]=16'd611; fn_rom[3]=16'd568;
    fn_rom[4]=16'd44; fn_rom[5]=16'd348; fn_rom[6]=16'd78; fn_rom[7]=16'd547;
    fn_rom[8]=16'd303; fn_rom[9]=16'd439; fn_rom[10]=16'd642; fn_rom[11]=16'd184;
    fn_rom[12]=16'd415; fn_rom[13]=16'd416; fn_rom[14]=16'd491; fn_rom[15]=16'd318;
    fn_rom[16]=16'd378; fn_rom[17]=16'd403; fn_rom[18]=16'd740; fn_rom[19]=16'd260;
    fn_rom[20]=16'd670; fn_rom[21]=16'd755; fn_rom[22]=16'd209; fn_rom[23]=16'd115;
    fn_rom[24]=16'd664; fn_rom[25]=16'd358; fn_rom[26]=16'd478; fn_rom[27]=16'd355;
    fn_rom[28]=16'd412; fn_rom[29]=16'd602; fn_rom[30]=16'd241; fn_rom[31]=16'd438;
    fn_rom[32]=16'd244; fn_rom[33]=16'd252; fn_rom[34]=16'd83; fn_rom[35]=16'd237;
    fn_rom[36]=16'd522; fn_rom[37]=16'd703; fn_rom[38]=16'd436; fn_rom[39]=16'd652;
    fn_rom[40]=16'd274; fn_rom[41]=16'd699; fn_rom[42]=16'd276; fn_rom[43]=16'd575;
    fn_rom[44]=16'd624; fn_rom[45]=16'd531; fn_rom[46]=16'd477; fn_rom[47]=16'd417;
    fn_rom[48]=16'd220; fn_rom[49]=16'd202; fn_rom[50]=16'd390; fn_rom[51]=16'd428;
    fn_rom[52]=16'd748; fn_rom[53]=16'd533; fn_rom[54]=16'd557; fn_rom[55]=16'd71;
    fn_rom[56]=16'd537; fn_rom[57]=16'd542; fn_rom[58]=16'd148; fn_rom[59]=16'd52;
    fn_rom[60]=16'd134; fn_rom[61]=16'd151; fn_rom[62]=16'd657; fn_rom[63]=16'd23;
    fn_rom[64]=16'd246; fn_rom[65]=16'd128; fn_rom[66]=16'd506; fn_rom[67]=16'd157;
    fn_rom[68]=16'd375; fn_rom[69]=16'd589; fn_rom[70]=16'd490; fn_rom[71]=16'd380;
    fn_rom[72]=16'd188; fn_rom[73]=16'd648; fn_rom[74]=16'd543; fn_rom[75]=16'd170;
    fn_rom[76]=16'd24; fn_rom[77]=16'd50; fn_rom[78]=16'd462; fn_rom[79]=16'd578;
    fn_rom[80]=16'd600; fn_rom[81]=16'd481; fn_rom[82]=16'd15; fn_rom[83]=16'd608;
    fn_rom[84]=16'd502; fn_rom[85]=16'd405; fn_rom[86]=16'd51; fn_rom[87]=16'd683;
    fn_rom[88]=16'd346; fn_rom[89]=16'd80; fn_rom[90]=16'd124; fn_rom[91]=16'd2;
    fn_rom[92]=16'd715; fn_rom[93]=16'd272; fn_rom[94]=16'd114; fn_rom[95]=16'd622;
    fn_rom[96]=16'd192; fn_rom[97]=16'd400; fn_rom[98]=16'd620; fn_rom[99]=16'd10;
    fn_rom[100]=16'd499; fn_rom[101]=16'd591; fn_rom[102]=16'd570; fn_rom[103]=16'd34;
    fn_rom[104]=16'd203; fn_rom[105]=16'd487; fn_rom[106]=16'd255; fn_rom[107]=16'd339;
    fn_rom[108]=16'd75; fn_rom[109]=16'd733; fn_rom[110]=16'd98; fn_rom[111]=16'd76;
    fn_rom[112]=16'd337; fn_rom[113]=16'd638; fn_rom[114]=16'd143; fn_rom[115]=16'd362;
    fn_rom[116]=16'd223; fn_rom[117]=16'd16; fn_rom[118]=16'd640; fn_rom[119]=16'd308;
    fn_rom[120]=16'd120; fn_rom[121]=16'd250; fn_rom[122]=16'd3; fn_rom[123]=16'd583;
    fn_rom[124]=16'd408; fn_rom[125]=16'd81; fn_rom[126]=16'd164; fn_rom[127]=16'd655;
  end

  always_comb begin
    twiddle = inverse ? fn_rom[addr] : f_rom[addr];
  end

endmodule
