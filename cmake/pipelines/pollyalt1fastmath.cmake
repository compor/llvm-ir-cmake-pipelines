# cmake file

# pipeline that attaches to bitcode level targets and performs a series of LLVM
# polly passes

set(_THIS_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

include(${_THIS_LIST_DIR}/internal/common.cmake)

function(pollyalt1fastmath)
  # CAUTION
  # function name and NAME provided below are required to match in
  # order for things to work, since there is currently no programmatic way of
  # accessing a function's name
  pipeline_setup(NAME "pollyalt1fastmath" ${ARGV})

  if(NOT DEFINED ENV{POLLYALT1FASTMATH_PASS_MODULE})
    message(FATAL_ERROR "pipeline ${PLINE_NAME} requires env variable: \
    POLLYALT1FASTMATH_PASS_MODULE")
  endif()

  # pipeline targets and chaining

  llvmir_attach_opt_pass_target(
    TARGET ${PLINE_PREFIX}_opt
    DEPENDS ${PLINE_DEPENDS}
    -load $ENV{POLLYALT1FASTMATH_PASS_MODULE}
    -polly-canonicalize
    -polly-process-unprofitable
    -polly-scops
    -polly-export-jscop
    -polly-codegen
    -polly-parallel)
  add_dependencies(${PLINE_PREFIX}_opt ${PLINE_DEPENDS})

  # aggregate targets for pipeline

  list(APPEND INTERNAL_TARGET_LIST
    ${PLINE_PREFIX}_opt)

  add_dependencies(${PLINE_SUBTARGET} ${INTERNAL_TARGET_LIST})

  # expose targets

  set(${PLINE_MAIN_TARGET} "${PLINE_PREFIX}_opt" PARENT_SCOPE)

  if(PLINE_TARGET_LIST)
    list(APPEND INTERNAL_TARGET_LIST ${PLINE_SUBTARGET})
    set(${PLINE_TARGET_LIST} "${INTERNAL_TARGET_LIST}" PARENT_SCOPE)
  endif()
endfunction()

