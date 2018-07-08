cmake_minimum_required(VERSION 3.0)
project(PlasmaPrefix NONE)

option(BUILD_STATIC_LIBS "Build static libraries instead of DLLs" ON)
set(BUILD_GENERATOR "" CACHE STRING "CMake generator to use for building projects")
set(INSTALL_DIR "prefix" CACHE STRING "Path to install built libraries and headers")

function(check_download pkgname tarball)
    list(GET ${pkgname}_STATUS 0 RESULT)
    list(GET ${pkgname}_STATUS 1 MESSAGE)
    if(NOT RESULT EQUAL 0)
        message(FATAL_ERROR ${MESSAGE})
    endif()
endfunction()

if(NOT BUILD_GENERATOR MATCHES "Visual Studio.*")
    message(FATAL_ERROR "This project currently only supports building Visual Studio solutions")
endif()

include(zlib.cmake)
