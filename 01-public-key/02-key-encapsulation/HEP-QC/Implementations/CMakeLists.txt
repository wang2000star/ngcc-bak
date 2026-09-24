cmake_minimum_required(VERSION 3.21)
project(hep-qc VERSION 1.0 LANGUAGES C CXX)

# Enable testing & export compile commands
enable_testing()
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# -----------------------------------------------------------------------------
# ARCHITECTURE SELECTION
# -----------------------------------------------------------------------------
set(HEP_QC_ARCH "ref" CACHE STRING "Choose implementation: ref or x86_64")
set_property(CACHE HEP_QC_ARCH PROPERTY STRINGS ref x86_64)
if(NOT HEP_QC_ARCH STREQUAL "ref" AND NOT HEP_QC_ARCH STREQUAL "x86_64")
    message(FATAL_ERROR "HEP_QC_ARCH must be 'ref' or 'x86_64'")
endif()

# -----------------------------------------------------------------------------
# COMPILE-TIME MACROS
# -----------------------------------------------------------------------------
if(HEP_QC_ARCH STREQUAL "ref")
    add_compile_definitions(HEP_QC_ARCH_REF=1)
else()
    add_compile_definitions(HEP_QC_ARCH_X86_64=1)
endif()

# -----------------------------------------------------------------------------
# WARNING & OPTIMIZATION FLAGS (always on)
# -----------------------------------------------------------------------------
set(HEP_QC_C_FLAGS
        -Wall -Werror -Wextra -Wpedantic -Wredundant-decls
)

# -----------------------------------------------------------------------------
# C STANDARD & SANITIZERS
# -----------------------------------------------------------------------------
set(HEP_QC_C_STANDARD "99" CACHE STRING "Select a C standard")
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD ${HEP_QC_C_STANDARD})

# Default build-type based optimization
if(CMAKE_BUILD_TYPE MATCHES Debug)
    list(APPEND HEP_QC_C_FLAGS -O0)
else()
    list(APPEND HEP_QC_C_FLAGS -O3)
endif()

set(HEP_QC_SANITIZER "NONE" CACHE STRING "Select a sanitizer: NONE, ASAN, LSAN, MSAN, UBSAN")
mark_as_advanced(HEP_QC_SANITIZER)
option(CLANG_FORMAT_ARCH "" "If non-empty, only format files under Implementations/<this>; e.g. ref or x86_64")

if(HEP_QC_SANITIZER STREQUAL "ASAN")
    list(REMOVE_ITEM HEP_QC_C_FLAGS -O3 -O0)
    list(APPEND HEP_QC_C_FLAGS -O1 -g -fsanitize=address -fno-omit-frame-pointer)
    add_link_options(-fsanitize=address)
elseif(HEP_QC_SANITIZER STREQUAL "LSAN")
    list(REMOVE_ITEM HEP_QC_C_FLAGS -O3 -O0)
    list(APPEND HEP_QC_C_FLAGS -O1 -g -fsanitize=leak -fno-omit-frame-pointer)
    add_link_options(-fsanitize=leak)
elseif(HEP_QC_SANITIZER STREQUAL "MSAN")
    list(REMOVE_ITEM HEP_QC_C_FLAGS -O3 -O0)
    list(APPEND HEP_QC_C_FLAGS -O1 -g -fsanitize=memory -fsanitize-memory-track-origins=2)
    add_link_options(-fsanitize=memory)
elseif(HEP_QC_SANITIZER STREQUAL "UBSAN")
    list(REMOVE_ITEM HEP_QC_C_FLAGS -O3 -O0)
    list(APPEND HEP_QC_C_FLAGS -O1 -g -fsanitize=undefined)
    add_link_options(-fsanitize=undefined)
endif()

foreach(hep_qc_c_flag IN LISTS HEP_QC_C_FLAGS)
    add_compile_options($<$<COMPILE_LANGUAGE:C>:${hep_qc_c_flag}>)
endforeach()

# -----------------------------------------------------------------------------
# BUILD SUBDIRECTORIES
# -----------------------------------------------------------------------------
set(VARIANTS hep-qc-1 hep-qc-3 hep-qc-5 hep-qc-7)

add_subdirectory(Lib)
add_subdirectory(Implementations)
add_subdirectory(Tests)

# -----------------------------------------------------------------------------
# FORMAT, STATIC ANALYSIS, PACKAGING
# -----------------------------------------------------------------------------
find_program(CLANG_FORMAT_EXE NAMES clang-format-18 clang-format)
if(CLANG_FORMAT_EXE)
    file(GLOB_RECURSE ALL_SRC
            Implementations/*.c Implementations/*.h
            Lib/*.c Lib/*.h
            Tests/*.c Tests/*.h Tests/*.cpp
    )
    list(FILTER ALL_SRC EXCLUDE REGEX ".*/parameters\\.h$")
    if(CLANG_FORMAT_ARCH)
        list(FILTER ALL_SRC INCLUDE REGEX ".*/Implementations/${CLANG_FORMAT_ARCH}/.*")
    endif()
    add_custom_target(check-format
            COMMAND ${CLANG_FORMAT_EXE} --dry-run --Werror --style=file ${ALL_SRC}
            COMMENT "Checking formatting with ${CLANG_FORMAT_EXE}"
    )
    add_custom_target(clang-format
            COMMAND ${CLANG_FORMAT_EXE} -i --style=file ${ALL_SRC}
            COMMENT "Reformatting all sources with ${CLANG_FORMAT_EXE}"
    )
endif()

find_program(CPPCHECK_EXE NAMES cppcheck)
if(CPPCHECK_EXE)
    file(GLOB_RECURSE CPPCHECK_SRCS
            Implementations/*.c Implementations/*.h
            Lib/*.c Lib/*.h
            Tests/*.c Tests/*.h Tests/*.cpp
    )
    add_custom_target(cppcheck
            COMMAND ${CPPCHECK_EXE}
            --project=${CMAKE_BINARY_DIR}/compile_commands.json
            --enable=all
            --inconclusive
            --suppress=missingIncludeSystem
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            COMMENT "Running cppcheck via compile_commands.json"
            VERBATIM
    )
endif()

