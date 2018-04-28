# cmake file

macro(DecoupleLoopsFrontPipelineSetupNames)
  set(PIPELINE_NAME "DecoupleLoopsFront")
  set(PIPELINE_INSTALL_TARGET "${PIPELINE_NAME}-install")
endmacro()


macro(DecoupleLoopsFrontPipelineSetup)
  DecoupleLoopsFrontPipelineSetupNames()

  message(STATUS "setting up pipeline DecoupleLoopsFront")

  if(NOT DEFINED ENV{HARNESS_REPORT_DIR})
    message(WARNING
      "${PIPELINE_NAME} env variable HARNESS_REPORT_DIR is not defined. \
      Using ${CMAKE_BINARY_DIR}/reports/")

      set(ENV{HARNESS_REPORT_DIR} "${CMAKE_BINARY_DIR}/reports/")
  endif()

  file(TO_CMAKE_PATH $ENV{HARNESS_REPORT_DIR} HARNESS_REPORT_DIR)
  if(NOT EXISTS ${HARNESS_REPORT_DIR})
    file(MAKE_DIRECTORY ${HARNESS_REPORT_DIR})
  endif()

  message(STATUS
    "${PIPELINE_NAME} uses env variable: HARNESS_REPORT_DIR=${HARNESS_REPORT_DIR}")

  #

  find_package(DecoupleLoopsFront CONFIG REQUIRED)

  get_target_property(DLF_LIB_LOCATION LLVMDecoupleLoopsFrontPass LOCATION)

  set(PREAMBLE_SCRIPT "preamble.sh")
  set(PREAMBLE_SCRIPT_INPUT "${CMAKE_SOURCE_DIR}/scripts/preamble/${PREAMBLE_SCRIPT}.in")

  if(EXISTS ${PREAMBLE_SCRIPT_INPUT})
    configure_file(${PREAMBLE_SCRIPT_INPUT} "preamble/${PIPELINE_NAME}_${PREAMBLE_SCRIPT}" @ONLY)
  endif()
endmacro()

DecoupleLoopsFrontPipelineSetup()

#

function(DecoupleLoopsFrontPipeline trgt)
  DecoupleLoopsFrontPipelineSetupNames()

  if(NOT TARGET ${PIPELINE_NAME})
    add_custom_target(${PIPELINE_NAME})
  endif()

  set(PIPELINE_SUBTARGET "${PIPELINE_NAME}_${trgt}")
  set(PIPELINE_PREFIX ${PIPELINE_SUBTARGET})

  set(DEPENDEE_TRGT "AnnotateLoops_${trgt}_opt2")

  ## pipeline targets and chaining
  get_property(bmk_name TARGET ${trgt} PROPERTY BMK_NAME)
  file(TO_CMAKE_PATH ${HARNESS_REPORT_DIR} REPORT_DIR)
  file(TO_CMAKE_PATH ${REPORT_DIR}/${BMK_NAME} REPORT_DIR)
  file(MAKE_DIRECTORY ${REPORT_DIR})

  llvmir_attach_opt_pass_target(${PIPELINE_PREFIX}_le
    ${DEPENDEE_TRGT}
    -loop-extract)
  add_dependencies(${PIPELINE_PREFIX}_le ${DEPENDEE_TRGT})

  llvmir_attach_opt_pass_target(${PIPELINE_PREFIX}_dlf
    ${PIPELINE_PREFIX}_le
    -load ${DLF_LIB_LOCATION}
    -decouple-loops-front
    -dlf-debug
    -dlf-annotate-type
    -dlf-bb-annotate-weight
    -dlf-bb-prefix-type
    -dlf-report ${HARNESS_REPORT_DIR}/${BMK_NAME}
    -dlf-dot-cfg-only
    -dlf-dot-dir ${REPORT_DIR})
  add_dependencies(${PIPELINE_PREFIX}_dlf ${PIPELINE_PREFIX}_le)

  llvmir_attach_executable(${PIPELINE_PREFIX}_bc_exe ${PIPELINE_PREFIX}_dlf)
  add_dependencies(${PIPELINE_PREFIX}_bc_exe ${PIPELINE_PREFIX}_dlf)

  target_link_libraries(${PIPELINE_PREFIX}_bc_exe m)

  ## pipeline aggregate targets
  add_custom_target(${PIPELINE_SUBTARGET} DEPENDS
    ${DEPENDEE_TRGT}
    ${PIPELINE_PREFIX}_le
    ${PIPELINE_PREFIX}_dlf
    ${PIPELINE_PREFIX}_bc_exe)

  add_dependencies(${PIPELINE_NAME} ${PIPELINE_SUBTARGET})


  # installation
  get_property(bmk_name TARGET ${trgt} PROPERTY BMK_NAME)
  set(DEST_DIR "${bmk_name}")

  install(TARGETS ${PIPELINE_PREFIX}_bc_exe
    DESTINATION ${DEST_DIR} OPTIONAL)

  set(BMK_BIN_NAME "${PIPELINE_PREFIX}_bc_exe")
  set(BMK_BIN_PREAMBLE "")
  set(PIPELINE_SCRIPT_PREFIX "${PIPELINE_NAME}")

  configure_file("scripts/_run.sh.in" "scripts/${PIPELINE_PREFIX}_run.sh" @ONLY)

  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/scripts/
    DESTINATION ${DEST_DIR}
    PATTERN "*.sh"
    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)

  # IR installation
  if(NOT TARGET ${PIPELINE_INSTALL_TARGET})
    add_custom_target(${PIPELINE_INSTALL_TARGET})
  endif()

  InstallPipelineLLVMIR(DEPENDS ${PIPELINE_PREFIX}_dlf
    ATTACH_TO_TARGET ${PIPELINE_INSTALL_TARGET} BMK_NAME ${bmk_name})
endfunction()

