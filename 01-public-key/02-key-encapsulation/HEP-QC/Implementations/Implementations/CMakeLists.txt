cmake_minimum_required(VERSION 3.21)
project(hep-qc-Implementations C)

# List of HEP-QC parameter variants
set(VARIANTS "hep-qc-1;hep-qc-3;hep-qc-5;hep-qc-7" CACHE INTERNAL "List of variants")

# 1) cross-arch common sources
file(GLOB COMMON_SOURCES
        "${CMAKE_SOURCE_DIR}/Implementations/common/*.c"
)

# 2) arch-common: shared across variants (top-level .c)
if(HEP_QC_ARCH STREQUAL "ref")
    set(ARCH_COMMON_DIR "${CMAKE_SOURCE_DIR}/Implementations/ref")
else()
    set(ARCH_COMMON_DIR "${CMAKE_SOURCE_DIR}/Implementations/x86_64")
endif()
file(GLOB ARCH_COMMON_TOP_SOURCES
        "${ARCH_COMMON_DIR}/*.c"
)

# 3) arch-specific implementation sources
if(HEP_QC_ARCH STREQUAL "ref")
    set(PLATFORM_DIR "${CMAKE_SOURCE_DIR}/Implementations/ref")
else()
    set(PLATFORM_DIR "${CMAKE_SOURCE_DIR}/Implementations/x86_64")
endif()
file(GLOB PLATFORM_SOURCES
        "${PLATFORM_DIR}/*.c"
)

# 4) build one static library per variant
foreach(var IN LISTS VARIANTS)
    string(REPLACE "-" "_" safe_tmp ${var})
    string(TOUPPER ${safe_tmp} safe)

    if(HEP_QC_ARCH STREQUAL "ref")
        set(VAR_DIR "${CMAKE_SOURCE_DIR}/Implementations/ref/${var}")
    else()
        set(VAR_DIR "${CMAKE_SOURCE_DIR}/Implementations/x86_64/${var}")
    endif()
    file(GLOB VARIANT_SOURCES
            "${VAR_DIR}/*.c"
    )

    file(GLOB ARCH_COMMON_VARIANT_SOURCES
            "${ARCH_COMMON_DIR}/${var}/*.c"
    )

    add_library(${safe}_${HEP_QC_ARCH} STATIC
            ${COMMON_SOURCES}
            ${ARCH_COMMON_TOP_SOURCES}
            ${ARCH_COMMON_VARIANT_SOURCES}
            ${PLATFORM_SOURCES}
            ${VARIANT_SOURCES}
    )

    target_include_directories(${safe}_${HEP_QC_ARCH} PUBLIC
            "${CMAKE_SOURCE_DIR}/Implementations/common"
            "${CMAKE_SOURCE_DIR}/Implementations/common/${var}"
            "${ARCH_COMMON_DIR}"
            "${ARCH_COMMON_DIR}/${var}"
            "${PLATFORM_DIR}"
            "${VAR_DIR}"
            "${CMAKE_SOURCE_DIR}/lib/drng"
            "${CMAKE_SOURCE_DIR}/lib/auxfunc"
    )

    target_link_libraries(${safe}_${HEP_QC_ARCH} PUBLIC
            drng
            auxfunc
    )
endforeach()
