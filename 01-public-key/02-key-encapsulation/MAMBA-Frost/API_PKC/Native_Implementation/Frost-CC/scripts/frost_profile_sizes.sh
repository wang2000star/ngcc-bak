#!/usr/bin/env bash
# Central Frost profile metadata for benchmark/CSV harnesses.
# Sizes are CRYPTO_* byte sizes (KEM secret key size for sk_bytes), derived
# from the active five-profile Frost parameter set using the unified
# rectangular ell_r/ell_s size formulas.

frost_level_params(){
  case "$1" in
    128) echo "q=32768,qbits=15,n=512,m=512,ell_r=8,ell_s=8,eta_s=2,eta_r=2,b_msg=2,t_pk=10,t_u=10,t_v=5" ;;
    192) echo "q=65536,qbits=16,n=880,m=880,ell_r=8,ell_s=8,eta_s=1,eta_r=1,b_msg=3,t_pk=11,t_u=11,t_v=6" ;;
    256) echo "q=65536,qbits=16,n=1288,m=1288,ell_r=8,ell_s=8,eta_s=1,eta_r=1,b_msg=4,t_pk=13,t_u=12,t_v=8" ;;
    384) echo "q=65536,qbits=16,n=1928,m=1928,ell_r=8,ell_s=12,eta_s=1,eta_r=1,b_msg=4,t_pk=13,t_u=13,t_v=9" ;;
    512) echo "q=65536,qbits=16,n=2600,m=2600,ell_r=8,ell_s=16,eta_s=1,eta_r=1,b_msg=4,t_pk=14,t_u=14,t_v=7" ;;
    *) echo "unknown Frost level: $1" >&2; return 1 ;;
  esac
}

frost_expected_sizes(){
  case "$1" in
    128) echo "5152,5192,6736,16" ;;
    192) echo "9712,9760,11528,24" ;;
    256) echo "16776,15552,19416,32" ;;
    384) echo "37628,25204,43492,48" ;;
    512) echo "72832,36544,83328,64" ;;
    *) echo "unknown Frost level: $1" >&2; return 1 ;;
  esac
}
