#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
RTL_DIR="${ROOT_DIR}/rtl"
TB_DIR="${ROOT_DIR}"
BUILD_DIR="${ROOT_DIR}/software/build_self_eval"
LOG_DIR="${BUILD_DIR}/path_cycle_logs"
BOARD_FAMILY="v80"

SUMMARY_MD=""
SUMMARY_CSV=""
VERBOSE=0

mkdir -p "${BUILD_DIR}"
mkdir -p "${LOG_DIR}"

usage() {
  cat <<'EOF'
Usage:
  software/scripts/run_profile_path_cycles.sh [options] [profile ...]

Options:
  --board <v80|xcv80|xcvu37p>
                            select board family, default v80
  --summary-md <path>   write markdown summary table
  --summary-csv <path>  write csv summary table
  --verbose             stream compile/sim logs to stdout

Profiles:
  safe balanced timing aggr all

Default:
  balanced timing aggr

This 512-only workspace compiles and runs:
  - zen_pke_enc_path_tb
  - zen_pke_keygen_path_tb
  - zen_pke_dec_path_tb

These root testbenches are fixed to swift512 vectors under testdata/swift512/.
Then it prints the top-level command total cycles for each profile/path pair.
EOF
}

log() {
  printf '[PATH-CYCLES] %s\n' "$1"
}

board_define() {
  case "$1" in
    v80|V80|xcv80) echo "ZEN_BOARD_XCV80" ;;
    xcvu37p) echo "" ;;
    *)
      printf 'Unknown board family: %s\n' "$1" >&2
      exit 1
      ;;
  esac
}

board_filelist() {
  case "$1" in
    v80|V80|xcv80) echo "${RTL_DIR}/filelist_xcv80.f" ;;
    xcvu37p) echo "${RTL_DIR}/filelist_xcvu37p.f" ;;
    *)
      printf 'Unknown board family: %s\n' "$1" >&2
      exit 1
      ;;
  esac
}

profile_define() {
  case "$1" in
    safe) echo "USE_SAFE" ;;
    balanced) echo "" ;;
    timing) echo "USE_TIMING" ;;
    aggr) echo "USE_AGGR" ;;
    *)
      printf 'Unknown profile: %s\n' "$1" >&2
      exit 1
      ;;
  esac
}

profile_label() {
  case "$1" in
    safe) echo "SAFE" ;;
    balanced) echo "BALANCED" ;;
    timing) echo "TIMING" ;;
    aggr) echo "AGGR" ;;
    *)
      printf 'Unknown profile: %s\n' "$1" >&2
      exit 1
      ;;
  esac
}

expand_profiles() {
  if [ "$#" -eq 0 ]; then
    printf '%s\n' balanced timing aggr
    return
  fi

  for arg in "$@"; do
    case "$arg" in
      all)
        printf '%s\n' safe balanced timing aggr
        ;;
      safe|balanced|timing|aggr)
        printf '%s\n' "$arg"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        printf 'Unknown argument: %s\n' "$arg" >&2
        usage >&2
        exit 1
        ;;
    esac
  done
}

tb_column_name() {
  case "$1" in
    zen_pke_enc_path_tb) echo "pke_enc" ;;
    zen_pke_keygen_path_tb) echo "pke_keygen" ;;
    zen_pke_dec_path_tb) echo "pke_dec" ;;
    *)
      printf 'Unknown testbench: %s\n' "$1" >&2
      exit 1
      ;;
  esac
}

write_summary_outputs() {
  local tsv_path="$1"
  local md_path="$2"
  local csv_path="$3"
  local board_name="$4"

  if [ -n "$md_path" ]; then
    mkdir -p "$(dirname "$md_path")"
    {
      printf '# %s Path Cycle Summary\n\n' "${board_name^^}"
      printf '| Profile | `pke_enc` | `pke_keygen` | `pke_dec` |\n'
      printf '|---|---:|---:|---:|\n'
      awk '
        BEGIN {
          order[1] = "SAFE"
          order[2] = "BALANCED"
          order[3] = "TIMING"
          order[4] = "AGGR"
        }
        {
          key = $1 SUBSEP $2
          value[key] = $3
        }
        END {
          for (i = 1; i <= 4; i++) {
            profile = order[i]
            printf("| %s | %s | %s | %s |\n",
              profile,
              value[profile SUBSEP "pke_enc"],
              value[profile SUBSEP "pke_keygen"],
              value[profile SUBSEP "pke_dec"])
          }
        }
      ' "$tsv_path"
    } > "$md_path"
    log "写出 markdown 汇总: ${md_path}"
  fi

  if [ -n "$csv_path" ]; then
    mkdir -p "$(dirname "$csv_path")"
    {
      printf 'profile,pke_enc,pke_keygen,pke_dec\n'
      awk -F '\t' '
        BEGIN {
          order[1] = "SAFE"
          order[2] = "BALANCED"
          order[3] = "TIMING"
          order[4] = "AGGR"
        }
        {
          key = $1 SUBSEP $2
          value[key] = $3
        }
        END {
          for (i = 1; i <= 4; i++) {
            profile = order[i]
            printf("%s,%s,%s,%s\n",
              profile,
              value[profile SUBSEP "pke_enc"],
              value[profile SUBSEP "pke_keygen"],
              value[profile SUBSEP "pke_dec"])
          }
        }
      ' "$tsv_path"
    } > "$csv_path"
    log "写出 csv 汇总: ${csv_path}"
  fi
}

