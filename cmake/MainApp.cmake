include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/qt/QmlModule.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/platform/PlatformSources.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/platform/AndroidVersion.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/toolchain/CompilerSettings.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/packaging/AppImage.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/packaging/Install.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/docs/QDoc.cmake")

# Create and fully configure the main application target.
# Must be called after add_subdirectory(libs).
function(configure_main_app)
    qt_add_executable(${PROJECT_NAME}
        src/main/common/main.cpp
    )

    target_compile_definitions(${PROJECT_NAME} PRIVATE
        APP_VERSION_STRING="${PROJECT_VERSION}"
    )

    setup_app_qml_module(${PROJECT_NAME})

    if (NOT ANDROID AND NOT APPLE)
        set_target_properties(${PROJECT_NAME} PROPERTIES
            OUTPUT_NAME app${PROJECT_NAME}
        )
    endif ()

    set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE TRUE
        WIN32_EXECUTABLE TRUE
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
        QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/platforms/android
    )

    add_android_version_target(${PROJECT_NAME})
    add_platform_sources(${PROJECT_NAME})

    target_link_libraries(${PROJECT_NAME}
        PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Qml
        apptheme
        appthemeplugin
        appstyle
        appstyleplugin
        helloworld
    )

    qt_import_qml_plugins(${PROJECT_NAME})

    if (ANDROID)
        # Android 15 requires 16 KB page size support for ELF alignment.
        # See https://developer.android.com/16kb-page-size
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

    configure_appimage(${PROJECT_NAME})
    configure_install(${PROJECT_NAME})
endfunction()
