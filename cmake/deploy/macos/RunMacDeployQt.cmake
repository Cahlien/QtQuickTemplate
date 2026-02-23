foreach (_req IN ITEMS MACDEPLOYQT_EXECUTABLE APP_BUNDLE_PATH)
    if (NOT DEFINED ENV{${_req}} OR "$ENV{${_req}}" STREQUAL "")
        message(FATAL_ERROR "${_req} env var is required")
    endif ()
endforeach ()

set(_bundle "$ENV{APP_BUNDLE_PATH}")
if (NOT EXISTS "${_bundle}")
    message(FATAL_ERROR "App bundle not found: ${_bundle}")
endif ()

set(_cmd "$ENV{MACDEPLOYQT_EXECUTABLE}" "${_bundle}" "-always-overwrite" "-verbose=1")

if (DEFINED ENV{QML_DIR} AND EXISTS "$ENV{QML_DIR}")
    list(APPEND _cmd "-qmldir=$ENV{QML_DIR}")
endif ()

if (DEFINED ENV{MACOS_APP_SIGN_IDENTITY} AND NOT "$ENV{MACOS_APP_SIGN_IDENTITY}" STREQUAL "")
    list(APPEND _cmd "-codesign=$ENV{MACOS_APP_SIGN_IDENTITY}" "-hardened-runtime" "-timestamp")
endif ()

if (DEFINED ENV{APPSTORE_COMPLIANT} AND "$ENV{APPSTORE_COMPLIANT}" STREQUAL "1")
    list(APPEND _cmd "-appstore-compliant")
endif ()

execute_process(
    COMMAND ${_cmd}
    RESULT_VARIABLE _rv
    OUTPUT_VARIABLE _out
    ERROR_VARIABLE _err
)

if (NOT _rv EQUAL 0)
    message(FATAL_ERROR "macdeployqt failed:\n${_out}\n${_err}")
endif ()

message(STATUS "macdeployqt completed successfully")
