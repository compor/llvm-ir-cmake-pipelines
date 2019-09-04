# cmake file

# pipeline that attaches to bitcode level targets and performs:
# - various off-the-shelf alias analyses
# using standard LLVM opt passes

set(_THIS_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

include(${_THIS_LIST_DIR}/internal/common.cmake)

function(aa1)
  # CAUTION
  # function name and NAME provided below are required to match in order for
  # things to work, since there is currently no programmatic way of accessing
  # a function's name
  pipeline_setup(NAME "aa1" ${ARGV})

  # pipeline targets and chaining

  llvmir_attach_opt_pass_target(
    TARGET ${PLINE_PREFIX}_opt
    DEPENDS ${PLINE_DEPENDS}
    -basicaa
    -scev-aa
    -globals-aa
    -tbaa)
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

