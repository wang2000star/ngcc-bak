cmake_minimum_required(VERSION 3.10)

project(MasterCube_CryptHash C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

set(MCUBE_IMPL "reference" CACHE STRING "MasterCube implementation: reference, x86-performance, x86-resource, x86-avx512, arm-resource, arm-performance")
set(MCUBE_IMPLDIR "" CACHE PATH "Custom implementation directory containing MasterCube-512/768/1024 sources")
set(MCUBE_ARM_PERFORMANCE_MARCH "auto" CACHE STRING "ARM performance -march value: auto, armv8.2-a+sve, or armv8.2-a")
set_property(CACHE MCUBE_IMPL PROPERTY STRINGS reference x86-performance x86-resource x86-avx512 arm-resource arm-performance)
set_property(CACHE MCUBE_ARM_PERFORMANCE_MARCH PROPERTY STRINGS auto armv8.2-a+sve armv8.2-a)

set(MCUBE_ALGORITHMS
    MasterCube-512
    MasterCube-768
    MasterCube-1024
)

set(MCUBE_INSTANCE_API_FILES
    KAT_CryptHash.c
    CryptHash_AlgorithmInstance.c
    CryptHash_AlgorithmInstance.h
    drng.c
    drng.h
)

function(mcube_check_instance_dir instance_dir algorithm)
    if(NOT EXISTS "${instance_dir}/${algorithm}.c")
        message(FATAL_ERROR "Missing source: ${instance_dir}/${algorithm}.c")
    endif()
    if(NOT EXISTS "${instance_dir}/mastercube.h")
        message(FATAL_ERROR "Missing header: ${instance_dir}/mastercube.h")
    endif()
    foreach(api_file IN LISTS MCUBE_INSTANCE_API_FILES)
        if(NOT EXISTS "${instance_dir}/${api_file}")
            message(FATAL_ERROR "Missing official API file: ${instance_dir}/${api_file}")
        endif()
    endforeach()
endfunction()

function(mcube_add_algorithm_dir out_dirs out_sources base_dir leaf_dir)
    foreach(algorithm IN LISTS MCUBE_ALGORITHMS)
        set(candidate "${base_dir}/${algorithm}/${leaf_dir}")
        mcube_check_instance_dir("${candidate}" "${algorithm}")
        list(APPEND dirs "${candidate}")
        list(APPEND sources "${candidate}/${algorithm}.c")
    endforeach()
    set(${out_dirs} "${dirs}" PARENT_SCOPE)
    set(${out_sources} "${sources}" PARENT_SCOPE)
endfunction()

function(mcube_add_custom_algorithm_dir out_dirs out_sources custom_dir)
    foreach(algorithm IN LISTS MCUBE_ALGORITHMS)
        if(EXISTS "${custom_dir}/${algorithm}.c")
            set(candidate "${custom_dir}")
        else()
            set(candidate "${custom_dir}/${algorithm}")
        endif()
        mcube_check_instance_dir("${candidate}" "${algorithm}")
        list(APPEND dirs "${candidate}")
        list(APPEND sources "${candidate}/${algorithm}.c")
    endforeach()
    set(${out_dirs} "${dirs}" PARENT_SCOPE)
    set(${out_sources} "${sources}" PARENT_SCOPE)
endfunction()

function(mcube_copy_instance_api api_dir instance_dir)
    file(MAKE_DIRECTORY "${api_dir}")
    foreach(api_file IN LISTS MCUBE_INSTANCE_API_FILES)
        configure_file("${instance_dir}/${api_file}" "${api_dir}/${api_file}" COPYONLY)
    endforeach()
endfunction()

set(MCUBE_COMPILE_OPTIONS)

if(MCUBE_IMPLDIR)
    file(TO_CMAKE_PATH "${MCUBE_IMPLDIR}" MCUBE_CUSTOM_IMPLDIR)
    if(NOT IS_ABSOLUTE "${MCUBE_CUSTOM_IMPLDIR}")
        get_filename_component(MCUBE_CUSTOM_IMPLDIR "${MCUBE_CUSTOM_IMPLDIR}" ABSOLUTE BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    endif()
    mcube_add_custom_algorithm_dir(MCUBE_IMPL_DIRS MCUBE_IMPL_SOURCES "${MCUBE_CUSTOM_IMPLDIR}")
    list(APPEND MCUBE_COMPILE_OPTIONS -std=c99 -Wpedantic -Wall -Wextra -O2)
elseif(MCUBE_IMPL STREQUAL "reference")
    mcube_add_algorithm_dir(MCUBE_IMPL_DIRS MCUBE_IMPL_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/Reference_Implementation" "")
    list(APPEND MCUBE_COMPILE_OPTIONS -std=c99 -Wpedantic -Wall -Wextra -O2)
elseif(MCUBE_IMPL STREQUAL "x86-performance")
    mcube_add_algorithm_dir(MCUBE_IMPL_DIRS MCUBE_IMPL_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/Optimized_Implementation" "")
    list(APPEND MCUBE_COMPILE_OPTIONS -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra)
elseif(MCUBE_IMPL STREQUAL "x86-resource")
    mcube_add_algorithm_dir(MCUBE_IMPL_DIRS MCUBE_IMPL_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/Additional_Implementation" "X86/Resource_Optimized_Implementation")
    list(APPEND MCUBE_COMPILE_OPTIONS -Os -march=x86-64 -mavx2 -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra)
elseif(MCUBE_IMPL STREQUAL "x86-avx512")
    mcube_add_algorithm_dir(MCUBE_IMPL_DIRS MCUBE_IMPL_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/Additional_Implementation" "X86/AVX512_Implementation")
    list(APPEND MCUBE_COMPILE_OPTIONS -O3 -march=x86-64 -mavx512f -mavx512bw -mavx512vl -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra)
elseif(MCUBE_IMPL STREQUAL "arm-resource")
    mcube_add_algorithm_dir(MCUBE_IMPL_DIRS MCUBE_IMPL_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/Additional_Implementation" "ARM/Resource_Optimized_Implementation")
    list(APPEND MCUBE_COMPILE_OPTIONS -Os -march=armv8-a -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra)
elseif(MCUBE_IMPL STREQUAL "arm-performance")
    mcube_add_algorithm_dir(MCUBE_IMPL_DIRS MCUBE_IMPL_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/Additional_Implementation" "ARM/Performance_Optimized_Implementation")
    set(MCUBE_ARM_PERFORMANCE_EFFECTIVE_MARCH "${MCUBE_ARM_PERFORMANCE_MARCH}")
    if(MCUBE_ARM_PERFORMANCE_EFFECTIVE_MARCH STREQUAL "auto")
        set(MCUBE_ARM_PERFORMANCE_EFFECTIVE_MARCH "armv8.2-a+sve")
        if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)$" AND EXISTS "/proc/cpuinfo")
            file(READ "/proc/cpuinfo" MCUBE_PROC_CPUINFO)
            if(NOT MCUBE_PROC_CPUINFO MATCHES "(^|[ \t])sve([ \t]|$)")
                set(MCUBE_ARM_PERFORMANCE_EFFECTIVE_MARCH "armv8.2-a")
            endif()
        endif()
    endif()
    list(APPEND MCUBE_COMPILE_OPTIONS -O3 "-march=${MCUBE_ARM_PERFORMANCE_EFFECTIVE_MARCH}" -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra)
else()
    message(FATAL_ERROR "Unsupported MCUBE_IMPL='${MCUBE_IMPL}'")
endif()

add_library(mastercube_compile_objects OBJECT
    ${MCUBE_IMPL_SOURCES}
)
target_include_directories(mastercube_compile_objects PRIVATE
    ${MCUBE_IMPL_DIRS}
)
target_compile_options(mastercube_compile_objects PRIVATE ${MCUBE_COMPILE_OPTIONS})

add_custom_target(compile-only
    DEPENDS mastercube_compile_objects
)

set(MCUBE_TEST_VECTOR_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../Test_Vectors")
set(MCUBE_KAT_EXE_TARGETS)
set(MCUBE_VERIFY_COMMANDS)

list(LENGTH MCUBE_ALGORITHMS MCUBE_ALGORITHM_COUNT)
math(EXPR MCUBE_ALGORITHM_LAST_INDEX "${MCUBE_ALGORITHM_COUNT} - 1")

foreach(index RANGE 0 ${MCUBE_ALGORITHM_LAST_INDEX})
    list(GET MCUBE_ALGORITHMS ${index} algorithm)
    list(GET MCUBE_IMPL_DIRS ${index} impl_dir)
    list(GET MCUBE_IMPL_SOURCES ${index} impl_source)
    string(REPLACE "-" "_" target_suffix "${algorithm}")
    set(api_dir "${CMAKE_CURRENT_BINARY_DIR}/generated/${algorithm}")
    set(kat_target "kat_crypthash_${target_suffix}")

    mcube_copy_instance_api("${api_dir}" "${impl_dir}")

    add_executable(${kat_target}
        "${api_dir}/KAT_CryptHash.c"
        "${api_dir}/CryptHash_AlgorithmInstance.c"
        "${api_dir}/drng.c"
        "${impl_source}"
    )
    target_include_directories(${kat_target} PRIVATE
        "${api_dir}"
        "${impl_dir}"
    )
    target_compile_options(${kat_target} PRIVATE ${MCUBE_COMPILE_OPTIONS})

    set_target_properties(${kat_target} PROPERTIES
        OUTPUT_NAME "kat_crypthash"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${algorithm}"
    )

    list(APPEND MCUBE_KAT_EXE_TARGETS ${kat_target})

    list(APPEND MCUBE_VERIFY_COMMANDS
        COMMAND "${CMAKE_COMMAND}" -E chdir "${api_dir}" "$<TARGET_FILE:${kat_target}>"
    )
    foreach(prefix IN ITEMS KAT_2_12_ KAT_2_23_ KAT_2_33_ KAT_Loop_)
        set(kat_file "${prefix}${algorithm}.txt")
        list(APPEND MCUBE_VERIFY_COMMANDS
            COMMAND "${CMAKE_COMMAND}" -E compare_files
                    "${api_dir}/output/${kat_file}"
                    "${MCUBE_TEST_VECTOR_DIR}/${kat_file}"
        )
    endforeach()
endforeach()

add_custom_target(kat_crypthash
    DEPENDS ${MCUBE_KAT_EXE_TARGETS}
)

add_custom_target(verify
    ${MCUBE_VERIFY_COMMANDS}
    DEPENDS ${MCUBE_KAT_EXE_TARGETS}
)

add_custom_target(run
    ${MCUBE_VERIFY_COMMANDS}
    DEPENDS ${MCUBE_KAT_EXE_TARGETS}
)

message(STATUS "MCUBE_IMPL=${MCUBE_IMPL}")
message(STATUS "MCUBE_IMPLDIR=${MCUBE_IMPLDIR}")
message(STATUS "MCUBE_COMPILE_OPTIONS=${MCUBE_COMPILE_OPTIONS}")
