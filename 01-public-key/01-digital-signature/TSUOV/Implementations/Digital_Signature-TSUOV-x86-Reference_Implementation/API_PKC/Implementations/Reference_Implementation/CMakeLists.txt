set(SIG_REF_CFLAGS
    -std=c99 -Wpedantic -Wall -Wextra -O2
)

foreach(FOLDER ${SIG_ALG_FOLDERS})
    sig_parse_folder_name(${FOLDER} FAMILY LEVEL)
    set(ALG_DIR ${CMAKE_CURRENT_SOURCE_DIR}/${FOLDER})

    file(GLOB _srcs ${ALG_DIR}/*.c)
    list(FILTER _srcs EXCLUDE REGEX ".*/KAT_SIG\\.c$")
    if(NOT _srcs)
        message(FATAL_ERROR "No .c sources found in ${ALG_DIR}")
    endif()

    add_library(sigalg_${FOLDER} STATIC ${_srcs})
    target_include_directories(sigalg_${FOLDER} PUBLIC ${ALG_DIR})
    target_compile_options(sigalg_${FOLDER} PRIVATE ${SIG_REF_CFLAGS})
    set_target_properties(sigalg_${FOLDER} PROPERTIES
        OUTPUT_NAME "sigalg_${FOLDER}"
    )
    target_compile_definitions(sigalg_${FOLDER} PUBLIC
        ALG_SECURITY_LEVEL=${LEVEL}
        TSUOV_VARIANT=${LEVEL}
    )
    target_link_libraries(sigalg_${FOLDER} PUBLIC m)
endforeach()
