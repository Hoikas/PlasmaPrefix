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

file(DOWNLOAD "https://download.sourceforge.net/libjpeg-turbo/libjpeg-turbo-1.5.3.tar.gz"
    "${CMAKE_BINARY_DIR}/libjpeg-turbo-1.5.3.tar.gz"
    EXPECTED_HASH SHA256=b24890e2bb46e12e72a79f7e965f409f4e16466d00e1dd15d93d73ee6b592523
    SHOW_PROGRESS
    )
unpack_tgz(libjpeg-turbo-1.5.3.tar.gz libjpeg-turbo-1.5.3)

file(DOWNLOAD "https://raw.githubusercontent.com/Microsoft/vcpkg/89589c000a6f523fba8f7b44582a1347694b9ece/ports/libjpeg-turbo/add-options-for-exes-docs-headers.patch"
    "${CMAKE_BINARY_DIR}/add-options-for-exes-docs-headers.patch"
    EXPECTED_HASH SHA256=39d73a4b638f80d1975c1fa8dfd1b13881c4291e717531b56c287a16c3a460e9
    STATUS libjpeg-turbo_p0_STATUS
    )
apply_patch(libjpeg-turbo_p0
    add-options-for-exes-docs-headers.patch
    "${CMAKE_BINARY_DIR}/libjpeg-turbo-1.5.3"
    )

if(BUILD_STATIC_LIBS)
    set(JPEGT_CMAKE_ARGS -DENABLE_STATIC=ON -DENABLE_SHARED=OFF)
else()
    set(JPEGT_CMAKE_ARGS -DENABLE_STATIC=OFF -DENABLE_SHARED=ON)
endif()
set(JPEGT_CMAKE_ARGS ${JPEGT_CMAKE_ARGS} -DWITH_CRT_DLL=ON -DWITH_SIMD=ON
                        -DENABLE_EXECUTABLES=OFF -DINSTALL_DOCS=OFF
                        -DNASM="${NASM_PATH}"
    )

add_custom_target(libjpeg-turbo-debug
    COMMAND ${CMAKE_COMMAND} -G "${VCSLN_GENERATOR}" ${JPEGT_CMAKE_ARGS}
                -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}/debug"
                -Hlibjpeg-turbo-1.5.3 -Blibjpeg-turbo-debug
    COMMAND ${CMAKE_COMMAND} --build libjpeg-turbo-debug --config Debug
    COMMAND ${CMAKE_COMMAND} --build libjpeg-turbo-debug --config Debug --target INSTALL
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Building libjpeg-turbo-debug"
    )

add_custom_target(libjpeg-turbo-release
    COMMAND ${CMAKE_COMMAND} -G "${VCSLN_GENERATOR}" ${JPEGT_CMAKE_ARGS}
                -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"
                -Hlibjpeg-turbo-1.5.3 -Blibjpeg-turbo-release
    COMMAND ${CMAKE_COMMAND} --build libjpeg-turbo-release --config Release
    COMMAND ${CMAKE_COMMAND} --build libjpeg-turbo-release --config Release --target INSTALL
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Building libjpeg-turbo-release"
    )

if(BUILD_STATIC_LIBS)
    add_custom_target(libjpeg-turbo-postinst
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/include"
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/share"
        COMMAND ${CMAKE_COMMAND} -E rename "${INSTALL_DIR}/lib/jpeg-static.lib"
                    "${INSTALL_DIR}/lib/jpeg.lib"
        COMMAND ${CMAKE_COMMAND} -E rename "${INSTALL_DIR}/lib/turbojpeg-static.lib"
                    "${INSTALL_DIR}/lib/turbojpeg.lib"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        DEPENDS libjpeg-turbo-debug libjpeg-turbo-release
        )
else()
    add_custom_target(libjpeg-turbo-postinst
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/include"
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/share"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        DEPENDS libjpeg-turbo-debug libjpeg-turbo-release
        )
endif()

add_custom_target(libjpeg-turbo ALL DEPENDS libjpeg-turbo-postinst)