run_one() {
  local profile="$1"
  local tb_name="$2"
  local tsv_path="$3"
  local board="$4"
  local define
  local board_def
  local variant_def
  local label
  local build_name
  local out_dir
  local obj_dir
  local exe
  local log_path
  local total_line
  local total_cycles
  local column_name
  local -a cmd=()

  define="$(profile_define "$profile")"
  board_def="$(board_define "$board")"
  variant_def="ZEN_SWIFT_512"
  label="$(profile_label "$profile")"
  column_name="$(tb_column_name "$tb_name")"
  build_name="${tb_name}_${board}_${profile}"
  out_dir="${BUILD_DIR}/${build_name}"
  obj_dir="${out_dir}/obj_dir"
  exe="${out_dir}/${tb_name}"
  log_path="${LOG_DIR}/${build_name}.log"
  rm -rf "$out_dir"
  mkdir -p "$out_dir"

  cmd=(verilator --sv --timing --binary -Wno-fatal)
  if [ -n "$board_def" ]; then
    cmd+=(-D"$board_def")
  fi
  if [ -n "$variant_def" ]; then
    cmd+=(-D"$variant_def")
  fi
  if [ -n "$define" ]; then
    cmd+=(-D"$define")
  fi
  cmd+=(--top-module "$tb_name")
  cmd+=(-Mdir "$obj_dir")
  cmd+=(-o "$exe")
  cmd+=("${RTL_FILELIST[@]}")
  cmd+=("${TB_DIR}/${tb_name}.sv")

  if [ "$VERBOSE" -eq 1 ]; then
    log "编译 ${tb_name} (${label})"
    (
      cd "${ROOT_DIR}"
      "${cmd[@]}"
    ) 2>&1 | tee "$log_path"

    log "运行 ${tb_name} (${label})"
    (
      cd "${ROOT_DIR}"
      "$exe"
    ) 2>&1 | tee -a "$log_path"
  else
    {
      log "编译 ${tb_name} (${label})"
      (
        cd "${ROOT_DIR}"
        "${cmd[@]}"
      )
      log "运行 ${tb_name} (${label})"
      (
        cd "${ROOT_DIR}"
        "$exe"
      )
    } > "$log_path" 2>&1
  fi

  total_line="$(grep -E "(top-level command total cycles|fused command cycles) =" "$log_path" | tail -n 1 || true)"
  total_cycles="$(printf '%s\n' "$total_line" | sed -E 's/.*= ([0-9]+)$/\1/')"

  if [ -z "$total_cycles" ]; then
    printf 'Failed to extract total cycles from %s\n' "$log_path" >&2
    exit 1
  fi

  printf '%-8s %-12s %-12s %s\n' "$label" "$column_name" "$total_cycles" "$log_path"
  printf '%s\t%s\t%s\n' "$label" "$column_name" "$total_cycles" >> "$tsv_path"
}

main() {
  local -a profiles=()
  local -a selected=()
  local -a RTL_FILELIST=()
  local filelist_path
  local profile
  local tsv_path

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --board)
        BOARD_FAMILY="$2"
        shift 2
        ;;
      --summary-md)
        SUMMARY_MD="$2"
        shift 2
        ;;
      --summary-csv)
        SUMMARY_CSV="$2"
        shift 2
        ;;
      --verbose)
        VERBOSE=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        profiles+=("$1")
        shift
        ;;
    esac
  done

  readarray -t profiles < <(expand_profiles "${profiles[@]}")
  filelist_path="$(board_filelist "${BOARD_FAMILY}")"
  readarray -t RTL_FILELIST < <(sed "s#^#${RTL_DIR}/#" "${filelist_path}")

  declare -A seen=()
  for profile in "${profiles[@]}"; do
    if [ -z "$profile" ]; then
      continue
    fi
    if [ -z "${seen[$profile]:-}" ]; then
      selected+=("$profile")
      seen[$profile]=1
    fi
  done

  tsv_path="$(mktemp)"

  printf '%-8s %-12s %-12s %s\n' "PROFILE" "PATH" "TOTAL_CYCLES" "LOG"
  printf '%-8s %-12s %-12s %s\n' "-------" "------------" "------------" "---"

  for profile in "${selected[@]}"; do
    run_one "$profile" "zen_pke_enc_path_tb" "$tsv_path" "${BOARD_FAMILY}"
    run_one "$profile" "zen_pke_keygen_path_tb" "$tsv_path" "${BOARD_FAMILY}"
    run_one "$profile" "zen_pke_dec_path_tb" "$tsv_path" "${BOARD_FAMILY}"
  done

  write_summary_outputs "$tsv_path" "$SUMMARY_MD" "$SUMMARY_CSV" "${BOARD_FAMILY}"
  rm -f "$tsv_path"
}

main "$@"
