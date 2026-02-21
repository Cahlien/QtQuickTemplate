include_guard(GLOBAL)

set(QTQUICKTEMPLATE_MACOS_PACKAGE_CONFIG "Release" CACHE STRING
    "Build configuration used when generating the macOS package"
)

set(QTQUICKTEMPLATE_MACOS_DMG_SIGN_IDENTITY "" CACHE STRING
    "Optional macOS signing identity for signing the generated DMG"
)

function(configure_macos_dmg target)
    if (NOT APPLE OR IOS)
        return()
    endif ()

    set(CPACK_GENERATOR "DragNDrop")
    set(CPACK_PACKAGE_NAME "${PROJECT_NAME}")
    set(CPACK_PACKAGE_VENDOR "QtQuickTemplate")
    set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
    set(CPACK_PACKAGE_FILE_NAME "${PROJECT_NAME}-${PROJECT_VERSION}-macOS")
    set(CPACK_DMG_VOLUME_NAME "${PROJECT_NAME} ${PROJECT_VERSION}")

    if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/platforms/macos/app.icns")
        set(CPACK_PACKAGE_ICON "${CMAKE_CURRENT_SOURCE_DIR}/platforms/macos/app.icns")
    endif ()

    include(CPack)

    set(_dmg_output "${CMAKE_BINARY_DIR}/${CPACK_PACKAGE_FILE_NAME}.dmg")

    set(_dmg_dependency_target ${target})
    if (TARGET MacDeployQt)
        set(_dmg_dependency_target MacDeployQt)
    endif ()

    set(_sign_script "${CMAKE_CURRENT_BINARY_DIR}/sign_macos_dmg.cmake")
    file(WRITE "${_sign_script}" [=[
if (NOT DEFINED ENV{CODESIGN_IDENTITY} OR "$ENV{CODESIGN_IDENTITY}" STREQUAL "")
    message(FATAL_ERROR "CODESIGN_IDENTITY env var is required")
endif ()

if (NOT DEFINED ENV{EXPECTED_DMG} OR "$ENV{EXPECTED_DMG}" STREQUAL "")
    message(FATAL_ERROR "EXPECTED_DMG env var is required")
endif ()

if (NOT DEFINED ENV{DMG_DIR} OR "$ENV{DMG_DIR}" STREQUAL "")
    message(FATAL_ERROR "DMG_DIR env var is required")
endif ()

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
    RESULT_VARIABLE _codesign_rv
    OUTPUT_VARIABLE _codesign_out
    ERROR_VARIABLE _codesign_err
)

if (NOT _codesign_rv EQUAL 0)
    message(FATAL_ERROR "Failed to sign DMG ${_dmg}:\n${_codesign_out}\n${_codesign_err}")
endif ()

message(STATUS "Signed DMG: ${_dmg}")
]=])

    if (QTQUICKTEMPLATE_MACOS_DMG_SIGN_IDENTITY)
        add_custom_target(DMG
            DEPENDS ${_dmg_dependency_target}
            COMMAND ${CMAKE_CPACK_COMMAND}
                --config "${CMAKE_BINARY_DIR}/CPackConfig.cmake"
                -G DragNDrop
                -C ${QTQUICKTEMPLATE_MACOS_PACKAGE_CONFIG}
            COMMAND ${CMAKE_COMMAND} -E env
                CODESIGN_IDENTITY=${QTQUICKTEMPLATE_MACOS_DMG_SIGN_IDENTITY}
                EXPECTED_DMG=${_dmg_output}
                DMG_DIR=${CMAKE_BINARY_DIR}
                ${CMAKE_COMMAND} -P "${_sign_script}"
            COMMENT "Packaging ${PROJECT_NAME} ${PROJECT_VERSION} as signed macOS DMG"
            VERBATIM
        )
    else ()
        add_custom_target(DMG
            DEPENDS ${_dmg_dependency_target}
            COMMAND ${CMAKE_CPACK_COMMAND}
                --config "${CMAKE_BINARY_DIR}/CPackConfig.cmake"
                -G DragNDrop
                -C ${QTQUICKTEMPLATE_MACOS_PACKAGE_CONFIG}
            COMMENT "Packaging ${PROJECT_NAME} ${PROJECT_VERSION} as macOS DMG"
            VERBATIM
        )
    endif ()

    message(STATUS "DMG target configured -> cmake --build . --target DMG")
endfunction()
