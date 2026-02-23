include_guard(GLOBAL)

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

    get_target_property(_qmake_path Qt6::qmake IMPORTED_LOCATION)
    if (_qmake_path)
        get_filename_component(_qt_bin_dir "${_qmake_path}" DIRECTORY)
    else ()
        set(_qt_bin_dir "")
    endif ()
    find_program(MACDEPLOYQT_EXECUTABLE macdeployqt HINTS ${_qt_bin_dir})
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
    set(_version_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/GenerateVersion.cmake")
    set(_patch_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/macos/PatchArchiveInfo.cmake")
    set(_deployqt_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/macos/RunMacDeployQt.cmake")

    if (NOT TARGET GenerateMacOSVersion)
        add_custom_target(GenerateMacOSVersion
            COMMAND ${CMAKE_COMMAND}
                -DMAJOR=${PROJECT_VERSION_MAJOR}
                -DMINOR=${PROJECT_VERSION_MINOR}
                -DPATCH=${PROJECT_VERSION_PATCH}
                -DPLATFORM=macos
                -DOUT_FILE=${_version_xcconfig}
                -P ${_version_script}
            COMMENT "Generating macOS App Store version.xcconfig"
            VERBATIM
        )
    endif ()

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
                QML_DIR=${CMAKE_CURRENT_SOURCE_DIR}/ui
                APPSTORE_COMPLIANT=1
                ${CMAKE_COMMAND} -P "${_deployqt_script}"
            COMMENT "Archiving macOS app for App Store distribution"
            VERBATIM
        )
        message(STATUS "MacAppStoreArchive target configured -> cmake --build . --target MacAppStoreArchive")
    endif ()
endfunction()
