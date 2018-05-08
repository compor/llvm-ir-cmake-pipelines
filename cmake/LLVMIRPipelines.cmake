#.rst:
#LLVM-IR-Pipelines
# -------------
#
# LLVM IR pipelines for cmake

cmake_minimum_required(VERSION 3.2)

message(STATUS "LLVM IR Pipelines")

include(${CMAKE_CURRENT_LIST_DIR}/LLVMIRPipelinesGenerators.cmake)

if(LLVMIR_PIPELINES_TO_INCLUDE)
  set(PIPELINE_FILES "${LLVMIR_PIPELINES_TO_INCLUDE}")
  string(TOUPPER "${PIPELINE_FILES}" PIPELINE_FILES_UPPER)

  list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/pipelines/")

  if("ALL" STREQUAL ${PIPELINE_FILES_UPPER})
    file(GLOB PIPELINE_FILES
      RELATIVE "${CMAKE_CURRENT_LIST_DIR}/pipelines/"
      "${CMAKE_CURRENT_LIST_DIR}/pipelines/*.cmake")
  endif()

  foreach(FILE ${PIPELINE_FILES})
    message(STATUS "Including pipeline: ${FILE}")

    include("${FILE}")
  endforeach()
else()
  message(WARNING "No pipelines included")
endif()

#

if(LLVMIR_COMPOUND_PIPELINES)
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
      OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR})

    generate_pipeline_runner_lists(
      PIPELINES ${LLVMIR_COMPOUND_PIPELINES}
      DEPENDS TARGET_HOOK_TO_REPLACE
      OUTPUT_FILE runner
      OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR})
  endforeach()
endif()
