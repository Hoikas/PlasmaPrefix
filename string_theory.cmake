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

set(ST_VERSION 2.1)

file(DOWNLOAD "https://github.com/zrax/string_theory/archive/${ST_VERSION}.tar.gz"
    "${CMAKE_BINARY_DIR}/string_theory-${ST_VERSION}.tar.gz"
    EXPECTED_HASH SHA256=abb4e67320d82149aad289c714a089bf25b9956d81dd0010dfdc1dc1492c0b8c
    STATUS string_theory_STATUS SHOW_PROGRESS
    )
unpack_tgz(string_theory-${ST_VERSION}.tar.gz string_theory-${ST_VERSION})

add_custom_target(string_theory-build
    COMMAND ${CMAKE_COMMAND} -G "${VCSLN_GENERATOR}"
                -DST_BUILD_STATIC=${BUILD_STATIC_LIBS} -DST_BUILD_TESTS=OFF
                -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"
                -Hstring_theory-${ST_VERSION} -Bstring_theory-release
    COMMAND ${CMAKE_COMMAND} --build string_theory-release --config Debug
    COMMAND ${CMAKE_COMMAND} --build string_theory-release --config Debug --target INSTALL
    COMMAND ${CMAKE_COMMAND} --build string_theory-release --config Release
    COMMAND ${CMAKE_COMMAND} --build string_theory-release --config Release --target INSTALL
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Building string_theory"
    )

add_custom_target(string_theory ALL DEPENDS string_theory-build)
