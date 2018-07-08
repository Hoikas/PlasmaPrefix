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

file(DOWNLOAD "https://zlib.net/zlib-1.2.11.tar.xz"
    "${CMAKE_BINARY_DIR}/zlib-1.2.11.tar.xz"
    EXPECTED_HASH SHA256=4ff941449631ace0d4d203e3483be9dbc9da454084111f97ea0a2114e19bf066
    SHOW_PROGRESS
    )
unpack_txz(zlib-1.2.11.tar.xz zlib-1.2.11)

add_custom_target(zlib-debug
    COMMAND ${CMAKE_COMMAND} -G "${VCSLN_GENERATOR}"
                -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}/debug"
                -Hzlib-1.2.11 -Bzlib-debug
    COMMAND ${CMAKE_COMMAND} --build zlib-debug --config Debug
    COMMAND ${CMAKE_COMMAND} --build zlib-debug --config Debug --target INSTALL
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Building zlib-debug"
    )

add_custom_target(zlib-release
    COMMAND ${CMAKE_COMMAND} -G "${VCSLN_GENERATOR}"
                -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"
                -Hzlib-1.2.11 -Bzlib-release
    COMMAND ${CMAKE_COMMAND} --build zlib-release --config Release
    COMMAND ${CMAKE_COMMAND} --build zlib-release --config Release --target INSTALL
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Building zlib-release"
    # HACK: zlib can't be built in parallel since it renames a file in the
    # source directory.  Shame on you zlib :(
    DEPENDS zlib-debug
    )

if(BUILD_STATIC_LIBS)
    add_custom_target(zlib
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/bin"
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/include"
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/share"
        COMMAND ${CMAKE_COMMAND} -E remove "${INSTALL_DIR}/debug/lib/zlibd.lib"
        COMMAND ${CMAKE_COMMAND} -E rename "${INSTALL_DIR}/debug/lib/zlibstaticd.lib"
                    "${INSTALL_DIR}/debug/lib/zlibd.lib"
        COMMAND ${CMAKE_COMMAND} -E remove "${INSTALL_DIR}/bin/zlib.dll"
        COMMAND ${CMAKE_COMMAND} -E remove "${INSTALL_DIR}/lib/zlib.lib"
        COMMAND ${CMAKE_COMMAND} -E rename "${INSTALL_DIR}/lib/zlibstatic.lib"
                    "${INSTALL_DIR}/lib/zlib.lib"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        DEPENDS zlib-debug zlib-release
        )
else()
    add_custom_target(zlib
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/include"
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/share"
        COMMAND ${CMAKE_COMMAND} -E remove "${INSTALL_DIR}/debug/lib/zlibstaticd.lib"
        COMMAND ${CMAKE_COMMAND} -E remove "${INSTALL_DIR}/lib/zlibstatic.lib"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        DEPENDS zlib-debug zlib-release
        )
endif()
