cmake_minimum_required(VERSION 3.10)
project(TRIKE-9 C)

option(VPCLMUL_AVAILABLE "Enable VPCLMUL/AVX-512 optimized build flags" OFF)
option(AVX512_AVAILABLE "Enable AVX-512 build flags" OFF)

file(GLOB TRIKE_SOURCES
	"${CMAKE_CURRENT_SOURCE_DIR}/ICCS/*.c"
	"${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
)

add_library(trike9 STATIC ${TRIKE_SOURCES})
target_include_directories(trike9 PUBLIC
	"${CMAKE_CURRENT_SOURCE_DIR}/ICCS"
	"${CMAKE_CURRENT_SOURCE_DIR}/src"
)

if(VPCLMUL_AVAILABLE)
	set(AVX512_AVAILABLE ON CACHE BOOL "Enable AVX-512 build flags" FORCE)
	target_compile_definitions(trike9 PUBLIC VPCLMUL_AVAILABLE)
	target_compile_options(trike9 PRIVATE
		-mvpclmulqdq
	)
endif()

if(AVX512_AVAILABLE)
	target_compile_definitions(trike9 PUBLIC AVX512_AVAILABLE)
	target_compile_options(trike9 PRIVATE
		-mavx512f
		-mavx512bw
		-mavx512dq
		-mavx512vl
		-mavx512vpopcntdq
	)
endif()

add_executable(kat_kem "${CMAKE_CURRENT_SOURCE_DIR}/tests/KAT_KEM.c")
target_link_libraries(kat_kem PRIVATE trike9 m)