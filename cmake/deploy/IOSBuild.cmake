include_guard(GLOBAL)

set(QTQUICKTEMPLATE_IOS_ARCHIVE_CONFIGURATION "Release" CACHE STRING
    "Build configuration used for iOS archive/export"
)

function(configure_ios_build target)
    if (NOT APPLE OR NOT IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()

    if (NOT QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM)
        message(WARNING "QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM not set; iOS App Store targets unavailable.")
        return()
    endif ()

    find_program(XCODEBUILD_EXECUTABLE xcodebuild)
    if (NOT XCODEBUILD_EXECUTABLE)
        message(WARNING "xcodebuild not found; iOS App Store targets unavailable.")
        return()
    endif ()

    set(_archive_path "${CMAKE_BINARY_DIR}/ios/${PROJECT_NAME}.xcarchive")
    set(_export_options "${CMAKE_CURRENT_BINARY_DIR}/${target}_ExportOptions.plist")
    set(_config "${QTQUICKTEMPLATE_IOS_ARCHIVE_CONFIGURATION}")
    set(_app_bundle "${CMAKE_BINARY_DIR}/${_config}-iphoneos/${target}.app")
    set(_dsym_bundle "${CMAKE_BINARY_DIR}/${_config}-iphoneos/${target}.app.dSYM")

    file(WRITE "${_export_options}"
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

    set(_version_xcconfig "${CMAKE_BINARY_DIR}/ios/version.xcconfig")
    set(_version_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/GenerateVersion.cmake")

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

    set(QTQUICKTEMPLATE_IOS_ARCHIVE_PATH "${_archive_path}" PARENT_SCOPE)
    set(QTQUICKTEMPLATE_IOS_EXPORT_OPTIONS "${_export_options}" PARENT_SCOPE)
endfunction()
