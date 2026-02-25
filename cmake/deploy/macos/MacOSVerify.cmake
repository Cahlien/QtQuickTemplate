include_guard(GLOBAL)

# MacOSVerify.cmake — Configures the VerifyMacOSPackage target that runs
# codesign, spctl, and stapler checks on the final DMG and app bundle.

function(configure_macos_verify target)
    if (NOT APPLE OR IOS)
        return()
    endif ()

    if (NOT TARGET NotarizeMacOS)
        return()
    endif ()

    find_program(CODESIGN_EXECUTABLE codesign)
    find_program(SPCTL_EXECUTABLE spctl)
    find_program(XCRUN_EXECUTABLE xcrun)
    if (NOT CODESIGN_EXECUTABLE OR NOT SPCTL_EXECUTABLE OR NOT XCRUN_EXECUTABLE)
        message(WARNING "codesign/spctl/xcrun required; VerifyMacOSPackage target unavailable.")
        return()
    endif ()

    set(_verify_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/macos/VerifyPackage.cmake")
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
        register_help_target(
            NAME VerifyMacOSPackage
            GROUP "macOS (DMG)"
            DESCRIPTION "Verify codesign, spctl, and notarization of the DMG and app bundle"
            COMMAND "cmake --build <dir> --target VerifyMacOSPackage"
        )

        message(STATUS "VerifyMacOSPackage target configured -> cmake --build . --target VerifyMacOSPackage")
    endif ()
endfunction()
