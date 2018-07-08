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

file(DOWNLOAD "https://download.sourceforge.net/libpng/libpng-1.6.34.tar.xz"
    "${CMAKE_BINARY_DIR}/libpng-1.6.34.tar.xz"
    EXPECTED_HASH MD5=c05b6ca7190a5e387b78657dbe5536b2
    STATUS libpng_STATUS SHOW_PROGRESS
    )
check_download(libpng libpng-1.6.34.tar.xz)

add_custom_target(libpng-preinst
    COMMAND ${CMAKE_COMMAND} -E tar xJf libpng-1.6.34.tar.xz
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Unpacking libpng"
    )

if(BUILD_STATIC_LIBS)
    set(LIBPNG_CMAKE_ARGS -DPNG_STATIC=ON -DPNG_SHARED=OFF)
else()
    set(LIBPNG_CMAKE_ARGS -DPNG_STATIC=OFF -DPNG_SHARED=ON)
endif()

set(ZLIB_ARGS
    -DZLIB_INCLUDE_DIR="${INSTALL_DIR}/include"
    -DZLIB_LIBRARY_DEBUG="${INSTALL_DIR}/debug/lib/zlibd.lib"
    -DZLIB_LIBRARY_RELEASE="${INSTALL_DIR}/lib/zlib.lib"
    )
set(LIBPNG_CMAKE_ARGS ${LIBPNG_CMAKE_ARGS} ${ZLIB_ARGS})

add_custom_target(libpng-debug
    COMMAND ${CMAKE_COMMAND} -G "${VCSLN_GENERATOR}" ${LIBPNG_CMAKE_ARGS}
                -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}/debug"
                -Hlibpng-1.6.34 -Blibpng-debug
    COMMAND ${CMAKE_COMMAND} --build libpng-debug --config Debug
    COMMAND ${CMAKE_COMMAND} --build libpng-debug --config Debug --target INSTALL
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Building libpng-debug"
    DEPENDS libpng-preinst zlib
    )

add_custom_target(libpng-release
    COMMAND ${CMAKE_COMMAND} -G "${VCSLN_GENERATOR}" ${LIBPNG_CMAKE_ARGS}
                -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"
                -Hlibpng-1.6.34 -Blibpng-release
    COMMAND ${CMAKE_COMMAND} --build libpng-release --config Release
    COMMAND ${CMAKE_COMMAND} --build libpng-release --config Release --target INSTALL
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Building libpng-release"
    DEPENDS libpng-preinst zlib
    )

if(BUILD_STATIC_LIBS)
    add_custom_target(libpng-postinst
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/include"
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/share"
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/lib/libpng"
        COMMAND ${CMAKE_COMMAND} -E rename "${INSTALL_DIR}/debug/lib/libpng16_staticd.lib"
                    "${INSTALL_DIR}/debug/lib/libpng16d.lib"
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/lib/libpng"
        COMMAND ${CMAKE_COMMAND} -E rename "${INSTALL_DIR}/lib/libpng16_static.lib"
                    "${INSTALL_DIR}/lib/libpng16.lib"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        DEPENDS libpng-debug libpng-release
        )
else()
    add_custom_target(libpng-postinst
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/include"
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/share"
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/lib/libpng"
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/lib/libpng"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        DEPENDS libpng-debug libpng-release
        )
endif()

add_custom_target(libpng ALL DEPENDS libpng-postinst)
