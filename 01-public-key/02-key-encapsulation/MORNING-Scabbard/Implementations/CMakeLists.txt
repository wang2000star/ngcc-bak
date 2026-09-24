cmake_minimum_required(VERSION 4.3)

project(scabbard C ASM)
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_EXTENSIONS OFF)

# Includes
include(CTest)
enable_language(ASM)

set(CC gcc-13)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c99 -Wpedantic -Wall -Wextra")
set(SANITIZE "-fsanitize=address -fsanitize=undefined -fsanitize=leak -g3 -O0 ")
set(CMAKE_EXPORT_COMPILE_COMMANDS OFF)

# Compilation flags
option(AVX2_OPT "Build the AVX2 optimised implementation instead of the Reference" ON)
option(CMAKE_C_COMPILER "Compiler to use (e.g. `gcc`, `clang`)" gcc-13)

# flag only works on clang
if(CMAKE_C_COMPILER_ID STREQUAL "Clang")
	set(SANITIZE "${SANITIZE} -fsanitize=unsigned-integer-overflow")
endif()

set(CMAKE_C_FLAGS_DEBUG  "-Wuninitialized ${SANITIZE}")

message("Compilation flags:" ${C_FLAGS})

# selection of specialized compilation units differing between ref and opt
# implementations.
set(REFERENCE_CODE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Reference_Implementation)
set(AVX2_CODE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Optimized_Implementation)
set(TESTING_PATH ${CMAKE_CURRENT_SOURCE_DIR}/Additional_Implementations/Testing)

set(TESTING_HEADERS
	${TESTING_PATH}/speed_print.h
	${TESTING_PATH}/cpucycles.h
)

set(TESTING_SOURCES
	${TESTING_PATH}/speed_print.c
	${TESTING_PATH}/cpucycles.c
)

set(IMPLEMENTATIONS scabbard128 scabbard256 scabbard512)

set(TESTS test_packing test_indcpa test_kem test_speed test_benchmark)

if(AVX2_OPT)
	set(WORKING_CODE_DIR ${AVX2_CODE_DIR})
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D__AVX2 -mavx2 -O3 -march=x86-64 -mtune=native -fomit-frame-pointer")
	message("Using AVX2 optimized code")
else()
	set(WORKING_CODE_DIR ${REFERENCE_CODE_DIR})
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2")
	message("Using reference code")
endif()

foreach(impl ${IMPLEMENTATIONS})
	set(IMPL_PATH ${WORKING_CODE_DIR}/${impl})
	message("Compiling for ${impl}")

	# Ensure assembler can find .inc files referenced by .S sources
	# The ASM include path must be target-local, otherwise multiple implementations
	# append directories globally and the assembler can choose the wrong .inc file.

	set(BASE_HEADERS
		${IMPL_PATH}/KEM_${impl}.h
		${IMPL_PATH}/api.h
		${IMPL_PATH}/auxfunc.h
		${IMPL_PATH}/cbd.h
		${IMPL_PATH}/drng.h
		${IMPL_PATH}/indcpa.h
		${IMPL_PATH}/poly.h
		${IMPL_PATH}/polyvec.h
		${IMPL_PATH}/packing.h
		${IMPL_PATH}/verify.h
		${IMPL_PATH}/params.h
		${IMPL_PATH}/minal.h
	)

	set(BASE_SOURCES
		${IMPL_PATH}/KEM_${impl}.c
		#${IMPL_PATH}/api.c
		${IMPL_PATH}/auxfunc.c
		${IMPL_PATH}/cbd.c
		${IMPL_PATH}/drng.c
		${IMPL_PATH}/indcpa.c
		${IMPL_PATH}/poly.c
		${IMPL_PATH}/polyvec.c
		${IMPL_PATH}/packing.c
		${IMPL_PATH}/verify.c
		${IMPL_PATH}/minal.c
	)
	if(AVX2_OPT)
		set(BASE_SOURCES
			${BASE_SOURCES}
			${IMPL_PATH}/round.S
		)
	endif()
	# SENG Requirement Executable
	add_executable(${impl}-genKat ${BASE_HEADERS} ${BASE_SOURCES} ${IMPL_PATH}/KAT_KEM.c)
	target_compile_options(${impl}-genKat PRIVATE
		$<$<COMPILE_LANGUAGE:ASM>:-Wa,-I${IMPL_PATH}>
	)
	target_link_libraries(${impl}-genKat crypto)

	# Tests
	if(BUILD_TESTING)
		foreach(test ${TESTS})
			set(HEADERS
				${BASE_HEADERS}
				${TESTING_HEADERS}
			)

			set(SOURCES
				${BASE_SOURCES}
				${TESTING_SOURCES}
			)
			add_executable(${impl}-${test} ${HEADERS} ${SOURCES} ${TESTING_PATH}/${test}.c)
			target_compile_options(${impl}-${test} PRIVATE
				$<$<COMPILE_LANGUAGE:ASM>:-Wa,-I${IMPL_PATH}>
			)
			target_include_directories(${impl}-${test} PRIVATE ${IMPL_PATH})
			if(${test} STREQUAL "test_kat")
			    message("Build test kat")
    			add_test(NAME ${impl}-${test} COMMAND ${impl}-${test} ${CMAKE_CURRENT_SOURCE_DIR}/Test_Vectors/KAT_KEM_${impl}.txt)
            else()
    			add_test(NAME ${impl}-${test} COMMAND ${impl}-${test})
            endif()
		endforeach()
	endif()
endforeach()
