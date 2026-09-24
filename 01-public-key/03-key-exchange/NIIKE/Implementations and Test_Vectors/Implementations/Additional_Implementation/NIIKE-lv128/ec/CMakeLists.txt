set(SOURCE_FILES_EC_${SVARIANT_UPPER}
    ${COMMON_SRC_DIR}/ec/v8ec.c
    ${COMMON_SRC_DIR}/ec/v8kps.c
    ${COMMON_SRC_DIR}/ec/v8xisog.c
    ${COMMON_SRC_DIR}/ec/v8xeval.c
    ${COMMON_SRC_DIR}/ec/v8poly-mul.c
    ${COMMON_SRC_DIR}/ec/v8poly-redc.c
    ${COMMON_SRC_DIR}/ec/ec.c
    ${COMMON_SRC_DIR}/ec/kps.c
    ${COMMON_SRC_DIR}/ec/xisog.c
    ${COMMON_SRC_DIR}/ec/xeval.c
    ${COMMON_SRC_DIR}/ec/poly-mul.c
    ${COMMON_SRC_DIR}/ec/poly-redc.c
    v8dac.c
    dac.c
)

set(INC_EC_${SVARIANT_UPPER} ${CMAKE_CURRENT_SOURCE_DIR}/include ${COMMON_SRC_DIR}/ec/include CACHE INTERNAL "INC")
set(LIB_EC_${SVARIANT_UPPER} niike_ec_${SVARIANT} CACHE INTERNAL "LIB")
add_library(${LIB_EC_${SVARIANT_UPPER}} STATIC ${SOURCE_FILES_EC_${SVARIANT_UPPER}})
target_include_directories(${LIB_EC_${SVARIANT_UPPER}} PRIVATE ${INC_COMMON_${SVARIANT_UPPER}} ${INC_PRECOMP_${SVARIANT_UPPER}} ${INC_GF_${SVARIANT_UPPER}} ${INC_EC_${SVARIANT_UPPER}})
target_compile_options(${LIB_EC_${SVARIANT_UPPER}} PRIVATE ${C_OPT_FLAGS})
target_link_libraries(${LIB_EC_${SVARIANT_UPPER}} ${LIB_PRECOMP_${SVARIANT_UPPER}} ${LIB_GF_${SVARIANT_UPPER}})
