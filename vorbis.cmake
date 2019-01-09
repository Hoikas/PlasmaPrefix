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

set(vorbis_VERSION 1.3.6)

file(DOWNLOAD "http://downloads.xiph.org/releases/vorbis/libvorbis-${vorbis_VERSION}.zip"
    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}.zip"
    EXPECTED_HASH SHA256=3c16117a6d9fba78b905e4159e632f484700938d3f0c32f0c16caf932f5d0b5b
    SHOW_PROGRESS
    )
unpack_zip(libvorbis-${vorbis_VERSION}.zip libvorbis-${vorbis_VERSION})

# libvorbis identifies the path to libogg by a .props file with a hard-coded
# path and version assumption.  The path is compatible, but we need to
# ensure the version is correct
file(READ "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/libogg.props"
    LIBOGG_PROPS
    )
string(REGEX REPLACE "<LIBOGG_VERSION>[^<]*</LIBOGG_VERSION>"
    "<LIBOGG_VERSION>${ogg_VERSION}</LIBOGG_VERSION>"
    LIBOGG_PROPS "${LIBOGG_PROPS}"
    )
file(WRITE "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/libogg.props"
    "${LIBOGG_PROPS}"
    )

if(BUILD_STATIC_LIBS)
    set(VORBIS_SLN_FILE vorbis_static.sln)
else()
    set(VORBIS_SLN_FILE vorbis_dynamic.sln)

    # Fixup linkage to use the DLL version of libogg
    set(VORBIS_DLL_PROJECTS
        libvorbis/libvorbis_dynamic.vcxproj
        libvorbisfile/libvorbisfile_dynamic.vcxproj
        vorbisdec/vorbisdec_dynamic.vcxproj
        vorbisenc/vorbisenc_dynamic.vcxproj
        )
    foreach(_vcxproj_file ${VORBIS_DLL_PROJECTS})
        file(READ "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${_vcxproj_file}"
            _vcxproj_content
            )
        string(REPLACE "libogg_static.lib" "libogg.lib"
            _vcxproj_content "${_vcxproj_content}"
            )
        file(WRITE "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${_vcxproj_file}"
            "${_vcxproj_content}"
            )
    endforeach()
endif()

if(BUILD_ARCH STREQUAL "x86")
    set(VORBIS_PLATFORM "Win32")
elseif(BUILD_ARCH STREQUAL "x64")
    set(VORBIS_PLATFORM "x64")
else()
    message(FATAL_ERROR "Unsupported BUILD_ARCH ${BUILD_ARCH}")
endif()

set(BUILD_SCRIPT "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/plasma_build.bat")
file(WRITE "${BUILD_SCRIPT}" "
call \"${VCVARSALL_BAT}\" ${VCVARSALL_ARCH}
devenv.exe ${VORBIS_SLN_FILE} /upgrade
msbuild.exe ${VORBIS_SLN_FILE} /t:Build /p:Configuration=Debug /p:Platform=${VORBIS_PLATFORM} /m
msbuild.exe ${VORBIS_SLN_FILE} /t:Build /p:Configuration=Release /p:Platform=${VORBIS_PLATFORM} /m
")

add_custom_target(libvorbis-msbuild
    COMMAND ${CMAKE_COMMAND} -E env "${BUILD_SCRIPT}"
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010"
    COMMENT "Building libvorbis-msbuild"
    DEPENDS libogg
    )

if(BUILD_STATIC_LIBS)
    add_custom_target(libvorbis-postinst
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/include/vorbis"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/include/vorbis/codec.h"
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/include/vorbis/vorbisenc.h"
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/include/vorbis/vorbisfile.h"
                    "${INSTALL_DIR}/include/vorbis"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/debug/lib" "${INSTALL_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${VORBIS_PLATFORM}/Debug/libvorbis_static.lib"
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${VORBIS_PLATFORM}/Debug/libvorbisfile_static.lib"
                    "${INSTALL_DIR}/debug/lib"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${VORBIS_PLATFORM}/Release/libvorbis_static.lib"
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${VORBIS_PLATFORM}/Release/libvorbisfile_static.lib"
                    "${INSTALL_DIR}/lib"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        DEPENDS libvorbis-msbuild
        )
else()
    add_custom_target(libvorbis-postinst
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/include/vorbis"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/include/vorbis/codec.h"
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/include/vorbis/vorbisenc.h"
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/include/vorbis/vorbisfile.h"
                    "${INSTALL_DIR}/include/vorbis"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/debug/bin" "${INSTALL_DIR}/bin"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${VORBIS_PLATFORM}/Debug/libvorbis.dll"
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${VORBIS_PLATFORM}/Debug/libvorbisfile.dll"
                    "${INSTALL_DIR}/debug/bin"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${VORBIS_PLATFORM}/Release/libvorbis.dll"
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${VORBIS_PLATFORM}/Release/libvorbisfile.dll"
                    "${INSTALL_DIR}/bin"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/debug/lib" "${INSTALL_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${VORBIS_PLATFORM}/Debug/libvorbis.lib"
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${VORBIS_PLATFORM}/Debug/libvorbis.exp"
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${VORBIS_PLATFORM}/Debug/libvorbisfile.lib"
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${VORBIS_PLATFORM}/Debug/libvorbisfile.exp"
                    "${INSTALL_DIR}/debug/lib"
        COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${VORBIS_PLATFORM}/Release/libvorbis.lib"
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${VORBIS_PLATFORM}/Release/libvorbis.exp"
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${VORBIS_PLATFORM}/Release/libvorbisfile.lib"
                    "${CMAKE_BINARY_DIR}/libvorbis-${vorbis_VERSION}/win32/VS2010/${VORBIS_PLATFORM}/Release/libvorbisfile.exp"
                    "${INSTALL_DIR}/lib"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        DEPENDS libvorbis-msbuild
        )
endif()

add_custom_target(libvorbis ALL DEPENDS libvorbis-postinst)
