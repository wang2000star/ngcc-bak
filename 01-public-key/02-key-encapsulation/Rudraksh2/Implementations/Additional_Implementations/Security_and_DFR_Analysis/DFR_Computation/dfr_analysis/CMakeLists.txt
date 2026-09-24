cmake_minimum_required(VERSION 3.10.2)
enable_language(C ASM)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -march=native")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Winit-self")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c99 -Wno-array-parameter")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -funsigned-char -Wall -Wextra -Wpedantic")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wunused -Wcomment -Wchar-subscripts -Wuninitialized -Wshadow")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wwrite-strings -Wno-deprecated-declarations -Wno-unknown-pragmas -Wformat-security")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wcast-qual -Wunused-result -fPIC -fopenmp")

function(add_minal_variant suffix is_lwr)
    set(mp_matrix_target    "mp_matrix_${suffix}")
    set(fft_mpc_target      "fft_mpc_${suffix}")
    set(fft_mpc_test_target "fft_mpc_test_${suffix}")
    set(dfr_2d_target       "dfr_2d_codes_${suffix}")
    set(minal2d_target      "minal2d_dfr_computation_${suffix}")
    set(prob_dist_target    "prob_dist_${suffix}")

    # mp_matrix
    add_library(${mp_matrix_target} mp_matrix.c)
    target_link_libraries(${mp_matrix_target}
        PRIVATE
            mpfr
            mpc
            m
    )

    # fft_mpc
    add_library(${fft_mpc_target} fft_mpc.c)
    target_link_libraries(${fft_mpc_target}
        PRIVATE
            ${mp_matrix_target}
    )

    # fft_mpc_test
    add_executable(${fft_mpc_test_target} fft_mpc.c)
    target_compile_definitions(${fft_mpc_test_target}
        PRIVATE
            FFT_MPC_TEST
    )
    target_link_libraries(${fft_mpc_test_target}
        PRIVATE
            ${mp_matrix_target}
    )

    # dfr_2d_codes
    add_library(${dfr_2d_target} dfr_2d_codes.c minal.c)
    target_link_libraries(${dfr_2d_target}
        PRIVATE
            ${mp_matrix_target}
    )
    target_include_directories(${dfr_2d_target}
        PRIVATE
            ${CMAKE_SOURCE_DIR}
    )

    # minal2d_dfr_computation
    add_executable(${minal2d_target} joint_distribution_2d.c)
    target_compile_definitions(${minal2d_target}
        PRIVATE
            COMPUTE_JOINT_DISTRIBUTIONS_AND_DFR
    )
    target_link_libraries(${minal2d_target}
        PRIVATE
            ${fft_mpc_target}
            ${mp_matrix_target}
            ${dfr_2d_target}
    )

    # prob_dist
    add_library(${prob_dist_target} prob_dist.c)
    target_link_libraries(${prob_dist_target}
        PRIVATE
            mpfr
            m
    )

    # Definitions applying to the entire variant
    if(is_lwr)
        set(variant_targets
            ${mp_matrix_target}
            ${fft_mpc_target}
            ${fft_mpc_test_target}
            ${dfr_2d_target}
            ${minal2d_target}
            ${prob_dist_target}
        )

        foreach(target IN LISTS variant_targets)
            target_compile_definitions(${target}
                PRIVATE
                    MINAL_ANALYSIS_FOR_LWR
            )
        endforeach()
    endif()
endfunction()


# Generate both variants in the same build.
add_minal_variant(lwe FALSE)
add_minal_variant(lwr TRUE)
