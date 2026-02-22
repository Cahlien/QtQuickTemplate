include_guard(GLOBAL)

set(QTQUICKTEMPLATE_MACOS_APP_STORE_ARCHIVE_CONFIGURATION "Release" CACHE STRING
    "Build configuration used for macOS App Store archive/export"
)

# Fallback definitions for ASC API key vars in case IOSAppStoreConnect.cmake
# is not included (e.g., macOS-only projects).
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

# configure_macos_app_store_release(target)
#
# Adds MacAppStoreArchive, MacExportPkg, and VerifyMacPkg custom targets
# that archive the macOS app with xcodebuild and export a signed .pkg for
# Mac App Store submission.  Only active with the Xcode generator.
#
function(configure_macos_app_store_release target)
    if (NOT APPLE OR IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()

    if (NOT QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM)
        message(WARNING "QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM is not set; macOS App Store targets are unavailable.")
        return()
    endif ()

    find_program(XCODEBUILD_EXECUTABLE xcodebuild)
    if (NOT XCODEBUILD_EXECUTABLE)
        message(WARNING "xcodebuild not found; macOS App Store targets are unavailable.")
        return()
    endif ()

    # macdeployqt embeds Qt frameworks and plugins into the archived app bundle
    # so that the exported PKG is self-contained.  It must run after xcodebuild
    # archive but before xcodebuild -exportArchive.
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
    set(_export_path "${CMAKE_BINARY_DIR}/macos/export")
    set(_export_options_plist "${CMAKE_CURRENT_BINARY_DIR}/${target}_MacAppStoreExportOptions.plist")
    set(_config "${QTQUICKTEMPLATE_MACOS_APP_STORE_ARCHIVE_CONFIGURATION}")

    # Generate ExportOptions.plist for Mac App Store distribution.
    file(WRITE "${_export_options_plist}"
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

    # macdeployqt script for App Store: embeds Qt frameworks and plugins into
    # the archived app bundle.  No code-sign flag is passed here; the
    # xcodebuild -exportArchive step re-signs all embedded components.
    set(_deployqt_script "${CMAKE_CURRENT_BINARY_DIR}/appstore_deployqt.cmake")
    file(WRITE "${_deployqt_script}" [=[
cmake_minimum_required(VERSION 3.20)

foreach(_req_var IN ITEMS MACDEPLOYQT_EXECUTABLE APP_BUNDLE_PATH)
    if (NOT DEFINED ENV{${_req_var}} OR "$ENV{${_req_var}}" STREQUAL "")
        message(FATAL_ERROR "Required environment variable ${_req_var} is not set")
    endif ()
endforeach()

set(_bundle "$ENV{APP_BUNDLE_PATH}")
if (NOT EXISTS "${_bundle}")
    message(FATAL_ERROR "App bundle not found for macdeployqt: ${_bundle}")
endif ()

set(_cmd "$ENV{MACDEPLOYQT_EXECUTABLE}" "${_bundle}"
    "-always-overwrite" "-verbose=1" "-appstore-compliant")

if (DEFINED ENV{QML_DIR} AND EXISTS "$ENV{QML_DIR}")
    list(APPEND _cmd "-qmldir=$ENV{QML_DIR}")
endif ()

message(STATUS "Running macdeployqt (App Store) on ${_bundle}")
execute_process(
    COMMAND ${_cmd}
    RESULT_VARIABLE _rv
    OUTPUT_VARIABLE _out
    ERROR_VARIABLE  _err
)
if (NOT _rv EQUAL 0)
    message(FATAL_ERROR "macdeployqt failed:\n${_out}\n${_err}")
endif ()
message(STATUS "macdeployqt (App Store) completed successfully")
]=])

    # Post-archive patch script: Xcode 26 command-line archiving omits the
    # ApplicationProperties key from the xcarchive Info.plist for macOS targets.
    # Without that key, xcodebuild -exportArchive rejects every distribution
    # method.  This script reads the archived bundle's Info.plist and codesign
    # output and injects ApplicationProperties using PlistBuddy.
    set(_patch_script "${CMAKE_CURRENT_BINARY_DIR}/patch_macos_archive_info.cmake")
    file(WRITE "${_patch_script}" [=[
cmake_minimum_required(VERSION 3.20)

foreach(_req_var IN ITEMS ARCHIVE_PATH APP_NAME DEVELOPMENT_TEAM)
    if (NOT DEFINED ENV{${_req_var}} OR "$ENV{${_req_var}}" STREQUAL "")
        message(FATAL_ERROR "Required environment variable ${_req_var} is not set")
    endif ()
endforeach()

set(_archive_path  "$ENV{ARCHIVE_PATH}")
set(_app_name      "$ENV{APP_NAME}")
set(_team_id       "$ENV{DEVELOPMENT_TEAM}")
set(_app_bundle    "${_archive_path}/Products/Applications/${_app_name}.app")
set(_archive_plist "${_archive_path}/Info.plist")
set(_bundle_plist  "${_app_bundle}/Contents/Info.plist")

if (NOT EXISTS "${_bundle_plist}")
    message(FATAL_ERROR "App bundle Info.plist not found: ${_bundle_plist}")
endif ()
if (NOT EXISTS "${_archive_plist}")
    message(FATAL_ERROR "Archive Info.plist not found: ${_archive_plist}")
endif ()

# Skip if already present (e.g., re-running without a clean).
execute_process(
    COMMAND /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "${_archive_plist}"
    RESULT_VARIABLE _ap_result
    OUTPUT_QUIET ERROR_QUIET
)
if (_ap_result EQUAL 0)
    message(STATUS "ApplicationProperties already present in archive Info.plist — skipping patch")
    return()
endif ()

# Read bundle metadata.
foreach(_key IN ITEMS CFBundleIdentifier CFBundleShortVersionString CFBundleVersion)
    execute_process(
        COMMAND /usr/libexec/PlistBuddy -c "Print :${_key}" "${_bundle_plist}"
        OUTPUT_VARIABLE _val
        ERROR_VARIABLE  _err
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if ("${_val}" STREQUAL "")
        message(FATAL_ERROR "Could not read ${_key} from ${_bundle_plist}: ${_err}")
    endif ()
    set(_bundle_${_key} "${_val}")
endforeach()

# Derive signing identity from the archived app bundle.
# --verbose=4 is required: Authority= lines only appear at verbosity level 4.
execute_process(
    COMMAND codesign -dv --verbose=4 "${_app_bundle}"
    OUTPUT_VARIABLE _cs_out
    ERROR_VARIABLE  _cs_err
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
)
string(APPEND _cs_out "${_cs_err}")
string(REGEX MATCH "Authority=([^\n\r]+)" _auth_match "${_cs_out}")
set(_signing_id "${CMAKE_MATCH_1}")
if ("${_signing_id}" STREQUAL "")
    message(FATAL_ERROR "Could not determine signing identity from codesign output:\n${_cs_out}")
endif ()

message(STATUS "Patching archive Info.plist with ApplicationProperties:")
message(STATUS "  ApplicationPath            : Applications/${_app_name}.app")
message(STATUS "  CFBundleIdentifier         : ${_bundle_CFBundleIdentifier}")
message(STATUS "  CFBundleShortVersionString : ${_bundle_CFBundleShortVersionString}")
message(STATUS "  CFBundleVersion            : ${_bundle_CFBundleVersion}")
message(STATUS "  SigningIdentity            : ${_signing_id}")
message(STATUS "  Team                       : ${_team_id}")

execute_process(
    COMMAND /usr/libexec/PlistBuddy
        -c "Add :ApplicationProperties dict"
        -c "Add :ApplicationProperties:ApplicationPath string Applications/${_app_name}.app"
        -c "Add :ApplicationProperties:CFBundleIdentifier string ${_bundle_CFBundleIdentifier}"
        -c "Add :ApplicationProperties:CFBundleShortVersionString string ${_bundle_CFBundleShortVersionString}"
        -c "Add :ApplicationProperties:CFBundleVersion string ${_bundle_CFBundleVersion}"
        -c "Add :ApplicationProperties:SigningIdentity string ${_signing_id}"
        -c "Add :ApplicationProperties:Team string ${_team_id}"
        "${_archive_plist}"
    RESULT_VARIABLE _rv
    ERROR_VARIABLE  _err
)
if (NOT _rv EQUAL 0)
    message(FATAL_ERROR "Failed to patch archive Info.plist:\n${_err}")
endif ()

message(STATUS "Archive Info.plist patched successfully")
]=])

    # PKG verification script.
    set(_verify_script "${CMAKE_CURRENT_BINARY_DIR}/verify_macos_pkg.cmake")
    file(WRITE "${_verify_script}" [=[
if (NOT DEFINED ENV{MACOS_EXPORT_PATH} OR "$ENV{MACOS_EXPORT_PATH}" STREQUAL "")
    message(FATAL_ERROR "MACOS_EXPORT_PATH env var is required")
endif ()

file(GLOB _pkgs "$ENV{MACOS_EXPORT_PATH}/*.pkg")
list(LENGTH _pkgs _pkg_count)
if (_pkg_count EQUAL 0)
    message(FATAL_ERROR "No .pkg file found in $ENV{MACOS_EXPORT_PATH}")
endif ()

list(SORT _pkgs)
list(GET _pkgs -1 _pkg)
message(STATUS "Exported macOS PKG: ${_pkg}")
]=])

    # Version xcconfig — macOS uses 3-part CURRENT_PROJECT_VERSION (no build number).
    set(_version_xcconfig "${CMAKE_BINARY_DIR}/macos/version.xcconfig")
    set(_version_script "${CMAKE_CURRENT_SOURCE_DIR}/scripts/generate_version.cmake")

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
            # Xcode 26 omits ApplicationProperties from the xcarchive Info.plist
            # for macOS command-line archives.  Patch it in so that
            # xcodebuild -exportArchive can validate the distribution method.
            # Run the patch BEFORE macdeployqt so we can read the valid Apple
            # Distribution codesign info from the freshly archived bundle.
            COMMAND ${CMAKE_COMMAND} -E env
                ARCHIVE_PATH=${_archive_path}
                APP_NAME=${PROJECT_NAME}
                DEVELOPMENT_TEAM=${QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM}
                ${CMAKE_COMMAND} -P "${_patch_script}"
            # Embed Qt frameworks and plugins into the archived app bundle so the
            # exported PKG is self-contained.  This runs after the patch because
            # macdeployqt breaks the bundle's code signature; the export step
            # re-signs everything with the App Store distribution certificate.
            COMMAND ${CMAKE_COMMAND} -E env
                MACDEPLOYQT_EXECUTABLE=${MACDEPLOYQT_EXECUTABLE}
                APP_BUNDLE_PATH=${_archive_path}/Products/Applications/${PROJECT_NAME}.app
                QML_DIR=${CMAKE_CURRENT_SOURCE_DIR}/ui
                ${CMAKE_COMMAND} -P "${_deployqt_script}"
            COMMENT "Archiving macOS app for App Store distribution"
            VERBATIM
        )
        message(STATUS "MacAppStoreArchive target configured -> cmake --build . --target MacAppStoreArchive")
    endif ()

    if (NOT TARGET MacExportPkg)
        add_custom_target(MacExportPkg
            DEPENDS MacAppStoreArchive
            COMMAND ${CMAKE_COMMAND} -E make_directory "${_export_path}"
            COMMAND "${XCODEBUILD_EXECUTABLE}"
                -exportArchive
                -archivePath "${_archive_path}"
                -exportPath "${_export_path}"
                -exportOptionsPlist "${_export_options_plist}"
                -allowProvisioningUpdates
            COMMENT "Exporting signed macOS PKG for App Store submission"
            VERBATIM
        )
        message(STATUS "MacExportPkg target configured -> cmake --build . --target MacExportPkg")
    endif ()

    if (NOT TARGET VerifyMacPkg)
        add_custom_target(VerifyMacPkg
            DEPENDS MacExportPkg
            COMMAND ${CMAKE_COMMAND} -E env
                MACOS_EXPORT_PATH=${_export_path}
                ${CMAKE_COMMAND} -P "${_verify_script}"
            COMMENT "Verifying exported macOS PKG output"
            VERBATIM
        )
        message(STATUS "VerifyMacPkg target configured -> cmake --build . --target VerifyMacPkg")
    endif ()
endfunction()
