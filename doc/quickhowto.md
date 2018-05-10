# Quick How-To

## How To Add A New Pipeline

This section describes how to add a simple pipeline/chain to the current framework.

Let's say that we require the following:

-   A pass to act on LLVM IR, and
-   A pass to perform scalar replacement of aggregates and tail-call elimination

The simplest way to start is to copy one of the existing, simpler pipelines and adapt it. So, we can copy
`loopc14n.cmake` and rename it to `myopts.cmake`. Then, you need to replace the function name from `loopc14n` to
`myopts` and also convert this statement:

```cmake
pipeline_setup(NAME "loopc14n" ${ARGV})
```

to

```cmake
pipeline_setup(NAME "myopts" ${ARGV})
```

Unfortunately, since `cmake` lacks reflection capabilities and we have to deal with the fact that it treats command (aka
function) names as case-insensitive. So, we adopt the convention of using the same _lowercase_ name for naming the
chain/pipeline and the `cmake` lists file that contains it.

The required signature for a pipeline/chain function is:

```cmake
  function(foobar DEPENDS MyTarget MAIN_TARGET FoobarOutTarget [TARGET_LIST FoobarOutTargetList] [ALL])
```

-   `DEPENDS`  
    This option specifies an already defined target on which the targets of the pipeline are going to operate and be 
    dependent on. This target can be either a source language level target or a `LLVM` bitcode target (created by the 
    [LLVM IR cmake utilities][1]. The author of the pipeline will call the appropriate [LLVM IR cmake utilities][1]
    command based on the source target's source language/type.
-   `MAIN_TARGET`  
    This option specifies the variable name which will contain the main target defined by the pipeline in order to be
    used in further chaining with other pipelines. This target should not be an empty target.
-   `TARGET_LIST`  
    This option specifies the variable name which will contain the list of targets defined by the pipeline. The targets 
    in this list should not be empty targets.
-   `ALL`  
    This option specifies if the pipeline empty target (see `PLINE_NAME` below) is going to be added to the default
    build target. This behaves exactly the same as the `ALL` option of the `add_custom_target` command.

The `pipeline_setup()` utility function handles the parsing of the command-line arguments and it is used to avoid 
repeating the same setup code every time. It provides the following variables in the calling scope:

-   `PLINE_NAME`  
    Contains the name of current pipeline and also the name of an empty target (also see next paragraph).
-   `PLINE_DEPENDS`  
    Contains the name of the target upon which this pipeline will be dependent on and it will be passed as an argument 
    to the `DEPENDS` option when the pipeline function is called.
-   `PLINE_MAIN_TARGET`  
    Contains the name of the main target that this pipeline will expose to the calling scope, in order to allow further
    chaining and dependencies to be set up on it. The contents of this variable are required to be set by the pipeline
    function.
-   `PLINE_TARGET_LIST`  
    A list with the names of the targets that this pipelines exposes. The contents of this variable are required to be
    set by the pipeline function.
-   `PLINE_ALL`  
    Boolean denoting if the custom empty target that corresponds to this pipeline (i.e. `PLINE_NAME`) is going to added
    to the default build target so that it will be run every time. This behaves exactly the same as the `ALL` option of 
    the `add_custom_target` command.
-   `PLINE_SUBTARGET`  
    Contains the name of custom empty target that corresponds and depends on all internal target that is pipeline chain
    defines (also documented in the next paragraph). `cmake` targets are required to be unique, so the current 
    convention is for this variable to be set to a concatenation of the `PLINE_NAME` and `PLINE_DEPENDS` variables as in 
    `${PLINE_NAME}_${PLINE_DEPDENDS}`.
-   `PLINE_PREFIX`  
    Contains a unique prefix with which each internal subtarget name defined in the pipeline chain is required to start 
    with, since `cmake` target are required to be unique. The current convention is for this variable to be set to the 
    value of `PLINE_SUBTARGET`.

Moreover, `pipeline_setup()` also defines these empty targets:

-   `${PLINE_NAME}`  
    It is the name of the empty target that corresponds to all the targets that are affected by this pipeline.
-   `${PLINE_SUBTARGET}`  
    It is the name of the empty target that corresponds to all the target created by applying this pipeline chain to the
    target pointed by the `DEPENDS` options.

Continuing with our modifications and since the `loopc14n` pipeline function already operates on bitcode, our first
requirement is already fulfilled by the `llvmir_attach_opt_pass_target()` command.

Next, we need to add the required passes. So, we change the current passes to:

```cmake
  llvmir_attach_opt_pass_target(
    TARGET ${PLINE_PREFIX}_opt
    DEPENDS ${PLINE_DEPENDS}
    -sroa
    -tailcallelim)
```

The exported targets for `PLINE_MAIN_TARGET` and `PLINE_TARGET_LIST` remain the same. We are done!

In order to configure our project with our new pipeline chain we can follow the configuration described in the main
README document. We can call explicitly `myopts()` command in our `CMakeLists.txt` and configure our project with:

```cmake
cmake \
-DLLVMIR_PIPELINES_TO_INCLUDE="basicbc;myopts" \
... \
[path to source dir]
```

Otherwise, we can take advantage of the dynamic generation of compound pipelines (essentially groups of pipelines) and
configure our project with:

```cmake
cmake \
-DLLVMIR_PIPELINES_TO_INCLUDE="basicbc;myopts" \
-DLLVMIR_PIPELINES_COMPOUND="mygroup" \
-DLLVMIR_PIPELINES_COMPOUND_MYGROUP="basicbc;myopts" \
... \
[path to source dir]
```

For a complete working example have a look at this [repo][2].

[1]: https://github.com/compor/llvm-ir-cmake-utils

[2]: https://github.com/compor/llvm-ir-cmake-pipelines-examples
