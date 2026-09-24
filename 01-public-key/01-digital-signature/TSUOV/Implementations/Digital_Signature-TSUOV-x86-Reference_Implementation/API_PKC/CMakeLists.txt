include(${CMAKE_SOURCE_DIR}/cmake/SigAlgorithmDiscovery.cmake)

if(PKC_OPTIMIZED_IMPL)
    set(SIG_IMPL_DIR_NAME "Optimized_Implementation")
else()
    set(SIG_IMPL_DIR_NAME "Reference_Implementation")
endif()

set(SIG_IMPL_ROOT
    ${CMAKE_CURRENT_SOURCE_DIR}/Implementations/${SIG_IMPL_DIR_NAME})
sig_discover_implementations(${SIG_IMPL_ROOT} SIG_ALG_FOLDERS)

if(PKC_OPTIMIZED_IMPL)
    add_subdirectory(Implementations/Optimized_Implementation)
else()
    add_subdirectory(Implementations/Reference_Implementation)
endif()

set(SIG_ALG_FOLDERS ${SIG_ALG_FOLDERS} PARENT_SCOPE)
set(SIG_IMPL_DIR_NAME ${SIG_IMPL_DIR_NAME} PARENT_SCOPE)
