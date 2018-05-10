# cmake file

include(CMakeParseArguments)

function(pipeline_setup)
  set(options ALL)
  set(oneValueArgs NAME DEPENDS MAIN_TARGET TARGET_LIST)
  set(multiValueArgs)
  cmake_parse_arguments(PLINE
    "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # argument checks

  if(PLINE_ALL)
    set(PLINE_ALL "ALL")
  else()
    set(PLINE_ALL "")
  endif()

  if(NOT PLINE_MAIN_TARGET)
    message(FATAL_ERROR "pipeline ${PLINE_NAME}: missing MAIN_TARGET target")
  endif()

  if(NOT PLINE_DEPENDS)
    message(FATAL_ERROR "pipeline ${PLINE_NAME}: missing DEPENDS target")
  endif()

  if(NOT TARGET ${PLINE_DEPENDS})
    message(FATAL_ERROR "pipeline ${PLINE_NAME}: ${PLINE_DEPENDS} is not a \
    target")
  endif()

  if(PLINE_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "pipeline ${PLINE_NAME}: has extraneous arguments \
    ${PLINE_UNPARSED_ARGUMENTS}")
  endif()

  # set up targets

  if(NOT TARGET "${PLINE_NAME}")
    add_custom_target("${PLINE_NAME}" ${PLINE_ALL})
  endif()

  set(PLINE_SUBTARGET "${PLINE_NAME}_${PLINE_DEPENDS}")
  set(PLINE_PREFIX "${PLINE_SUBTARGET}")

  add_custom_target(${PLINE_SUBTARGET})
  add_dependencies(${PLINE_NAME} ${PLINE_SUBTARGET})

  set(PLINE_NAME "${PLINE_NAME}" PARENT_SCOPE)
  set(PLINE_DEPENDS "${PLINE_DEPENDS}" PARENT_SCOPE)
  set(PLINE_MAIN_TARGET "${PLINE_MAIN_TARGET}" PARENT_SCOPE)
  set(PLINE_TARGET_LIST "${PLINE_TARGET_LIST}" PARENT_SCOPE)
  set(PLINE_ALL "${PLINE_ALL}" PARENT_SCOPE)
  set(PLINE_SUBTARGET "${PLINE_SUBTARGET}" PARENT_SCOPE)
  set(PLINE_PREFIX "${PLINE_PREFIX}" PARENT_SCOPE)
endfunction()

