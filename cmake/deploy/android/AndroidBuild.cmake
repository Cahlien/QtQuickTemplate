include_guard(GLOBAL)

# AndroidBuild.cmake — Configures AndroidAAB and AndroidAPK targets that invoke
# Gradle to produce signed release bundles and APKs for Android distribution.

set(QTQUICKTEMPLATE_ANDROID_KEYSTORE_PATH "" CACHE FILEPATH
    "Path to Android keystore used for release signing"
)
set(QTQUICKTEMPLATE_ANDROID_KEYSTORE_PASSWORD "" CACHE STRING
    "Keystore password used for release signing"
)
set(QTQUICKTEMPLATE_ANDROID_KEY_ALIAS "" CACHE STRING
    "Key alias used for release signing"
)
set(QTQUICKTEMPLATE_ANDROID_KEY_PASSWORD "" CACHE STRING
    "Key password used for release signing"
)

function(_resolve_android_signing_vars out_ks out_ksp out_ka out_kp)
    foreach (_pair "QTQUICKTEMPLATE_ANDROID_KEYSTORE_PATH;QT_ANDROID_KEYSTORE_PATH"
                   "QTQUICKTEMPLATE_ANDROID_KEYSTORE_PASSWORD;QT_ANDROID_KEYSTORE_PASSWORD"
                   "QTQUICKTEMPLATE_ANDROID_KEY_ALIAS;QT_ANDROID_KEY_ALIAS"
                   "QTQUICKTEMPLATE_ANDROID_KEY_PASSWORD;QT_ANDROID_KEY_PASSWORD")
        list(GET _pair 0 _cache_var)
        list(GET _pair 1 _env_var)
        if (${_cache_var})
            set(_val "${${_cache_var}}")
        else ()
            set(_val "$ENV{${_env_var}}")
        endif ()
        list(APPEND _resolved "${_val}")
    endforeach ()

    list(GET _resolved 0 _ks)
    list(GET _resolved 1 _ksp)
    list(GET _resolved 2 _ka)
    list(GET _resolved 3 _kp)
    set(${out_ks} "${_ks}" PARENT_SCOPE)
    set(${out_ksp} "${_ksp}" PARENT_SCOPE)
    set(${out_ka} "${_ka}" PARENT_SCOPE)
    set(${out_kp} "${_kp}" PARENT_SCOPE)
endfunction()

function(_configure_android_gradle_build target_name depends qt_target comment)
    if (NOT TARGET ${target_name})
        add_custom_target(${target_name}
            DEPENDS ${depends}
            COMMAND ${CMAKE_COMMAND} --build "${CMAKE_BINARY_DIR}" --target ${qt_target}
            COMMENT "${comment}"
            VERBATIM
        )
        message(STATUS "${target_name} target configured -> cmake --build . --target ${qt_target}")
    endif ()
endfunction()

function(_configure_android_sign_aab)
    if (NOT TARGET AndroidAAB)
        return()
    endif ()

    _resolve_android_signing_vars(_ks _ksp _ka _kp)

    if (NOT _ks OR NOT _ksp OR NOT _ka OR NOT _kp)
        message(WARNING "Android signing credentials incomplete; SignAndroidAAB target unavailable.")
        return()
    endif ()

    set(_build_dir "${CMAKE_BINARY_DIR}/android-build")

    if (NOT TARGET SignAndroidAAB)
        add_custom_target(SignAndroidAAB
            DEPENDS AndroidAAB
            COMMAND ${CMAKE_COMMAND} -E env
                QT_ANDROID_KEYSTORE_PATH=${_ks}
                QT_ANDROID_KEYSTORE_PASSWORD=${_ksp}
                QT_ANDROID_KEY_ALIAS=${_ka}
                QT_ANDROID_KEY_PASSWORD=${_kp}
                ${CMAKE_COMMAND} -E chdir "${_build_dir}" ./gradlew --no-daemon bundleRelease
            COMMENT "Signing Android release AAB via Gradle"
            VERBATIM
        )
        message(STATUS "SignAndroidAAB target configured")
    endif ()
endfunction()

function(configure_android_build_aab target)
    if (NOT ANDROID)
        return()
    endif ()
    _configure_android_gradle_build(AndroidAAB ${target} aab
        "Building unsigned Android release AAB")
    _configure_android_sign_aab()

endfunction()

function(configure_android_build_apk target)
    if (NOT ANDROID)
        return()
    endif ()
    _configure_android_gradle_build(AndroidAPK ${target} apk
        "Building unsigned Android release APK")
endfunction()
