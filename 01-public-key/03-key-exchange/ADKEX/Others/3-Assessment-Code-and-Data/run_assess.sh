#!/usr/bin/env bash
# Enhanced self-assessment measurement: per instance ->
#   functional KAT (PASS/FAIL), average time (us), average cycles, peak RSS (KB), static memory (size).
# x86: cycles = RDTSC (TSC). arm64: cycles = derived (avg_time_s * CPU_max_freq), labelled. Single core.
set -u
ROOT="${ASSESS_ROOT:-$PWD}"
CC="${CC:-gcc}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
ARCH="$(uname -m)"
case "$ARCH" in x86_64|amd64) IMPLS="Reference_Implementation Optimized_Implementation";;
  aarch64|arm64) IMPLS="Reference_Implementation Additional_Implementation/AArch64_NEON";;
  *) IMPLS="Reference_Implementation";; esac
label(){ case "$1" in *Reference*) echo Reference;; *Optimized*) echo Optimized;; *AArch64*) echo NEON;; *) echo "$1";; esac; }
idof(){ case "$1" in
  DKEM) echo "DKEM (PKCKEM-380333)";; DKEX) echo "DKEX (PKCKEX-359777)";; ADKEX) echo "ADKEX (PKCKEX-142803)";;
  *) echo "$1";; esac; }
# arm cpu max freq (kHz) for derived cycles
FREQ_KHZ=0
[ -r /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq ] && FREQ_KHZ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null)
echo "host=$ARCH cc=$CC freq_kHz=$FREQ_KHZ  start=$(date -u +%FT%TZ)"

cat > "$TMP/bench_kem2.c" <<'CEOF'
#define _POSIX_C_SOURCE 199309L
#include "parameters.h"
#include "dkecca.h"
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <sys/resource.h>
typedef unsigned long long ull;
#if defined(__x86_64__)||defined(_M_X64)
#include <x86intrin.h>
#define RD() __rdtsc()
#define HC 1
#else
#define RD() 0ull
#define HC 0
#endif
static ull ns(void){struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return (ull)t.tv_sec*1000000000ull+(ull)t.tv_nsec;}
#ifndef NTESTS
#define NTESTS 300
#endif
int main(void){
 static uint8_t pk[DKE_PKBYTES],sk[DKE_SKBYTES],ct[DKE_CTBYTES],ss[DKE_SSBYTES],s2[DKE_SSBYTES],ck[DKE_SEEDBYTES+DKE_SSBYTES],ce[DKE_SEEDBYTES];
 ull a,b,tk=0,te=0,td=0,ckg=0,cen=0,cde=0;
 for(int i=0;i<NTESTS;i++){memset(ck,0x11+(i&255),sizeof ck);memset(ce,0x22+(i&255),sizeof ce);
  b=ns();a=RD();DKE_CCA_keygen_derand(pk,sk,ck);ckg+=RD()-a;tk+=ns()-b;
  b=ns();a=RD();DKE_CCA_enc_derand(ct,ss,pk,ce);cen+=RD()-a;te+=ns()-b;
  b=ns();a=RD();DKE_CCA_dec(s2,sk,ct);cde+=RD()-a;td+=ns()-b;
  if(memcmp(ss,s2,DKE_SSBYTES)){printf("CORRECTNESS-FAIL\n");return 1;}}
 double n=NTESTS;
 printf("avg_us keygen=%.2f enc=%.2f dec=%.2f\n",tk/n/1000.0,te/n/1000.0,td/n/1000.0);
 if(HC) printf("avg_cyc keygen=%.0f enc=%.0f dec=%.0f\n",ckg/n,cen/n,cde/n);
 else   printf("avg_cyc keygen=NA enc=NA dec=NA\n");
 struct rusage ru; getrusage(RUSAGE_SELF,&ru);
 printf("peak_rss_kb=%ld\n",(long)ru.ru_maxrss);
 return 0;}
CEOF

