file(DOWNLOAD "https://zlib.net/zlib-1.2.11.tar.xz"
    "${CMAKE_BINARY_DIR}/zlib-1.2.11.tar.xz"
    EXPECTED_HASH SHA256=4ff941449631ace0d4d203e3483be9dbc9da454084111f97ea0a2114e19bf066
    STATUS zlib_STATUS SHOW_PROGRESS
    )
check_download(zlib zlib-1.2.11.tar.xz)

add_custom_target(zlib-preinst
    COMMAND ${CMAKE_COMMAND} -E tar xJf zlib-1.2.11.tar.xz
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Unpacking zlib"
    )

add_custom_target(zlib-debug
    COMMAND ${CMAKE_COMMAND} -G "${VCSLN_GENERATOR}"
                -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}/debug"
                -Hzlib-1.2.11 -Bzlib-debug
    COMMAND ${CMAKE_COMMAND} --build zlib-debug --config Debug
    COMMAND ${CMAKE_COMMAND} --build zlib-debug --config Debug --target INSTALL
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Building zlib-debug"
    DEPENDS zlib-preinst
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
    DEPENDS zlib-preinst zlib-debug
    )

if(BUILD_STATIC_LIBS)
    add_custom_target(zlib-postinst
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
    add_custom_target(zlib-postinst
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/include"
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${INSTALL_DIR}/debug/share"
        COMMAND ${CMAKE_COMMAND} -E remove "${INSTALL_DIR}/debug/lib/zlibstaticd.lib"
        COMMAND ${CMAKE_COMMAND} -E remove "${INSTALL_DIR}/lib/zlibstatic.lib"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        DEPENDS zlib-debug zlib-release
        )
endif()

add_custom_target(zlib ALL DEPENDS zlib-postinst)
