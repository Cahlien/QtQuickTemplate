include_guard(GLOBAL)

# IOSBuild.cmake — Configures the IOSArchive target that builds and archives
# the iOS app via xcodebuild for App Store distribution.

include("${CMAKE_CURRENT_LIST_DIR}/../VersionTarget.cmake")

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

    add_version_target(GenerateIOSVersion ios "${_version_xcconfig}")

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
        register_help_target(
            NAME IOSArchive
            GROUP "iOS"
            DESCRIPTION "Archive iOS app for App Store distribution via xcodebuild"
            COMMAND "cmake --build <dir> --target IOSArchive"
            VARIABLES "QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM -- Apple development team ID"
        )

        message(STATUS "IOSArchive target configured -> cmake --build . --target IOSArchive")
    endif ()

    set(QTQUICKTEMPLATE_IOS_ARCHIVE_PATH "${_archive_path}" PARENT_SCOPE)
    set(QTQUICKTEMPLATE_IOS_EXPORT_OPTIONS "${_export_options}" PARENT_SCOPE)
endfunction()
