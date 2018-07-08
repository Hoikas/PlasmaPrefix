# Copyright (c) 2018 Michael Hansen
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

cmake_minimum_required(VERSION 3.2)
project(PlasmaPrefix NONE)

option(BUILD_STATIC_LIBS "Build static libraries instead of DLLs" ON)
set(BUILD_ARCH "x86" CACHE STRING "Target architecture for building projects")
set_property(CACHE BUILD_ARCH PROPERTY STRINGS x86 x64)
set(MSVC_VERSION "2013" CACHE STRING "Target MSVC Version for building projects")
set(INSTALL_DIR "${CMAKE_SOURCE_DIR}/prefix" CACHE STRING "Path to install built libraries and headers")

if(MSVC_VERSION STREQUAL "2013")
    set(VCSLN_GENERATOR "Visual Studio 12 2013")
elseif(MSVC_VERSION STREQUAL "2015")
    set(VCSLN_GENERATOR "Visual Studio 14 2015")
elseif(MSVC_VERSION STREQUAL "2017")
    set(VCSLN_GENERATOR "Visual Studio 15 2017")
else()
    message(FATAL_ERROR "Unsupported or unknown MSVC_VERSION ${MSVC_VERSION}")
endif()

if(BUILD_ARCH STREQUAL "x86")
    # No generator suffix
elseif(BUILD_ARCH STREQUAL "x64")
    set(VCSLN_GENERATOR "${VCSLN_GENERATOR} Win64")
else()
    message(FATAL_ERROR "Unsupported or unknown BUILD_ARCH ${BUILD_ARCH}")
endif()

function(_unpack_archive tarball tarflags pkgdir)
    if(NOT EXISTS "${CMAKE_BINARY_DIR}/${pkgdir}")
        message(STATUS "Unpacking ${tarball}")
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E tar ${tarflags} ${tarball}
            WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        )
    endif()
endfunction()

function(unpack_tgz tarball pkgdir)
    _unpack_archive(${tarball} xzf ${pkgdir})
endfunction()

function(unpack_txz tarball pkgdir)
    _unpack_archive(${tarball} xJf ${pkgdir})
endfunction()

function(unpack_zip tarball pkgdir)
    # The docs state cmake -E tar can unpack zip files, but doesn't give
    # any hint on the tar flags to use.  xzf seems to work...
    _unpack_archive(${tarball} xzf ${pkgdir})
endfunction()

# Build tools
include(nasm.cmake)
include(patch.cmake)

# Packages
include(zlib.cmake)
include(libpng.cmake)
include(libjpeg-turbo.cmake)
