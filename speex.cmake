# Copyright (c) 2019 Michael Hansen
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

set(speex_VERSION 1.2.0)

file(DOWNLOAD "http://downloads.xiph.org/releases/speex/speex-${speex_VERSION}.tar.gz"
    "${CMAKE_BINARY_DIR}/speex-${speex_VERSION}.tar.gz"
    EXPECTED_HASH SHA256=eaae8af0ac742dc7d542c9439ac72f1f385ce838392dc849cae4536af9210094
    SHOW_PROGRESS
    )
unpack_tgz(speex-${speex_VERSION}.tar.gz speex-${speex_VERSION})

# The shipped solution file refers to projects which don't exist.
# msbuild.exe complains about these projects, even if we don't try to build
# them, so we must remove them from the solution before trying to build.
apply_patch(
    "${CMAKE_SOURCE_DIR}/patches/speex/remove-nonexistent-projects.patch"
    "${CMAKE_BINARY_DIR}/speex-${speex_VERSION}/win32/VS2008"
    )

# File missing from the official release tarball.  WTF xiph?
file(DOWNLOAD "https://raw.githubusercontent.com/xiph/speex/Speex-1.2.0/libspeex/fftwrap.c"
    "${CMAKE_BINARY_DIR}/speex-${speex_VERSION}/libspeex/fftwrap.c"
    EXPECTED_HASH SHA256=a59ec583e5660207da9cf3c1ddd6a7ff1ed91382eb40df2a4e77d5cddfe14c52
    SHOW_PROGRESS
    )

if(BUILD_ARCH STREQUAL "x86")
    set(SPEEX_PLATFORM "Win32")
elseif(BUILD_ARCH STREQUAL "x64")
    message(WARNING "Speex does not currently support the x64 platform.
It will be EXCLUDED from this build.")
    set(SPEEX_PLATFORM "SKIP")
else()
    message(FATAL_ERROR "Unsupported BUILD_ARCH ${BUILD_ARCH}")
endif()

# Fixup linkage to always use the DLL MSVC runtime
set(SPEEX_PROJECTS
    libspeex/libspeex.vcproj
    speexdec/speexdec.vcproj
    speexenc/speexenc.vcproj
    tests/testenc.vcproj
    tests/testenc_uwb.vcproj
    tests/testenc_wb.vcproj
    )
foreach(_vcproj_file ${SPEEX_PROJECTS})
    file(READ "${CMAKE_BINARY_DIR}/speex-${speex_VERSION}/win32/VS2008/${_vcproj_file}"
        _vcproj_content
        )
    string(REPLACE "RuntimeLibrary=\"0\"" "RuntimeLibrary=\"2\""
        _vcproj_content "${_vcproj_content}"
        )
    string(REPLACE "RuntimeLibrary=\"1\"" "RuntimeLibrary=\"3\""
        _vcproj_content "${_vcproj_content}"
        )
    file(WRITE "${CMAKE_BINARY_DIR}/speex-${speex_VERSION}/win32/VS2008/${_vcproj_file}"
        "${_vcproj_content}"
        )
endforeach()

# NOTE: Always static.  libspeex doesn't have complete support for DLL builds.
# We build the .vcxproj directly since the .sln file refers to some projects
# that don't exist, which confuses msbuild even though we don't care about
# building them.
if(NOT SPEEX_PLATFORM STREQUAL "SKIP")
    set(BUILD_SCRIPT "${CMAKE_BINARY_DIR}/speex-${speex_VERSION}/win32/VS2008/plasma_build.bat")
    file(WRITE "${BUILD_SCRIPT}" "
call \"${VCVARSALL_BAT}\" ${VCVARSALL_ARCH}
devenv.exe libspeex.sln /upgrade
msbuild.exe libspeex.sln /t:libspeex /p:Configuration=Debug /p:Platform=${SPEEX_PLATFORM} /m
msbuild.exe libspeex.sln /t:libspeex /p:Configuration=Release_SSE2 /p:Platform=${SPEEX_PLATFORM} /m
")

    add_custom_target(speex-msbuild
        COMMAND ${CMAKE_COMMAND} -E env "${BUILD_SCRIPT}"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/speex-${speex_VERSION}/win32/VS2008"
        COMMENT "Building speex-msbuild"
        )

    add_custom_target(speex-postinst
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/include/speex"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/speex-${speex_VERSION}/include/speex/speex.h"
                    "${CMAKE_BINARY_DIR}/speex-${speex_VERSION}/include/speex/speex_bits.h"
                    "${CMAKE_BINARY_DIR}/speex-${speex_VERSION}/include/speex/speex_callbacks.h"
                    "${CMAKE_BINARY_DIR}/speex-${speex_VERSION}/include/speex/speex_header.h"
                    "${CMAKE_BINARY_DIR}/speex-${speex_VERSION}/include/speex/speex_stereo.h"
                    "${CMAKE_BINARY_DIR}/speex-${speex_VERSION}/include/speex/speex_types.h"
                    "${INSTALL_DIR}/include/speex"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/debug/lib" "${INSTALL_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/speex-${speex_VERSION}/win32/VS2008/Debug/libspeex.lib"
                    "${INSTALL_DIR}/debug/lib"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/speex-${speex_VERSION}/win32/VS2008/libspeex/Release_SSE2/libspeex.lib"
                    "${INSTALL_DIR}/lib"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        DEPENDS speex-msbuild
        )

    add_custom_target(speex ALL DEPENDS speex-postinst)
endif()
