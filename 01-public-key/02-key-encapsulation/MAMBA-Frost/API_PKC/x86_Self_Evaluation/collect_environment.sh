#!/usr/bin/env bash
set -u
out_dir=${1:?usage: collect_environment.sh <result-dir>}
repo_root=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$out_dir"
{
  echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "hostname: $(hostname 2>/dev/null || echo not found)"
  echo "uname: $(uname -a 2>/dev/null || echo not found)"
  echo "shell: ${SHELL:-unknown}"
  echo "pwd: $repo_root"
  echo
  echo "os-release:"
  if [ -r /etc/os-release ]; then cat /etc/os-release; elif command -v lsb_release >/dev/null 2>&1; then lsb_release -a; else echo "not found"; fi
  echo
  echo "gcc --version:"
  if command -v gcc >/dev/null 2>&1; then gcc --version; else echo "not found"; fi
  echo
  echo "make --version:"
  if command -v make >/dev/null 2>&1; then make --version; else echo "not found"; fi
  echo
  echo "cmake --version:"
  if command -v cmake >/dev/null 2>&1; then cmake --version; else echo "not found"; fi
  echo
  echo "lscpu:"
  if command -v lscpu >/dev/null 2>&1; then lscpu; else echo "not found"; fi
  echo
  echo "nproc: $(nproc 2>/dev/null || echo not found)"
  echo
  echo "free -h:"
  if command -v free >/dev/null 2>&1; then free -h; else echo "not found"; fi
  flags=$(grep -m1 '^flags' /proc/cpuinfo 2>/dev/null || true)
  echo
  case " $flags " in *" avx2 "*) echo "AVX2: yes";; *) echo "AVX2: no";; esac
  case " $flags " in *" aes "*) echo "AES-NI: yes";; *) echo "AES-NI: no";; esac
} > "$out_dir/environment.txt"
{
  cd "$repo_root" || exit 1
  git status --short --branch
  git log --oneline -10
  git rev-parse HEAD
  git diff --stat
} > "$out_dir/git_status.txt" 2>&1
{
  cd "$repo_root" || exit 1
  find API_PKC -maxdepth 4 -type d | sort
  find API_PKC -maxdepth 4 -type f | sort
} > "$out_dir/package_layout.txt" 2>&1
