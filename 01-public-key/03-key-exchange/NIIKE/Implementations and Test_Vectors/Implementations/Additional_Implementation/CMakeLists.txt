cmake_minimum_required(VERSION 3.12)
project(NIIKE VERSION 1.0 LANGUAGES C ASM)

set(CMAKE_C_STANDARD 99)

set(C_OPT_FLAGS "")
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    add_definitions(-DRADIX_64)
else()
    message(FATAL_ERROR "This codebase currently supports only 64-bit systems")
endif()

include(CheckCSourceCompiles)
function(detect_avx512ifma OUT_VAR)
    set(code "
    #include <immintrin.h>
    int main() {
        __m512i a = _mm512_set1_epi64(1);
        __m512i b = _mm512_madd52lo_epu64(a, a, a);
        (void)b; return 0;
    }")

    if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
        set(CMAKE_REQUIRED_FLAGS "-march=native")
    endif()
    check_c_source_compiles("${code}" PLATFORM_SUPPORT_AVX512IFMA)
    unset(CMAKE_REQUIRED_FLAGS)
    set(${OUT_VAR} ${PLATFORM_SUPPORT_AVX512IFMA} PARENT_SCOPE)
endfunction()

if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
    detect_avx512ifma(NIIKE_PLATFORM_HAS_AVX512IFMA)
else()
    set(NIIKE_PLATFORM_HAS_AVX512IFMA FALSE)
endif()

if(NIIKE_PLATFORM_HAS_AVX512IFMA)
else()
    message(FATAL_ERROR "This platform does not support the AVX512IFMA instruction set.")
endif()

if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types -march=native")
endif()
if(CMAKE_C_COMPILER_ID MATCHES "Clang")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-error=macro-redefined")
endif()

add_subdirectory(NIIKE-lv128)