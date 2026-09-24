file(GLOB DRNG_SRCS
        "${CMAKE_CURRENT_SOURCE_DIR}/drng/drng.c"
)
add_library(drng STATIC ${DRNG_SRCS})

target_include_directories(drng PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/drng
)


file(GLOB AUXFUNC_SRCS
        "${CMAKE_CURRENT_SOURCE_DIR}/auxfunc/auxfunc.c"
)
add_library(auxfunc STATIC ${AUXFUNC_SRCS})

target_include_directories(auxfunc PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/auxfunc
)