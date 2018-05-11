# cmake file

# pipeline that attaches to source level targets and produces LLVM IR

set(_THIS_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

include(${_THIS_LIST_DIR}/internal/common.cmake)

function(basicbc)
  # CAUTION
  # function name and NAME provided below are required to match in order for
  # things to work, since there is currently no programmatic way of accessing
  # a function's name
  pipeline_setup(NAME "basicbc" ${ARGV})

  # pipeline targets and chaining

  llvmir_attach_bc_target(
    TARGET ${PLINE_PREFIX}_bc
    DEPENDS ${PLINE_DEPENDS})
  add_dependencies(${PLINE_PREFIX}_bc ${PLINE_DEPENDS})

  # aggregate targets for pipeline

  list(APPEND INTERNAL_TARGET_LIST
    ${PLINE_PREFIX}_bc)

  add_dependencies(${PLINE_SUBTARGET} ${INTERNAL_TARGET_LIST})

  # export targets

  set(${PLINE_MAIN_TARGET} "${PLINE_PREFIX}_bc" PARENT_SCOPE)

  if(PLINE_TARGET_LIST)
    list(APPEND INTERNAL_TARGET_LIST ${PLINE_SUBTARGET})
    set(${PLINE_TARGET_LIST} "${INTERNAL_TARGET_LIST}" PARENT_SCOPE)
  endif()
endfunction()

