foreach (_req IN ITEMS CODESIGN_EXECUTABLE SPCTL_EXECUTABLE XCRUN_EXECUTABLE APP_BUNDLE_PATH DMG_PATH)
    if (NOT DEFINED ENV{${_req}} OR "$ENV{${_req}}" STREQUAL "")
        message(FATAL_ERROR "${_req} env var is required")
    endif ()
endforeach ()

set(_codesign "$ENV{CODESIGN_EXECUTABLE}")
set(_spctl "$ENV{SPCTL_EXECUTABLE}")
set(_xcrun "$ENV{XCRUN_EXECUTABLE}")
set(_bundle "$ENV{APP_BUNDLE_PATH}")
set(_dmg "$ENV{DMG_PATH}")

if (NOT EXISTS "${_dmg}")
    message(FATAL_ERROR "DMG not found: ${_dmg}")
endif ()
if (NOT EXISTS "${_bundle}")
    message(FATAL_ERROR "App bundle not found: ${_bundle}")
endif ()

# Verify DMG
execute_process(COMMAND "${_codesign}" --verify --verbose=2 "${_dmg}"
    RESULT_VARIABLE _rv OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
if (NOT _rv EQUAL 0)
    message(FATAL_ERROR "DMG codesign verification failed:\n${_out}\n${_err}")
endif ()

execute_process(COMMAND "${_spctl}" -a -vv -t open "${_dmg}"
    RESULT_VARIABLE _rv OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
if (NOT _rv EQUAL 0)
    string(FIND "${_out}${_err}" "Insufficient Context" _pos)
    if (NOT _pos EQUAL -1)
        message(WARNING "DMG Gatekeeper: 'Insufficient Context'; continuing.\n${_out}\n${_err}")
    else ()
        message(FATAL_ERROR "DMG Gatekeeper assessment failed:\n${_out}\n${_err}")
    endif ()
endif ()

execute_process(COMMAND "${_xcrun}" stapler validate "${_dmg}"
    RESULT_VARIABLE _rv OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
if (NOT _rv EQUAL 0)
    message(FATAL_ERROR "DMG stapler validation failed:\n${_out}\n${_err}")
endif ()

# Verify app bundle
execute_process(COMMAND "${_codesign}" --verify --deep --strict --verbose=2 "${_bundle}"
    RESULT_VARIABLE _rv OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
if (NOT _rv EQUAL 0)
    message(FATAL_ERROR "App codesign verification failed:\n${_out}\n${_err}")
endif ()

execute_process(COMMAND "${_spctl}" -a -vv -t exec "${_bundle}"
    RESULT_VARIABLE _rv OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
if (NOT _rv EQUAL 0)
    string(FIND "${_out}${_err}" "Insufficient Context" _pos)
    if (NOT _pos EQUAL -1)
        message(WARNING "App Gatekeeper: 'Insufficient Context'; continuing.\n${_out}\n${_err}")
    else ()
        message(FATAL_ERROR "App Gatekeeper assessment failed:\n${_out}\n${_err}")
    endif ()
endif ()

execute_process(COMMAND "${_xcrun}" stapler validate "${_bundle}"
    RESULT_VARIABLE _rv OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
if (NOT _rv EQUAL 0)
    message(FATAL_ERROR "App stapler validation failed:\n${_out}\n${_err}")
endif ()

message(STATUS "macOS package verification passed: signed, notarized, stapled, Gatekeeper OK")
