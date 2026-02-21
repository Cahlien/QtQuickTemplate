include_guard(GLOBAL)

function(configure_release_distributables target)
    if (APPLE AND NOT IOS AND TARGET VerifyAppleSigning AND TARGET NotarizeMacOS)
        if (NOT TARGET ReleaseDistributableMacOS)
            add_custom_target(ReleaseDistributableMacOS
                DEPENDS VerifyAppleSigning NotarizeMacOS
                COMMENT "Building, verifying, packaging, and notarizing macOS release artifacts"
            )
            message(STATUS "ReleaseDistributableMacOS target configured -> cmake --build . --target ReleaseDistributableMacOS")
        endif ()
    endif ()

    if (APPLE AND IOS AND TARGET VerifyAppleSigning)
        if (NOT TARGET ReleaseDistributableIOS)
            add_custom_target(ReleaseDistributableIOS
                DEPENDS VerifyAppleSigning
                COMMENT "Building and verifying iOS release artifacts"
            )
            message(STATUS "ReleaseDistributableIOS target configured -> cmake --build . --target ReleaseDistributableIOS")
        endif ()
    endif ()

    if (ANDROID)
        if (NOT TARGET ReleaseDistributableAndroidAAB)
            if (TARGET VerifyAndroidAAB)
                add_custom_target(ReleaseDistributableAndroidAAB
                    DEPENDS VerifyAndroidAAB
                    COMMENT "Building and verifying signed Android release AAB artifacts"
                )
            else ()
                add_custom_target(ReleaseDistributableAndroidAAB
                    DEPENDS ${target}
                    COMMENT "Building Android release AAB artifacts"
                )
            endif ()
            message(STATUS "ReleaseDistributableAndroidAAB target configured -> cmake --build . --target ReleaseDistributableAndroidAAB")
        endif ()

        if (NOT TARGET ReleaseDistributableAndroidAPK)
            if (TARGET VerifyAndroidAPK)
                add_custom_target(ReleaseDistributableAndroidAPK
                    DEPENDS VerifyAndroidAPK
                    COMMENT "Building and verifying signed Android release APK artifacts"
                )
            else ()
                add_custom_target(ReleaseDistributableAndroidAPK
                    DEPENDS ${target}
                    COMMENT "Building Android release APK artifacts"
                )
            endif ()
            message(STATUS "ReleaseDistributableAndroidAPK target configured -> cmake --build . --target ReleaseDistributableAndroidAPK")
        endif ()

        if (NOT TARGET ReleaseDistributableAndroid)
            add_custom_target(ReleaseDistributableAndroid
                COMMENT "Building Android release distributables"
            )
            if (TARGET ReleaseDistributableAndroidAAB)
                add_dependencies(ReleaseDistributableAndroid ReleaseDistributableAndroidAAB)
            endif ()
            if (TARGET ReleaseDistributableAndroidAPK)
                add_dependencies(ReleaseDistributableAndroid ReleaseDistributableAndroidAPK)
            endif ()
            message(STATUS "ReleaseDistributableAndroid target configured -> cmake --build . --target ReleaseDistributableAndroid")
        endif ()
    endif ()

    if (UNIX AND NOT APPLE AND NOT ANDROID)
        if (NOT TARGET ReleaseDistributableLinux)
            if (TARGET AppImage)
                add_custom_target(ReleaseDistributableLinux
                    DEPENDS AppImage
                    COMMENT "Building Linux release artifacts"
                )
            else ()
                add_custom_target(ReleaseDistributableLinux
                    DEPENDS ${target}
                    COMMENT "Building Linux release artifacts"
                )
            endif ()
            message(STATUS "ReleaseDistributableLinux target configured -> cmake --build . --target ReleaseDistributableLinux")
        endif ()
    endif ()

    if (WIN32)
        if (NOT TARGET ReleaseDistributableWindows)
            add_custom_target(ReleaseDistributableWindows
                DEPENDS ${target}
                COMMENT "Building Windows release artifacts"
            )
            message(STATUS "ReleaseDistributableWindows target configured -> cmake --build . --target ReleaseDistributableWindows")
        endif ()
    endif ()

    if (NOT TARGET ReleaseDistributable)
        add_custom_target(ReleaseDistributable
            COMMENT "Building all supported release distributable targets for this platform"
        )
    endif ()

    if (TARGET ReleaseDistributableMacOS)
        add_dependencies(ReleaseDistributable ReleaseDistributableMacOS)
    endif ()
    if (TARGET ReleaseDistributableIOS)
        add_dependencies(ReleaseDistributable ReleaseDistributableIOS)
    endif ()
    if (TARGET ReleaseDistributableAndroid)
        add_dependencies(ReleaseDistributable ReleaseDistributableAndroid)
    endif ()
    if (TARGET ReleaseDistributableLinux)
        add_dependencies(ReleaseDistributable ReleaseDistributableLinux)
    endif ()
    if (TARGET ReleaseDistributableWindows)
        add_dependencies(ReleaseDistributable ReleaseDistributableWindows)
    endif ()
endfunction()
