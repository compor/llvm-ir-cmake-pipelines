# cmake file

include(CMakeParseArguments)

function(loopc14n)
  set(PIPELINE_NAME "loopc14n")
  string(TOUPPER "${PIPELINE_NAME}" PIPELINE_NAME_UPPER)

  set(options ALL)
  set(oneValueArgs NAME DEPENDS MAIN_TARGET TARGET_LIST)
  set(multiValueArgs)
  cmake_parse_arguments(${PIPELINE_NAME_UPPER}
    "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  set(NAME ${${PIPELINE_NAME_UPPER}_NAME})
  set(TRGT ${${PIPELINE_NAME_UPPER}_DEPENDS})
  set(MAIN_TRGT ${${PIPELINE_NAME_UPPER}_MAIN_TARGET})
  set(TRGT_LIST ${${PIPELINE_NAME_UPPER}_TARGET_LIST})

  # argument checks

  if(NOT NAME)
    set(NAME "${PIPELINE_NAME}")
  endif()

  if(${PIPELINE_NAME_UPPER}_ALL)
    set(ALL_OPTION "ALL")
  endif()

  if(NOT MAIN_TRGT)
    message(FATAL_ERROR "pipeline ${PIPELINE_NAME}: missing MAIN_TARGET target")
  endif()

  if(NOT TRGT)
    message(FATAL_ERROR "pipeline ${PIPELINE_NAME}: missing DEPENDS target")
  endif()

  if(NOT TARGET ${TRGT})
    message(FATAL_ERROR "pipeline ${PIPELINE_NAME}: ${TRGT} is not a target")
  endif()

  if(${PIPELINE_NAME_UPPER}_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "pipeline ${PIPELINE_NAME}: has extraneous arguments \
    ${${PIPELINE_NAME_UPPER}_UNPARSED_ARGUMENTS}")
  endif()

  # set up targets

  if(NOT TARGET ${NAME})
    add_custom_target(${NAME} ${ALL_OPTION})
  endif()

  set(PIPELINE_SUBTARGET "${NAME}_${TRGT}")
  set(PIPELINE_PREFIX "${PIPELINE_SUBTARGET}")

  # pipeline targets and chaining

  llvmir_attach_opt_pass_target(
    TARGET ${PIPELINE_PREFIX}_opt
    DEPENDS ${TRGT}
    -mem2reg
    -mergereturn
    -simplifycfg
    -loop-simplify)
  add_dependencies(${PIPELINE_PREFIX}_opt ${TRGT})

  llvmir_attach_link_target(
    TARGET ${PIPELINE_PREFIX}_link
    DEPENDS ${PIPELINE_PREFIX}_opt)
  add_dependencies(${PIPELINE_PREFIX}_link ${PIPELINE_PREFIX}_opt)

  llvmir_attach_executable(
    TARGET ${PIPELINE_PREFIX}_bc_exe
    DEPENDS ${PIPELINE_PREFIX}_link)
  add_dependencies(${PIPELINE_PREFIX}_bc_exe ${PIPELINE_PREFIX}_link)

  # aggregate targets for pipeline

  add_custom_target(${PIPELINE_SUBTARGET} DEPENDS
    ${PIPELINE_PREFIX}_opt
    ${PIPELINE_PREFIX}_link
    ${PIPELINE_PREFIX}_bc_exe)

  set(INTERNAL_TRGT_LIST "")
  list(APPEND INTERNAL_TRGT_LIST
    ${PIPELINE_SUBTARGET}
    ${PIPELINE_PREFIX}_opt
    ${PIPELINE_PREFIX}_link
    ${PIPELINE_PREFIX}_bc_exe)

  add_dependencies(${NAME} ${PIPELINE_SUBTARGET})

  # export targets

  set(${MAIN_TRGT} "${PIPELINE_PREFIX}_link" PARENT_SCOPE)

  if(TRGT_LIST)
    set(${TRGT_LIST} "${INTERNAL_TRGT_LIST}" PARENT_SCOPE)
  endif()
endfunction()

