#!/usr/bin/env bash
# ============================================================================
#  run_all_tests.sh  —  build + KAT-verify + benchmark all submission codes.
#  Runs on Linux / macOS / WSL. Auto-adapts to CPU:
#    x86-64 : Reference + Optimized(AVX2)
#    arm64  : Reference + Additional/AArch64_NEON
#  Cortex-M4 (Additional) is included automatically if arm-none-eabi-gcc and
#  qemu-system-arm are on PATH. Needs gcc/clang + diff.
# ============================================================================
set -u
cd "$(dirname "$0")"
ROOT="$PWD"
idof(){ case "$1" in
  DKEM)  echo "DKEM (PKCKEM-380333)";;
  DKEX)  echo "DKEX (PKCKEX-359777)";;
  ADKEX) echo "ADKEX (PKCKEX-142803)";;
  *) echo "$1";; esac; }
CC="${CC:-gcc}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)  IMPLS="Reference_Implementation Optimized_Implementation" ;;
  aarch64|arm64) IMPLS="Reference_Implementation Additional_Implementation/AArch64_NEON" ;;
  *)             IMPLS="Reference_Implementation" ;;
esac
label(){ case "$1" in *Reference*) echo Reference;; *Optimized*) echo Optimized;; *AArch64*) echo arm64-NEON;; *) echo "$1";; esac; }

echo "############################################################"
echo "#  DKEM / DKEX / ADKEX  : build + KAT + performance"
echo "#  host=$ARCH  compiler=$CC  impls: $IMPLS"
echo "############################################################"

# ---------- embedded benchmarks ----------
cat > "$TMP/bench_kem.c" <<'CEOF'
#define _POSIX_C_SOURCE 199309L
#include "parameters.h"
#include "dkecca.h"
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
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
static int c64(const void*a,const void*b){ull x=*(const ull*)a,y=*(const ull*)b;return (x>y)-(x<y);}
#ifndef NTESTS
#define NTESTS 300
#endif
int main(void){
 static uint8_t pk[DKE_PKBYTES],sk[DKE_SKBYTES],ct[DKE_CTBYTES],ss[DKE_SSBYTES],s2[DKE_SSBYTES],ck[DKE_SEEDBYTES+DKE_SSBYTES],ce[DKE_SEEDBYTES];
 static ull tk[NTESTS],te[NTESTS],td[NTESTS],yk[NTESTS],ye[NTESTS],yd[NTESTS];ull a,b;
 for(int i=0;i<NTESTS;i++){memset(ck,0x11+(i&255),sizeof ck);memset(ce,0x22+(i&255),sizeof ce);
  b=ns();a=RD();DKE_CCA_keygen_derand(pk,sk,ck);yk[i]=RD()-a;tk[i]=ns()-b;
  b=ns();a=RD();DKE_CCA_enc_derand(ct,ss,pk,ce);ye[i]=RD()-a;te[i]=ns()-b;
  b=ns();a=RD();DKE_CCA_dec(s2,sk,ct);yd[i]=RD()-a;td[i]=ns()-b;
  if(memcmp(ss,s2,DKE_SSBYTES)){printf("CORRECTNESS-FAIL\n");return 1;}}
 qsort(tk,NTESTS,8,c64);qsort(te,NTESTS,8,c64);qsort(td,NTESTS,8,c64);qsort(yk,NTESTS,8,c64);qsort(ye,NTESTS,8,c64);qsort(yd,NTESTS,8,c64);int m=NTESTS/2;
 if(HC) printf("keygen=%llu enc=%llu dec=%llu cyc\n",yk[m],ye[m],yd[m]);
 else   printf("keygen=%.1f enc=%.1f dec=%.1f us\n",tk[m]/1000.0,te[m]/1000.0,td[m]/1000.0);
 return 0;}
