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

set(opus_VERSION 1.3)

file(DOWNLOAD "http://downloads.xiph.org/releases/opus/opus-${opus_VERSION}.tar.gz"
    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}.tar.gz"
    EXPECTED_HASH SHA256=4f3d69aefdf2dbaf9825408e452a8a414ffc60494c70633560700398820dc550
    SHOW_PROGRESS
    )
unpack_tgz(opus-${opus_VERSION}.tar.gz opus-${opus_VERSION})

# Fix MSVC Runtime for static libs
file(READ "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/win32/VS2015/common.props"
    OPUS_COMMON_PROPS
    )
string(REPLACE ">MultiThreaded</RuntimeLibrary>"
    ">MultiThreadedDLL</RuntimeLibrary>"
    OPUS_COMMON_PROPS "${OPUS_COMMON_PROPS}"
    )
string(REPLACE ">MultiThreadedDebug</RuntimeLibrary>"
    ">MultiThreadedDebugDLL</RuntimeLibrary>"
    OPUS_COMMON_PROPS "${OPUS_COMMON_PROPS}"
    )
file(WRITE "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/win32/VS2015/common.props"
    "${OPUS_COMMON_PROPS}"
    )

if(BUILD_ARCH STREQUAL "x86")
    set(OPUS_PLATFORM "Win32")
elseif(BUILD_ARCH STREQUAL "x64")
    set(OPUS_PLATFORM "x64")
else()
    message(FATAL_ERROR "Unsupported BUILD_ARCH ${BUILD_ARCH}")
endif()

if(BUILD_STATIC_LIBS)
    set(OPUS_DEBUG_CONFIG Debug)
    set(OPUS_RELEASE_CONFIG Release)
else()
    set(OPUS_DEBUG_CONFIG DebugDLL)
    set(OPUS_RELEASE_CONFIG ReleaseDLL)
endif()

set(BUILD_SCRIPT "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/win32/VS2015/plasma_build.bat")

if(MSVC_VERSION STREQUAL "2013")
    # "Downgrade" the projects to use the VS 2013 toolset
    set(OPUS_PROJECTS
        opus.vcxproj
        opus_demo.vcxproj
        test_opus_api.vcxproj
        test_opus_decode.vcxproj
        test_opus_encode.vcxproj
        )
    foreach(_vcxproj_file ${OPUS_PROJECTS})
        file(READ "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/win32/VS2015/${_vcxproj_file}"
            _vcxproj_content
            )
        string(REPLACE "<PlatformToolset>v140</PlatformToolset>"
            "<PlatformToolset>v120</PlatformToolset>"
            _vcxproj_content "${_vcxproj_content}"
            )
        file(WRITE "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/win32/VS2015/${_vcxproj_file}"
            "${_vcxproj_content}"
            )
    endforeach()

    file(WRITE "${BUILD_SCRIPT}" "
call \"${VCVARSALL_BAT}\" ${VCVARSALL_ARCH}
msbuild.exe opus.sln /t:opus /p:Configuration=${OPUS_DEBUG_CONFIG} /p:Platform=${OPUS_PLATFORM} /m
msbuild.exe opus.sln /t:opus /p:Configuration=${OPUS_RELEASE_CONFIG} /p:Platform=${OPUS_PLATFORM} /m
")

else()
    file(WRITE "${BUILD_SCRIPT}" "
call \"${VCVARSALL_BAT}\" ${VCVARSALL_ARCH}
devenv.exe opus.sln /upgrade
msbuild.exe opus.sln /t:opus /p:Configuration=${OPUS_DEBUG_CONFIG} /p:Platform=${OPUS_PLATFORM} /m
msbuild.exe opus.sln /t:opus /p:Configuration=${OPUS_RELEASE_CONFIG} /p:Platform=${OPUS_PLATFORM} /m
")
endif()

add_custom_target(opus-msbuild
    COMMAND ${CMAKE_COMMAND} -E env "${BUILD_SCRIPT}"
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/win32/VS2015"
    COMMENT "Building opus-msbuild"
    )

if(BUILD_STATIC_LIBS)
    add_custom_target(opus-postinst
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/include/opus"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/include/opus.h"
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/include/opus_custom.h"
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/include/opus_defines.h"
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/include/opus_multistream.h"
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/include/opus_projection.h"
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/include/opus_types.h"
                    "${INSTALL_DIR}/include/opus"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/debug/lib" "${INSTALL_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/win32/VS2015/${OPUS_PLATFORM}/Debug/opus.lib"
                    "${INSTALL_DIR}/debug/lib"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/win32/VS2015/${OPUS_PLATFORM}/Release/opus.lib"
                    "${INSTALL_DIR}/lib"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        DEPENDS opus-msbuild
        )
else()
    add_custom_target(opus-postinst
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/include/opus"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/include/opus.h"
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/include/opus_custom.h"
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/include/opus_defines.h"
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/include/opus_multistream.h"
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/include/opus_projection.h"
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/include/opus_types.h"
                    "${INSTALL_DIR}/include/opus"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/debug/bin" "${INSTALL_DIR}/bin"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/win32/VS2015/${OPUS_PLATFORM}/DebugDLL/opus.dll"
                    "${INSTALL_DIR}/debug/bin"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/win32/VS2015/${OPUS_PLATFORM}/ReleaseDLL/opus.dll"
                    "${INSTALL_DIR}/bin"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/debug/lib" "${INSTALL_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/win32/VS2015/${OPUS_PLATFORM}/DebugDLL/opus.lib"
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/win32/VS2015/${OPUS_PLATFORM}/DebugDLL/opus.exp"
                    "${INSTALL_DIR}/debug/lib"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/win32/VS2015/${OPUS_PLATFORM}/ReleaseDLL/opus.lib"
                    "${CMAKE_BINARY_DIR}/opus-${opus_VERSION}/win32/VS2015/${OPUS_PLATFORM}/ReleaseDLL/opus.exp"
                    "${INSTALL_DIR}/lib"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        DEPENDS opus-msbuild
        )
endif()

add_custom_target(opus ALL DEPENDS opus-postinst)
