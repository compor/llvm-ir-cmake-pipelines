# cmake file

include(CMakeParseArguments)

function(pipeline_parse_dep_args)
  set(options)
  set(oneValueArgs PASS_TARGET OUT)
  set(multiValueArgs)
  cmake_parse_arguments(PLINE_PDA
    "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # argument checks
  if(NOT PLINE_PDA_PASS_TARGET)
    message(FATAL_ERROR "missing PASS_TARGET target")
  endif()

  if(NOT PLINE_PDA_OUT)
    message(FATAL_ERROR "missing OUT variable name")
  endif()

  get_target_property(PASS_DEPENDEES ${PLINE_PDA_PASS_TARGET} DEPENDEE)

  set(LOAD_CMDLINE_ARG "")
  if(PASS_DEPENDEES)
    foreach(dep ${PASS_DEPENDEES})
      list(APPEND LOAD_CMDLINE_ARG -load;${dep})
    endforeach()
  endif()

  set(${PLINE_PDA_OUT} ${LOAD_CMDLINE_ARG} PARENT_SCOPE)
endfunction()

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
  else()
    get_target_property(HasExcludeAll "${PLINE_NAME}" EXCLUDE_FROM_ALL)
    if(PLINE_ALL EQUAL HasExcludeAll)
      message(WARNING "target ${PLINE_NAME} defined with conflicting \
      EXCLUDE_FROM_ALL properties")
    endif()
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

function(install_llvmir_bc)
  set(options)
  set(oneValueArgs TARGET)
  set(multiValueArgs)

  cmake_parse_arguments(ILIB "${options}" "${oneValueArgs}"
    "${multiValueArgs}" ${ARGN})

  get_property(HAS_LLVMIR_DIR TARGET ${ILIB_TARGET} PROPERTY LLVMIR_DIR DEFINED)

  if(NOT HAS_LLVMIR_DIR)
    message(FATAL_ERROR "Target ${ILIB_TARGET} does not have LLVMIR_DIR \
    property")
  endif()

  get_property(LLVMIR_DIR TARGET ${ILIB_TARGET} PROPERTY LLVMIR_DIR)

  install(DIRECTORY ${LLVMIR_DIR}
    DESTINATION .
    COMPONENT llvmir_bc
    USE_SOURCE_PERMISSIONS
    EXCLUDE_FROM_ALL
    OPTIONAL)
endfunction()

function(install_llvmir_binary)
  set(options)
  set(oneValueArgs TARGET)
  set(multiValueArgs)

  cmake_parse_arguments(ILIB "${options}" "${oneValueArgs}"
    "${multiValueArgs}" ${ARGN})

  install(TARGETS ${ILIB_TARGET}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    COMPONENT llvmir_binary
    EXCLUDE_FROM_ALL
    OPTIONAL)
endfunction()
