include_guard(GLOBAL)

# AndroidVerify.cmake — Configures VerifyAndroidAAB and VerifyAndroidAPK targets
# that verify release artifact signatures via jarsigner and apksigner.

function(configure_android_verify_aab target)
    if (NOT ANDROID)
        return()
    endif ()

    if (NOT TARGET SignAndroidAAB)
        return()
    endif ()

    find_program(JARSIGNER_EXECUTABLE jarsigner)
    if (NOT JARSIGNER_EXECUTABLE)
        message(WARNING "jarsigner not found; VerifyAndroidAAB target unavailable.")
        return()
    endif ()

    set(_build_dir "${CMAKE_BINARY_DIR}/android-build")
    set(_verify_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/android/VerifyAab.cmake")

    _resolve_android_signing_vars(_ks _ksp _ka _kp)

    if (NOT TARGET VerifyAndroidAAB)
        add_custom_target(VerifyAndroidAAB
            DEPENDS SignAndroidAAB
            COMMAND ${CMAKE_COMMAND} -E env
                ANDROID_PACKAGE_DIR=${_build_dir}
                JARSIGNER_EXECUTABLE=${JARSIGNER_EXECUTABLE}
                QT_ANDROID_KEYSTORE_PATH=${_ks}
                QT_ANDROID_KEYSTORE_PASSWORD=${_ksp}
                QT_ANDROID_KEY_ALIAS=${_ka}
                QT_ANDROID_KEY_PASSWORD=${_kp}
                ${CMAKE_COMMAND} -P "${_verify_script}"
            COMMENT "Verifying Android release AAB signature"
            VERBATIM
        )

        message(STATUS "VerifyAndroidAAB target configured -> cmake --build . --target VerifyAndroidAAB")
    endif ()
endfunction()

function(configure_android_verify_apk target)
    if (NOT ANDROID)
        return()
    endif ()

    if (NOT TARGET AndroidAPK)
        return()
    endif ()

    find_program(APKSIGNER_EXECUTABLE apksigner)
    if (NOT APKSIGNER_EXECUTABLE)
        message(WARNING "apksigner not found; VerifyAndroidAPK target unavailable.")
        return()
    endif ()

    set(_build_dir "${CMAKE_BINARY_DIR}/android-build")
    set(_verify_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/android/VerifyApk.cmake")

    if (NOT TARGET VerifyAndroidAPK)
        add_custom_target(VerifyAndroidAPK
            DEPENDS AndroidAPK
            COMMAND ${CMAKE_COMMAND} -E env
                ANDROID_PACKAGE_DIR=${_build_dir}
                APKSIGNER_EXECUTABLE=${APKSIGNER_EXECUTABLE}
                ${CMAKE_COMMAND} -P "${_verify_script}"
            COMMENT "Verifying Android release APK signature"
            VERBATIM
        )

        message(STATUS "VerifyAndroidAPK target configured -> cmake --build . --target VerifyAndroidAPK")
    endif ()
endfunction()
