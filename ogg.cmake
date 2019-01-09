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

set(ogg_VERSION 1.3.3)

file(DOWNLOAD "http://downloads.xiph.org/releases/ogg/libogg-${ogg_VERSION}.zip"
    "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}.zip"
    EXPECTED_HASH SHA256=ddbb0884406ea2b30d831dc7304fd4a958a05d62f24429d8fa83e1c9d620e7f8
    SHOW_PROGRESS
    )
unpack_zip(libogg-${ogg_VERSION}.zip libogg-${ogg_VERSION})

# The "VS2015" project files are mostly compatible with VS2013, but need some
# important fixes (most notably, the MSVC runtime) before they can be used by
# any MSVC compiler
file(READ "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}/win32/VS2015/libogg_static.vcxproj"
    LIBOGG_STATIC_VCXPROJ
    )

string(REPLACE "<RuntimeLibrary>MultiThreaded</RuntimeLibrary>"
               "<RuntimeLibrary>MultiThreadedDLL</RuntimeLibrary>"
    LIBOGG_STATIC_VCXPROJ "${LIBOGG_STATIC_VCXPROJ}"
    )
string(REPLACE "<RuntimeLibrary>MultiThreadedDebug</RuntimeLibrary>"
               "<RuntimeLibrary>MultiThreadedDebugDLL</RuntimeLibrary>"
    LIBOGG_STATIC_VCXPROJ "${LIBOGG_STATIC_VCXPROJ}"
    )

# Only needed in the static vcxproj file...  The dynamic vcxproj is already
# set to using the v120 toolset, despite being in a "VS2015" directory
string(REPLACE "<PlatformToolset>v140</PlatformToolset>"
               "<PlatformToolset>v120</PlatformToolset>"
    LIBOGG_STATIC_VCXPROJ "${LIBOGG_STATIC_VCXPROJ}"
    )

file(WRITE "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}/win32/VS2015/libogg_static.vcxproj"
    "${LIBOGG_STATIC_VCXPROJ}"
    )

if(BUILD_STATIC_LIBS)
    set(OGG_SLN_FILE libogg_static.sln)
else()
    set(OGG_SLN_FILE libogg_dynamic.sln)
endif()

if(BUILD_ARCH STREQUAL "x86")
    set(OGG_PLATFORM "Win32")
elseif(BUILD_ARCH STREQUAL "x64")
    set(OGG_PLATFORM "x64")
else()
    message(FATAL_ERROR "Unsupported BUILD_ARCH ${BUILD_ARCH}")
endif()

set(BUILD_SCRIPT "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}/win32/VS2015/plasma_build.bat")
file(WRITE "${BUILD_SCRIPT}" "
call \"${VCVARSALL_BAT}\" ${VCVARSALL_ARCH}
devenv.exe ${OGG_SLN_FILE} /upgrade
msbuild.exe ${OGG_SLN_FILE} /t:Build /p:Configuration=Debug /p:Platform=${OGG_PLATFORM} /m
msbuild.exe ${OGG_SLN_FILE} /t:Build /p:Configuration=Release /p:Platform=${OGG_PLATFORM} /m
")

add_custom_target(libogg-msbuild
    COMMAND ${CMAKE_COMMAND} -E env "${BUILD_SCRIPT}"
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}/win32/VS2015"
    COMMENT "Building libogg-msbuild"
    )

if(BUILD_STATIC_LIBS)
    add_custom_target(libogg-postinst
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/include/ogg"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}/include/ogg/ogg.h"
                    "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}/include/ogg/os_types.h"
                    "${INSTALL_DIR}/include/ogg"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/debug/lib" "${INSTALL_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}/win32/VS2015/${OGG_PLATFORM}/Debug/libogg_static.lib"
                    "${INSTALL_DIR}/debug/lib"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}/win32/VS2015/${OGG_PLATFORM}/Release/libogg_static.lib"
                    "${INSTALL_DIR}/lib"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        DEPENDS libogg-msbuild
        )
else()
    add_custom_target(libogg-postinst
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/include/ogg"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}/include/ogg/ogg.h"
                    "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}/include/ogg/os_types.h"
                    "${INSTALL_DIR}/include/ogg"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/debug/bin" "${INSTALL_DIR}/bin"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}/win32/VS2015/${OGG_PLATFORM}/Debug/libogg.dll"
                    "${INSTALL_DIR}/debug/bin"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}/win32/VS2015/${OGG_PLATFORM}/Release/libogg.dll"
                    "${INSTALL_DIR}/bin"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/debug/lib" "${INSTALL_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}/win32/VS2015/${OGG_PLATFORM}/Debug/libogg.exp"
                    "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}/win32/VS2015/${OGG_PLATFORM}/Debug/libogg.lib"
                    "${INSTALL_DIR}/debug/lib"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}/win32/VS2015/${OGG_PLATFORM}/Release/libogg.exp"
                    "${CMAKE_BINARY_DIR}/libogg-${ogg_VERSION}/win32/VS2015/${OGG_PLATFORM}/Release/libogg.lib"
                    "${INSTALL_DIR}/lib"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        DEPENDS libogg-msbuild
        )
endif()

add_custom_target(libogg ALL DEPENDS libogg-postinst)
