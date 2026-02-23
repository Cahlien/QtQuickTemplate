include_guard(GLOBAL)

function(configure_macos_appstore_verify target)
    if (NOT APPLE OR IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()

    if (NOT TARGET MacExportPkg)
        return()
    endif ()

    set(_export_path "${CMAKE_BINARY_DIR}/macos/export")
    set(_verify_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/macos/VerifyPkg.cmake")

    if (NOT TARGET VerifyMacPkg)
        add_custom_target(VerifyMacPkg
            DEPENDS MacExportPkg
            COMMAND ${CMAKE_COMMAND} -E env
                MACOS_EXPORT_PATH=${_export_path}
                ${CMAKE_COMMAND} -P "${_verify_script}"
            COMMENT "Verifying exported macOS PKG output"
            VERBATIM
        )
        message(STATUS "VerifyMacPkg target configured -> cmake --build . --target VerifyMacPkg")
    endif ()
endfunction()
