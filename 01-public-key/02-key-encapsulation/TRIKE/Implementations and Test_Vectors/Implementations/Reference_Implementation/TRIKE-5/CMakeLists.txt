cmake_minimum_required(VERSION 3.10)
project(TRIKE-5 C)

file(GLOB TRIKE_SOURCES
	"${CMAKE_CURRENT_SOURCE_DIR}/ICCS/*.c"
	"${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
)

add_library(trike5 STATIC ${TRIKE_SOURCES})
target_include_directories(trike5 PUBLIC
	"${CMAKE_CURRENT_SOURCE_DIR}/ICCS"
	"${CMAKE_CURRENT_SOURCE_DIR}/src"
)

add_executable(kat_kem "${CMAKE_CURRENT_SOURCE_DIR}/tests/KAT_KEM.c")
target_link_libraries(kat_kem PRIVATE trike5 m)