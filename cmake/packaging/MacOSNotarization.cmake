include_guard(GLOBAL)

set(QTQUICKTEMPLATE_MACOS_NOTARY_KEYCHAIN_PROFILE "" CACHE STRING
    "Keychain profile name used by notarytool for macOS notarization"
)

set(QTQUICKTEMPLATE_MACOS_NOTARY_TEAM_ID "" CACHE STRING
    "Apple team ID used for notarytool when using APPLE_ID credentials"
)

set(QTQUICKTEMPLATE_MACOS_NOTARIZE_ARTIFACT "" CACHE FILEPATH
    "Artifact path to notarize; defaults to generated DMG"
)

set(QTQUICKTEMPLATE_MACOS_NOTARIZE_STAPLE_APP ON CACHE BOOL
    "Also staple the built .app bundle when notarizing"
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

    set(_default_artifact "${CMAKE_BINARY_DIR}/${PROJECT_NAME}-${PROJECT_VERSION}-macOS.dmg")
    if (QTQUICKTEMPLATE_MACOS_NOTARIZE_ARTIFACT)
        set(_artifact "${QTQUICKTEMPLATE_MACOS_NOTARIZE_ARTIFACT}")
    else ()
        set(_artifact "${_default_artifact}")
    endif ()

    if (QTQUICKTEMPLATE_MACOS_NOTARY_TEAM_ID)
        set(_team_id "${QTQUICKTEMPLATE_MACOS_NOTARY_TEAM_ID}")
    else ()
        set(_team_id "${QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM}")
    endif ()

    if (QTQUICKTEMPLATE_MACOS_NOTARIZE_STAPLE_APP)
        set(_staple_app "1")
    else ()
        set(_staple_app "0")
    endif ()

    set(_notary_script "${CMAKE_CURRENT_BINARY_DIR}/notarize_macos.cmake")
    file(WRITE "${_notary_script}" [=[
if (NOT DEFINED ENV{XCRUN_EXECUTABLE})
    message(FATAL_ERROR "XCRUN_EXECUTABLE env var is required")
endif ()

if (NOT DEFINED ENV{NOTARIZE_ARTIFACT})
    message(FATAL_ERROR "NOTARIZE_ARTIFACT env var is required")
endif ()

if (NOT EXISTS "$ENV{NOTARIZE_ARTIFACT}")
    message(FATAL_ERROR "Artifact not found: $ENV{NOTARIZE_ARTIFACT}")
endif ()

if (NOT DEFINED ENV{APP_BUNDLE_PATH})
    message(FATAL_ERROR "APP_BUNDLE_PATH env var is required")
endif ()

set(_xcrun "$ENV{XCRUN_EXECUTABLE}")
set(_artifact "$ENV{NOTARIZE_ARTIFACT}")
set(_bundle "$ENV{APP_BUNDLE_PATH}")

if (DEFINED ENV{NOTARY_KEYCHAIN_PROFILE} AND NOT "$ENV{NOTARY_KEYCHAIN_PROFILE}" STREQUAL "")
    execute_process(
        COMMAND "${_xcrun}" notarytool submit "${_artifact}" --keychain-profile "$ENV{NOTARY_KEYCHAIN_PROFILE}" --wait
        RESULT_VARIABLE _submit_rv
        OUTPUT_VARIABLE _submit_out
        ERROR_VARIABLE _submit_err
    )
else ()
    if (NOT DEFINED ENV{APPLE_ID} OR "$ENV{APPLE_ID}" STREQUAL "")
        message(FATAL_ERROR "APPLE_ID env var is required when NOTARY_KEYCHAIN_PROFILE is not set")
    endif ()
    if (NOT DEFINED ENV{APPLE_APP_SPECIFIC_PASSWORD} OR "$ENV{APPLE_APP_SPECIFIC_PASSWORD}" STREQUAL "")
        message(FATAL_ERROR "APPLE_APP_SPECIFIC_PASSWORD env var is required when NOTARY_KEYCHAIN_PROFILE is not set")
    endif ()
    if (NOT DEFINED ENV{NOTARY_TEAM_ID} OR "$ENV{NOTARY_TEAM_ID}" STREQUAL "")
        message(FATAL_ERROR "NOTARY_TEAM_ID is required when NOTARY_KEYCHAIN_PROFILE is not set")
    endif ()

    execute_process(
        COMMAND "${_xcrun}" notarytool submit "${_artifact}" --apple-id "$ENV{APPLE_ID}" --password "$ENV{APPLE_APP_SPECIFIC_PASSWORD}" --team-id "$ENV{NOTARY_TEAM_ID}" --wait
        RESULT_VARIABLE _submit_rv
        OUTPUT_VARIABLE _submit_out
        ERROR_VARIABLE _submit_err
    )
endif ()

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

if ("$ENV{STAPLE_APP}" STREQUAL "1")
    if (EXISTS "${_bundle}")
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
    else ()
        message(WARNING "App bundle for stapling not found: ${_bundle}")
    endif ()
endif ()
]=])

    if (TARGET NotarizeMacOS)
        message(STATUS "NotarizeMacOS target already exists; skipping duplicate creation.")
        return()
    endif ()

    add_custom_target(NotarizeMacOS
        DEPENDS DMG
        COMMAND ${CMAKE_COMMAND} -E env
            XCRUN_EXECUTABLE=${XCRUN_EXECUTABLE}
            NOTARIZE_ARTIFACT=${_artifact}
            APP_BUNDLE_PATH=$<TARGET_BUNDLE_DIR:${target}>
            NOTARY_KEYCHAIN_PROFILE=${QTQUICKTEMPLATE_MACOS_NOTARY_KEYCHAIN_PROFILE}
            NOTARY_TEAM_ID=${_team_id}
            STAPLE_APP=${_staple_app}
            APPLE_ID=$ENV{APPLE_ID}
            APPLE_APP_SPECIFIC_PASSWORD=$ENV{APPLE_APP_SPECIFIC_PASSWORD}
            ${CMAKE_COMMAND} -P "${_notary_script}"
        COMMENT "Notarizing and stapling macOS artifacts"
        VERBATIM
    )

    message(STATUS "NotarizeMacOS target configured -> cmake --build . --target NotarizeMacOS")
endfunction()
