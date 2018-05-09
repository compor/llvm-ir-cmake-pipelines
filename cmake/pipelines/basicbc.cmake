# cmake file

set(_THIS_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

include(${_THIS_LIST_DIR}/internal/common.cmake)

function(basicbc)
  pipeline_setup(NAME "basicbc" ${ARGV})

  # pipeline targets and chaining

  llvmir_attach_bc_target(
    TARGET ${PLINE_PREFIX}_bc
    DEPENDS ${PLINE_DEPENDS})
  add_dependencies(${PLINE_PREFIX}_bc ${PLINE_DEPENDS})

  llvmir_attach_link_target(
    TARGET ${PLINE_PREFIX}_link
    DEPENDS ${PLINE_PREFIX}_bc)
  add_dependencies(${PLINE_PREFIX}_link ${PLINE_PREFIX}_bc)

  llvmir_attach_executable(
    TARGET ${PLINE_PREFIX}_bc_exe
    DEPENDS ${PLINE_PREFIX}_link)
  add_dependencies(${PLINE_PREFIX}_bc_exe ${PLINE_PREFIX}_link)

  # aggregate targets for pipeline

  add_custom_target(${PLINE_SUBTARGET} DEPENDS
    ${PLINE_PREFIX}_bc
    ${PLINE_PREFIX}_link
    ${PLINE_PREFIX}_bc_exe)

  set(INTERNAL_TARGET_LIST "")
  list(APPEND INTERNAL_TARGET_LIST
    ${PLINE_PREFIX}_bc
    ${PLINE_PREFIX}_link
    ${PLINE_PREFIX}_bc_exe)

  add_dependencies(${PLINE_NAME} ${PLINE_SUBTARGET})

  # export targets

  set(${PLINE_MAIN_TARGET} "${PLINE_PREFIX}_link" PARENT_SCOPE)

  if(PLINE_TARGET_LIST)
    set(${PLINE_TARGET_LIST} "${INTERNAL_TARGET_LIST}" PARENT_SCOPE)
  endif()
endfunction()

