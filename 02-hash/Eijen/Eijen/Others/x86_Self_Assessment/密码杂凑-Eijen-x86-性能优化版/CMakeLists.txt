cmake_minimum_required(VERSION 3.11.4)
project(eijen_x86_performance_package C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

set(EIJEN_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/algorithm_source/include)
set(EIJEN_SOURCE algorithm_source/src/eijen_avx2.c)
set(EIJEN_FLAGS -std=c99 -Wpedantic -Wall -Wextra -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer)

add_library(eijen_impl_obj OBJECT ${EIJEN_SOURCE})
target_include_directories(eijen_impl_obj PRIVATE ${EIJEN_INCLUDE_DIR})
target_compile_options(eijen_impl_obj PRIVATE ${EIJEN_FLAGS})

add_executable(kat self_assessment/tests/eijen_kat.c $<TARGET_OBJECTS:eijen_impl_obj>)
target_include_directories(kat PRIVATE ${EIJEN_INCLUDE_DIR})
target_compile_options(kat PRIVATE ${EIJEN_FLAGS})
target_compile_definitions(kat PRIVATE EIJEN_HAS_HASH4)
target_link_options(kat PRIVATE -flto)

add_executable(bench self_assessment/tools/eijen_bench.c $<TARGET_OBJECTS:eijen_impl_obj>)
target_include_directories(bench PRIVATE ${EIJEN_INCLUDE_DIR})
target_compile_options(bench PRIVATE ${EIJEN_FLAGS})
target_link_options(bench PRIVATE -flto)

enable_testing()
add_test(NAME kat COMMAND kat)
