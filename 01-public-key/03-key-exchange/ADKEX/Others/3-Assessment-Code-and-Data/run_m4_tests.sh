#!/usr/bin/env bash
# ============================================================================
#  run_m4_tests.sh  —  build + QEMU self-test (KAT/handshake) + cycles for the
#  Cortex-M4 (Additional) implementations of DKEM / ADKEX / DKEX.
#  Run from Git Bash / MSYS2 (so the Windows arm-none-eabi-gcc + qemu are visible),
#  or from any shell on Linux/macOS with those tools on PATH.
# ============================================================================
set -u
cd "$(dirname "$0")"
ROOT="$PWD"
idof(){ case "$1" in
  DKEM)  echo "DKEM (PKCKEM-380333)";;
  DKEX)  echo "DKEX (PKCKEX-359777)";;
  ADKEX) echo "ADKEX (PKCKEX-142803)";;
  *) echo "$1";; esac; }

# locate toolchain (fall back to common Windows install dirs)
if ! command -v arm-none-eabi-gcc >/dev/null 2>&1; then
  for d in "/c/Program Files (x86)/Arm GNU Toolchain arm-none-eabi/"*/bin \
           "/c/Program Files/Arm GNU Toolchain arm-none-eabi/"*/bin; do
    [ -x "$d/arm-none-eabi-gcc.exe" ] && PATH="$d:$PATH"
  done
fi
if ! command -v qemu-system-arm >/dev/null 2>&1; then
  for d in "/c/Program Files/qemu" "/c/Program Files (x86)/qemu"; do
    [ -x "$d/qemu-system-arm.exe" ] && PATH="$d:$PATH"
  done
fi
command -v arm-none-eabi-gcc >/dev/null 2>&1 || { echo "[ERROR] arm-none-eabi-gcc not found. Install Arm GNU Toolchain (arm-none-eabi) and/or add it to PATH."; exit 1; }
command -v qemu-system-arm  >/dev/null 2>&1 || { echo "[ERROR] qemu-system-arm not found. Install QEMU and/or add it to PATH."; exit 1; }

echo "############################################################"
echo "#  Cortex-M4  (Plantard + matacc)  : build + QEMU self-test"
echo "#  $(arm-none-eabi-gcc --version | head -1)"
echo "############################################################"
echo

pass=0; fail=0
for A in DKEM ADKEX DKEX; do for M in 128 256 512; do
  d="$ROOT/$(idof "$A")/Implementations/Additional_Implementation/Cortex-M4/$A-$M"; [ -d "$d" ] || continue
  out=$( cd "$d" && rm -f kat_$A-$M.elf && bash build.sh 2>&1 )
  if echo "$out" | grep -q PASS; then st=PASS; pass=$((pass+1)); else st=FAIL; fail=$((fail+1)); fi
  echo "### $A-$M  [$st]  (self-test + min cycles) ###"
  echo "$out" | grep -E ': *[0-9]{3,}' | grep -vaE 'ld|warning|note|libc|0x|\.o\)|/' | sed 's/^/    /'
  rm -rf "$d/obj" "$d/kat_$A-$M.elf"
done; done
echo
echo "============  Cortex-M4: $pass/9 PASS  (fail=$fail)  ============"
