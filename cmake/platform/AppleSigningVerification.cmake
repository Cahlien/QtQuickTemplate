include_guard(GLOBAL)

function(configure_apple_signing_verification target)
    if (NOT APPLE)
        return()
    endif ()

    find_program(CODESIGN_EXECUTABLE codesign)
    if (NOT CODESIGN_EXECUTABLE)
        message(WARNING "codesign not found; VerifyAppleSigning target is unavailable.")
        return()
    endif ()

    find_program(SPCTL_EXECUTABLE spctl)

    set(_verify_script "${CMAKE_CURRENT_BINARY_DIR}/verify_apple_signing.cmake")
    file(WRITE "${_verify_script}" [=[
if (NOT DEFINED ENV{CODESIGN_EXECUTABLE})
    message(FATAL_ERROR "CODESIGN_EXECUTABLE env var is required")
endif ()

if (NOT DEFINED ENV{BUNDLE_PATH})
    message(FATAL_ERROR "BUNDLE_PATH env var is required")
endif ()

if (NOT EXISTS "$ENV{BUNDLE_PATH}")
    message(FATAL_ERROR "Bundle not found: $ENV{BUNDLE_PATH}")
endif ()

set(_codesign "$ENV{CODESIGN_EXECUTABLE}")
set(_bundle "$ENV{BUNDLE_PATH}")

message(STATUS "Inspecting signature for: ${_bundle}")
execute_process(
    COMMAND "${_codesign}" -dv --verbose=4 "${_bundle}"
    RESULT_VARIABLE _inspect_rv
    OUTPUT_VARIABLE _inspect_out
    ERROR_VARIABLE _inspect_err
)

if (NOT _inspect_rv EQUAL 0)
    message(FATAL_ERROR "codesign inspect failed:\n${_inspect_out}\n${_inspect_err}")
endif ()

message(STATUS "${_inspect_out}${_inspect_err}")

execute_process(
    COMMAND "${_codesign}" --verify --deep --strict --verbose=2 "${_bundle}"
    RESULT_VARIABLE _verify_rv
    OUTPUT_VARIABLE _verify_out
    ERROR_VARIABLE _verify_err
)

if (NOT _verify_rv EQUAL 0)
    message(FATAL_ERROR "codesign verification failed:\n${_verify_out}\n${_verify_err}")
endif ()

message(STATUS "codesign verification passed")
message(STATUS "${_verify_out}${_verify_err}")

if (NOT "$ENV{IOS}" STREQUAL "1" AND DEFINED ENV{SPCTL_EXECUTABLE} AND NOT "$ENV{SPCTL_EXECUTABLE}" STREQUAL "")
    execute_process(
        COMMAND "$ENV{SPCTL_EXECUTABLE}" -a -vv "${_bundle}"
        RESULT_VARIABLE _spctl_rv
        OUTPUT_VARIABLE _spctl_out
        ERROR_VARIABLE _spctl_err
    )

    if (NOT _spctl_rv EQUAL 0)
        message(WARNING "spctl assessment did not pass (often expected before notarization):\n${_spctl_out}\n${_spctl_err}")
    else ()
        message(STATUS "spctl assessment passed")
        message(STATUS "${_spctl_out}${_spctl_err}")
    endif ()
endif ()
]=])

    if (TARGET VerifyAppleSigning)
        message(STATUS "VerifyAppleSigning target already exists; skipping duplicate creation.")
        return()
    endif ()

    if (SPCTL_EXECUTABLE)
        set(_spctl_env "SPCTL_EXECUTABLE=${SPCTL_EXECUTABLE}")
    else ()
        set(_spctl_env "SPCTL_EXECUTABLE=")
    endif ()

    if (IOS)
        set(_ios_env "IOS=1")
    else ()
        set(_ios_env "IOS=0")
    endif ()

    add_custom_target(VerifyAppleSigning
        DEPENDS ${target}
        COMMAND ${CMAKE_COMMAND} -E env
            CODESIGN_EXECUTABLE=${CODESIGN_EXECUTABLE}
            ${_spctl_env}
            ${_ios_env}
            BUNDLE_PATH=$<TARGET_BUNDLE_DIR:${target}>
            ${CMAKE_COMMAND} -P "${_verify_script}"
        COMMENT "Verifying Apple code signature for ${target}"
        VERBATIM
    )

    message(STATUS "VerifyAppleSigning target configured -> cmake --build . --target VerifyAppleSigning")
endfunction()
