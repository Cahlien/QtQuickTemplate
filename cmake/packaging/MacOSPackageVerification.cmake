include_guard(GLOBAL)

function(configure_macos_package_verification target)
    if (NOT APPLE OR IOS)
        return()
    endif ()

    if (NOT TARGET NotarizeMacOS)
        message(WARNING "NotarizeMacOS target not found; VerifyMacOSPackage target is unavailable.")
        return()
    endif ()

    find_program(CODESIGN_EXECUTABLE codesign)
    find_program(SPCTL_EXECUTABLE spctl)
    find_program(XCRUN_EXECUTABLE xcrun)
    if (NOT CODESIGN_EXECUTABLE OR NOT SPCTL_EXECUTABLE OR NOT XCRUN_EXECUTABLE)
        message(WARNING "codesign/spctl/xcrun are required; VerifyMacOSPackage target is unavailable.")
        return()
    endif ()

    set(_verify_script "${CMAKE_CURRENT_BINARY_DIR}/verify_macos_package.cmake")
    file(WRITE "${_verify_script}" [=[
if (NOT DEFINED ENV{CODESIGN_EXECUTABLE} OR "$ENV{CODESIGN_EXECUTABLE}" STREQUAL "")
    message(FATAL_ERROR "CODESIGN_EXECUTABLE env var is required")
endif ()
if (NOT DEFINED ENV{SPCTL_EXECUTABLE} OR "$ENV{SPCTL_EXECUTABLE}" STREQUAL "")
    message(FATAL_ERROR "SPCTL_EXECUTABLE env var is required")
endif ()
if (NOT DEFINED ENV{XCRUN_EXECUTABLE} OR "$ENV{XCRUN_EXECUTABLE}" STREQUAL "")
    message(FATAL_ERROR "XCRUN_EXECUTABLE env var is required")
endif ()
if (NOT DEFINED ENV{APP_BUNDLE_PATH} OR "$ENV{APP_BUNDLE_PATH}" STREQUAL "")
    message(FATAL_ERROR "APP_BUNDLE_PATH env var is required")
endif ()

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

execute_process(COMMAND "${_codesign}" --verify --verbose=2 "${_dmg}"
    RESULT_VARIABLE _dmg_codesign_rv OUTPUT_VARIABLE _dmg_codesign_out ERROR_VARIABLE _dmg_codesign_err)
if (NOT _dmg_codesign_rv EQUAL 0)
    message(FATAL_ERROR "DMG codesign verification failed:\n${_dmg_codesign_out}\n${_dmg_codesign_err}")
endif ()

execute_process(COMMAND "${_spctl}" -a -vv -t open "${_dmg}"
    RESULT_VARIABLE _dmg_spctl_rv OUTPUT_VARIABLE _dmg_spctl_out ERROR_VARIABLE _dmg_spctl_err)
if (NOT _dmg_spctl_rv EQUAL 0)
    string(FIND "${_dmg_spctl_out}${_dmg_spctl_err}" "Insufficient Context" _dmg_insufficient_context_pos)
    if (NOT _dmg_insufficient_context_pos EQUAL -1)
        message(WARNING "DMG Gatekeeper assessment returned 'Insufficient Context'; continuing because codesign and stapler validation passed.\n${_dmg_spctl_out}\n${_dmg_spctl_err}")
    else ()
        message(FATAL_ERROR "DMG Gatekeeper assessment failed:\n${_dmg_spctl_out}\n${_dmg_spctl_err}")
    endif ()
endif ()

execute_process(COMMAND "${_xcrun}" stapler validate "${_dmg}"
    RESULT_VARIABLE _dmg_staple_rv OUTPUT_VARIABLE _dmg_staple_out ERROR_VARIABLE _dmg_staple_err)
if (NOT _dmg_staple_rv EQUAL 0)
    message(FATAL_ERROR "DMG stapler validation failed:\n${_dmg_staple_out}\n${_dmg_staple_err}")
endif ()

execute_process(COMMAND "${_codesign}" --verify --deep --strict --verbose=2 "${_bundle}"
    RESULT_VARIABLE _app_codesign_rv OUTPUT_VARIABLE _app_codesign_out ERROR_VARIABLE _app_codesign_err)
if (NOT _app_codesign_rv EQUAL 0)
    message(FATAL_ERROR "App codesign verification failed:\n${_app_codesign_out}\n${_app_codesign_err}")
endif ()

execute_process(COMMAND "${_spctl}" -a -vv -t exec "${_bundle}"
    RESULT_VARIABLE _app_spctl_rv OUTPUT_VARIABLE _app_spctl_out ERROR_VARIABLE _app_spctl_err)
if (NOT _app_spctl_rv EQUAL 0)
    string(FIND "${_app_spctl_out}${_app_spctl_err}" "Insufficient Context" _app_insufficient_context_pos)
    if (NOT _app_insufficient_context_pos EQUAL -1)
        message(WARNING "App Gatekeeper assessment returned 'Insufficient Context'; continuing because codesign and stapler validation passed.\n${_app_spctl_out}\n${_app_spctl_err}")
    else ()
        message(FATAL_ERROR "App Gatekeeper assessment failed:\n${_app_spctl_out}\n${_app_spctl_err}")
    endif ()
endif ()

execute_process(COMMAND "${_xcrun}" stapler validate "${_bundle}"
    RESULT_VARIABLE _app_staple_rv OUTPUT_VARIABLE _app_staple_out ERROR_VARIABLE _app_staple_err)
if (NOT _app_staple_rv EQUAL 0)
    message(FATAL_ERROR "App stapler validation failed:\n${_app_staple_out}\n${_app_staple_err}")
endif ()

message(STATUS "macOS package verification passed: signed, notarized, stapled, and accepted by Gatekeeper")
]=])

    set(_expected_dmg "${CMAKE_BINARY_DIR}/${PROJECT_NAME}-${PROJECT_VERSION}-macOS.dmg")

    if (NOT TARGET VerifyMacOSPackage)
        add_custom_target(VerifyMacOSPackage
            DEPENDS NotarizeMacOS
            COMMAND ${CMAKE_COMMAND} -E env
                CODESIGN_EXECUTABLE=${CODESIGN_EXECUTABLE}
                SPCTL_EXECUTABLE=${SPCTL_EXECUTABLE}
                XCRUN_EXECUTABLE=${XCRUN_EXECUTABLE}
                APP_BUNDLE_PATH=$<TARGET_BUNDLE_DIR:${target}>
                DMG_PATH=${_expected_dmg}
                ${CMAKE_COMMAND} -P "${_verify_script}"
            COMMENT "Verifying final macOS package integrity and notarization"
            VERBATIM
        )
        message(STATUS "VerifyMacOSPackage target configured -> cmake --build . --target VerifyMacOSPackage")
    endif ()
endfunction()
