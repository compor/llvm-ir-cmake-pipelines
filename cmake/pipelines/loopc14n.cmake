# cmake file

set(_THIS_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

include(${_THIS_LIST_DIR}/internal/common.cmake)

function(loopc14n)
  pipeline_setup(NAME "loopc14n" ${ARGV})

  # pipeline targets and chaining

  llvmir_attach_opt_pass_target(
    TARGET ${PLINE_PREFIX}_opt
    DEPENDS ${PLINE_DEPENDS}
    -mem2reg
    -mergereturn
    -simplifycfg
    -loop-simplify)
  add_dependencies(${PLINE_PREFIX}_opt ${PLINE_DEPENDS})

  llvmir_attach_link_target(
    TARGET ${PLINE_PREFIX}_link
    DEPENDS ${PLINE_PREFIX}_opt)
  add_dependencies(${PLINE_PREFIX}_link ${PLINE_PREFIX}_opt)

  llvmir_attach_executable(
    TARGET ${PLINE_PREFIX}_bc_exe
    DEPENDS ${PLINE_PREFIX}_link)
  add_dependencies(${PLINE_PREFIX}_bc_exe ${PLINE_PREFIX}_link)

  # aggregate targets for pipeline

  add_custom_target(${PLINE_SUBTARGET} DEPENDS
    ${PLINE_PREFIX}_opt
    ${PLINE_PREFIX}_link
    ${PLINE_PREFIX}_bc_exe)

  list(APPEND INTERNAL_TARGET_LIST
    ${PLINE_SUBTARGET}
    ${PLINE_PREFIX}_opt
    ${PLINE_PREFIX}_link
    ${PLINE_PREFIX}_bc_exe)

  add_dependencies(${PLINE_NAME} ${PLINE_SUBTARGET})

  # export targets

  set(${PLINE_MAIN_TARGET} "${PLINE_PREFIX}_link" PARENT_SCOPE)

  if(TRGT_LIST)
    set(${PLINE_TARGET_LIST} "${INTERNAL_TARGET_LIST}" PARENT_SCOPE)
  endif()
endfunction()

