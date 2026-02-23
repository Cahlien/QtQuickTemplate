include_guard(GLOBAL)

if (NOT DEFINED CACHE{QTQUICKTEMPLATE_ASC_API_KEY_ID})
    set(QTQUICKTEMPLATE_ASC_API_KEY_ID "" CACHE STRING
        "App Store Connect API key ID used for upload (e.g. ABCD123456)"
    )
endif ()

if (NOT DEFINED CACHE{QTQUICKTEMPLATE_ASC_API_ISSUER_ID})
    set(QTQUICKTEMPLATE_ASC_API_ISSUER_ID "" CACHE STRING
        "App Store Connect API issuer ID (UUID) used for upload"
    )
endif ()

function(configure_macos_appstore_upload target)
    if (NOT APPLE OR IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()

    if (NOT TARGET VerifyMacPkg)
        return()
    endif ()

    if (NOT QTQUICKTEMPLATE_ASC_API_KEY_ID OR NOT QTQUICKTEMPLATE_ASC_API_ISSUER_ID)
        message(WARNING "ASC API credentials not set; MacUploadASC target unavailable.")
        return()
    endif ()

    find_program(XCRUN_EXECUTABLE xcrun)
    if (NOT XCRUN_EXECUTABLE)
        message(WARNING "xcrun not found; MacUploadASC target unavailable.")
        return()
    endif ()

    set(_export_path "${CMAKE_BINARY_DIR}/macos/export")
    set(_upload_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/UploadAsc.cmake")

    if (NOT TARGET MacUploadASC)
        add_custom_target(MacUploadASC
            DEPENDS VerifyMacPkg
            COMMAND ${CMAKE_COMMAND} -E env
                XCRUN_EXECUTABLE=${XCRUN_EXECUTABLE}
                EXPORT_PATH=${_export_path}
                ARTIFACT_GLOB=*.pkg
                ASC_API_KEY_ID=${QTQUICKTEMPLATE_ASC_API_KEY_ID}
                ASC_API_ISSUER_ID=${QTQUICKTEMPLATE_ASC_API_ISSUER_ID}
                ${CMAKE_COMMAND} -P "${_upload_script}"
            COMMENT "Uploading signed macOS PKG to App Store Connect"
            VERBATIM
        )
        message(STATUS "MacUploadASC target configured -> cmake --build . --target MacUploadASC")
    endif ()
endfunction()
