include_guard(GLOBAL)

set(QTQUICKTEMPLATE_ASC_API_KEY_ID "" CACHE STRING
    "App Store Connect API key ID used for upload (e.g. NV3YP3T2C5)"
)

set(QTQUICKTEMPLATE_ASC_API_ISSUER_ID "" CACHE STRING
    "App Store Connect API issuer ID (UUID) used for upload"
)

# Private helper shared by iOS and macOS App Store upload targets.
function(_configure_asc_upload target_name depends_target export_path artifact_glob comment)
    if (NOT QTQUICKTEMPLATE_ASC_API_KEY_ID OR NOT QTQUICKTEMPLATE_ASC_API_ISSUER_ID)
        message(WARNING "ASC API credentials not set; ${target_name} target unavailable.")
        return()
    endif ()

    find_program(XCRUN_EXECUTABLE xcrun)
    if (NOT XCRUN_EXECUTABLE)
        message(WARNING "xcrun not found; ${target_name} target unavailable.")
        return()
    endif ()

    set(_upload_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/UploadAsc.cmake")

    if (NOT TARGET ${target_name})
        add_custom_target(${target_name}
            DEPENDS ${depends_target}
            COMMAND ${CMAKE_COMMAND} -E env
                XCRUN_EXECUTABLE=${XCRUN_EXECUTABLE}
                EXPORT_PATH=${export_path}
                ARTIFACT_GLOB=${artifact_glob}
                ASC_API_KEY_ID=${QTQUICKTEMPLATE_ASC_API_KEY_ID}
                ASC_API_ISSUER_ID=${QTQUICKTEMPLATE_ASC_API_ISSUER_ID}
                ${CMAKE_COMMAND} -P "${_upload_script}"
            COMMENT "${comment}"
            VERBATIM
        )
        message(STATUS "${target_name} target configured -> cmake --build . --target ${target_name}")
    endif ()
endfunction()

function(configure_ios_upload target)
    if (NOT APPLE OR NOT IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()
    if (NOT TARGET VerifyIOSIPA)
        return()
    endif ()
    _configure_asc_upload(IOSUploadASC VerifyIOSIPA
        "${CMAKE_BINARY_DIR}/ios/export" "*.ipa"
        "Uploading signed iOS IPA to App Store Connect")
endfunction()

function(configure_macos_appstore_upload target)
    if (NOT APPLE OR IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()
    if (NOT TARGET VerifyMacPkg)
        return()
    endif ()
    _configure_asc_upload(MacUploadASC VerifyMacPkg
        "${CMAKE_BINARY_DIR}/macos/export" "*.pkg"
        "Uploading signed macOS PKG to App Store Connect")
endfunction()
