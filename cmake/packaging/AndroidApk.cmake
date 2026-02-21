include_guard(GLOBAL)

set(QTQUICKTEMPLATE_ANDROID_KEYSTORE_PATH "" CACHE FILEPATH
    "Path to Android keystore used for release APK signing"
)

set(QTQUICKTEMPLATE_ANDROID_KEYSTORE_PASSWORD "" CACHE STRING
    "Keystore password used for release APK signing"
)

set(QTQUICKTEMPLATE_ANDROID_KEY_ALIAS "" CACHE STRING
    "Key alias used for release APK signing"
)

set(QTQUICKTEMPLATE_ANDROID_KEY_PASSWORD "" CACHE STRING
    "Key password used for release APK signing"
)

function(configure_android_release_apk target)
    if (NOT ANDROID)
        return()
    endif ()

    set(_android_package_dir "${CMAKE_CURRENT_SOURCE_DIR}/platforms/android")
    set(_gradle_wrapper "${_android_package_dir}/gradlew")
    if (NOT EXISTS "${_gradle_wrapper}")
        message(WARNING "Android Gradle wrapper not found; AndroidAPK target is unavailable.")
        return()
    endif ()

    find_program(APKSIGNER_EXECUTABLE apksigner)
    if (NOT APKSIGNER_EXECUTABLE)
        message(WARNING "apksigner not found; Android APK signing verification is unavailable.")
        return()
    endif ()

    set(_verify_script "${CMAKE_CURRENT_BINARY_DIR}/verify_android_apk.cmake")
    file(WRITE "${_verify_script}" [=[
if (NOT DEFINED ENV{ANDROID_PACKAGE_DIR})
    message(FATAL_ERROR "ANDROID_PACKAGE_DIR env var is required")
endif ()

if (NOT DEFINED ENV{APKSIGNER_EXECUTABLE})
    message(FATAL_ERROR "APKSIGNER_EXECUTABLE env var is required")
endif ()

set(_android_package_dir "$ENV{ANDROID_PACKAGE_DIR}")
set(_apk_dir "${_android_package_dir}/build/outputs/apk/release")

if (NOT EXISTS "${_apk_dir}")
    message(FATAL_ERROR "APK output directory not found: ${_apk_dir}")
endif ()

file(GLOB _apk_files "${_apk_dir}/*.apk")
list(LENGTH _apk_files _apk_count)
if (_apk_count EQUAL 0)
    message(FATAL_ERROR "No APK files found in ${_apk_dir}")
endif ()

list(SORT _apk_files)
list(GET _apk_files -1 _apk_file)

execute_process(
    COMMAND "$ENV{APKSIGNER_EXECUTABLE}" verify --verbose --print-certs "${_apk_file}"
    RESULT_VARIABLE _verify_rv
    OUTPUT_VARIABLE _verify_out
    ERROR_VARIABLE _verify_err
)

if (NOT _verify_rv EQUAL 0)
    message(FATAL_ERROR "APK signature verification failed for ${_apk_file}:\n${_verify_out}\n${_verify_err}")
endif ()

message(STATUS "Signed Android APK verified: ${_apk_file}")
]=])

    set(_keystore_path "${QTQUICKTEMPLATE_ANDROID_KEYSTORE_PATH}")
    if (NOT _keystore_path)
        set(_keystore_path "$ENV{QT_ANDROID_KEYSTORE_PATH}")
    endif ()

    set(_keystore_password "${QTQUICKTEMPLATE_ANDROID_KEYSTORE_PASSWORD}")
    if (NOT _keystore_password)
        set(_keystore_password "$ENV{QT_ANDROID_KEYSTORE_PASSWORD}")
    endif ()

    set(_key_alias "${QTQUICKTEMPLATE_ANDROID_KEY_ALIAS}")
    if (NOT _key_alias)
        set(_key_alias "$ENV{QT_ANDROID_KEY_ALIAS}")
    endif ()

    set(_key_password "${QTQUICKTEMPLATE_ANDROID_KEY_PASSWORD}")
    if (NOT _key_password)
        set(_key_password "$ENV{QT_ANDROID_KEY_PASSWORD}")
    endif ()

    if (NOT TARGET AndroidAPK)
        add_custom_target(AndroidAPK
            DEPENDS ${target}
            COMMAND ${CMAKE_COMMAND} -E env
                QT_ANDROID_KEYSTORE_PATH=${_keystore_path}
                QT_ANDROID_KEYSTORE_PASSWORD=${_keystore_password}
                QT_ANDROID_KEY_ALIAS=${_key_alias}
                QT_ANDROID_KEY_PASSWORD=${_key_password}
                ${CMAKE_COMMAND} -E chdir "${_android_package_dir}" "${_gradle_wrapper}" --no-daemon assembleRelease
            COMMENT "Building signed Android release APK"
            VERBATIM
        )
        message(STATUS "AndroidAPK target configured -> cmake --build . --target AndroidAPK")
    endif ()

    if (NOT TARGET VerifyAndroidAPK)
        add_custom_target(VerifyAndroidAPK
            DEPENDS AndroidAPK
            COMMAND ${CMAKE_COMMAND} -E env
                ANDROID_PACKAGE_DIR=${_android_package_dir}
                APKSIGNER_EXECUTABLE=${APKSIGNER_EXECUTABLE}
                ${CMAKE_COMMAND} -P "${_verify_script}"
            COMMENT "Verifying Android release APK signature"
            VERBATIM
        )
        message(STATUS "VerifyAndroidAPK target configured -> cmake --build . --target VerifyAndroidAPK")
    endif ()
endfunction()
