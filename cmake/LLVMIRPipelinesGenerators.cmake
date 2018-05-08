# cmake file

include(CMakeParseArguments)

function(generate_compound_pipeline_lists)
  set(options)
  set(oneValueArgs COMPOUND_PIPELINE OUTPUT_DIR)
  set(multiValueArgs PIPELINES)
  cmake_parse_arguments(GENPLISTS
    "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  set(GEN_SCRIPTS_DIR "${CMAKE_CURRENT_LIST_DIR}/../scripts/")

  execute_process(
    COMMAND ${GEN_SCRIPTS_DIR}/compound_pipeline_generator.py
    -t ${GEN_SCRIPTS_DIR}/templates/
    -c ${GENPLISTS_COMPOUND_PIPELINE}
    -p "${GENPLISTS_PIPELINES}"
    -f ${GENPLISTS_COMPOUND_PIPELINE}.cmake
    WORKING_DIRECTORY ${GENPLISTS_OUTPUT_DIR}
    RESULT_VARIABLE RC)

  if(RC)
    message(FATAL_ERROR "Failed to generate compound pipelines lists file")
  endif()
endfunction()

function(generate_pipeline_runner_lists)
  set(options)
  set(oneValueArgs DEPENDS OUTPUT_DIR)
  set(multiValueArgs PIPELINES)
  cmake_parse_arguments(GENPLISTS
    "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  set(GEN_SCRIPTS_DIR "${CMAKE_CURRENT_LIST_DIR}/../scripts/")

  execute_process(
    COMMAND ${GEN_SCRIPTS_DIR}/pipeline_runner_generator.py
    -t ${GEN_SCRIPTS_DIR}/templates/
    -p "${GENPLISTS_PIPELINES}"
    -d ${GENPLISTS_DEPENDS}
    -f runner.cmake
    WORKING_DIRECTORY ${GENPLISTS_OUTPUT_DIR}
    RESULT_VARIABLE RC)

  if(RC)
    message(FATAL_ERROR "Failed to generate pipelines runner lists file")
  endif()
endfunction()

