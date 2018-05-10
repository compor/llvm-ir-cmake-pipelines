# cmake file

# pipeline that attaches to source level targets and performs:
# - conversion to SSA form
# - loop, CFG and function return simplification
# using standard LLVM opt passes

set(_THIS_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

include(${_THIS_LIST_DIR}/internal/common.cmake)

function(loopc14n_full)
  # CAUTION
  # function name and NAME provided below are required to match in order for
  # things to work, since there is currently no programmatic way of accessing
  # a function's name
  pipeline_setup(NAME "loopc14n_full" ${ARGV})

  # pipeline targets and chaining

  llvmir_attach_bc_target(
    TARGET ${PLINE_PREFIX}_bc
    DEPENDS ${PLINE_DEPENDS})
  add_dependencies(${PLINE_PREFIX}_bc ${PLINE_DEPENDS})

  llvmir_attach_opt_pass_target(
    TARGET ${PLINE_PREFIX}_opt
    DEPENDS ${PLINE_PREFIX}_bc
    -mem2reg
    -mergereturn
    -simplifycfg
    -loop-simplify)
  add_dependencies(${PLINE_PREFIX}_opt ${PLINE_PREFIX}_bc)

  llvmir_attach_link_target(
    TARGET ${PLINE_PREFIX}_link
    DEPENDS ${PLINE_PREFIX}_opt)
  add_dependencies(${PLINE_PREFIX}_link ${PLINE_PREFIX}_opt)

  llvmir_attach_executable(
    TARGET ${PLINE_PREFIX}_bc_exe
    DEPENDS ${PLINE_PREFIX}_link)
  add_dependencies(${PLINE_PREFIX}_bc_exe ${PLINE_PREFIX}_link)

  # aggregate targets for pipeline

  list(APPEND INTERNAL_TARGET_LIST
    ${PLINE_PREFIX}_bc
    ${PLINE_PREFIX}_opt
    ${PLINE_PREFIX}_link
    ${PLINE_PREFIX}_bc_exe)

  add_dependencies(${PLINE_SUBTARGET} ${INTERNAL_TARGET_LIST})

  # export targets

  set(${PLINE_MAIN_TARGET} "${PLINE_PREFIX}_link" PARENT_SCOPE)

  if(TARGET_LIST)
    list(APPEND INTERNAL_TARGET_LIST ${PLINE_SUBTARGET})
    set(${TARGET_LIST} "${INTERNAL_TARGET_LIST}" PARENT_SCOPE)
  endif()
endfunction()

