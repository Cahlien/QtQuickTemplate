include_guard(GLOBAL)

# DeployPipelines.cmake — Platform-conditional dispatcher that includes all deploy
# modules and provides configure_deploy_pipelines(target) as the single entry point
# for wiring up build → package → sign → verify → upload target chains.

include("${CMAKE_CURRENT_LIST_DIR}/Install.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ReleaseDistributables.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/android/AndroidHelpTargets.cmake")

# Apple shared helpers (iOS and macOS)
if (APPLE)
    include("${CMAKE_CURRENT_LIST_DIR}/apple/XcodeExport.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/apple/ArtifactVerify.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/apple/AscUpload.cmake")
endif ()

# Platform-specific deploy modules
if (APPLE AND IOS)
    include("${CMAKE_CURRENT_LIST_DIR}/ios/IOSBuild.cmake")
elseif (APPLE AND NOT IOS)
    include("${CMAKE_CURRENT_LIST_DIR}/macos/MacOSBuild.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/macos/MacOSPackage.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/macos/MacOSSign.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/macos/MacOSVerify.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/macos/MacOSAppStoreBuild.cmake")
elseif (ANDROID)
    include("${CMAKE_CURRENT_LIST_DIR}/android/AndroidBuild.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/android/AndroidVerify.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/android/AndroidUpload.cmake")
elseif (UNIX AND NOT APPLE AND NOT ANDROID)
    include("${CMAKE_CURRENT_LIST_DIR}/linux/LinuxPackage.cmake")
endif ()

# Configures all deploy pipeline targets for the given app target.
function(configure_deploy_pipelines target)
    configure_install(${target})

    if (APPLE AND IOS)
        configure_ios_build(${target})
        configure_ios_package(${target})
        configure_ios_verify(${target})
        configure_ios_upload(${target})
    elseif (APPLE AND NOT IOS)
        configure_macos_build(${target})
        configure_macos_package(${target})
        configure_macos_sign(${target})
        configure_macos_verify(${target})
        configure_macos_appstore_build(${target})
        configure_macos_appstore_package(${target})
        configure_macos_appstore_verify(${target})
        configure_macos_appstore_upload(${target})
    elseif (ANDROID)
        configure_android_build_aab(${target})
        configure_android_build_apk(${target})
        configure_android_verify_aab(${target})
        configure_android_verify_apk(${target})
        configure_android_upload_play(${target})
    elseif (UNIX AND NOT APPLE AND NOT ANDROID)
        configure_linux_package(${target})
    endif ()

    configure_release_distributables(${target})

    register_android_help_targets()
    finalize_help_targets()
endfunction()
