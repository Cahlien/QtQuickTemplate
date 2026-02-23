foreach (_req IN ITEMS XCRUN_EXECUTABLE NOTARIZE_ARTIFACT NOTARY_KEYCHAIN_PROFILE APP_BUNDLE_PATH)
    if (NOT DEFINED ENV{${_req}} OR "$ENV{${_req}}" STREQUAL "")
        message(FATAL_ERROR "${_req} env var is required")
    endif ()
endforeach ()

set(_xcrun "$ENV{XCRUN_EXECUTABLE}")
set(_artifact "$ENV{NOTARIZE_ARTIFACT}")
set(_bundle "$ENV{APP_BUNDLE_PATH}")

if (NOT EXISTS "${_artifact}")
    message(FATAL_ERROR "Artifact not found: ${_artifact}")
endif ()

execute_process(
    COMMAND "${_xcrun}" notarytool submit "${_artifact}"
        --keychain-profile "$ENV{NOTARY_KEYCHAIN_PROFILE}" --wait
    RESULT_VARIABLE _rv
    OUTPUT_VARIABLE _out
    ERROR_VARIABLE _err
)
if (NOT _rv EQUAL 0)
    message(FATAL_ERROR "Notary submission failed:\n${_out}\n${_err}")
endif ()
message(STATUS "Notary submission succeeded")
message(STATUS "${_out}${_err}")

execute_process(
    COMMAND "${_xcrun}" stapler staple "${_artifact}"
    RESULT_VARIABLE _rv OUTPUT_VARIABLE _out ERROR_VARIABLE _err
)
if (NOT _rv EQUAL 0)
    message(FATAL_ERROR "Failed to staple artifact:\n${_out}\n${_err}")
endif ()
message(STATUS "Stapled notarization ticket to artifact")

if (NOT EXISTS "${_bundle}")
    message(FATAL_ERROR "App bundle not found: ${_bundle}")
endif ()

execute_process(
    COMMAND "${_xcrun}" stapler staple "${_bundle}"
    RESULT_VARIABLE _rv OUTPUT_VARIABLE _out ERROR_VARIABLE _err
)
if (NOT _rv EQUAL 0)
    message(FATAL_ERROR "Failed to staple app bundle:\n${_out}\n${_err}")
endif ()
message(STATUS "Stapled notarization ticket to app bundle")
