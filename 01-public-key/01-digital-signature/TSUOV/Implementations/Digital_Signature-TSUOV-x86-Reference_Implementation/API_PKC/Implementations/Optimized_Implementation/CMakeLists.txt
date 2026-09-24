set(SIG_OPT_CFLAGS
    -O3 -march=x86-64 -mavx2 -mtune=native -flto
    -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra
)

set(SIG_KAT_TARGETS "")

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
    target_compile_options(sigalg_${FOLDER} PRIVATE ${SIG_OPT_CFLAGS})
    set_target_properties(sigalg_${FOLDER} PROPERTIES
        INTERPROCEDURAL_OPTIMIZATION TRUE
        OUTPUT_NAME "sigalg_${FOLDER}"
    )
    target_compile_definitions(sigalg_${FOLDER} PUBLIC
        ALG_SECURITY_LEVEL=${LEVEL}
        TSUOV_VARIANT=${LEVEL}
    )
    target_link_libraries(sigalg_${FOLDER} PUBLIC crypto m)

    if(EXISTS ${ALG_DIR}/KAT_SIG.c)
        add_executable(KAT_SIG_${FOLDER} ${ALG_DIR}/KAT_SIG.c)
        target_include_directories(KAT_SIG_${FOLDER} PRIVATE ${ALG_DIR})
        target_compile_options(KAT_SIG_${FOLDER} PRIVATE ${SIG_OPT_CFLAGS} -fno-pie)
        set_target_properties(KAT_SIG_${FOLDER} PROPERTIES
            LINK_FLAGS "-no-pie"
            INTERPROCEDURAL_OPTIMIZATION TRUE
        )
        target_link_libraries(KAT_SIG_${FOLDER} PRIVATE sigalg_${FOLDER})

        add_custom_target(kat_${FOLDER}
            COMMAND KAT_SIG_${FOLDER}
            WORKING_DIRECTORY ${ALG_DIR}
            DEPENDS KAT_SIG_${FOLDER}
            COMMENT "Generate KAT vectors for ${FOLDER} -> ${FOLDER}/output/"
        )
        list(APPEND SIG_KAT_TARGETS kat_${FOLDER})
    endif()
endforeach()

if(SIG_KAT_TARGETS)
    add_custom_target(kat DEPENDS ${SIG_KAT_TARGETS})
endif()
