include_guard(GLOBAL)

# MacOSAppStoreBuild.cmake — Configures the MacAppStoreArchive target that builds,
# archives, patches ApplicationProperties, and runs macdeployqt -appstore-compliant
# for macOS App Store distribution.

include("${CMAKE_CURRENT_LIST_DIR}/../apple/FindMacDeployQt.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../VersionTarget.cmake")

set(QTQUICKTEMPLATE_MACOS_APP_STORE_ARCHIVE_CONFIGURATION "Release" CACHE STRING
    "Build configuration used for macOS App Store archive/export"
)

function(configure_macos_appstore_build target)
    if (NOT APPLE OR IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()

    if (NOT QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM)
        message(WARNING "QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM not set; macOS App Store targets unavailable.")
        return()
    endif ()

    find_program(XCODEBUILD_EXECUTABLE xcodebuild)
    if (NOT XCODEBUILD_EXECUTABLE)
        message(WARNING "xcodebuild not found; macOS App Store targets unavailable.")
        return()
    endif ()

    find_macdeployqt(MACDEPLOYQT_EXECUTABLE)
    if (NOT MACDEPLOYQT_EXECUTABLE)
        message(WARNING "macdeployqt not found; App Store archive will lack Qt frameworks.")
    endif ()

    set(_archive_path "${CMAKE_BINARY_DIR}/macos/${PROJECT_NAME}.xcarchive")
    set(_config "${QTQUICKTEMPLATE_MACOS_APP_STORE_ARCHIVE_CONFIGURATION}")

    set(_export_options "${CMAKE_CURRENT_BINARY_DIR}/${target}_MacAppStoreExportOptions.plist")
    file(WRITE "${_export_options}"
[=[<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>]=] "${QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM}" [=[</string>
</dict>
</plist>
]=])

    set(_version_xcconfig "${CMAKE_BINARY_DIR}/macos/version.xcconfig")
    set(_patch_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/macos/PatchArchiveInfo.cmake")
    set(_deployqt_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/macos/RunMacDeployQt.cmake")

    add_version_target(GenerateMacOSVersion macos "${_version_xcconfig}")

    if (NOT TARGET MacAppStoreArchive)
        add_custom_target(MacAppStoreArchive
            DEPENDS GenerateMacOSVersion
            COMMAND "${XCODEBUILD_EXECUTABLE}"
                -project "${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}.xcodeproj"
                -scheme "${target}"
                -configuration "${_config}"
                -destination "generic/platform=macOS"
                -archivePath "${_archive_path}"
                -xcconfig "${_version_xcconfig}"
                archive
                -allowProvisioningUpdates
                "CODE_SIGNING_ALLOWED=YES"
                "CODE_SIGN_STYLE=Manual"
                "CODE_SIGN_IDENTITY=Apple Distribution"
                "DEVELOPMENT_TEAM=${QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM}"
            COMMAND ${CMAKE_COMMAND} -E env
                ARCHIVE_PATH=${_archive_path}
                APP_NAME=${PROJECT_NAME}
                DEVELOPMENT_TEAM=${QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM}
                ${CMAKE_COMMAND} -P "${_patch_script}"
            COMMAND ${CMAKE_COMMAND} -E env
                MACDEPLOYQT_EXECUTABLE=${MACDEPLOYQT_EXECUTABLE}
                APP_BUNDLE_PATH=${_archive_path}/Products/Applications/${PROJECT_NAME}.app
                QML_DIR=${CMAKE_CURRENT_SOURCE_DIR}/qml
                APPSTORE_COMPLIANT=1
                ${CMAKE_COMMAND} -P "${_deployqt_script}"
            COMMENT "Archiving macOS app for App Store distribution"
            VERBATIM
        )
        register_help_target(
            NAME MacAppStoreArchive
            GROUP "macOS (App Store)"
            DESCRIPTION "Archive macOS app for App Store distribution via xcodebuild"
            COMMAND "cmake --build <dir> --target MacAppStoreArchive"
            VARIABLES "QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM -- Apple development team ID"
        )

        message(STATUS "MacAppStoreArchive target configured -> cmake --build . --target MacAppStoreArchive")
    endif ()
endfunction()
