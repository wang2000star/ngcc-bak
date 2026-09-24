cmake_minimum_required(VERSION 3.10)

set(MCUBE_IMPL "x86-performance" CACHE STRING "Build the MasterCube x86 performance implementation" FORCE)
add_subdirectory("${CMAKE_CURRENT_LIST_DIR}/.." "${CMAKE_BINARY_DIR}/MasterCubeX86Performance")
