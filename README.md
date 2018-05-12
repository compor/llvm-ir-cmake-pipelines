# LLVM IR CMake Pipelines

## Introduction

This repository provides common `cmake` based pipelines that allow to run various `LLVM` `opt` passes in an order
specified by the user. This is accomplished by attaching the desired pipeline to the targets specified in the `cmake`
file of a project.

Although the [LLVM IR cmake utilities][2] can be used directly in a project, it becomes cumbersome and repetitive when
the chaining of many `LLVM` passes together. This project is an attempt to solve that problem, while maintaining a
degree of flexibility and customizability for the end user. This problem is especially heightened when it is required to
execute the same pass chain/pipeline over several subprojects (e.g. in a benchmark suite).

## Dependencies

-   [cmake][1] 3.2.0 or later
-   [LLVM IR cmake utilities][2]

# Installation

-   Clone this repo (or even add it as a submodule to your project).
-   Make sure you satisfy the installation requirements of the dependencies
-   In your `CMakeLists.txt` file `include()` `LLVMIRPipelines.cmake`.
-   Call the setup function `llvmir_pipelines_setup()` in your lists file.
-   You are good to go!

## Quick Overview

The operation of the project is influenced and controlled by these `cmake` variables:

-   `LLVMIR_PIPELINES_TO_INCLUDE`  
    This is a semicolon-separated list of pipelines to be included in the current project. The directory searched for is
    under directory `cmake/pipelines`. Each filename should correspond to one `cmake` command with the same name.  

    A pipeline file named `foobar.cmake` should define the `foobar` command with the following signature:

    ```cmake
    function(foobar DEPENDS MyTarget MAIN_TARGET FoobarOutTarget [TARGET_LIST FoobarOutTargetList] [ALL])
    ```

    The `DEPENDS` option must be an existing target in the user's project for which `LLVM` bitcode generation is
    required. The `MAIN_TARGET` option defines the variable that will be set to the name of the target (out of those
    defined in the pipeline `foobar`) that is going to be used for chaining pipelines. The `TARGET_LIST` option defines
    the variable that will be set to the names of the targets defined in the pipeline.

    **CAUTION**: Command names in `cmake` are [case-insensitive][4], but filesystems do not typically treat file name in
    this manner. Thus, in an attempt to preserve our sanity, we have adopted the convention of using _all lowercase_ for
    the filenames containing pipelines of the same name.

-   `LLVMIR_PIPELINES_COMPOUND`
    This is a semicolon-separated list of compound pipelines to be defined and used in the user's project. Currently,
    only 1 compound pipeline is supported for a single configuration.

-   `LLVMIR_PIPELINES_COMPOUND_[UPPERCASE_NAME]`  
    This is a semicolon-separated list of pipelines (defined in `LLVMIR_PIPELINES_TO_INCLUDE`) to be used as part of of
    this compound pipeline with this order.

    An example configuration would be:

    ```cmake
    cmake \
    -DLLVMIR_PIPELINES_TO_INCLUDE="genbc;linkbc;loopc14n" \
    -DLLVMIR_PIPELINES_COMPOUND="mygroup" \
    -DLLVMIR_PIPELINES_COMPOUND_MYGROUP="genbc;linkbc;loopc14n" \
    [path to source dir]
    ```

## Work In Progress

-   The pipelines in the `cmake-wip` directory represent WIP and should not be used in any way, till their conversion is
     completed (upon which they will be removed).

## TODO

-   Provide a mechanism to handle installation of pipeline targets in a uniform manner.

## Examples

For complete example configurations and uses see this [repo][3].

## Documentation

For further documentation, have a look in the `doc` directory.

[1]: https://cmake.org

[2]: https://github.com/compor/llvm-ir-cmake-utils

[3]: https://github.com/compor/llvm-ir-cmake-pipelines-examples

[4]: https://cmake.org/cmake/help/latest/manual/cmake-language.7.html#syntax
