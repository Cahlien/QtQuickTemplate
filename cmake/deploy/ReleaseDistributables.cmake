include_guard(GLOBAL)

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

        _add_release_meta(ReleaseDistributableMacOSAppStore ""
            "Full macOS App Store release pipeline"
            MacUploadASC VerifyMacPkg MacExportPkg MacAppStoreArchive)
    endif ()

    # iOS pipeline
    if (APPLE AND IOS)
        _add_release_meta(ReleaseDistributableIOS "${target}"
            "Full iOS release pipeline"
            IOSUploadASC VerifyIOSIPA IOSExportIPA IOSArchive)
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
    endif ()

    # Windows pipeline
    if (WIN32)
        _add_release_meta(ReleaseDistributableWindows "${target}"
            "Building Windows release artifacts")
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
endfunction()
