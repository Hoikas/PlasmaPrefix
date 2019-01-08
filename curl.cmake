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

set(curl_VERSION 7.63.0)

file(DOWNLOAD "https://curl.haxx.se/download/curl-${curl_VERSION}.tar.xz"
    "${CMAKE_BINARY_DIR}/curl-${curl_VERSION}.tar.xz"
    EXPECTED_HASH SHA256=9600234c794bfb8a0d3f138e9294d60a20e7a5f10e35ece8cf518e2112d968c4
    SHOW_PROGRESS
    )
unpack_txz(curl-${curl_VERSION}.tar.xz curl-${curl_VERSION})

if(BUILD_STATIC_LIBS)
    set(CURL_LIBTYPE "static")
else()
    set(CURL_LIBTYPE "dll")
endif()

set(BUILD_SCRIPT "${CMAKE_BINARY_DIR}/curl-${curl_VERSION}/winbuild/plasma_build.bat")
file(WRITE "${BUILD_SCRIPT}" "
call \"${VCVARSALL_BAT}\" ${VCVARSALL_ARCH}
nmake /f Makefile.vc MODE=${CURL_LIBTYPE} \
  VC=${MSVC_SHORT_VERSION} \
  WITH_DEVEL=${INSTALL_DIR} \
  WITH_SSL=${CURL_LIBTYPE} \
  WITH_ZLIB=${CURL_LIBTYPE} \
  MACHINE=${BUILD_ARCH} \
  ENABLE_IPV6=yes \
  ENABLE_SSPI=yes \
  ENABLE_IDN=yes \
  %*
")

# These write their output to different build directories, so no extra
# source tree copy is necessary
add_custom_target(curl-debug
    COMMAND ${CMAKE_COMMAND} -E env "${BUILD_SCRIPT}" DEBUG=yes
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/curl-${curl_VERSION}/winbuild"
    COMMENT "Building curl-debug"
    DEPENDS zlib openssl
    )

add_custom_target(curl-release
    COMMAND ${CMAKE_COMMAND} -E env "${BUILD_SCRIPT}" DEBUG=no
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/curl-${curl_VERSION}/winbuild"
    COMMENT "Building curl-release"
    DEPENDS zlib openssl
    )

# The Windows makefile does not include an install target
set(CURL_DEBUG_OUTDIR "${CMAKE_BINARY_DIR}/curl-${curl_VERSION}/builds/libcurl-vc${MSVC_SHORT_VERSION}-${BUILD_ARCH}-debug-${CURL_LIBTYPE}-ssl-${CURL_LIBTYPE}-zlib-${CURL_LIBTYPE}-ipv6-sspi")
set(CURL_RELEASE_OUTDIR "${CMAKE_BINARY_DIR}/curl-${curl_VERSION}/builds/libcurl-vc${MSVC_SHORT_VERSION}-${BUILD_ARCH}-release-${CURL_LIBTYPE}-ssl-${CURL_LIBTYPE}-zlib-${CURL_LIBTYPE}-ipv6-sspi")

if(BUILD_STATIC_LIBS)
    add_custom_target(curl-postinst
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${CURL_RELEASE_OUTDIR}/include"
                    "${INSTALL_DIR}/include"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/debug/bin" "${INSTALL_DIR}/bin"
        COMMAND ${CMAKE_COMMAND} -E copy "${CURL_DEBUG_OUTDIR}/bin/curl.exe"
                    "${INSTALL_DIR}/debug/bin"
        COMMAND ${CMAKE_COMMAND} -E copy "${CURL_RELEASE_OUTDIR}/bin/curl.exe"
                    "${INSTALL_DIR}/bin"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/debug/lib" "${INSTALL_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy "${CURL_DEBUG_OUTDIR}/lib/libcurl_a_debug.lib"
                    "${INSTALL_DIR}/debug/lib"
        COMMAND ${CMAKE_COMMAND} -E copy "${CURL_RELEASE_OUTDIR}/lib/libcurl_a.lib"
                    "${INSTALL_DIR}/lib"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        DEPENDS curl-debug curl-release
        )
else()
    add_custom_target(curl-postinst
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${CURL_RELEASE_OUTDIR}/include"
                    "${INSTALL_DIR}/include"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/debug/bin" "${INSTALL_DIR}/bin"
        COMMAND ${CMAKE_COMMAND} -E copy "${CURL_DEBUG_OUTDIR}/bin/libcurl_debug.dll"
                    "${CURL_DEBUG_OUTDIR}/bin/curl.exe"
                    "${INSTALL_DIR}/debug/bin"
        COMMAND ${CMAKE_COMMAND} -E copy "${CURL_RELEASE_OUTDIR}/bin/libcurl.dll"
                    "${CURL_RELEASE_OUTDIR}/bin/curl.exe"
                    "${INSTALL_DIR}/bin"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_DIR}/debug/lib" "${INSTALL_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy "${CURL_DEBUG_OUTDIR}/lib/libcurl_debug.exp"
                    "${CURL_DEBUG_OUTDIR}/lib/libcurl_debug.lib"
                    "${INSTALL_DIR}/debug/lib"
        COMMAND ${CMAKE_COMMAND} -E copy "${CURL_RELEASE_OUTDIR}/lib/libcurl.exp"
                    "${CURL_RELEASE_OUTDIR}/lib/libcurl.lib"
                    "${INSTALL_DIR}/lib"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        DEPENDS curl-debug curl-release
        )
endif()

add_custom_target(curl ALL DEPENDS curl-postinst)
