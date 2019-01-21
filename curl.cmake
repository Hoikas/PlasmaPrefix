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

# CURL claims that CMake is "poorly maintained", but in fact it builds
# a version of libcurl that works correctly whereas the MSVC Makefiles
# do not.  Therefore, we use cmake.
if(BUILD_STATIC_LIBS)
    set(CURL_CMAKE_ARGS -DBUILD_SHARED_LIBS=OFF -DCURL_STATICLIB=ON)
else()
    set(CURL_CMAKE_ARGS -DBUILD_SHARED_LIBS=ON -DCURL_STATICLIB=OFF)
endif()

set(ZLIB_ARGS
    -DZLIB_INCLUDE_DIR="${INSTALL_DIR}/include"
    -DZLIB_LIBRARY_DEBUG="${INSTALL_DIR}/debug/lib/zlibd.lib"
    -DZLIB_LIBRARY_RELEASE="${INSTALL_DIR}/lib/zlib.lib"
    )
set(OPENSSL_ARGS
    -DOPENSSL_INCLUDE_DIR="${INSTALL_DIR}/include"
    -DLIB_EAY_DEBUG="${INSTALL_DIR}/debug/lib/libeay32.lib"
    -DSSL_EAY_DEBUG="${INSTALL_DIR}/debug/lib/ssleay32.lib"
    -DLIB_EAY_RELEASE="${INSTALL_DIR}/lib/libeay32.lib"
    -DSSL_EAY_RELEASE="${INSTALL_DIR}/lib/ssleay32.lib"
    )

set(CURL_CMAKE_ARGS ${CURL_CMAKE_ARGS} -DENABLE_MANUAL=OFF
    -DCMAKE_USE_OPENSSL=ON -DCURL_ZLIB=ON -DUSE_WIN32_LDAP=OFF
    -DPERL_EXECUTABLE="${PERL_COMMAND}" ${ZLIB_ARGS} ${OPENSSL_ARGS})

add_custom_target(curl-debug
    COMMAND ${CMAKE_COMMAND} -G "${VCSLN_GENERATOR}" ${CURL_CMAKE_ARGS}
                -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}/debug"
                -Hcurl-${curl_VERSION} -Bcurl-debug
    COMMAND ${CMAKE_COMMAND} --build curl-debug --config Debug
    COMMAND ${CMAKE_COMMAND} --build curl-debug --config Debug --target INSTALL
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Building curl-debug"
    DEPENDS zlib openssl
    )

add_custom_target(curl-release
    COMMAND ${CMAKE_COMMAND} -G "${VCSLN_GENERATOR}" ${CURL_CMAKE_ARGS}
                -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"
                -Hcurl-${curl_VERSION} -Bcurl-release
    COMMAND ${CMAKE_COMMAND} --build curl-release --config Release
    COMMAND ${CMAKE_COMMAND} --build curl-release --config Release --target INSTALL
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Building curl-release"
    DEPENDS zlib openssl
    )

add_custom_target(curl-postinst
    COMMAND ${CMAKE_COMMAND} -E remove "${INSTALL_DIR}/debug/bin/curl-config"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/include"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/lib/cmake"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/lib/pkgconfig"
    # Also remove the libcurl CMake files, since CMake itself doesn't use
    # them and they're generally considered broken.
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/lib/cmake/CURL"
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    DEPENDS curl-debug curl-release
    )

add_custom_target(curl ALL DEPENDS curl-postinst)
