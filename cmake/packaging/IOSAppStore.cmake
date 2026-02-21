include_guard(GLOBAL)

set(QTQUICKTEMPLATE_IOS_ARCHIVE_CONFIGURATION "Release" CACHE STRING
    "Build configuration used for iOS archive/export"
)

set(QTQUICKTEMPLATE_IOS_ARCHIVE_PATH "${CMAKE_BINARY_DIR}/ios/${PROJECT_NAME}.xcarchive" CACHE PATH
    "Output path for the generated iOS .xcarchive"
)

set(QTQUICKTEMPLATE_IOS_EXPORT_PATH "${CMAKE_BINARY_DIR}/ios/export" CACHE PATH
    "Output directory for exported iOS artifacts (.ipa)"
)

set(QTQUICKTEMPLATE_IOS_EXPORT_OPTIONS_PLIST "" CACHE FILEPATH
    "Optional existing ExportOptions.plist path; generated automatically when empty"
)

set(QTQUICKTEMPLATE_IOS_ALLOW_PROVISIONING_UPDATES ON CACHE BOOL
    "Allow xcodebuild to auto-manage provisioning updates during archive/export"
)

set(QTQUICKTEMPLATE_IOS_EXPORT_METHOD "app-store" CACHE STRING
    "xcodebuild -exportArchive method for iOS export"
)

