cmake_minimum_required(VERSION 3.20)

foreach (_req IN ITEMS ARCHIVE_PATH APP_NAME DEVELOPMENT_TEAM)
    if (NOT DEFINED ENV{${_req}} OR "$ENV{${_req}}" STREQUAL "")
        message(FATAL_ERROR "${_req} env var is required")
    endif ()
endforeach ()

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

execute_process(
    COMMAND /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "${_archive_plist}"
    RESULT_VARIABLE _ap_result OUTPUT_QUIET ERROR_QUIET
)
if (_ap_result EQUAL 0)
    message(STATUS "ApplicationProperties already present -- skipping patch")
    return()
endif ()

foreach (_key IN ITEMS CFBundleIdentifier CFBundleShortVersionString CFBundleVersion)
    execute_process(
        COMMAND /usr/libexec/PlistBuddy -c "Print :${_key}" "${_bundle_plist}"
        OUTPUT_VARIABLE _val ERROR_VARIABLE _err OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if ("${_val}" STREQUAL "")
        message(FATAL_ERROR "Could not read ${_key} from ${_bundle_plist}: ${_err}")
    endif ()
    set(_bundle_${_key} "${_val}")
endforeach ()

execute_process(
    COMMAND codesign -dv --verbose=4 "${_app_bundle}"
    OUTPUT_VARIABLE _cs_out ERROR_VARIABLE _cs_err
    OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_STRIP_TRAILING_WHITESPACE
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
    RESULT_VARIABLE _rv ERROR_VARIABLE _err
)
if (NOT _rv EQUAL 0)
    message(FATAL_ERROR "Failed to patch archive Info.plist:\n${_err}")
endif ()

message(STATUS "Archive Info.plist patched successfully")
