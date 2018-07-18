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

set(perl_VERSION 5.24.4.1)

file(DOWNLOAD "http://strawberryperl.com/download/${perl_VERSION}/strawberry-perl-${perl_VERSION}-32bit-portable.zip"
    "${CMAKE_BINARY_DIR}/strawberry-perl-${perl_VERSION}-32bit-portable.zip"
    EXPECTED_HASH SHA1=0ec52e7864e1b90128399e36858fa2a000be8360
    SHOW_PROGRESS
    )

unpack_zip(strawberry-perl-${perl_VERSION}-32bit-portable.zip perl
    DEST_DIR "${CMAKE_BINARY_DIR}/strawberry-perl"
    )
set(PERL_PATH "${CMAKE_BINARY_DIR}/strawberry-perl/perl/bin")
set(PERL_COMMAND "${PERL_PATH}/perl.exe")
