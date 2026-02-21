include_guard(GLOBAL)

set(QTQUICKTEMPLATE_MACOS_NOTARY_KEYCHAIN_PROFILE "" CACHE STRING
    "Keychain profile name used by notarytool for macOS notarization"
)

function(configure_macos_notarization target)
    if (NOT APPLE OR IOS)
        return()
    endif ()

    if (NOT TARGET DMG)
        message(WARNING "DMG target not found; NotarizeMacOS target is unavailable.")
        return()
    endif ()

    find_program(XCRUN_EXECUTABLE xcrun)
    if (NOT XCRUN_EXECUTABLE)
        message(WARNING "xcrun not found; NotarizeMacOS target is unavailable.")
        return()
    endif ()

    if (NOT QTQUICKTEMPLATE_MACOS_NOTARY_KEYCHAIN_PROFILE)
        message(WARNING "QTQUICKTEMPLATE_MACOS_NOTARY_KEYCHAIN_PROFILE is not set; NotarizeMacOS target is unavailable.")
        return()
    endif ()

    set(_artifact "${CMAKE_BINARY_DIR}/${PROJECT_NAME}-${PROJECT_VERSION}-macOS.dmg")

    set(_notary_script "${CMAKE_CURRENT_BINARY_DIR}/notarize_macos.cmake")
    file(WRITE "${_notary_script}" [=[
if (NOT DEFINED ENV{XCRUN_EXECUTABLE})
    message(FATAL_ERROR "XCRUN_EXECUTABLE env var is required")
endif ()

if (NOT DEFINED ENV{NOTARIZE_ARTIFACT})
    message(FATAL_ERROR "NOTARIZE_ARTIFACT env var is required")
endif ()

if (NOT DEFINED ENV{NOTARY_KEYCHAIN_PROFILE} OR "$ENV{NOTARY_KEYCHAIN_PROFILE}" STREQUAL "")
    message(FATAL_ERROR "NOTARY_KEYCHAIN_PROFILE env var is required")
endif ()

if (NOT DEFINED ENV{APP_BUNDLE_PATH})
    message(FATAL_ERROR "APP_BUNDLE_PATH env var is required")
endif ()

set(_xcrun "$ENV{XCRUN_EXECUTABLE}")
set(_artifact "$ENV{NOTARIZE_ARTIFACT}")
set(_bundle "$ENV{APP_BUNDLE_PATH}")

if (NOT EXISTS "${_artifact}")
    message(FATAL_ERROR "Artifact not found: $ENV{NOTARIZE_ARTIFACT}")
endif ()

execute_process(
    COMMAND "${_xcrun}" notarytool submit "${_artifact}" --keychain-profile "$ENV{NOTARY_KEYCHAIN_PROFILE}" --wait
    RESULT_VARIABLE _submit_rv
    OUTPUT_VARIABLE _submit_out
    ERROR_VARIABLE _submit_err
)

if (NOT _submit_rv EQUAL 0)
    message(FATAL_ERROR "Notary submission failed:\n${_submit_out}\n${_submit_err}")
endif ()

message(STATUS "Notary submission succeeded")
message(STATUS "${_submit_out}${_submit_err}")

execute_process(
    COMMAND "${_xcrun}" stapler staple "${_artifact}"
    RESULT_VARIABLE _staple_artifact_rv
    OUTPUT_VARIABLE _staple_artifact_out
    ERROR_VARIABLE _staple_artifact_err
)

if (NOT _staple_artifact_rv EQUAL 0)
    message(FATAL_ERROR "Failed to staple artifact:\n${_staple_artifact_out}\n${_staple_artifact_err}")
endif ()

message(STATUS "Stapled notarization ticket to artifact")

if (NOT EXISTS "${_bundle}")
    message(FATAL_ERROR "App bundle for stapling not found: ${_bundle}")
endif ()

execute_process(
    COMMAND "${_xcrun}" stapler staple "${_bundle}"
    RESULT_VARIABLE _staple_bundle_rv
    OUTPUT_VARIABLE _staple_bundle_out
    ERROR_VARIABLE _staple_bundle_err
)

if (NOT _staple_bundle_rv EQUAL 0)
    message(FATAL_ERROR "Failed to staple app bundle:\n${_staple_bundle_out}\n${_staple_bundle_err}")
endif ()

message(STATUS "Stapled notarization ticket to app bundle")
]=])

    add_custom_target(NotarizeMacOS
        DEPENDS DMG
        COMMAND ${CMAKE_COMMAND} -E env
            XCRUN_EXECUTABLE=${XCRUN_EXECUTABLE}
            NOTARIZE_ARTIFACT=${_artifact}
            APP_BUNDLE_PATH=$<TARGET_BUNDLE_DIR:${target}>
            NOTARY_KEYCHAIN_PROFILE=${QTQUICKTEMPLATE_MACOS_NOTARY_KEYCHAIN_PROFILE}
            ${CMAKE_COMMAND} -P "${_notary_script}"
        COMMENT "Notarizing and stapling macOS artifacts"
        VERBATIM
    )

    message(STATUS "NotarizeMacOS target configured -> cmake --build . --target NotarizeMacOS")
endfunction()