cat > "$TMP/bench_kex2.c" <<'CEOF'
#define _POSIX_C_SOURCE 199309L
#include "KEX_AlgorithmInstance.h"
#include "drng.h"
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <sys/resource.h>
typedef unsigned long long ull;
#if defined(__x86_64__)||defined(_M_X64)
#include <x86intrin.h>
#define RD() __rdtsc()
#define HC 1
#else
#define RD() 0ull
#define HC 0
#endif
DRNG_ctx drng_algorithm;
static ull ns(void){struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return (ull)t.tv_sec*1000000000ull+(ull)t.tv_nsec;}
#ifndef NT
#define NT 128
#endif
#define SL 64
int main(void){
 ull P=kex_get_passes_num(),pkL=kex_get_pk_len_bytes(),skL=kex_get_sk_len_bytes(),saL=kex_get_sta_len_bytes(),sbL=kex_get_stb_len_bytes(),ssL=kex_get_ss_len_bytes(),tL=kex_get_total_msg_len_bytes();
 unsigned char*pka=calloc(pkL,1),*ska=calloc(skL,1),*pkb=calloc(pkL,1),*skb=calloc(skL,1),*sta=calloc(saL,1),*stb=calloc(sbL,1),*ssa=calloc(ssL,1),*ssb=calloc(ssL,1),*m1=calloc(tL,1),*m2=calloc(tL,1),*m3=calloc(tL,1),seed[SL];
 ull T=0,C=0,a,b;
 for(ull i=0;i<NT;i++){memset(seed,0x42,SL);seed[0]=i;seed[1]=i>>8;init_random_number(&drng_algorithm,seed,SL);
  ull paL=pkL,sa2=skL,pbL=pkL,sb2=skL,staL=saL,stbL=sbL,sa3=ssL,sb3=ssL,m1L=0,m2L=0,m3L=0;
  b=ns();a=RD();
  kex_init_a(pka,&paL,ska,&sa2,sta,&staL);
  kex_init_b(pkb,&pbL,skb,&sb2,stb,&stbL);
  kex_generate_pass1_msg_a(ska,sa2,pkb,pbL,sta,&staL,m1,&m1L);
  kex_generate_pass2_msg_b(skb,sb2,pka,paL,m1,m1L,stb,&stbL,m2,&m2L);
  if(P>=3) kex_generate_pass3_msg_a(ska,sa2,pkb,pbL,m2,m2L,sta,&staL,m3,&m3L);
  unsigned char*ma=(P>=3)?m3:m1;ull maL=(P>=3)?m3L:m1L;
  kex_derive_ss_a(ska,sa2,pkb,pbL,m2,m2L,sta,staL,ssa,&sa3);
  kex_derive_ss_b(skb,sb2,pka,paL,ma,maL,stb,stbL,ssb,&sb3);
  C+=RD()-a;T+=ns()-b;}
 double n=NT;
 printf("avg_us handshake=%.2f\n",T/n/1000.0);
 if(HC) printf("avg_cyc handshake=%.0f\n",C/n); else printf("avg_cyc handshake=NA\n");
 struct rusage ru; getrusage(RUSAGE_SELF,&ru);
 printf("peak_rss_kb=%ld\n",(long)ru.ru_maxrss);
 return 0;}
CEOF

run_one(){ # algo benchsrc katsym
  local A="$1" SRC="$2" SYM="$3"
  for V in $IMPLS; do for M in 128 256 512; do
    d="$ROOT/$(idof "$A")/Implementations/$V/$A-$M"; [ -d "$d" ] || continue
    # functional KAT
    ( cd "$d" && rm -f kat_$A-$M && CC=$CC bash build.sh ) >/dev/null 2>&1
    k=$(ls "$d/output/"KAT_*_$A-$M.txt 2>/dev/null|head -1)
    tv=$(ls "$ROOT/$(idof "$A")/Test_Vectors/"*_$A-$M.txt 2>/dev/null|head -1)
    if [ -n "$k" ] && diff -q "$k" "$tv" >/dev/null 2>&1; then KAT=PASS; else KAT=FAIL; fi
    stat=$(size "$d/kat_$A-$M" 2>/dev/null | awk 'NR==2{printf "text=%s data=%s bss=%s total=%s",$1,$2,$3,$1+$2+$3}')
    # perf+rss bench
    bn=$(basename "$SRC"); cp "$SRC" "$d/$bn"
    ( cd "$d" && sed -e "s/$SYM/${bn%.c}/g" -e 's/kat_/bench_/g' build.sh > bb.sh && rm -f bench_$A-$M && CC=$CC bash bb.sh ) >/dev/null 2>&1
    r=$( cd "$d" && ./bench_$A-$M 2>/dev/null | tr '\n' ' ' )
    echo "[$A-$M | $(label "$V")] KAT=$KAT | $r| static($stat)"
    rm -rf "$d/build" "$d/output" "$d/obj" "$d/bb.sh" "$d/$bn" "$d/bench_$A-$M" "$d/kat_$A-$M"
  done; done
}
echo "==== DKEM ===="; run_one DKEM  "$TMP/bench_kem2.c" KAT_KEM
echo "==== ADKEX ===="; run_one ADKEX "$TMP/bench_kex2.c" KAT_KEX
echo "==== DKEX ===="; run_one DKEX  "$TMP/bench_kex2.c" KAT_KEX
echo "end=$(date -u +%FT%TZ)"
