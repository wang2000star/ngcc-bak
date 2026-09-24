#!/bin/bash

set -e

echo "Running TaiChi-512"
./bin/TaiChi-512
echo "Running TaiChi-768"
./bin/TaiChi-768
echo "Running TaiChi-1024"
./bin/TaiChi-1024
echo "Running TaiChi-512-op-per"
./bin/TaiChi-512-op-per
echo "Running TaiChi-768-op-per"
./bin/TaiChi-768-op-per
echo "Running TaiChi-1024-op-per"
./bin/TaiChi-1024-op-per
echo "Running TaiChi-512-op-res"
./bin/TaiChi-512-op-res
echo "Running TaiChi-768-op-res"
./bin/TaiChi-768-op-res
echo "Running TaiChi-1024-op-res"
./bin/TaiChi-1024-op-res
echo "All done."