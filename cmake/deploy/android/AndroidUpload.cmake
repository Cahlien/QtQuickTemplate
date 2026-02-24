include_guard(GLOBAL)

# AndroidUpload.cmake — Configures the UploadAndroidPlay target that publishes
# a signed AAB to Google Play via Gradle's publishReleaseBundle task.

set(QTQUICKTEMPLATE_ANDROID_PLAY_SERVICE_ACCOUNT_FILE "" CACHE FILEPATH
    "Path to Google Play service-account JSON used for publishing"
)
set(QTQUICKTEMPLATE_ANDROID_PLAY_TRACK "internal" CACHE STRING
    "Google Play track used for publishing (internal, alpha, beta, production)"
)
set(QTQUICKTEMPLATE_ANDROID_PLAY_RELEASE_STATUS "completed" CACHE STRING
    "Google Play release status (completed, draft, inProgress, halted)"
)

function(configure_android_upload_play target)
    if (NOT ANDROID)
        return()
    endif ()

    if (NOT TARGET VerifyAndroidAAB)
        return()
    endif ()

    set(_pkg_dir "${CMAKE_CURRENT_SOURCE_DIR}/platforms/android")
    set(_gradle "${_pkg_dir}/gradlew")
    if (NOT EXISTS "${_gradle}")
        message(WARNING "Android Gradle wrapper not found; UploadAndroidPlay target unavailable.")
        return()
    endif ()

    if (NOT QTQUICKTEMPLATE_ANDROID_PLAY_SERVICE_ACCOUNT_FILE)
        message(WARNING "QTQUICKTEMPLATE_ANDROID_PLAY_SERVICE_ACCOUNT_FILE not set; UploadAndroidPlay target unavailable.")
        return()
    endif ()

    if (NOT EXISTS "${QTQUICKTEMPLATE_ANDROID_PLAY_SERVICE_ACCOUNT_FILE}")
        message(WARNING "Google Play service-account JSON not found: ${QTQUICKTEMPLATE_ANDROID_PLAY_SERVICE_ACCOUNT_FILE}")
        return()
    endif ()

    if (NOT TARGET UploadAndroidPlay)
        add_custom_target(UploadAndroidPlay
            DEPENDS VerifyAndroidAAB
            COMMAND ${CMAKE_COMMAND} -E env
                QT_ANDROID_PLAY_SERVICE_ACCOUNT_FILE=${QTQUICKTEMPLATE_ANDROID_PLAY_SERVICE_ACCOUNT_FILE}
                QT_ANDROID_PLAY_TRACK=${QTQUICKTEMPLATE_ANDROID_PLAY_TRACK}
                QT_ANDROID_PLAY_RELEASE_STATUS=${QTQUICKTEMPLATE_ANDROID_PLAY_RELEASE_STATUS}
                ${CMAKE_COMMAND} -E chdir "${_pkg_dir}" "${_gradle}" --no-daemon publishReleaseBundle
            COMMENT "Uploading signed Android AAB to Google Play"
            VERBATIM
        )
        message(STATUS "UploadAndroidPlay target configured -> cmake --build . --target UploadAndroidPlay")
    endif ()
endfunction()
