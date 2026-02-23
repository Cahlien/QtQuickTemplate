include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/qt/QmlModule.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/platform/PlatformSources.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/platform/AppleCodeSigning.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/platform/AndroidVersion.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/toolchain/CompilerSettings.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/docs/QDoc.cmake")

include("${CMAKE_CURRENT_LIST_DIR}/deploy/Install.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/IOSBuild.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/IOSPackage.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/IOSVerify.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/IOSUpload.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/MacOSBuild.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/MacOSPackage.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/MacOSSign.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/MacOSVerify.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/MacOSAppStoreBuild.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/MacOSAppStorePackage.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/MacOSAppStoreVerify.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/MacOSAppStoreUpload.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/AndroidBuild.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/AndroidVerify.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/AndroidUpload.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/LinuxPackage.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/deploy/ReleaseDistributables.cmake")

function(configure_main_app)
    # Compute git-derived build number so the four-part version
    # (MAJOR.MINOR.PATCH.BUILD) is available at configure time.
    execute_process(
        COMMAND git rev-list --count HEAD
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        OUTPUT_VARIABLE _build_number
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    if (NOT _build_number)
        set(_build_number 1)
    endif ()
    set(QTQUICKTEMPLATE_BUILD_NUMBER "${_build_number}" CACHE INTERNAL
        "Git commit count used as the fourth version component")

    qt_add_executable(${PROJECT_NAME}
        src/main/common/main.cpp
    )

    if (IOS AND COMMAND qt_add_ios_ffmpeg_libraries)
        qt_add_ios_ffmpeg_libraries(${PROJECT_NAME})
    endif ()

    target_compile_definitions(${PROJECT_NAME} PRIVATE
        APP_VERSION_STRING="${PROJECT_VERSION}.${QTQUICKTEMPLATE_BUILD_NUMBER}"
    )

    get_property(_helloworld_modules_enabled GLOBAL PROPERTY QTQUICKTEMPLATE_HELLOWORLD_MODULE_ENABLED)
    if (_helloworld_modules_enabled)
        target_compile_definitions(${PROJECT_NAME} PRIVATE QTQUICKTEMPLATE_USE_HELLOWORLD_MODULE=1)
    endif ()

    setup_app_qml_module(${PROJECT_NAME})

    if (NOT ANDROID AND NOT APPLE)
        set_target_properties(${PROJECT_NAME} PROPERTIES
            OUTPUT_NAME app${PROJECT_NAME}
        )
    endif ()

    set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE TRUE
        WIN32_EXECUTABLE TRUE
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}.${QTQUICKTEMPLATE_BUILD_NUMBER}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
        QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/platforms/android
    )

    add_android_version_target(${PROJECT_NAME})
    add_platform_sources(${PROJECT_NAME})
    configure_apple_release_code_signing(${PROJECT_NAME})

    target_link_libraries(${PROJECT_NAME}
        PRIVATE
        Qt6::Core
        Qt6::CorePrivate
        Qt6::Quick
        Qt6::QuickPrivate
        Qt6::QuickControls2
        Qt6::QuickControls2Private
        Qt6::Qml
        Qt6::QmlPrivate
        apptheme
        appthemeplugin
        appstyle
        appstyleplugin
        helloworld
    )

    qt_import_qml_plugins(${PROJECT_NAME})

    if (ANDROID)
        set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS "-Wl,-z,max-page-size=16384")
    endif ()

    target_include_directories(${PROJECT_NAME}
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include/main/common
        ${CMAKE_CURRENT_SOURCE_DIR}/include/main/common/navigation
        ${CMAKE_CURRENT_SOURCE_DIR}/src/main/common
    )

    configure_ipo(${PROJECT_NAME})
    add_qdoc_target(docs "${CMAKE_CURRENT_SOURCE_DIR}/doc/qtquicktemplate.qdocconf")

    configure_install(${PROJECT_NAME})
    configure_ios_build(${PROJECT_NAME})
    configure_ios_package(${PROJECT_NAME})
    configure_ios_verify(${PROJECT_NAME})
    configure_ios_upload(${PROJECT_NAME})
    configure_macos_build(${PROJECT_NAME})
    configure_macos_package(${PROJECT_NAME})
    configure_macos_sign(${PROJECT_NAME})
    configure_macos_verify(${PROJECT_NAME})
    configure_macos_appstore_build(${PROJECT_NAME})
    configure_macos_appstore_package(${PROJECT_NAME})
    configure_macos_appstore_verify(${PROJECT_NAME})
    configure_macos_appstore_upload(${PROJECT_NAME})
    configure_android_build_aab(${PROJECT_NAME})
    configure_android_build_apk(${PROJECT_NAME})
    configure_android_verify_aab(${PROJECT_NAME})
    configure_android_verify_apk(${PROJECT_NAME})
    configure_android_upload_play(${PROJECT_NAME})
    configure_linux_package(${PROJECT_NAME})

    configure_release_distributables(${PROJECT_NAME})
endfunction()
