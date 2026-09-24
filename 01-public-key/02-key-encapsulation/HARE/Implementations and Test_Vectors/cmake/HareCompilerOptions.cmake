option(HARE_X86_ENABLE_LTO "Enable -flto/IPO for optimized x86 targets" OFF)
option(HARE_ARM_SVE_ENABLE_LTO "Enable -flto/IPO for ARM/SVE optimized targets" OFF)

function(hare_apply_c99_warnings target)
  target_compile_options(${target} PRIVATE -std=c99 -Wpedantic -Wall -Wextra -O2)
endfunction()

function(hare_apply_x86_performance_options target)
  target_compile_options(${target} PRIVATE
    -O3
    -march=x86-64
    -mavx2
    -mpclmul
    -fomit-frame-pointer
    -std=c99
    -Wpedantic
    -Wall
    -Wextra
  )
  if(HARE_X86_ENABLE_LTO)
    target_compile_options(${target} PRIVATE -flto)
    set_property(TARGET ${target} PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
  endif()
endfunction()

function(hare_apply_arm_sve_performance_options target)
  if(HARE_ARM_SVE_ENABLE_PMULL)
    set(_hare_arm_march -march=armv8.2-a+sve+crypto)
  else()
    set(_hare_arm_march -march=armv8.2-a+sve)
  endif()
  target_compile_options(${target} PRIVATE
    -O3
    ${_hare_arm_march}
    -fomit-frame-pointer
    -std=c99
    -Wpedantic
    -Wall
    -Wextra
  )
  if(HARE_ARM_SVE_ENABLE_LTO)
    target_compile_options(${target} PRIVATE -flto)
    set_property(TARGET ${target} PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
  endif()
endfunction()

function(hare_apply_instance_compile_options target role_upper core_kind_upper)
  if(core_kind_upper STREQUAL "X86")
    hare_apply_x86_performance_options(${target})
  elseif(core_kind_upper STREQUAL "ARM_SVE")
    hare_apply_arm_sve_performance_options(${target})
  elseif(role_upper STREQUAL "OPTIMIZED")
    hare_apply_x86_performance_options(${target})
  else()
    hare_apply_c99_warnings(${target})
  endif()
endfunction()
