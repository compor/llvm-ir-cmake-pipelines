# cmake file

# pipeline that attaches to bitcode level targets and performs:
# - conversion to SSA form
# - loop, CFG and function return simplification
# using standard LLVM opt passes

set(_THIS_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

include(${_THIS_LIST_DIR}/internal/common.cmake)

find_package(pedigree CONFIG REQUIRED)

get_target_property(_PEDIGREE_PASS_TYPE LLVMPedigreePass TYPE)

if(NOT _PEDIGREE_PASS_TYPE STREQUAL "MODULE_LIBRARY")
  message(FATAL_ERROR "package has unexpected TYPE: ${_PEDIGREE_PASS_TYPE}")
endif()

function(pedigree)
  # CAUTION
  # function name and NAME provided below are required to match in order for
  # things to work, since there is currently no programmatic way of accessing
  # a function's name
  pipeline_setup(NAME "pedigree" ${ARGV})

  # pipeline targets and chaining
  get_target_property(_PEDIGREE_PASS_LOCATION LLVMPedigreePass LOCATION)

  get_target_property(_PEDIGREE_PASS_DEPENDEE LLVMPedigreePass DEPENDEE)
  set(_PEDIGREE_LOAD_CMDLINE_ARG "")
  if(_PEDIGREE_PASS_DEPENDEE)
    foreach(dep ${_PEDIGREE_PASS_DEPENDEE})
      list(APPEND _PEDIGREE_LOAD_CMDLINE_ARG -load;${dep})
    endforeach()
  endif()

  set(_PEDIGREE_OPTS_CMDLINE_ARG "")
  foreach(opt $ENV{PEDIGREE_OPTS})
    list(APPEND _PEDIGREE_OPTS_CMDLINE_ARG ${opt})
  endforeach()

  llvmir_attach_opt_pass_target(
    TARGET ${PLINE_PREFIX}_opt
    DEPENDS ${PLINE_DEPENDS}
    ${_PEDIGREE_LOAD_CMDLINE_ARG}
    -load ${_PEDIGREE_PASS_LOCATION}
    -pedigree-pdg
    ${_PEDIGREE_OPTS_CMDLINE_ARG})
  add_dependencies(${PLINE_PREFIX}_opt ${PLINE_DEPENDS})

  # aggregate targets for pipeline

  list(APPEND INTERNAL_TARGET_LIST
    ${PLINE_PREFIX}_opt)

  add_dependencies(${PLINE_SUBTARGET} ${INTERNAL_TARGET_LIST})

  # expose targets

  set(${PLINE_MAIN_TARGET} "${PLINE_PREFIX}_opt" PARENT_SCOPE)

  if(TRGT_LIST)
    list(APPEND INTERNAL_TARGET_LIST ${PLINE_SUBTARGET})
    set(${PLINE_TARGET_LIST} "${INTERNAL_TARGET_LIST}" PARENT_SCOPE)
  endif()
endfunction()

