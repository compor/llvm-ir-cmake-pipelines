#.rst:
#LLVM-IR-Pipelines
# -------------
#
# LLVM IR pipelines for cmake

cmake_minimum_required(VERSION 3.2)

message(STATUS "LLVM IR Pipelines")

include(CMakeParseArguments)

set(_THIS_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

include(${_THIS_LIST_DIR}/LLVMIRPipelinesGenerators.cmake)

function(llvmir_pipelines_setup)
  set(options)
  set(oneValueArgs DEPENDS OUTPUT_FILE)
  set(multiValueArgs)
  cmake_parse_arguments(LPS
    "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT LPS_DEPENDS)
    message(FATAL_ERROR "setup command is missing DEPENDS option")
  endif()

  if(NOT LPS_OUTPUT_FILE)
    message(FATAL_ERROR "setup command is missing OUTPUT_FILE option")
  endif()

  if(NOT LLVMIR_PIPELINES_TO_INCLUDE)
    message(WARNING "No pipelines to be included using variable: \
    LLVMIR_PIPELINES_TO_INCLUDE")
  endif()

  if(NOT LLVMIR_COMPOUND_PIPELINES)
    message(WARNING "No compound pipelines specified using variable:\
    LLVMIR_COMPOUND_PIPELINES")
  endif()

  if(LLVMIR_PIPELINES_TO_INCLUDE)
    set(PIPELINE_FILES "${LLVMIR_PIPELINES_TO_INCLUDE}")
    string(TOUPPER "${PIPELINE_FILES}" PIPELINE_FILES_UPPER)

    list(APPEND CMAKE_MODULE_PATH "${_THIS_LIST_DIR}/pipelines/")
    set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" PARENT_SCOPE)

    if("ALL" STREQUAL ${PIPELINE_FILES_UPPER})
      file(GLOB PIPELINE_FILES
        RELATIVE "${_THIS_LIST_DIR}/pipelines/"
        "${_THIS_LIST_DIR}/pipelines/*.cmake")
    endif()

    foreach(FILE ${PIPELINE_FILES})
      message(STATUS "Including pipeline: ${FILE}")

      include("${FILE}")
    endforeach()
  endif()

  #

  if(LLVMIR_COMPOUND_PIPELINES)
    list(LENGTH LLVMIR_COMPOUND_PIPELINES LEN)
    if(LEN GREATER 1)
      message(FATAL_ERROR "More than 1 compound pipelines are not supported")
    endif()

    set(PIPELINE_FILES_DIR "${CMAKE_CURRENT_BINARY_DIR}/pipelines/")
    file(MAKE_DIRECTORY "${PIPELINE_FILES_DIR}")

    list(APPEND CMAKE_MODULE_PATH "${PIPELINE_FILES_DIR}")
    set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" PARENT_SCOPE)

    foreach(CPLINE ${LLVMIR_COMPOUND_PIPELINES})
      string(TOUPPER "${CPLINE}" CPLINE_UC)
      set(CPLINE_PARTS "LLVMIR_COMPOUND_PIPELINE_${CPLINE_UC}")

      if(NOT DEFINED ${CPLINE_PARTS})
        message(FATAL_ERROR "pipeline ${CPLINE_PARTS} is not defined!")
      endif()

      set(CPLINE_PARTS_CONTENTS "${${CPLINE_PARTS}}")

      generate_compound_pipeline_lists(
        COMPOUND_PIPELINE ${CPLINE}
        PIPELINES ${CPLINE_PARTS_CONTENTS}
        OUTPUT_DIR ${PIPELINE_FILES_DIR})

      include(${CPLINE})
    endforeach()

    generate_pipeline_runner_lists(
      PIPELINES ${LLVMIR_COMPOUND_PIPELINES}
      DEPENDS ${LPS_DEPENDS}
      OUTPUT_FILE ${LPS_OUTPUT_FILE}
      OUTPUT_DIR ${PIPELINE_FILES_DIR})
  endif()
endfunction()
