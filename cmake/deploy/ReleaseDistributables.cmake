include_guard(GLOBAL)

# ReleaseDistributables.cmake — Defines per-platform ReleaseDistributable* meta-targets
# that depend on the deepest available pipeline target, plus an umbrella
# ReleaseDistributable target aggregating all platforms.

# Adds a guarded release meta-target. Iterates ARGN to find the deepest
# existing pipeline target. Falls back to fallback_target if no candidate
# exists. If both are empty, the meta-target is not created.
function(_add_release_meta name fallback_target comment)
    if (TARGET ${name})
        return()
    endif ()
    set(_dep "")
    foreach (_t IN ITEMS ${ARGN})
        if (TARGET ${_t})
            set(_dep "${_t}")
            break()
        endif ()
    endforeach ()
    if (NOT _dep)
        if ("${fallback_target}" STREQUAL "")
            return()
        endif ()
        set(_dep "${fallback_target}")
    endif ()
    add_custom_target(${name} DEPENDS ${_dep} COMMENT "${comment}")
    message(STATUS "${name} target configured")
endfunction()

function(configure_release_distributables target)
    # macOS DMG pipeline
    if (APPLE AND NOT IOS)
        _add_release_meta(ReleaseDistributableMacOS ""
            "Full macOS DMG release pipeline"
            VerifyMacOSPackage NotarizeMacOS)

        if (TARGET ReleaseDistributableMacOS)
            register_help_target(
                NAME ReleaseDistributableMacOS
                GROUP "macOS (DMG)"
                DESCRIPTION "Full macOS DMG release pipeline (build -> deploy -> DMG -> notarize -> verify)"
                COMMAND "cmake --build <dir> --target ReleaseDistributableMacOS"
            )
        endif ()

        _add_release_meta(ReleaseDistributableMacOSAppStore ""
            "Full macOS App Store release pipeline"
            MacUploadASC VerifyMacPkg MacExportPkg MacAppStoreArchive)

        if (TARGET ReleaseDistributableMacOSAppStore)
            register_help_target(
                NAME ReleaseDistributableMacOSAppStore
                GROUP "macOS (App Store)"
                DESCRIPTION "Full macOS App Store release pipeline (archive -> export -> verify -> upload)"
                COMMAND "cmake --build <dir> --target ReleaseDistributableMacOSAppStore"
            )
        endif ()
    endif ()

    # iOS pipeline
    if (APPLE AND IOS)
        _add_release_meta(ReleaseDistributableIOS "${target}"
            "Full iOS release pipeline"
            IOSUploadASC VerifyIOSIPA IOSExportIPA IOSArchive)

        if (TARGET ReleaseDistributableIOS)
            register_help_target(
                NAME ReleaseDistributableIOS
                GROUP "iOS"
                DESCRIPTION "Full iOS release pipeline (archive -> export -> verify -> upload)"
                COMMAND "cmake --build <dir> --target ReleaseDistributableIOS"
            )
        endif ()
    endif ()

    # Android pipeline
    if (ANDROID)
        _add_release_meta(ReleaseDistributableAndroidAAB "${target}"
            "Full Android AAB release pipeline"
            UploadAndroidPlay VerifyAndroidAAB)

        _add_release_meta(ReleaseDistributableAndroidAPK "${target}"
            "Full Android APK release pipeline"
            VerifyAndroidAPK)

        if (NOT TARGET ReleaseDistributableAndroid)
            add_custom_target(ReleaseDistributableAndroid COMMENT "Full Android release pipeline")
            foreach (_t IN ITEMS ReleaseDistributableAndroidAAB ReleaseDistributableAndroidAPK)
                if (TARGET ${_t})
                    add_dependencies(ReleaseDistributableAndroid ${_t})
                endif ()
            endforeach ()
            message(STATUS "ReleaseDistributableAndroid target configured")
        endif ()

    endif ()

    # Linux pipeline
    if (UNIX AND NOT APPLE AND NOT ANDROID)
        _add_release_meta(ReleaseDistributableLinux "${target}"
            "Full Linux release pipeline"
            AppImage)

        if (TARGET ReleaseDistributableLinux)
            register_help_target(
                NAME ReleaseDistributableLinux
                GROUP "Linux"
                DESCRIPTION "Full Linux release pipeline (depends on AppImage)"
                COMMAND "cmake --build <dir> --target ReleaseDistributableLinux"
            )
        endif ()
    endif ()

    # Windows pipeline
    if (WIN32)
        _add_release_meta(ReleaseDistributableWindows "${target}"
            "Building Windows release artifacts")

        if (TARGET ReleaseDistributableWindows)
            register_help_target(
                NAME ReleaseDistributableWindows
                GROUP "Windows"
                DESCRIPTION "Full Windows release pipeline"
                COMMAND "cmake --build <dir> --target ReleaseDistributableWindows"
            )
        endif ()
    endif ()

    # Umbrella target
    if (NOT TARGET ReleaseDistributable)
        add_custom_target(ReleaseDistributable
            COMMENT "Building all release distributables for this platform")
    endif ()
    foreach (_t IN ITEMS ReleaseDistributableMacOS ReleaseDistributableMacOSAppStore
            ReleaseDistributableIOS ReleaseDistributableAndroid
            ReleaseDistributableLinux ReleaseDistributableWindows)
        if (TARGET ${_t})
            add_dependencies(ReleaseDistributable ${_t})
        endif ()
    endforeach ()

    register_help_target(
        NAME ReleaseDistributable
        GROUP "Utilities"
        DESCRIPTION "Build all release distributables for the current platform"
        COMMAND "cmake --build <dir> --target ReleaseDistributable"
    )
endfunction()
