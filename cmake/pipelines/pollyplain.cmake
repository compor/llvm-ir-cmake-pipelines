# cmake file

# pipeline that attaches to bitcode level targets and performs a series of LLVM
# polly passes

set(_THIS_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

include(${_THIS_LIST_DIR}/internal/common.cmake)

function(pollyplain)
  # CAUTION
  # function name and NAME provided below are required to match in
  # order for things to work, since there is currently no programmatic way of
  # accessing a function's name
  pipeline_setup(NAME "pollyplain" ${ARGV})

  if(NOT ENV{POLLYPLAIN_PASS_MODULE})
    message(FATAL_ERROR "pipeline ${PLINE_NAME} requires env variable: \
    POLLYPLAIN_PASS_MODULE")
  endif()

  # pipeline targets and chaining

  llvmir_attach_opt_pass_target(
    TARGET ${PLINE_PREFIX}_link
    DEPENDS ${PLINE_DEPENDS}
    -load $ENV{POLLYPLAIN_PASS_MODULE}
    -polly-canonicalize
    -polly-scops
    -polly-export-jscop
    -polly-codegen
    -polly-parallel)
  add_dependencies(${PLINE_PREFIX}_link ${PLINE_DEPENDS})

  llvmir_attach_executable(
    TARGET ${PLINE_PREFIX}_bc_exe
    DEPENDS ${PLINE_PREFIX}_link)
  add_dependencies(${PLINE_PREFIX}_bc_exe ${PLINE_PREFIX}_link)

  # aggregate targets for pipeline

  add_custom_target(${PLINE_SUBTARGET} DEPENDS
    ${PLINE_DEPENDS}
    ${PLINE_PREFIX}_link
    ${PLINE_PREFIX}_bc_exe)

  list(APPEND INTERNAL_TARGET_LIST
    ${PLINE_SUBTARGET}
    ${PLINE_PREFIX}_link
    ${PLINE_PREFIX}_bc_exe)

  add_dependencies(${PLINE_NAME} ${PLINE_SUBTARGET})

  # export targets

  set(${PLINE_MAIN_TARGET} "${PLINE_PREFIX}_link" PARENT_SCOPE)

  if(PLINE_TARGET_LIST)
    set(${PLINE_TARGET_LIST} "${INTERNAL_TARGET_LIST}" PARENT_SCOPE)
  endif()
endfunction()

