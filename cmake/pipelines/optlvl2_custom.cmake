# cmake file

# pipeline that attaches to bitcode level targets and performs:
# - passes under optimization level 2 (O2)
# - loop unroll disabled
# - loop rotation disabled
# - loop vectorization disabled
# - SLP vectorization disabled
# using standard LLVM opt passes

set(_THIS_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

include(${_THIS_LIST_DIR}/internal/common.cmake)

function(optlvl2_custom)
  # CAUTION
  # function name and NAME provided below are required to match in order for
  # things to work, since there is currently no programmatic way of accessing
  # a function's name
  pipeline_setup(NAME "optlvl2_custom" ${ARGV})

  # pipeline targets and chaining

  llvmir_attach_opt_pass_target(
    TARGET ${PLINE_PREFIX}_opt
    DEPENDS ${PLINE_DEPENDS}
    -tti -verify -ee-instrument -targetlibinfo -assumption-cache-tracker
    -profile-summary-info -forceattrs -basiccg -always-inline -barrier
    -targetlibinfo -tti -tbaa -scoped-noalias -assumption-cache-tracker
    -profile-summary-info -forceattrs -inferattrs -ipsccp
    -called-value-propagation
    -globalopt -domtree -mem2reg -deadargelim -basicaa -aa -loops
    -lazy-branch-prob
    -lazy-block-freq -opt-remark-emitter -instcombine -simplifycfg -basiccg
    -globals-aa -prune-eh -always-inline -functionattrs -sroa -memoryssa
    -early-cse-memssa -speculative-execution -lazy-value-info -jump-threading
    -correlated-propagation -libcalls-shrinkwrap -branch-prob -block-freq
    -pgo-memop-opt -tailcallelim -reassociate -loop-simplify -lcssa-verification
    -lcssa -scalar-evolution -licm -loop-unswitch -indvars -loop-idiom
    -loop-deletion -memdep -memcpyopt -sccp -demanded-bits -bdce -dse
    -postdomtree -adce -barrier -rpo-functionattrs -globaldce -float2int
    -loop-accesses -loop-distribute -loop-load-elim
    -alignment-from-assumptions -strip-dead-prototypes -loop-sink -instsimplify
    -div-rem-pairs -verify -ee-instrument -early-cse -lower-expect)
  add_dependencies(${PLINE_PREFIX}_opt ${PLINE_DEPENDS})

  # aggregate targets for pipeline

  list(APPEND INTERNAL_TARGET_LIST
    ${PLINE_PREFIX}_opt)

  add_dependencies(${PLINE_SUBTARGET} ${INTERNAL_TARGET_LIST})

  # expose targets

  set(${PLINE_MAIN_TARGET} "${PLINE_PREFIX}_opt" PARENT_SCOPE)

  if(TRGT_LIST)
    list(APPEND INTERNAL_TARGET_LIST ${PLINE_SUBTARGET})
    set(${PLINE_TARGET_LIST} "${INTERNAL_TARGET_LIST}" PARENT_SCOPE)
  endif()
endfunction()

