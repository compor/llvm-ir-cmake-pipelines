# cmake file

# pipeline that attaches to source level targets and produces LLVM IR

set(_THIS_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

include(${_THIS_LIST_DIR}/internal/common.cmake)

function(binarybc)
  # CAUTION
  # function name and NAME provided below are required to match in order for
  # things to work, since there is currently no programmatic way of accessing
  # a function's name
  pipeline_setup(NAME "binarybc" ${ARGV})

  # pipeline targets and chaining

  get_target_property(LLVMIR_EXTERNAL_TYPE
    ${PLINE_DEPENDS} LLVMIR_EXTERNAL_TYPE)

  if(LLVMIR_EXTERNAL_TYPE STREQUAL "EXECUTABLE")
    llvmir_attach_executable(
      TARGET ${PLINE_PREFIX}_bin
      DEPENDS ${PLINE_DEPENDS})
  else()
    llvmir_attach_library(
      TARGET ${PLINE_PREFIX}_bin
      DEPENDS ${PLINE_DEPENDS})
    set_target_properties(${PLINE_PREFIX}_bin
      PROPERTIES TYPE ${LLVMIR_EXTERNAL_TYPE})
  endif()
  add_dependencies(${PLINE_PREFIX}_bin ${PLINE_DEPENDS})

  # aggregate targets for pipeline

  list(APPEND INTERNAL_TARGET_LIST
    ${PLINE_PREFIX}_bin)

  add_dependencies(${PLINE_SUBTARGET} ${INTERNAL_TARGET_LIST})

  # expose targets

  set(${PLINE_MAIN_TARGET} "${PLINE_PREFIX}_bin" PARENT_SCOPE)

  if(PLINE_TARGET_LIST)
    list(APPEND INTERNAL_TARGET_LIST ${PLINE_SUBTARGET})
    set(${PLINE_TARGET_LIST} "${INTERNAL_TARGET_LIST}" PARENT_SCOPE)
  endif()
endfunction()

