include_guard(GLOBAL)

function(configure_ios_verify target)
    if (NOT APPLE OR NOT IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()

    if (NOT TARGET IOSExportIPA)
        return()
    endif ()

    set(_export_path "${CMAKE_BINARY_DIR}/ios/export")
    set(_verify_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/ios/VerifyIpa.cmake")

    if (NOT TARGET VerifyIOSIPA)
        add_custom_target(VerifyIOSIPA
            DEPENDS IOSExportIPA
            COMMAND ${CMAKE_COMMAND} -E env
                IOS_EXPORT_PATH=${_export_path}
                ${CMAKE_COMMAND} -P "${_verify_script}"
            COMMENT "Verifying exported iOS IPA output"
            VERBATIM
        )
        message(STATUS "VerifyIOSIPA target configured -> cmake --build . --target VerifyIOSIPA")
    endif ()
endfunction()
