include_guard(GLOBAL)

set(QTQUICKTEMPLATE_ANDROID_KEYSTORE_PATH "" CACHE FILEPATH
    "Path to Android keystore used for release AAB signing"
)

set(QTQUICKTEMPLATE_ANDROID_KEYSTORE_PASSWORD "" CACHE STRING
    "Keystore password used for release AAB signing"
)

set(QTQUICKTEMPLATE_ANDROID_KEY_ALIAS "" CACHE STRING
    "Key alias used for release AAB signing"
)

set(QTQUICKTEMPLATE_ANDROID_KEY_PASSWORD "" CACHE STRING
    "Key password used for release AAB signing"
)

function(configure_android_release_aab target)
    if (NOT ANDROID)
        return()
    endif ()

    set(_android_package_dir "${CMAKE_CURRENT_SOURCE_DIR}/platforms/android")
    set(_gradle_wrapper "${_android_package_dir}/gradlew")
    if (NOT EXISTS "${_gradle_wrapper}")
        message(WARNING "Android Gradle wrapper not found; AndroidAAB target is unavailable.")
        return()
    endif ()

    find_program(JARSIGNER_EXECUTABLE jarsigner)
    if (NOT JARSIGNER_EXECUTABLE)
        message(WARNING "jarsigner not found; Android AAB signing verification is unavailable.")
        return()
    endif ()

    set(_verify_script "${CMAKE_CURRENT_BINARY_DIR}/verify_android_aab.cmake")
    file(WRITE "${_verify_script}" [=[
if (NOT DEFINED ENV{ANDROID_PACKAGE_DIR})
    message(FATAL_ERROR "ANDROID_PACKAGE_DIR env var is required")
endif ()

if (NOT DEFINED ENV{JARSIGNER_EXECUTABLE})
    message(FATAL_ERROR "JARSIGNER_EXECUTABLE env var is required")
endif ()

if (NOT DEFINED ENV{QT_ANDROID_KEYSTORE_PATH} OR "$ENV{QT_ANDROID_KEYSTORE_PATH}" STREQUAL "")
    message(FATAL_ERROR "QT_ANDROID_KEYSTORE_PATH must be set for signed AAB builds")
endif ()

if (NOT DEFINED ENV{QT_ANDROID_KEYSTORE_PASSWORD} OR "$ENV{QT_ANDROID_KEYSTORE_PASSWORD}" STREQUAL "")
    message(FATAL_ERROR "QT_ANDROID_KEYSTORE_PASSWORD must be set for signed AAB builds")
endif ()

if (NOT DEFINED ENV{QT_ANDROID_KEY_ALIAS} OR "$ENV{QT_ANDROID_KEY_ALIAS}" STREQUAL "")
    message(FATAL_ERROR "QT_ANDROID_KEY_ALIAS must be set for signed AAB builds")
endif ()

if (NOT DEFINED ENV{QT_ANDROID_KEY_PASSWORD} OR "$ENV{QT_ANDROID_KEY_PASSWORD}" STREQUAL "")
    message(FATAL_ERROR "QT_ANDROID_KEY_PASSWORD must be set for signed AAB builds")
endif ()

if (NOT EXISTS "$ENV{QT_ANDROID_KEYSTORE_PATH}")
    message(FATAL_ERROR "Android keystore does not exist: $ENV{QT_ANDROID_KEYSTORE_PATH}")
endif ()

set(_android_package_dir "$ENV{ANDROID_PACKAGE_DIR}")
set(_aab_dir "${_android_package_dir}/build/outputs/bundle/release")

if (NOT EXISTS "${_aab_dir}")
    message(FATAL_ERROR "AAB output directory not found: ${_aab_dir}")
endif ()

file(GLOB _aab_files "${_aab_dir}/*.aab")
list(LENGTH _aab_files _aab_count)
if (_aab_count EQUAL 0)
    message(FATAL_ERROR "No AAB files found in ${_aab_dir}")
endif ()

list(SORT _aab_files)
list(GET _aab_files -1 _aab_file)

execute_process(
    COMMAND "$ENV{JARSIGNER_EXECUTABLE}" -verify -verbose -certs "${_aab_file}"
    RESULT_VARIABLE _verify_rv
    OUTPUT_VARIABLE _verify_out
    ERROR_VARIABLE _verify_err
)

if (NOT _verify_rv EQUAL 0)
    message(FATAL_ERROR "AAB signature verification failed for ${_aab_file}:\n${_verify_out}\n${_verify_err}")
endif ()

message(STATUS "Signed Android AAB verified: ${_aab_file}")
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

    if (NOT TARGET AndroidAAB)
        add_custom_target(AndroidAAB
            DEPENDS ${target}
            COMMAND ${CMAKE_COMMAND} -E env
                QT_ANDROID_KEYSTORE_PATH=${_keystore_path}
                QT_ANDROID_KEYSTORE_PASSWORD=${_keystore_password}
                QT_ANDROID_KEY_ALIAS=${_key_alias}
                QT_ANDROID_KEY_PASSWORD=${_key_password}
                ${CMAKE_COMMAND} -E chdir "${_android_package_dir}" "${_gradle_wrapper}" --no-daemon bundleRelease
            COMMENT "Building signed Android release AAB"
            VERBATIM
        )
        message(STATUS "AndroidAAB target configured -> cmake --build . --target AndroidAAB")
    endif ()

    if (NOT TARGET VerifyAndroidAAB)
        add_custom_target(VerifyAndroidAAB
            DEPENDS AndroidAAB
            COMMAND ${CMAKE_COMMAND} -E env
                ANDROID_PACKAGE_DIR=${_android_package_dir}
                JARSIGNER_EXECUTABLE=${JARSIGNER_EXECUTABLE}
                QT_ANDROID_KEYSTORE_PATH=${_keystore_path}
                QT_ANDROID_KEYSTORE_PASSWORD=${_keystore_password}
                QT_ANDROID_KEY_ALIAS=${_key_alias}
                QT_ANDROID_KEY_PASSWORD=${_key_password}
                ${CMAKE_COMMAND} -P "${_verify_script}"
            COMMENT "Verifying Android release AAB signature"
            VERBATIM
        )
        message(STATUS "VerifyAndroidAAB target configured -> cmake --build . --target VerifyAndroidAAB")
    endif ()
endfunction()
