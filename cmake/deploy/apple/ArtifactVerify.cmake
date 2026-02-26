include_guard(GLOBAL)

# ArtifactVerify.cmake — Unified artifact verification for Apple pipelines.
# Provides configure_ios_verify() and configure_macos_appstore_verify() which
# create targets that run the VerifyArtifact.cmake -P script.

set(_ARTIFACT_VERIFY_DIR "${CMAKE_CURRENT_LIST_DIR}")

# Private helper shared by iOS and macOS App Store verify targets.
function(_configure_artifact_verify target_name depends_target export_path artifact_glob comment)
    set(_verify_script "${_ARTIFACT_VERIFY_DIR}/VerifyArtifact.cmake")

    if (NOT TARGET ${target_name})
        add_custom_target(${target_name}
            DEPENDS ${depends_target}
            COMMAND ${CMAKE_COMMAND} -E env
                EXPORT_PATH=${export_path}
                ARTIFACT_GLOB=${artifact_glob}
                ${CMAKE_COMMAND} -P "${_verify_script}"
            COMMENT "${comment}"
            VERBATIM
        )
        message(STATUS "${target_name} target configured -> cmake --build . --target ${target_name}")
    endif ()
endfunction()

function(configure_ios_verify target)
    if (NOT APPLE OR NOT IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()
    if (NOT TARGET IOSExportIPA)
        return()
    endif ()
    _configure_artifact_verify(VerifyIOSIPA IOSExportIPA
        "${CMAKE_BINARY_DIR}/ios/export" "*.ipa"
        "Verifying exported iOS IPA output")

    if (TARGET VerifyIOSIPA)
        register_help_target(
            NAME VerifyIOSIPA
            GROUP "iOS"
            DESCRIPTION "Verify exported iOS IPA output"
            COMMAND "cmake --build <dir> --target VerifyIOSIPA"
        )
    endif ()
endfunction()

function(configure_macos_appstore_verify target)
    if (NOT APPLE OR IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()
    if (NOT TARGET MacExportPkg)
        return()
    endif ()
    _configure_artifact_verify(VerifyMacPkg MacExportPkg
        "${CMAKE_BINARY_DIR}/macos/export" "*.pkg"
        "Verifying exported macOS PKG output")

    if (TARGET VerifyMacPkg)
        register_help_target(
            NAME VerifyMacPkg
            GROUP "macOS (App Store)"
            DESCRIPTION "Verify exported macOS PKG output"
            COMMAND "cmake --build <dir> --target VerifyMacPkg"
        )
    endif ()
endfunction()
