include_guard(GLOBAL)

function(configure_release_distributables target)
    # macOS DMG pipeline
    if (APPLE AND NOT IOS)
        if (NOT TARGET ReleaseDistributableMacOS)
            set(_dep "")
            if (TARGET VerifyMacOSPackage)
                set(_dep VerifyMacOSPackage)
            elseif (TARGET NotarizeMacOS)
                set(_dep NotarizeMacOS)
            endif ()
            if (_dep)
                add_custom_target(ReleaseDistributableMacOS DEPENDS ${_dep}
                    COMMENT "Full macOS DMG release pipeline")
                message(STATUS "ReleaseDistributableMacOS target configured")
            endif ()
        endif ()

        # macOS App Store pipeline
        if (NOT TARGET ReleaseDistributableMacOSAppStore)
            set(_dep "")
            if (TARGET MacUploadASC)
                set(_dep MacUploadASC)
            elseif (TARGET VerifyMacPkg)
                set(_dep VerifyMacPkg)
            elseif (TARGET MacExportPkg)
                set(_dep MacExportPkg)
            elseif (TARGET MacAppStoreArchive)
                set(_dep MacAppStoreArchive)
            endif ()
            if (_dep)
                add_custom_target(ReleaseDistributableMacOSAppStore DEPENDS ${_dep}
                    COMMENT "Full macOS App Store release pipeline")
                message(STATUS "ReleaseDistributableMacOSAppStore target configured")
            endif ()
        endif ()
    endif ()

    # iOS pipeline
    if (APPLE AND IOS)
        if (NOT TARGET ReleaseDistributableIOS)
            set(_dep "")
            if (TARGET IOSUploadASC)
                set(_dep IOSUploadASC)
            elseif (TARGET VerifyIOSIPA)
                set(_dep VerifyIOSIPA)
            elseif (TARGET IOSExportIPA)
                set(_dep IOSExportIPA)
            elseif (TARGET IOSArchive)
                set(_dep IOSArchive)
            endif ()
            if (NOT _dep)
                set(_dep ${target})
            endif ()
            add_custom_target(ReleaseDistributableIOS DEPENDS ${_dep}
                COMMENT "Full iOS release pipeline")
            message(STATUS "ReleaseDistributableIOS target configured")
        endif ()
    endif ()

    # Android pipeline
    if (ANDROID)
        if (NOT TARGET ReleaseDistributableAndroidAAB)
            if (TARGET UploadAndroidPlay)
                add_custom_target(ReleaseDistributableAndroidAAB DEPENDS UploadAndroidPlay
                    COMMENT "Full Android AAB release pipeline")
            elseif (TARGET VerifyAndroidAAB)
                add_custom_target(ReleaseDistributableAndroidAAB DEPENDS VerifyAndroidAAB
                    COMMENT "Full Android AAB release pipeline")
            else ()
                add_custom_target(ReleaseDistributableAndroidAAB DEPENDS ${target}
                    COMMENT "Building Android AAB release artifacts")
            endif ()
            message(STATUS "ReleaseDistributableAndroidAAB target configured")
        endif ()

        if (NOT TARGET ReleaseDistributableAndroidAPK)
            if (TARGET VerifyAndroidAPK)
                add_custom_target(ReleaseDistributableAndroidAPK DEPENDS VerifyAndroidAPK
                    COMMENT "Full Android APK release pipeline")
            else ()
                add_custom_target(ReleaseDistributableAndroidAPK DEPENDS ${target}
                    COMMENT "Building Android APK release artifacts")
            endif ()
            message(STATUS "ReleaseDistributableAndroidAPK target configured")
        endif ()

        if (NOT TARGET ReleaseDistributableAndroid)
            add_custom_target(ReleaseDistributableAndroid COMMENT "Full Android release pipeline")
            if (TARGET ReleaseDistributableAndroidAAB)
                add_dependencies(ReleaseDistributableAndroid ReleaseDistributableAndroidAAB)
            endif ()
            if (TARGET ReleaseDistributableAndroidAPK)
                add_dependencies(ReleaseDistributableAndroid ReleaseDistributableAndroidAPK)
            endif ()
            message(STATUS "ReleaseDistributableAndroid target configured")
        endif ()
    endif ()

    # Linux pipeline
    if (UNIX AND NOT APPLE AND NOT ANDROID)
        if (NOT TARGET ReleaseDistributableLinux)
            if (TARGET AppImage)
                add_custom_target(ReleaseDistributableLinux DEPENDS AppImage
                    COMMENT "Full Linux release pipeline")
            else ()
                add_custom_target(ReleaseDistributableLinux DEPENDS ${target}
                    COMMENT "Building Linux release artifacts")
            endif ()
            message(STATUS "ReleaseDistributableLinux target configured")
        endif ()
    endif ()

    # Windows pipeline
    if (WIN32)
        if (NOT TARGET ReleaseDistributableWindows)
            add_custom_target(ReleaseDistributableWindows DEPENDS ${target}
                COMMENT "Building Windows release artifacts")
            message(STATUS "ReleaseDistributableWindows target configured")
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
endfunction()
