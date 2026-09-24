cmake_minimum_required(VERSION 3.10)
project(qube_reference_instances C)

enable_testing()

add_subdirectory(qube-128)
add_subdirectory(qube-192)
add_subdirectory(qube-256)
add_subdirectory(qube-384)
add_subdirectory(qube-512)
