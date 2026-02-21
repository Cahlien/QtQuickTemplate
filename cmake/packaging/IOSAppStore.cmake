include_guard(GLOBAL)

set(QTQUICKTEMPLATE_IOS_ARCHIVE_CONFIGURATION "Release" CACHE STRING
    "Build configuration used for iOS archive/export"
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

    set(_archive_path "${CMAKE_BINARY_DIR}/ios/${PROJECT_NAME}.xcarchive")
    set(_export_path "${CMAKE_BINARY_DIR}/ios/export")
    set(_export_options_plist "${CMAKE_CURRENT_BINARY_DIR}/${target}_ExportOptions.plist")
    set(_config "${QTQUICKTEMPLATE_IOS_ARCHIVE_CONFIGURATION}")

    # Build output paths that xcodebuild archive contaminates with symlinks
    # into Xcode DerivedData.  These must be cleaned before and after the
    # archive step to prevent broken symlinks from blocking subsequent builds.
    set(_app_bundle "${CMAKE_BINARY_DIR}/${_config}-iphoneos/${target}.app")
    set(_dsym_bundle "${CMAKE_BINARY_DIR}/${_config}-iphoneos/${target}.app.dSYM")

    # Generate ExportOptions.plist for App Store distribution.
    # Note: compileBitcode is intentionally omitted -- Apple deprecated
    # bitcode in Xcode 14 and App Store Connect ignores it.
    file(WRITE "${_export_options_plist}"
[=[<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>]=] "${QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM}" [=[</string>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
]=])

    # IPA verification script.
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

    # Note: macdeployqt is intentionally NOT used for iOS.  Qt is statically
    # linked on iOS (all libraries and QML modules are compiled into the
    # binary), so there are no frameworks to deploy.  xcodebuild archive
    # handles the final packaging, code signing, and resource embedding.

    # Generate a version xcconfig at build time so CFBundleVersion auto-
    # increments with each git commit (same scheme as Android).
    set(_version_xcconfig "${CMAKE_BINARY_DIR}/ios/version.xcconfig")
    set(_version_script "${CMAKE_CURRENT_SOURCE_DIR}/scripts/generate_version.cmake")

    if (NOT TARGET GenerateIOSVersion)
        add_custom_target(GenerateIOSVersion
            COMMAND ${CMAKE_COMMAND}
                -DMAJOR=${PROJECT_VERSION_MAJOR}
                -DMINOR=${PROJECT_VERSION_MINOR}
                -DPATCH=${PROJECT_VERSION_PATCH}
                -DPLATFORM=ios
                -DOUT_FILE=${_version_xcconfig}
                -P ${_version_script}
            COMMENT "Generating iOS version.xcconfig"
            VERBATIM
        )
    endif ()

    if (NOT TARGET IOSArchive)
        add_custom_target(IOSArchive
            DEPENDS ${target} GenerateIOSVersion
            COMMAND ${CMAKE_COMMAND} -E rm -rf "${_app_bundle}" "${_dsym_bundle}"
            COMMAND "${XCODEBUILD_EXECUTABLE}"
                -project "${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}.xcodeproj"
                -scheme "${target}"
                -configuration "${_config}"
                -destination "generic/platform=iOS"
                -archivePath "${_archive_path}"
                -xcconfig "${_version_xcconfig}"
                archive
                -allowProvisioningUpdates
                "CODE_SIGN_STYLE=Manual"
                "CODE_SIGN_IDENTITY=Apple Distribution"
                "DEVELOPMENT_TEAM=${QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM}"
            COMMAND ${CMAKE_COMMAND} -E rm -rf "${_app_bundle}" "${_dsym_bundle}"
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
                -allowProvisioningUpdates
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
