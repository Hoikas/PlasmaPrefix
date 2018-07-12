# Copyright (c) 2018 Michael Hansen
# Leveraged heavily from vcpkg:
# https://github.com/Microsoft/vcpkg/blob/master/scripts/cmake/vcpkg_apply_patches.cmake
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

function(apply_patch patch source_path)
    get_filename_component(patch_name "${patch}" NAME)
    if(NOT EXISTS "${source_path}/.${patch_name}-applied")
        find_program(GIT NAMES git git.cmd)
        if(NOT GIT)
            message(FATAL_ERROR "Could not find git executable")
        endif()

        message(STATUS "Applying patch ${patch_name}")
        execute_process(
            COMMAND ${GIT} --work-tree=. --git-dir=.git apply "${patch}"
                        --ignore-whitespace --whitespace=nowarn --verbose
            WORKING_DIRECTORY "${source_path}"
            RESULT_VARIABLE error_code
            )

        if(error_code)
            message(FATAL_ERROR "Applying patch ${patch_name} failed.")
        endif()

        file(WRITE "${source_path}/.${patch_name}-applied" "")
    endif()
endfunction()
