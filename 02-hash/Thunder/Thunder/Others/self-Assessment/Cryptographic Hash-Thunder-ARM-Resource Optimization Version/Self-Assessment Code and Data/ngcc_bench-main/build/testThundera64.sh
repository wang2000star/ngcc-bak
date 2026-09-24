#!/bin/bash
sudo rm Thunder*.json.en
sudo rm Thunder*.json.zh
#ref 
sudo ./ngcc_bench   --lib ../../Thunder_ARM64/API_CryptHash/Implementations/Reference_Implementation/Thunder512/libThunder512ref.so   --test hash   --mode all   --digest-len-bits 512   --kat ../../Thunder_ARM64/API_CryptHash/Test_Vector/Thunder512   --json-out Thunder512ref_A64_report.json
sudo ./ngcc_bench   --lib ../../Thunder_ARM64/API_CryptHash/Implementations/Reference_Implementation/Thunder768/libThunder768ref.so   --test hash   --mode all   --digest-len-bits 768   --kat ../../Thunder_ARM64/API_CryptHash/Test_Vector/Thunder768   --json-out Thunder768ref_A64_report.json
sudo ./ngcc_bench   --lib ../../Thunder_ARM64/API_CryptHash/Implementations/Reference_Implementation/Thunder1024/libThunder1024ref.so   --test hash   --mode all   --digest-len-bits 1024   --kat ../../Thunder_ARM64/API_CryptHash/Test_Vector/Thunder1024   --json-out Thunder1024ref_A64_report.json
#speed opt
sudo ./ngcc_bench   --lib ../../Thunder_ARM64/API_CryptHash/Implementations/Optimized_Implementation/Thunder512/libThunder512Opt.so   --test hash   --mode all   --digest-len-bits 512   --kat ../../Thunder_ARM64/API_CryptHash/Test_Vector/Thunder512   --json-out Thunder512opt_A64_report.json
sudo ./ngcc_bench   --lib ../../Thunder_ARM64/API_CryptHash/Implementations/Optimized_Implementation/Thunder768/libThunder768Opt.so   --test hash   --mode all   --digest-len-bits 768   --kat ../../Thunder_ARM64/API_CryptHash/Test_Vector/Thunder768   --json-out Thunder768opt_A64_report.json
sudo ./ngcc_bench   --lib ../../Thunder_ARM64/API_CryptHash/Implementations/Optimized_Implementation/Thunder1024/libThunder1024Opt.so   --test hash   --mode all   --digest-len-bits 1024   --kat ../../Thunder_ARM64/API_CryptHash/Test_Vector/Thunder1024   --json-out Thunder1024opt_A64_report.json
#size opt
sudo ./ngcc_bench   --lib ../../Thunder_ARM64/API_CryptHash/Implementations/Additional_Implementation/Thunder512/libThunder512s.so   --test hash   --mode all   --digest-len-bits 512   --kat ../../Thunder_ARM64/API_CryptHash/Test_Vector/Thunder512   --json-out Thunder512s_A64_report.json
sudo ./ngcc_bench   --lib ../../Thunder_ARM64/API_CryptHash/Implementations/Additional_Implementation/Thunder768/libThunder768s.so   --test hash   --mode all   --digest-len-bits 768   --kat ../../Thunder_ARM64/API_CryptHash/Test_Vector/Thunder768   --json-out Thunder768s_A64_report.json
sudo ./ngcc_bench   --lib ../../Thunder_ARM64/API_CryptHash/Implementations/Additional_Implementation/Thunder1024/libThunder1024s.so   --test hash   --mode all   --digest-len-bits 1024   --kat ../../Thunder_ARM64/API_CryptHash/Test_Vector/Thunder1024   --json-out Thunder1024s_A64_report.json
sudo chmod 777 Thunder*.json.en
sudo chmod 777 Thunder*.json.zh

