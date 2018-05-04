#.rst:
#LLVM-IR-Pipelines
# -------------
#
# LLVM IR pipelines for cmake

cmake_minimum_required(VERSION 3.2)

message(STATUS "LLVM IR Pipelines")

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

