cmake_minimum_required(VERSION 3.20)

project(Rudraksh C ASM)

# Includes
include(CTest)
enable_language(ASM)

set(CC gcc)
# set(CC gcc-13)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c99 -Wpedantic -Wall -Wextra")
set(SANITIZE "-fsanitize=address -fsanitize=undefined -fsanitize=leak -g3 -O0 ")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Compilation flags
option(AVX2_OPT "Build the AVX2 optimised implementation instead of the Reference" ON)
option(CMAKE_C_COMPILER "Compiler to use (e.g. `gcc`, `clang`)" gcc-13)

# flag only works on clang
if(CMAKE_C_COMPILER_ID STREQUAL "Clang")
	set(SANITIZE "${SANITIZE} -fsanitize=unsigned-integer-overflow")
endif()

# Configuration for different build types
set(CMAKE_C_FLAGS_DEBUG  "-Wuninitialized ${SANITIZE}")
set(CMAKE_C_FLAGS_RELEASE  "-O2 -DNDEBUG")
if(CMAKE_BUILD_TYPE STREQUAL "Profile")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2 -DNDEBUG -pg")
endif()

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

set(IMPLEMENTATIONS lwekem128 lwekem256 lwekem512)

set(TESTS test_reduce test_packing test_ntt test_indcpa test_kem test_poly test_polyvec test_cbd
	test_kat test_seed test_benchmark test_basic)

if(AVX2_OPT)
	set(WORKING_CODE_DIR ${AVX2_CODE_DIR})
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mavx2 -march=x86-64 -mtune=native -fomit-frame-pointer")
    set(CMAKE_C_FLAGS_RELEASE  "-O3 -DNDEBUG")

	# For working LTO
	include(CheckIPOSupported)
	check_ipo_supported(RESULT lto_supported OUTPUT lto_error)
	if(lto_supported)
		set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
		message("Link Time Optimization (LTO) enabled successfully")
	else()
		message(WARNING "LTO requested but not supported by compiler: ${lto_error}")
	endif()
	message("Using AVX2 optimized code")
else()
	set(WORKING_CODE_DIR ${REFERENCE_CODE_DIR})
	message("Using reference code")
endif()

foreach(impl ${IMPLEMENTATIONS})
	set(IMPL_PATH ${WORKING_CODE_DIR}/${impl})
	message("Compiling for ${impl}")

	# Ensure assembler can find .inc files referenced by .S sources
	# The ASM include path must be target-local, otherwise multiple implementations
	# append directories globally and the assembler can choose the wrong .inc file.

	set(BASE_HEADERS
		#${IMPL_PATH}/KEM_${impl}.h
		#${IMPL_PATH}/api.h
		#${IMPL_PATH}/ascon.h
		${IMPL_PATH}/auxfunc.h
		${IMPL_PATH}/cbd.h
		${IMPL_PATH}/drng.h
		${IMPL_PATH}/indcpa.h
		#${IMPL_PATH}/kex.h
		${IMPL_PATH}/ntt.h
		${IMPL_PATH}/poly.h
		${IMPL_PATH}/polyvec.h
		${IMPL_PATH}/reduce.h
		${IMPL_PATH}/verify.h
		${IMPL_PATH}/params.h
		${IMPL_PATH}/minal.h
		${IMPL_PATH}/symmetric.h
	)

	set(BASE_SOURCES
		#${IMPL_PATH}/KEM_${impl}.c
		#${IMPL_PATH}/api.c
		#${IMPL_PATH}/ascon.c
		${IMPL_PATH}/auxfunc.c
		${IMPL_PATH}/cbd.c
		${IMPL_PATH}/drng.c
		${IMPL_PATH}/indcpa.c
		#${IMPL_PATH}/kex.c
		${IMPL_PATH}/ntt.c
		${IMPL_PATH}/poly.c
		${IMPL_PATH}/polyvec.c
		${IMPL_PATH}/reduce.c
		${IMPL_PATH}/verify.c
		${IMPL_PATH}/minal.c
	)

	# Additional files for AVX2
	if(AVX2_OPT)
		set(BASE_HEADERS
			${BASE_HEADERS}
			${IMPL_PATH}/consts.h
			${IMPL_PATH}/arith.inc
			${IMPL_PATH}/shuffle.inc
		)
		set(BASE_SOURCES
			${BASE_SOURCES}
			${IMPL_PATH}/ntt.S
			${IMPL_PATH}/invntt.S
			${IMPL_PATH}/poly.S
		)

		# Optimisation is better O2 for these sources
		#set_source_files_properties(${IMPL_PATH}/indcpa.c ${IMPL_PATH}/auxfunc.c
		#    PROPERTIES
		#		COMPILE_OPTIONS "-O2"
		#)
	endif()

	# Compile Library
	add_library(${impl} STATIC)
	target_sources(${impl}
		PRIVATE
			${BASE_SOURCES}
			${IMPL_PATH}/api.c
			${IMPL_PATH}/KEM_${impl}.c

		PRIVATE
			FILE_SET internalHeaders
			TYPE HEADERS
			BASE_DIRS ${IMPL_PATH}
			FILES
				${BASE_HEADERS}

		INTERFACE
			FILE_SET apiHeader
			TYPE HEADERS
			BASE_DIRS ${IMPL_PATH}
			FILES
				${IMPL_PATH}/api.h

		PUBLIC
			FILE_SET kemHeader
			TYPE HEADERS
			BASE_DIRS ${IMPL_PATH}
			FILES
				${IMPL_PATH}/KEM_${impl}.h
	)
	set_target_properties(${impl}
	    PROPERTIES
    	    C_STANDARD 99
    		C_EXTENSIONS OFF
	)

	# SENG Requirement Executable
	add_executable(${impl}-genKat)

	target_sources(${impl}-genKat
		PRIVATE
			${IMPL_PATH}/KAT_KEM.c
	)

	target_compile_options(${impl}-genKat PRIVATE
		$<$<COMPILE_LANGUAGE:ASM>:-Wa,-I${IMPL_PATH}>
	)

	target_link_libraries(${impl}-genKat
	    PRIVATE
			crypto
			${impl}
	)



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

			add_executable(${impl}-${test} ${TESTING_PATH}/${test}.c)

			#target_compile_options(${impl}-${test} PRIVATE
			#	$<$<COMPILE_LANGUAGE:ASM>:-Wa,-I${IMPL_PATH}>
			#)

           	set_target_properties(${impl}-${test}
           	    PROPERTIES
               	    C_STANDARD 23
              		C_EXTENSIONS ON
           	)

           	target_link_libraries(${impl}-${test}
           	    PRIVATE
         			${impl}
           	)



			if(${test} STREQUAL "test_kat")
			    message("Build test kat")
    			add_test(NAME ${impl}-${test} COMMAND ${impl}-${test} ${CMAKE_CURRENT_SOURCE_DIR}/Test_Vectors/KAT_KEM_${impl}.txt)
            else()
    			add_test(NAME ${impl}-${test} COMMAND ${impl}-${test})
            endif()
		endforeach()
	endif()
endforeach()
