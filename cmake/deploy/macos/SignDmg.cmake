if (NOT DEFINED ENV{CODESIGN_IDENTITY} OR "$ENV{CODESIGN_IDENTITY}" STREQUAL "")
    message(STATUS "Skipping DMG signing (no CODESIGN_IDENTITY configured)")
    return()
endif ()

foreach (_req IN ITEMS EXPECTED_DMG DMG_DIR)
    if (NOT DEFINED ENV{${_req}} OR "$ENV{${_req}}" STREQUAL "")
        message(FATAL_ERROR "${_req} env var is required")
    endif ()
endforeach ()

set(_dmg "$ENV{EXPECTED_DMG}")
if (NOT EXISTS "${_dmg}")
    file(GLOB _candidate_dmgs "$ENV{DMG_DIR}/*.dmg")
    if (_candidate_dmgs)
        list(SORT _candidate_dmgs)
        list(GET _candidate_dmgs -1 _dmg)
        message(WARNING "Expected DMG not found. Falling back to: ${_dmg}")
    else ()
        message(FATAL_ERROR "No DMG produced in $ENV{DMG_DIR}")
    endif ()
endif ()

execute_process(
    COMMAND codesign --force --timestamp --sign "$ENV{CODESIGN_IDENTITY}" "${_dmg}"
    RESULT_VARIABLE _rv
    OUTPUT_VARIABLE _out
    ERROR_VARIABLE _err
)

if (NOT _rv EQUAL 0)
    message(FATAL_ERROR "Failed to sign DMG ${_dmg}:\n${_out}\n${_err}")
endif ()

message(STATUS "Signed DMG: ${_dmg}")
