# cmake file

# pipeline that attaches to bitcode level targets and performs:
# - conversion to SSA form
# - loop, CFG and function return simplification
# using standard LLVM opt passes

set(_THIS_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

include(${_THIS_LIST_DIR}/internal/common.cmake)

find_package(pedigree CONFIG REQUIRED)

function(pedigree)
  # CAUTION
  # function name and NAME provided below are required to match in order for
  # things to work, since there is currently no programmatic way of accessing
  # a function's name
  pipeline_setup(NAME "pedigree" ${ARGV})

  get_target_property(${NAME}_PASS_TYPE LLVMPedigreePass TYPE)

  if(NOT ${NAME}_PASS_TYPE STREQUAL "MODULE_LIBRARY")
    message(FATAL_ERROR "package has unexpected TYPE: ${${NAME}_PASS_TYPE}")
  endif()

  # pipeline targets and chaining
  get_target_property(${NAME}_PASS_LOCATION LLVMPedigreePass LOCATION)

  get_target_property(${NAME}_PASS_DEPENDEE LLVMPedigreePass DEPENDEE)
  set(${NAME}_LOAD_CMDLINE_ARG "")
  if(${NAME}_PASS_DEPENDEE)
    foreach(dep ${${NAME}_PASS_DEPENDEE})
      list(APPEND ${NAME}_LOAD_CMDLINE_ARG -load;${dep})
    endforeach()
  endif()

  set(${NAME}_OPTS_CMDLINE_ARG "")
  foreach(opt $ENV{PEDIGREE_OPTS})
    list(APPEND ${NAME}_OPTS_CMDLINE_ARG ${opt})
  endforeach()

  llvmir_attach_opt_pass_target(
    TARGET ${PLINE_PREFIX}_opt
    DEPENDS ${PLINE_DEPENDS}
    ${${NAME}_LOAD_CMDLINE_ARG}
    -load ${${NAME}_PASS_LOCATION}
    ${${NAME}_OPTS_CMDLINE_ARG})
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

