include_guard(GLOBAL)

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

function(configure_android_build_aab target)
    if (NOT ANDROID)
        return()
    endif ()

    set(_pkg_dir "${CMAKE_CURRENT_SOURCE_DIR}/platforms/android")
    set(_gradle "${_pkg_dir}/gradlew")
    if (NOT EXISTS "${_gradle}")
        message(WARNING "Android Gradle wrapper not found; AndroidAAB target unavailable.")
        return()
    endif ()

    _resolve_android_signing_vars(_ks _ksp _ka _kp)

    if (NOT TARGET AndroidAAB)
        add_custom_target(AndroidAAB
            DEPENDS ${target}
            COMMAND ${CMAKE_COMMAND} -E env
                QT_ANDROID_KEYSTORE_PATH=${_ks}
                QT_ANDROID_KEYSTORE_PASSWORD=${_ksp}
                QT_ANDROID_KEY_ALIAS=${_ka}
                QT_ANDROID_KEY_PASSWORD=${_kp}
                ${CMAKE_COMMAND} -E chdir "${_pkg_dir}" "${_gradle}" --no-daemon bundleRelease
            COMMENT "Building signed Android release AAB"
            VERBATIM
        )
        message(STATUS "AndroidAAB target configured -> cmake --build . --target AndroidAAB")
    endif ()
endfunction()

function(configure_android_build_apk target)
    if (NOT ANDROID)
        return()
    endif ()

    set(_pkg_dir "${CMAKE_CURRENT_SOURCE_DIR}/platforms/android")
    set(_gradle "${_pkg_dir}/gradlew")
    if (NOT EXISTS "${_gradle}")
        message(WARNING "Android Gradle wrapper not found; AndroidAPK target unavailable.")
        return()
    endif ()

    _resolve_android_signing_vars(_ks _ksp _ka _kp)

    if (NOT TARGET AndroidAPK)
        add_custom_target(AndroidAPK
            DEPENDS ${target}
            COMMAND ${CMAKE_COMMAND} -E env
                QT_ANDROID_KEYSTORE_PATH=${_ks}
                QT_ANDROID_KEYSTORE_PASSWORD=${_ksp}
                QT_ANDROID_KEY_ALIAS=${_ka}
                QT_ANDROID_KEY_PASSWORD=${_kp}
                ${CMAKE_COMMAND} -E chdir "${_pkg_dir}" "${_gradle}" --no-daemon assembleRelease
            COMMENT "Building signed Android release APK"
            VERBATIM
        )
        message(STATUS "AndroidAPK target configured -> cmake --build . --target AndroidAPK")
    endif ()
endfunction()
