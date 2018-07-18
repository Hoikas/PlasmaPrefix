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

# NOTE: Not using OpenSSL 1.1 yet due to removed support for SHA0
set(openssl_VERSION 1.0.2o)

file(DOWNLOAD "http://www.openssl.org/source/openssl-${openssl_VERSION}.tar.gz"
    "${CMAKE_BINARY_DIR}/openssl-${openssl_VERSION}.tar.gz"
    EXPECTED_HASH SHA256=ec3f5c9714ba0fd45cb4e087301eb1336c317e0d20b575a125050470e8089e4d
    SHOW_PROGRESS
    )
unpack_txz(openssl-${openssl_VERSION}.tar.gz openssl-${openssl_VERSION})

apply_patch(
    "${CMAKE_SOURCE_DIR}/patches/openssl/msvc-runtime.patch"
    "${CMAKE_BINARY_DIR}/openssl-${openssl_VERSION}"
    )

if(BUILD_ARCH STREQUAL "x86")
    set(OPENSSL_TARGET VC-WIN32)
    set(OPENSSL_TARGET_BAT "ms\\do_nasm.bat")
elseif(BUILD_ARCH STREQUAL "x64")
    set(OPENSSL_TARGET VC-WIN64A)
    set(OPENSSL_TARGET_BAT "ms\\do_win64a.bat")
else()
    message(FATAL_ERROR "Unsupported or unknown BUILD_ARCH ${BUILD_ARCH}")
endif()

if(BUILD_STATIC_LIBS)
    set(OPENSSL_TARGET ${OPENSSL_TARGET} no-shared)
    set(OPENSSL_MAKEFILE "ms\\nt.mak")
else()
    set(OPENSSL_TARGET ${OPENSSL_TARGET} shared)
    set(OPENSSL_MAKEFILE "ms\\ntdll.mak")
endif()

set(BUILD_PATH_EXT "$ENV{PATH};${PERL_PATH};${NASM_PATH}")

set(BUILD_SCRIPT "${CMAKE_BINARY_DIR}/openssl-${openssl_VERSION}/plasma_build.bat")
file(WRITE "${BUILD_SCRIPT}" "
call \"${VCVARSALL_BAT}\" ${VCVARSALL_ARCH}
set MAKEFLAGS=
nmake /f ${OPENSSL_MAKEFILE} %*
")

file(TO_CMAKE_PATH "${INSTALL_DIR}" INSTALL_DIR_CMAKE)

# TODO: Is there any need to build openssl in debug mode?
add_custom_target(openssl-release
    COMMAND ${CMAKE_COMMAND} -E env "PATH=${BUILD_PATH_EXT}"
                ${PERL_COMMAND} Configure --prefix="${INSTALL_DIR}"
                zlib --with-zlib-lib="${INSTALL_DIR_CMAKE}/lib/zlib.lib"
                --with-zlib-include="${INSTALL_DIR_CMAKE}/include" ${OPENSSL_TARGET}
    COMMAND ${CMAKE_COMMAND} -E env "PATH=${BUILD_PATH_EXT}" "${OPENSSL_TARGET_BAT}"
    COMMAND ${CMAKE_COMMAND} -E env "PATH=${BUILD_PATH_EXT}" "${BUILD_SCRIPT}"
    COMMAND ${CMAKE_COMMAND} -E env "PATH=${BUILD_PATH_EXT}" "${BUILD_SCRIPT}" install
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/openssl-${openssl_VERSION}"
    COMMENT "Building openssl-release"
    DEPENDS zlib
    )

add_custom_target(openssl ALL DEPENDS openssl-release)
