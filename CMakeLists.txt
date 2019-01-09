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

# CMake can't grok "$ENV{ProgramFiles(x86)}"
set(EnvProgramFilesX86 "ProgramFiles(x86)")

if(MSVC_VERSION STREQUAL "2013")
    set(MSVC_SHORT_VERSION "12")
    set(VCVARS_SEARCH_PATHS
        "$ENV{ProgramFiles}\\Microsoft Visual Studio 12.0\\VC"
        "$ENV{${EnvProgramFilesX86}}\\Microsoft Visual Studio 12.0\\VC"
        "$ENV{ProgramW6432}\\Microsoft Visual Studio 12.0\\VC"
        )
elseif(MSVC_VERSION STREQUAL "2015")
    set(MSVC_SHORT_VERSION "14")
    set(VCVARS_SEARCH_PATHS
        "$ENV{ProgramFiles}\\Microsoft Visual Studio 14.0\\VC"
        "$ENV{${EnvProgramFilesX86}}\\Microsoft Visual Studio 14.0\\VC"
        "$ENV{ProgramW6432}\\Microsoft Visual Studio 14.0\\VC"
        )
elseif(MSVC_VERSION STREQUAL "2017")
    set(MSVC_SHORT_VERSION "15")
    set(VCVARS_SEARCH_PATHS
        "$ENV{ProgramFiles}\\Microsoft Visual Studio\\2017\\Community\\VC\\Auxiliary\\Build"
        "$ENV{${EnvProgramFilesX86}}\\Microsoft Visual Studio\\2017\\Community\\VC\\Auxiliary\\Build"
        "$ENV{ProgramW6432}\\Microsoft Visual Studio\\2017\\Community\\VC\\Auxiliary\\Build"
        "$ENV{ProgramFiles}\\Microsoft Visual Studio\\2017\\Professional\\VC\\Auxiliary\\Build"
        "$ENV{${EnvProgramFilesX86}}\\Microsoft Visual Studio\\2017\\Professional\\VC\\Auxiliary\\Build"
        "$ENV{ProgramW6432}\\Microsoft Visual Studio\\2017\\Professional\\VC\\Auxiliary\\Build"
        "$ENV{ProgramFiles}\\Microsoft Visual Studio\\2017\\Enterprise\\VC\\Auxiliary\\Build"
        "$ENV{${EnvProgramFilesX86}}\\Microsoft Visual Studio\\2017\\Enterprise\\VC\\Auxiliary\\Build"
        "$ENV{ProgramW6432}\\Microsoft Visual Studio\\2017\\Enterprise\\VC\\Auxiliary\\Build"
        )
else()
    message(FATAL_ERROR "Unsupported or unknown MSVC_VERSION ${MSVC_VERSION}")
endif()

set(VCSLN_GENERATOR "Visual Studio ${MSVC_SHORT_VERSION} ${MSVC_VERSION}")

if(BUILD_ARCH STREQUAL "x86")
    # No generator suffix
    set(VCVARSALL_ARCH x86)
elseif(BUILD_ARCH STREQUAL "x64")
    set(VCSLN_GENERATOR "${VCSLN_GENERATOR} Win64")
    set(VCVARSALL_ARCH x86_amd64)
else()
    message(FATAL_ERROR "Unsupported or unknown BUILD_ARCH ${BUILD_ARCH}")
endif()

# TODO: Get the location from a more reliable source, like the registry
# or vswhere.exe (VS2017+ only)
find_program(VCVARSALL_BAT
    NAMES vcvarsall.bat
    PATHS ${VCVARS_SEARCH_PATHS}
    DOC "Path to Visual Studio's command line vcvarsall.bat script"
    NO_DEFAULT_PATH
    )
if(NOT VCVARSALL_BAT)
    message(FATAL_ERROR "Could not find vcvarsall.bat for Visual Studio ${MSVC_VERSION}")
endif()

function(_unpack_archive tarball pkgdir)
    cmake_parse_arguments(_unarch "" "DEST_DIR" "TAR_FLAGS" ${ARGN})
    if(NOT DEFINED _unarch_DEST_DIR)
        set(_unarch_DEST_DIR "${CMAKE_BINARY_DIR}")
    endif()
    if(NOT EXISTS "${_unarch_DEST_DIR}")
        file(MAKE_DIRECTORY "${_unarch_DEST_DIR}")
    endif()
    if(NOT EXISTS "${_unarch_DEST_DIR}/${pkgdir}")
        message(STATUS "Unpacking ${tarball}")
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E tar ${_unarch_TAR_FLAGS}
            WORKING_DIRECTORY "${_unarch_DEST_DIR}"
        )
    endif()
endfunction()

function(unpack_tgz tarball pkgdir)
    _unpack_archive("${tarball}" "${pkgdir}" ${ARGN}
        TAR_FLAGS xzf "${CMAKE_BINARY_DIR}/${tarball}"
        )
endfunction()

function(unpack_tbz2 tarball pkgdir)
    _unpack_archive("${tarball}" "${pkgdir}" ${ARGN}
        TAR_FLAGS xjf "${CMAKE_BINARY_DIR}/${tarball}"
        )
endfunction()

function(unpack_txz tarball pkgdir)
    _unpack_archive("${tarball}" "${pkgdir}" ${ARGN}
        TAR_FLAGS xJf "${CMAKE_BINARY_DIR}/${tarball}"
        )
endfunction()

function(unpack_zip tarball pkgdir)
    _unpack_archive("${tarball}" "${pkgdir}" ${ARGN}
        TAR_FLAGS xf "${CMAKE_BINARY_DIR}/${tarball}" --format=zip
        )
endfunction()

# Build tools
include(nasm.cmake)
include(patch.cmake)
include(perl.cmake)

# Packages
include(zlib.cmake)
include(libpng.cmake)
include(libjpeg-turbo.cmake)
include(string_theory.cmake)
include(openssl.cmake)
include(curl.cmake)
include(expat.cmake)
include(ogg.cmake)
include(vorbis.cmake)
