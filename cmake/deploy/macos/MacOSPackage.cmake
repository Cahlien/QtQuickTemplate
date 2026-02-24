include_guard(GLOBAL)

# MacOSPackage.cmake — Configures the DMG target that packages the macOS app
# bundle into a signed DMG using CPack DragNDrop generator.

set(QTQUICKTEMPLATE_MACOS_DMG_SIGN_IDENTITY "" CACHE STRING
    "Optional macOS signing identity for signing the generated DMG"
)

function(configure_macos_package target)
    if (NOT APPLE OR IOS)
        return()
    endif ()

    set(CPACK_GENERATOR "DragNDrop")
    set(CPACK_PACKAGE_NAME "${PROJECT_NAME}")
    set(CPACK_PACKAGE_VENDOR "QtQuickTemplate")
    set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
    set(CPACK_PACKAGE_FILE_NAME "${PROJECT_NAME}-${PROJECT_VERSION}-macOS")
    set(CPACK_DMG_VOLUME_NAME "${PROJECT_NAME} ${PROJECT_VERSION}")

    set(_dmg_output "${CMAKE_BINARY_DIR}/${CPACK_PACKAGE_FILE_NAME}.dmg")

    if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/platforms/macos/app.icns")
        set(CPACK_PACKAGE_ICON "${CMAKE_CURRENT_SOURCE_DIR}/platforms/macos/app.icns")
    endif ()

    include(CPack)

    set(_dmg_dep ${target})
    if (TARGET MacDeployQt)
        set(_dmg_dep MacDeployQt)
    endif ()

    set(_sign_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/macos/SignDmg.cmake")

    add_custom_target(DMG
        DEPENDS ${_dmg_dep}
        COMMAND ${CMAKE_CPACK_COMMAND}
            --config "${CMAKE_BINARY_DIR}/CPackConfig.cmake"
            -G DragNDrop
            -C Release
        COMMAND ${CMAKE_COMMAND} -E env
            CODESIGN_IDENTITY=${QTQUICKTEMPLATE_MACOS_DMG_SIGN_IDENTITY}
            EXPECTED_DMG=${_dmg_output}
            DMG_DIR=${CMAKE_BINARY_DIR}
            ${CMAKE_COMMAND} -P "${_sign_script}"
        COMMENT "Packaging ${PROJECT_NAME} ${PROJECT_VERSION} as macOS DMG"
        VERBATIM
    )

    message(STATUS "DMG target configured -> cmake --build . --target DMG")
endfunction()
