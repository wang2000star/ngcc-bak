BASE_DIR="$(pwd)"

IMPL_DIR="${BASE_DIR}/Implementations/"
REF_DIR="${IMPL_DIR}/Reference_Implementation/"
OPTI_DIR="${IMPL_DIR}/Optimized_Implementation/"
RES_DIR="${IMPL_DIR}/Resource_Implementation/"

# Reference IMPL

cd "${REF_DIR}/Facto-DSA-128"
make clean

cd "${REF_DIR}/Facto-DSA-256"
make clean

cd "${REF_DIR}/Facto-DSA-512"
make clean

# Optimized IMPL

cd "${OPTI_DIR}/Facto-DSA-128"
make clean

cd "${OPTI_DIR}/Facto-DSA-256"
make clean

cd "${OPTI_DIR}/Facto-DSA-512"
make clean

# Resource IMPL

cd "${RES_DIR}/Facto-DSA-128"
make clean

cd "${RES_DIR}/Facto-DSA-256"
make clean

cd "${RES_DIR}/Facto-DSA-512"
make clean