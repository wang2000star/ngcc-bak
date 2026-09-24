#!/bin/bash
sudo rm *.json.en
sudo rm *.json.zh
#ref 
sudo ./ngcc_bench   --lib ../../Dragon_ARM64/API_CryptHash/Implementations/Reference_Implementation/Dragon512/libDragon512ref.so   --test hash   --mode all   --digest-len-bits 512   --kat ../../Dragon_ARM64/API_CryptHash/Test_Vector/Dragon512   --json-out Dragon512ref_A64_report.json
sudo ./ngcc_bench   --lib ../../Dragon_ARM64/API_CryptHash/Implementations/Reference_Implementation/Dragon768/libDragon768ref.so   --test hash   --mode all   --digest-len-bits 768   --kat ../../Dragon_ARM64/API_CryptHash/Test_Vector/Dragon768   --json-out Dragon768ref_A64_report.json
sudo ./ngcc_bench   --lib ../../Dragon_ARM64/API_CryptHash/Implementations/Reference_Implementation/Dragon1024/libDragon1024ref.so   --test hash   --mode all   --digest-len-bits 1024   --kat ../../Dragon_ARM64/API_CryptHash/Test_Vector/Dragon1024   --json-out Dragon1024ref_A64_report.json
#speed opt
sudo ./ngcc_bench   --lib ../../Dragon_ARM64/API_CryptHash/Implementations/Optimized_Implementation/Dragon512/libDragon512Opt.so   --test hash   --mode all   --digest-len-bits 512   --kat ../../Dragon_ARM64/API_CryptHash/Test_Vector/Dragon512   --json-out Dragon512opt_A64_report.json
sudo ./ngcc_bench   --lib ../../Dragon_ARM64/API_CryptHash/Implementations/Optimized_Implementation/Dragon768/libDragon768Opt.so   --test hash   --mode all   --digest-len-bits 768   --kat ../../Dragon_ARM64/API_CryptHash/Test_Vector/Dragon768   --json-out Dragon768opt_A64_report.json
sudo ./ngcc_bench   --lib ../../Dragon_ARM64/API_CryptHash/Implementations/Optimized_Implementation/Dragon1024/libDragon1024Opt.so   --test hash   --mode all   --digest-len-bits 1024   --kat ../../Dragon_ARM64/API_CryptHash/Test_Vector/Dragon1024   --json-out Dragon1024opt_A64_report.json
#size opt
sudo ./ngcc_bench   --lib ../../Dragon_ARM64/API_CryptHash/Implementations/Additional_Implementation/Dragon512/libDragon512s.so   --test hash   --mode all   --digest-len-bits 512   --kat ../../Dragon_ARM64/API_CryptHash/Test_Vector/Dragon512   --json-out Dragon512s_A64_report.json
sudo ./ngcc_bench   --lib ../../Dragon_ARM64/API_CryptHash/Implementations/Additional_Implementation/Dragon768/libDragon768s.so   --test hash   --mode all   --digest-len-bits 768   --kat ../../Dragon_ARM64/API_CryptHash/Test_Vector/Dragon768   --json-out Dragon768s_A64_report.json
sudo ./ngcc_bench   --lib ../../Dragon_ARM64/API_CryptHash/Implementations/Additional_Implementation/Dragon1024/libDragon1024s.so   --test hash   --mode all   --digest-len-bits 1024   --kat ../../Dragon_ARM64/API_CryptHash/Test_Vector/Dragon1024   --json-out Dragon1024s_A64_report.json
sudo chmod 777 *.json.en
sudo chmod 777 *.json.zh

