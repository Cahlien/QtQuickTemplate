include_guard(GLOBAL)

# AndroidHelpTargets.cmake — Registers Android deploy targets with the help
# system unconditionally so they appear on every platform.

function(register_android_help_targets)
    register_help_target(
        NAME AndroidAAB
        GROUP "Android"
        DESCRIPTION "Build unsigned Android release AAB via Gradle"
        COMMAND "cmake --build <dir> --target AndroidAAB"
    )
    register_help_target(
        NAME SignAndroidAAB
        GROUP "Android"
        DESCRIPTION "Sign Android release AAB via Gradle"
        COMMAND "cmake --build <dir> --target SignAndroidAAB"
        VARIABLES "QTQUICKTEMPLATE_ANDROID_KEYSTORE_PATH -- Path to Android keystore"
                  "QTQUICKTEMPLATE_ANDROID_KEYSTORE_PASSWORD -- Keystore password"
                  "QTQUICKTEMPLATE_ANDROID_KEY_ALIAS -- Key alias"
                  "QTQUICKTEMPLATE_ANDROID_KEY_PASSWORD -- Key password"
    )
    register_help_target(
        NAME AndroidAPK
        GROUP "Android"
        DESCRIPTION "Build unsigned Android release APK via Gradle"
        COMMAND "cmake --build <dir> --target AndroidAPK"
    )
    register_help_target(
        NAME VerifyAndroidAAB
        GROUP "Android"
        DESCRIPTION "Verify Android release AAB signature via jarsigner"
        COMMAND "cmake --build <dir> --target VerifyAndroidAAB"
    )
    register_help_target(
        NAME VerifyAndroidAPK
        GROUP "Android"
        DESCRIPTION "Verify Android release APK signature via apksigner"
        COMMAND "cmake --build <dir> --target VerifyAndroidAPK"
    )
    register_help_target(
        NAME UploadAndroidPlay
        GROUP "Android"
        DESCRIPTION "Upload signed Android AAB to Google Play via Gradle"
        COMMAND "cmake --build <dir> --target UploadAndroidPlay"
        VARIABLES "QTQUICKTEMPLATE_ANDROID_PLAY_SERVICE_ACCOUNT_FILE -- Google Play service-account JSON"
                  "QTQUICKTEMPLATE_ANDROID_PLAY_TRACK (default: internal) -- Play track"
                  "QTQUICKTEMPLATE_ANDROID_PLAY_RELEASE_STATUS (default: completed) -- Release status"
    )
    register_help_target(
        NAME ReleaseDistributableAndroid
        GROUP "Android"
        DESCRIPTION "Full Android release pipeline (AAB + APK)"
        COMMAND "cmake --build <dir> --target ReleaseDistributableAndroid"
    )
endfunction()