CEOF
cat > "$TMP/bench_kex.c" <<'CEOF'
#define _POSIX_C_SOURCE 199309L
#include "KEX_AlgorithmInstance.h"
#include "drng.h"
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
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
static int c64(const void*a,const void*b){ull x=*(const ull*)a,y=*(const ull*)b;return (x>y)-(x<y);}
#ifndef NT
#define NT 80
#endif
#define SL 64
int main(void){
 ull P=kex_get_passes_num(),pkL=kex_get_pk_len_bytes(),skL=kex_get_sk_len_bytes(),saL=kex_get_sta_len_bytes(),sbL=kex_get_stb_len_bytes(),ssL=kex_get_ss_len_bytes(),tL=kex_get_total_msg_len_bytes();
 unsigned char*pka=calloc(pkL,1),*ska=calloc(skL,1),*pkb=calloc(pkL,1),*skb=calloc(skL,1),*sta=calloc(saL,1),*stb=calloc(sbL,1),*ssa=calloc(ssL,1),*ssb=calloc(ssL,1),*m1=calloc(tL,1),*m2=calloc(tL,1),*m3=calloc(tL,1),seed[SL];
 static ull T[NT],Y[NT];
 for(ull i=0;i<NT;i++){memset(seed,0x42,SL);seed[0]=i;seed[1]=i>>8;init_random_number(&drng_algorithm,seed,SL);
  ull paL=pkL,sa2=skL,pbL=pkL,sb2=skL,staL=saL,stbL=sbL,sa3=ssL,sb3=ssL,m1L=0,m2L=0,m3L=0,_a,_b;
  _b=ns();_a=RD();
  kex_init_a(pka,&paL,ska,&sa2,sta,&staL);
  kex_init_b(pkb,&pbL,skb,&sb2,stb,&stbL);
  kex_generate_pass1_msg_a(ska,sa2,pkb,pbL,sta,&staL,m1,&m1L);
  kex_generate_pass2_msg_b(skb,sb2,pka,paL,m1,m1L,stb,&stbL,m2,&m2L);
  if(P>=3) kex_generate_pass3_msg_a(ska,sa2,pkb,pbL,m2,m2L,sta,&staL,m3,&m3L);
  unsigned char*ma=(P>=3)?m3:m1;ull maL=(P>=3)?m3L:m1L;
  kex_derive_ss_a(ska,sa2,pkb,pbL,m2,m2L,sta,staL,ssa,&sa3);
  kex_derive_ss_b(skb,sb2,pka,paL,ma,maL,stb,stbL,ssb,&sb3);
  Y[i]=RD()-_a;T[i]=ns()-_b;}
 qsort(T,NT,8,c64);qsort(Y,NT,8,c64);int m=NT/2;
 if(HC) printf("full_handshake(%llu-pass)=%llu cyc\n",P,Y[m]);
 else   printf("full_handshake(%llu-pass)=%.1f us\n",P,T[m]/1000.0);
 return 0;}
CEOF

# ---------- [1] KAT consistency ----------
echo; echo "===== [1] KAT consistency  (output == Test_Vectors) ====="
kp=0; kf=0
for A in DKEM DKEX ADKEX; do for M in 128 256 512; do
  tv=$(ls "$ROOT/$(idof "$A")/Test_Vectors/"*_$A-$M.txt 2>/dev/null|head -1)
  for V in $IMPLS; do
    d="$ROOT/$(idof "$A")/Implementations/$V/$A-$M"; [ -d "$d" ] || continue
    ( cd "$d" && rm -f kat_$A-$M && CC=$CC bash build.sh ) >/dev/null 2>&1
    k=$(ls "$d/output/"KAT_*_$A-$M.txt 2>/dev/null|head -1)
    if [ -n "$k" ] && diff -q "$k" "$tv" >/dev/null 2>&1; then echo "  [PASS] $A-$M $(label "$V")"; kp=$((kp+1)); else echo "  [FAIL] $A-$M $(label "$V")"; kf=$((kf+1)); fi
    rm -rf "$d/output" "$d/build" "$d/obj" "$d/kat_$A-$M"
  done
done; done
echo "  ----> KAT: PASS=$kp FAIL=$kf"

# ---------- [2] performance ----------
echo; echo "===== [2] performance  (median; x86=cycles, arm64=microseconds) ====="
bench(){ # algo benchsrc katsym
  for V in $IMPLS; do for M in 128 256 512; do
    d="$ROOT/$(idof "$1")/Implementations/$V/$1-$M"; [ -d "$d" ] || continue
    bn=$(basename "$2"); cp "$2" "$d/$bn"
    ( cd "$d" && sed -e "s/$3/${bn%.c}/g" -e 's/kat_/bench_/g' build.sh > bb.sh && rm -f bench_$1-$M && CC=$CC bash bb.sh ) >/dev/null 2>&1
    r=$( cd "$d" && ./bench_$1-$M 2>/dev/null )
    printf "  %-11s %-11s %s\n" "$1-$M" "$(label "$V")" "${r:-BUILD-FAIL}"
    rm -rf "$d/build" "$d/output" "$d/bb.sh" "$d/$bn" "$d/bench_$1-$M" "$d/obj"
  done; done
}
bench DKEM  "$TMP/bench_kem.c" KAT_KEM
bench ADKEX "$TMP/bench_kex.c" KAT_KEX
bench DKEX  "$TMP/bench_kex.c" KAT_KEX

# ---------- [3] Cortex-M4 (optional) ----------
if command -v arm-none-eabi-gcc >/dev/null 2>&1 && command -v qemu-system-arm >/dev/null 2>&1; then
  echo; echo "===== [3] Cortex-M4 (QEMU): self-test PASS + cycles ====="
  for A in DKEM ADKEX DKEX; do for M in 128 256 512; do
    d="$ROOT/$(idof "$A")/Implementations/Additional_Implementation/Cortex-M4/$A-$M"; [ -d "$d" ] || continue
    out=$( cd "$d" && rm -f kat_$A-$M.elf && bash build.sh 2>&1 )
    echo "$out"|grep -q PASS && st=PASS || st=FAIL
    echo "  $A-$M [$st]"
    echo "$out"|grep -E ': *[0-9]{3,}'|grep -vaE 'ld|warning|note|libc|0x|\.o\)|/'|sed 's/^/        /'
    rm -rf "$d/obj" "$d/kat_$A-$M.elf"
  done; done
else
  echo; echo "  (Cortex-M4 skipped: arm-none-eabi-gcc / qemu-system-arm not on PATH)"
fi

echo; echo "############################  ALL DONE  ############################"
