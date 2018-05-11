# cmake file

# pipeline that attaches to source level targets and produces LLVM IR

set(_THIS_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

include(${_THIS_LIST_DIR}/internal/common.cmake)

function(binary)
  # CAUTION
  # function name and NAME provided below are required to match in order for
  # things to work, since there is currently no programmatic way of accessing
  # a function's name
  pipeline_setup(NAME "binary" ${ARGV})

  # pipeline targets and chaining

  get_target_property(SOURCE_FILES ${PLINE_DEPENDS} LLVMIR_FILES)
  list(LENGTH SOURCE_FILES FILES_NUMBER)

  if(FILES_NUMBER GREATER 1)
    llvmir_attach_link_target(
      TARGET ${PLINE_PREFIX}_link
      DEPENDS ${PLINE_DEPENDS})
    add_dependencies(${PLINE_PREFIX}_link ${PLINE_DEPENDS})

    llvmir_attach_executable(
      TARGET ${PLINE_PREFIX}_link_out
      DEPENDS ${PLINE_PREFIX}_link)
    add_dependencies(${PLINE_PREFIX}_link_out ${PLINE_PREFIX}_link)
  else()
    llvmir_attach_executable(
      TARGET ${PLINE_PREFIX}_link_out
      DEPENDS ${PLINE_DEPENDS})
    add_dependencies(${PLINE_PREFIX}_link_out ${PLINE_DEPENDS})
  endif()

  # aggregate targets for pipeline

  if(FILES_NUMBER GREATER 1)
    list(APPEND INTERNAL_TARGET_LIST
      ${PLINE_PREFIX}_link
      ${PLINE_PREFIX}_link_out)
  else()
    list(APPEND INTERNAL_TARGET_LIST
      ${PLINE_PREFIX}_link_out)
  endif()

  add_dependencies(${PLINE_SUBTARGET} ${INTERNAL_TARGET_LIST})

  # export targets

  set(${PLINE_MAIN_TARGET} "${PLINE_PREFIX}_link_out" PARENT_SCOPE)

  if(PLINE_TARGET_LIST)
    list(APPEND INTERNAL_TARGET_LIST ${PLINE_SUBTARGET})
    set(${PLINE_TARGET_LIST} "${INTERNAL_TARGET_LIST}" PARENT_SCOPE)
  endif()
endfunction()

