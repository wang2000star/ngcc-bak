FREQ=2000000 
echo $FREQ | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq 
echo $FREQ | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq 
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
openssl speed -evp sha3-512
openssl speed sha512
