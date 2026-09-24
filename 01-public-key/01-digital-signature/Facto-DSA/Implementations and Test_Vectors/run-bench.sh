export CC=clang

cores="$(nproc)"
cpu_name=`lscpu | awk -F': *' '/Model name/ {print $2; exit}'`
arch=`uname -m`

if [ "$cores" -ge 3 ]; then
    cpu=2
elif [ "$cores" -ge 2 ]; then
    cpu=1
else
    cpu=0
fi

BASE_DIR="$(pwd)"

IMPL_DIR="${BASE_DIR}/Implementations/"
REF_DIR="${IMPL_DIR}/Reference_Implementation/"
OPTI_DIR="${IMPL_DIR}/Optimized_Implementation/"
RES_DIR="${IMPL_DIR}/Resource_Implementation/"

BENCH_DIR="${BASE_DIR}/ngcc_bench/"
BENCH_BUILD="${BENCH_DIR}/build/"

REPORTS_DIR="${BASE_DIR}/reports"

cd "$BENCH_DIR"
rm -rf build
mkdir -p build
cd build
cmake ..
make -j

rm -rf ${REPORTS_DIR}

REPORT_REF_DIR="${REPORTS_DIR}/Digital Signature-Facto-DSA-${arch}-Reference Implementation Version/${cpu_name}"
REPORT_PERF_DIR="${REPORTS_DIR}/Digital Signature-Facto-DSA-${arch}-Performance Optimization Version/${cpu_name}"
REPORT_RES_DIR="${REPORTS_DIR}/Digital Signature-Facto-DSA-${arch}-Resource Optimization Version/${cpu_name}"

mkdir -p "$REPORT_REF_DIR"
mkdir -p "$REPORT_PERF_DIR"
mkdir -p "$REPORT_RES_DIR"

# Reference IMPL

cd "${REF_DIR}/Facto-DSA-128"
make clean && make libfactodsa128-ref.so
cp libfactodsa128-ref.so "${BENCH_BUILD}"

cd "${REF_DIR}/Facto-DSA-256"
make clean && make libfactodsa256-ref.so
cp libfactodsa256-ref.so "${BENCH_BUILD}"

cd "${REF_DIR}/Facto-DSA-512"
make clean && make libfactodsa512-ref.so
cp libfactodsa512-ref.so "${BENCH_BUILD}"

# Optimized IMPL

cd "${OPTI_DIR}/Facto-DSA-128"
make clean && make libfactodsa128-opti.so
cp libfactodsa128-opti.so "${BENCH_BUILD}"

cd "${OPTI_DIR}/Facto-DSA-256"
make clean && make libfactodsa256-opti.so
cp libfactodsa256-opti.so "${BENCH_BUILD}"

cd "${OPTI_DIR}/Facto-DSA-512"
make clean && make libfactodsa512-opti.so
cp libfactodsa512-opti.so "${BENCH_BUILD}"

# Resource IMPL

cd "${RES_DIR}/Facto-DSA-128"
make clean && make libfactodsa128-res.so
cp libfactodsa128-res.so "${BENCH_BUILD}"

cd "${RES_DIR}/Facto-DSA-256"
make clean && make libfactodsa256-res.so
cp libfactodsa256-res.so "${BENCH_BUILD}"

cd "${RES_DIR}/Facto-DSA-512"
make clean && make libfactodsa512-res.so
cp libfactodsa512-res.so "${BENCH_BUILD}"

cd "${BENCH_BUILD}"

# Bench REF IMPL

taskset -c "$cpu" ./ngcc_bench --lib ./libfactodsa128-ref.so --test sig --mode performance --json-out "${REPORT_REF_DIR}"/facto-dsa-128.json
taskset -c "$cpu" ./ngcc_bench --lib ./libfactodsa256-ref.so --test sig --mode performance --json-out "${REPORT_REF_DIR}"/facto-dsa-256.json
taskset -c "$cpu" ./ngcc_bench --lib ./libfactodsa512-ref.so --test sig --mode performance --json-out "${REPORT_REF_DIR}"/facto-dsa-512.json

# Bench OPTI IMPL

taskset -c "$cpu" ./ngcc_bench --lib ./libfactodsa128-opti.so --test sig --mode performance --json-out "${REPORT_PERF_DIR}"/facto-dsa-128.json
taskset -c "$cpu" ./ngcc_bench --lib ./libfactodsa256-opti.so --test sig --mode performance --json-out "${REPORT_PERF_DIR}"/facto-dsa-256.json
taskset -c "$cpu" ./ngcc_bench --lib ./libfactodsa512-opti.so --test sig --mode performance --json-out "${REPORT_PERF_DIR}"/facto-dsa-512.json

# Bench RES IMPL

taskset -c "$cpu" ./ngcc_bench --lib ./libfactodsa128-res.so --test sig --mode performance --json-out "${REPORT_RES_DIR}"/facto-dsa-128.json
taskset -c "$cpu" ./ngcc_bench --lib ./libfactodsa256-res.so --test sig --mode performance --json-out "${REPORT_RES_DIR}"/facto-dsa-256.json
taskset -c "$cpu" ./ngcc_bench --lib ./libfactodsa512-res.so --test sig --mode performance --json-out "${REPORT_RES_DIR}"/facto-dsa-512.json
