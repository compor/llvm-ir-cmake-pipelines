# cmake file

# pipeline that attaches to bitcode level targets and performs:
# - conversion to SSA form
# - loop, CFG and function return simplification
# using standard LLVM opt passes

set(_THIS_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

include(${_THIS_LIST_DIR}/internal/common.cmake)

function(loopc14n)
  # CAUTION
  # function name and NAME provided below are required to match in order for
  # things to work, since there is currently no programmatic way of accessing
  # a function's name
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

  get_target_property(SOURCE_FILES ${PLINE_PREFIX}_opt LLVMIR_FILES)
  list(LENGTH SOURCE_FILES FILES_NUMBER)

  if(FILES_NUMBER GREATER 1)
    llvmir_attach_link_target(
      TARGET ${PLINE_PREFIX}_link
      DEPENDS ${PLINE_PREFIX}_opt)
    add_dependencies(${PLINE_PREFIX}_link ${PLINE_PREFIX}_opt)
  endif()

  # aggregate targets for pipeline

  list(APPEND INTERNAL_TARGET_LIST
    ${PLINE_PREFIX}_opt)

  if(FILES_NUMBER GREATER 1)
    list(APPEND INTERNAL_TARGET_LIST
      ${PLINE_PREFIX}_link)
  endif()

  add_dependencies(${PLINE_SUBTARGET} ${INTERNAL_TARGET_LIST})

  # export targets

  if(FILES_NUMBER GREATER 1)
    set(${PLINE_MAIN_TARGET} "${PLINE_PREFIX}_link" PARENT_SCOPE)
  else()
    set(${PLINE_MAIN_TARGET} "${PLINE_PREFIX}_opt" PARENT_SCOPE)
  endif()

  if(TRGT_LIST)
    list(APPEND INTERNAL_TARGET_LIST ${PLINE_SUBTARGET})
    set(${PLINE_TARGET_LIST} "${INTERNAL_TARGET_LIST}" PARENT_SCOPE)
  endif()
endfunction()

