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

    if (QTQUICKTEMPLATE_MACOS_DMG_SIGN_IDENTITY)
        add_custom_target(DMG
            DEPENDS ${target}
            COMMAND ${CMAKE_CPACK_COMMAND}
                --config "${CMAKE_BINARY_DIR}/CPackConfig.cmake"
                -G DragNDrop
                -C ${QTQUICKTEMPLATE_MACOS_PACKAGE_CONFIG}
            COMMAND codesign --force --sign "${QTQUICKTEMPLATE_MACOS_DMG_SIGN_IDENTITY}" "${_dmg_output}"
            COMMENT "Packaging ${PROJECT_NAME} ${PROJECT_VERSION} as signed macOS DMG"
            VERBATIM
        )
    else ()
        add_custom_target(DMG
            DEPENDS ${target}
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
