include_guard(GLOBAL)

set(QTQUICKTEMPLATE_ASC_API_KEY_ID "" CACHE STRING
    "App Store Connect API key ID used for upload (e.g. NV3YP3T2C5)"
)

set(QTQUICKTEMPLATE_ASC_API_ISSUER_ID "" CACHE STRING
    "App Store Connect API issuer ID (UUID) used for upload"
)

function(configure_ios_upload target)
    if (NOT APPLE OR NOT IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()

    if (NOT TARGET VerifyIOSIPA)
        return()
    endif ()

    if (NOT QTQUICKTEMPLATE_ASC_API_KEY_ID OR NOT QTQUICKTEMPLATE_ASC_API_ISSUER_ID)
        message(WARNING "ASC API credentials not set; IOSUploadASC target unavailable.")
        return()
    endif ()

    find_program(XCRUN_EXECUTABLE xcrun)
    if (NOT XCRUN_EXECUTABLE)
        message(WARNING "xcrun not found; IOSUploadASC target unavailable.")
        return()
    endif ()

    set(_export_path "${CMAKE_BINARY_DIR}/ios/export")
    set(_upload_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/UploadAsc.cmake")

    if (NOT TARGET IOSUploadASC)
        add_custom_target(IOSUploadASC
            DEPENDS VerifyIOSIPA
            COMMAND ${CMAKE_COMMAND} -E env
                XCRUN_EXECUTABLE=${XCRUN_EXECUTABLE}
                EXPORT_PATH=${_export_path}
                ARTIFACT_GLOB=*.ipa
                ASC_API_KEY_ID=${QTQUICKTEMPLATE_ASC_API_KEY_ID}
                ASC_API_ISSUER_ID=${QTQUICKTEMPLATE_ASC_API_ISSUER_ID}
                ${CMAKE_COMMAND} -P "${_upload_script}"
            COMMENT "Uploading signed iOS IPA to App Store Connect"
            VERBATIM
        )
        message(STATUS "IOSUploadASC target configured -> cmake --build . --target IOSUploadASC")
    endif ()
endfunction()
