include_guard(GLOBAL)

# MacOSSign.cmake — Configures the NotarizeMacOS target that submits the DMG
# to Apple's notary service and staples the ticket to both DMG and app bundle.

set(QTQUICKTEMPLATE_MACOS_NOTARY_KEYCHAIN_PROFILE "" CACHE STRING
    "Keychain profile name used by notarytool for macOS notarization"
)

function(configure_macos_sign target)
    if (NOT APPLE OR IOS)
        return()
    endif ()

    if (NOT TARGET DMG)
        return()
    endif ()

    find_program(XCRUN_EXECUTABLE xcrun)
    if (NOT XCRUN_EXECUTABLE)
        message(WARNING "xcrun not found; NotarizeMacOS target unavailable.")
        return()
    endif ()

    if (NOT QTQUICKTEMPLATE_MACOS_NOTARY_KEYCHAIN_PROFILE)
        message(WARNING "QTQUICKTEMPLATE_MACOS_NOTARY_KEYCHAIN_PROFILE not set; NotarizeMacOS target unavailable.")
        return()
    endif ()

    set(_artifact "${CMAKE_BINARY_DIR}/${PROJECT_NAME}-${PROJECT_VERSION}-macOS.dmg")
    set(_notary_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/macos/Notarize.cmake")

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

    register_help_target(
        NAME NotarizeMacOS
        GROUP "macOS (DMG)"
        DESCRIPTION "Submit DMG to Apple notary service and staple the ticket"
        COMMAND "cmake --build <dir> --target NotarizeMacOS"
        VARIABLES "QTQUICKTEMPLATE_MACOS_NOTARY_KEYCHAIN_PROFILE -- Keychain profile for notarytool"
    )

    message(STATUS "NotarizeMacOS target configured -> cmake --build . --target NotarizeMacOS")
endfunction()