function(configure_ios_app_store_release target)
    if (NOT APPLE OR NOT IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()

    if (NOT QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM)
        message(WARNING "QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM is not set; iOS App Store targets are unavailable.")
        return()
    endif ()

    find_program(XCODEBUILD_EXECUTABLE xcodebuild)
    if (NOT XCODEBUILD_EXECUTABLE)
        message(WARNING "xcodebuild not found; iOS App Store targets are unavailable.")
        return()
    endif ()

    set(_archive_path "${QTQUICKTEMPLATE_IOS_ARCHIVE_PATH}")
    set(_export_path "${QTQUICKTEMPLATE_IOS_EXPORT_PATH}")
    set(_export_options_plist "${QTQUICKTEMPLATE_IOS_EXPORT_OPTIONS_PLIST}")
    string(TOLOWER "${QTQUICKTEMPLATE_IOS_CODE_SIGN_STYLE}" _ios_signing_style_lower)
    if (NOT _ios_signing_style_lower STREQUAL "automatic" AND NOT _ios_signing_style_lower STREQUAL "manual")
        message(FATAL_ERROR "QTQUICKTEMPLATE_IOS_CODE_SIGN_STYLE must be Automatic or Manual")
    endif ()

    if (_ios_signing_style_lower STREQUAL "manual" AND NOT QTQUICKTEMPLATE_IOS_PROVISIONING_PROFILE_SPECIFIER)
        message(WARNING "QTQUICKTEMPLATE_IOS_PROVISIONING_PROFILE_SPECIFIER is required for manual iOS signing; iOS App Store targets are unavailable.")
        return()
    endif ()

    if (NOT _export_options_plist)
        set(_export_options_plist "${CMAKE_CURRENT_BINARY_DIR}/${target}_ExportOptions.plist")
        file(WRITE "${_export_options_plist}" "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
        file(APPEND "${_export_options_plist}" "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n")
        file(APPEND "${_export_options_plist}" "<plist version=\"1.0\">\n")
        file(APPEND "${_export_options_plist}" "<dict>\n")
        file(APPEND "${_export_options_plist}" "    <key>method</key>\n")
        file(APPEND "${_export_options_plist}" "    <string>${QTQUICKTEMPLATE_IOS_EXPORT_METHOD}</string>\n")
        file(APPEND "${_export_options_plist}" "    <key>signingStyle</key>\n")
        file(APPEND "${_export_options_plist}" "    <string>${_ios_signing_style_lower}</string>\n")
        file(APPEND "${_export_options_plist}" "    <key>teamID</key>\n")
        file(APPEND "${_export_options_plist}" "    <string>${QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM}</string>\n")
        if (_ios_signing_style_lower STREQUAL "manual")
            file(APPEND "${_export_options_plist}" "    <key>provisioningProfiles</key>\n")
            file(APPEND "${_export_options_plist}" "    <dict>\n")
            file(APPEND "${_export_options_plist}" "        <key>${QTQUICKTEMPLATE_APPLE_BUNDLE_IDENTIFIER}</key>\n")
            file(APPEND "${_export_options_plist}" "        <string>${QTQUICKTEMPLATE_IOS_PROVISIONING_PROFILE_SPECIFIER}</string>\n")
            file(APPEND "${_export_options_plist}" "    </dict>\n")
        endif ()
        if (QTQUICKTEMPLATE_IOS_CODE_SIGN_IDENTITY)
            file(APPEND "${_export_options_plist}" "    <key>signingCertificate</key>\n")
            file(APPEND "${_export_options_plist}" "    <string>${QTQUICKTEMPLATE_IOS_CODE_SIGN_IDENTITY}</string>\n")
        endif ()
        file(APPEND "${_export_options_plist}" "    <key>stripSwiftSymbols</key>\n")
        file(APPEND "${_export_options_plist}" "    <true/>\n")
        file(APPEND "${_export_options_plist}" "    <key>compileBitcode</key>\n")
        file(APPEND "${_export_options_plist}" "    <true/>\n")
        file(APPEND "${_export_options_plist}" "</dict>\n")
        file(APPEND "${_export_options_plist}" "</plist>\n")
    endif ()

    set(_allow_updates_arg "")
    if (QTQUICKTEMPLATE_IOS_ALLOW_PROVISIONING_UPDATES)
        set(_allow_updates_arg "-allowProvisioningUpdates")
    endif ()

    set(_verify_script "${CMAKE_CURRENT_BINARY_DIR}/verify_ios_ipa.cmake")
    file(WRITE "${_verify_script}" [=[
if (NOT DEFINED ENV{IOS_EXPORT_PATH} OR "$ENV{IOS_EXPORT_PATH}" STREQUAL "")
    message(FATAL_ERROR "IOS_EXPORT_PATH env var is required")
endif ()

file(GLOB _ipas "$ENV{IOS_EXPORT_PATH}/*.ipa")
list(LENGTH _ipas _ipa_count)
if (_ipa_count EQUAL 0)
    message(FATAL_ERROR "No .ipa file found in $ENV{IOS_EXPORT_PATH}")
endif ()

list(SORT _ipas)
list(GET _ipas -1 _ipa)
message(STATUS "Exported iOS IPA: ${_ipa}")
]=])

    if (NOT TARGET IOSArchive)
        add_custom_target(IOSArchive
            DEPENDS ${target}
            COMMAND "${XCODEBUILD_EXECUTABLE}"
                -project "${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}.xcodeproj"
                -scheme "${target}"
                -configuration "${QTQUICKTEMPLATE_IOS_ARCHIVE_CONFIGURATION}"
                -destination "generic/platform=iOS"
                -archivePath "${_archive_path}"
                archive
                ${_allow_updates_arg}
            COMMENT "Archiving iOS app for App Store distribution"
            VERBATIM
        )
        message(STATUS "IOSArchive target configured -> cmake --build . --target IOSArchive")
    endif ()

    if (NOT TARGET IOSExportIPA)
        add_custom_target(IOSExportIPA
            DEPENDS IOSArchive
            COMMAND ${CMAKE_COMMAND} -E make_directory "${_export_path}"
            COMMAND "${XCODEBUILD_EXECUTABLE}"
                -exportArchive
                -archivePath "${_archive_path}"
                -exportPath "${_export_path}"
                -exportOptionsPlist "${_export_options_plist}"
                ${_allow_updates_arg}
            COMMENT "Exporting signed iOS IPA for App Store submission"
            VERBATIM
        )
        message(STATUS "IOSExportIPA target configured -> cmake --build . --target IOSExportIPA")
    endif ()

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
