#!/bin/bash
rm *.json.en
rm *.json.zh
#ref 
./ngcc_bench   --lib ../../Dragon_X86/API_CryptHash/Implementations/Reference_Implementation/Dragon512/libDragon512ref.so   --test hash   --mode all   --digest-len-bits 512   --kat ../../Dragon_X86/API_CryptHash/Test_Vector/Dragon512   --json-out Dragon512ref_X86_report.json
./ngcc_bench   --lib ../../Dragon_X86/API_CryptHash/Implementations/Reference_Implementation/Dragon768/libDragon768ref.so   --test hash   --mode all   --digest-len-bits 768   --kat ../../Dragon_X86/API_CryptHash/Test_Vector/Dragon768   --json-out Dragon768ref_X86_report.json
./ngcc_bench   --lib ../../Dragon_X86/API_CryptHash/Implementations/Reference_Implementation/Dragon1024/libDragon1024ref.so   --test hash   --mode all   --digest-len-bits 1024   --kat ../../Dragon_X86/API_CryptHash/Test_Vector/Dragon1024   --json-out Dragon1024ref_X86_report.json
#speed opt
./ngcc_bench   --lib ../../Dragon_X86/API_CryptHash/Implementations/Optimized_Implementation/Dragon512/libDragon512Opt.so   --test hash   --mode all   --digest-len-bits 512   --kat ../../Dragon_X86/API_CryptHash/Test_Vector/Dragon512   --json-out Dragon512opt_X86_report.json
./ngcc_bench   --lib ../../Dragon_X86/API_CryptHash/Implementations/Optimized_Implementation/Dragon768/libDragon768Opt.so   --test hash   --mode all   --digest-len-bits 768   --kat ../../Dragon_X86/API_CryptHash/Test_Vector/Dragon768   --json-out Dragon768opt_X86_report.json
./ngcc_bench   --lib ../../Dragon_X86/API_CryptHash/Implementations/Optimized_Implementation/Dragon1024/libDragon1024Opt.so   --test hash   --mode all   --digest-len-bits 1024   --kat ../../Dragon_X86/API_CryptHash/Test_Vector/Dragon1024   --json-out Dragon1024opt_X86_report.json
#size opt
./ngcc_bench   --lib ../../Dragon_X86/API_CryptHash/Implementations/Additional_Implementation/Dragon512/libDragon512s.so   --test hash   --mode all   --digest-len-bits 512   --kat ../../Dragon_X86/API_CryptHash/Test_Vector/Dragon512   --json-out Dragon512s_X86_report.json
./ngcc_bench   --lib ../../Dragon_X86/API_CryptHash/Implementations/Additional_Implementation/Dragon768/libDragon768s.so   --test hash   --mode all   --digest-len-bits 768   --kat ../../Dragon_X86/API_CryptHash/Test_Vector/Dragon768   --json-out Dragon768s_X86_report.json
./ngcc_bench   --lib ../../Dragon_X86/API_CryptHash/Implementations/Additional_Implementation/Dragon1024/libDragon1024s.so   --test hash   --mode all   --digest-len-bits 1024   --kat ../../Dragon_X86/API_CryptHash/Test_Vector/Dragon1024   --json-out Dragon1024s_X86_report.json

