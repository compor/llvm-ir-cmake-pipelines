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
  string(TOUPPER "${PLINE_NAME}" PLINE_NAME_UPPER)

  set(PASS_TARGET LLVMPedigreePass)
  get_target_property(${PLINE_NAME}_PASS_TYPE ${PASS_TARGET} TYPE)

  if(NOT ${PLINE_NAME}_PASS_TYPE STREQUAL "MODULE_LIBRARY")
    message(FATAL_ERROR "package has unexpected TYPE: ${${PLINE_NAME}_PASS_TYPE}")
  endif()

  # pipeline targets and chaining
  get_target_property(${PLINE_NAME}_PASS_LOCATION ${PASS_TARGET} LOCATION)

  pipeline_parse_dep_args(PASS_TARGET ${PASS_TARGET} OUT LOAD_CMDLINE)

  set(${PLINE_NAME}_OPTIONS_CMDLINE "")
  foreach(opt $ENV{${PLINE_NAME_UPPER}_OPTIONS})
    list(APPEND ${PLINE_NAME}_OPTIONS_CMDLINE ${opt})
  endforeach()

  llvmir_attach_opt_pass_target(
    TARGET ${PLINE_PREFIX}_opt
    DEPENDS ${PLINE_DEPENDS}
    ${LOAD_CMDLINE}
    -load ${${PLINE_NAME}_PASS_LOCATION}
    ${${PLINE_NAME}_OPTIONS_CMDLINE})
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

