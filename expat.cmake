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

set(expat_VERSION 2.2.6)

string(REPLACE "." "_" expat_TAG "${expat_VERSION}")
file(DOWNLOAD "https://github.com/libexpat/libexpat/releases/download/R_${expat_TAG}/expat-${expat_VERSION}.tar.bz2"
    "${CMAKE_BINARY_DIR}/expat-${expat_VERSION}.tar.bz2"
    EXPECTED_HASH SHA256=17b43c2716d521369f82fc2dc70f359860e90fa440bea65b3b85f0b246ea81f2
    SHOW_PROGRESS
    )
unpack_tbz2(expat-${expat_VERSION}.tar.bz2 expat-${expat_VERSION})

if(BUILD_STATIC_LIBS)
    set(EXPAT_CMAKE_ARGS -DBUILD_shared=OFF)
else()
    set(EXPAT_CMAKE_ARGS -DBUILD_shared=ON)
endif()
set(EXPAT_CMAKE_ARGS ${EXPAT_CMAKE_ARGS} -DBUILD_doc=OFF -DBUILD_examples=OFF
                        -DBUILD_tests=OFF -DBUILD_tools=OFF
    )

add_custom_target(expat-debug
    COMMAND ${CMAKE_COMMAND} -G "${VCSLN_GENERATOR}" ${EXPAT_CMAKE_ARGS}
                -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}/debug"
                -Hexpat-${expat_VERSION} -Bexpat-debug
    COMMAND ${CMAKE_COMMAND} --build expat-debug --config Debug
    COMMAND ${CMAKE_COMMAND} --build expat-debug --config Debug --target INSTALL
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Building expat-debug"
    )

add_custom_target(expat-release
    COMMAND ${CMAKE_COMMAND} -G "${VCSLN_GENERATOR}" ${EXPAT_CMAKE_ARGS}
                -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"
                -Hexpat-${expat_VERSION} -Bexpat-release
    COMMAND ${CMAKE_COMMAND} --build expat-release --config Release
    COMMAND ${CMAKE_COMMAND} --build expat-release --config Release --target INSTALL
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Building expat-release"
    )

add_custom_target(expat-postinst
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/include"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/lib/pkgconfig"
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    DEPENDS expat-debug expat-release
    )

add_custom_target(expat ALL DEPENDS expat-postinst)
