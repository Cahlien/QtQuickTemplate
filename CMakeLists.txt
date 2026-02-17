cmake_minimum_required(VERSION 3.16)

project(QtQuickTemplate VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 6.10 REQUIRED COMPONENTS Core Quick QuickControls2 Qml)

qt_policy(SET QTP0004 NEW)
qt_standard_project_setup(REQUIRES 6.10)

# ─────────────────────────────────────────────
# Module 1: AppTheme (shared theme tokens)
# ─────────────────────────────────────────────
qt_add_library(apptheme STATIC)
set_source_files_properties(qml/theme/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
    QT_RESOURCE_ALIAS "Theme.qml"
)
qt_add_qml_module(apptheme
    URI AppTheme
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/AppTheme
    QML_FILES
        qml/theme/Theme.qml
)

# ─────────────────────────────────────────────
# Module 2: AppStyle (custom controls style)
# ─────────────────────────────────────────────
qt_add_library(appstyle STATIC)

set(APPSTYLE_QML_FILES
    qml/AppStyle/Button.qml
    qml/AppStyle/CheckBox.qml
    qml/AppStyle/ComboBox.qml
    qml/AppStyle/GroupBox.qml
    qml/AppStyle/MenuItem.qml
    qml/AppStyle/ProgressBar.qml
    qml/AppStyle/ScrollBar.qml
    qml/AppStyle/Slider.qml
    qml/AppStyle/Switch.qml
    qml/AppStyle/TabButton.qml
    qml/AppStyle/TextField.qml
    qml/AppStyle/ToolTip.qml
)
foreach(_file ${APPSTYLE_QML_FILES})
    get_filename_component(_name "${_file}" NAME)
    set_source_files_properties("${_file}" PROPERTIES QT_RESOURCE_ALIAS "${_name}")
endforeach()

qt_add_qml_module(appstyle
    URI AppStyle
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/AppStyle
    QML_FILES
        ${APPSTYLE_QML_FILES}
    DEPENDENCIES
        AppTheme
)

# ─────────────────────────────────────────────
# Module 3: Main application
# ─────────────────────────────────────────────
qt_add_executable(${PROJECT_NAME}
    src/main/common/main.cpp
)

target_compile_definitions(${PROJECT_NAME} PRIVATE
    APP_VERSION_STRING="${PROJECT_VERSION}"
)

# Flatten ALL qml/ paths into the module root via QT_RESOURCE_ALIAS.
# Without this, files under qml/ keep the prefix in the resource tree
# (e.g. qrc:/qt/qml/QtQuickTemplate/qml/Main.qml) and Qt.resolvedUrl()
# breaks across differently-nested files.
set(QML_ALL_FILES
    qml/Main.qml
    qml/NavigationController.qml
    qml/organisms/Header.qml
    qml/organisms/Footer.qml
    qml/templates/MainPortraitLayout.qml
    qml/templates/MainLandscapeLayout.qml
    qml/pages/Home.qml
    qml/pages/SamplePage.qml
    qml/pages/StyleShowcase.qml
)
foreach(_file ${QML_ALL_FILES})
    get_filename_component(_name "${_file}" NAME)
    set_source_files_properties("${_file}" PROPERTIES QT_RESOURCE_ALIAS "${_name}")
endforeach()

qt_add_qml_module(${PROJECT_NAME}
    URI QtQuickTemplate
    VERSION 1.0
    QML_FILES
        ${QML_ALL_FILES}
    SOURCES
        src/main/common/app_info.cpp
        include/main/common/app_info.h
    DEPENDENCIES
        AppTheme
)

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

# ─────────────────────────────────────────────
# Platform-specific sources & configuration
# ─────────────────────────────────────────────
if (ANDROID)
    target_sources(${PROJECT_NAME} PRIVATE
        src/main/android/platform_init_android.cpp
    )

    target_include_directories(${PROJECT_NAME} PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include/main/android
    )
elseif (WIN32)
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/platforms/windows/app.rc.in
        ${CMAKE_CURRENT_BINARY_DIR}/app.rc
        @ONLY
    )
    target_sources(${PROJECT_NAME} PRIVATE
        src/main/common/platform_init_default.cpp
        ${CMAKE_CURRENT_BINARY_DIR}/app.rc
        ${CMAKE_CURRENT_SOURCE_DIR}/platforms/windows/app.manifest
    )
elseif (APPLE AND NOT IOS)
    target_sources(${PROJECT_NAME} PRIVATE
        src/main/common/platform_init_default.cpp
    )
    set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/platforms/macos/Info.plist
    )
    if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/platforms/macos/app.icns")
        set_source_files_properties(platforms/macos/app.icns PROPERTIES
            MACOSX_PACKAGE_LOCATION "Resources"
        )
        target_sources(${PROJECT_NAME} PRIVATE platforms/macos/app.icns)
        set_target_properties(${PROJECT_NAME} PROPERTIES
            MACOSX_BUNDLE_ICON_FILE app.icns
        )
    endif ()
elseif (UNIX AND NOT APPLE AND NOT ANDROID)
    target_sources(${PROJECT_NAME} PRIVATE
        src/main/common/platform_init_default.cpp
    )
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/platforms/linux/QtQuickTemplate.desktop.in
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.desktop
        @ONLY
    )
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/platforms/linux/dev.crowell.app.template.metainfo.xml.in
        ${CMAKE_CURRENT_BINARY_DIR}/dev.crowell.app.template.metainfo.xml
        @ONLY
    )
else ()
    target_sources(${PROJECT_NAME} PRIVATE
        src/main/common/platform_init_default.cpp
    )
endif ()

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
)

target_include_directories(${PROJECT_NAME}
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include/main/common
    ${CMAKE_CURRENT_SOURCE_DIR}/src/main/common
)

include(CheckIPOSupported)
check_ipo_supported(RESULT ipo_ok OUTPUT ipo_msg)
if (ipo_ok)
    set_property(TARGET ${PROJECT_NAME} PROPERTY INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE)
endif ()

include(GNUInstallDirs)
install(TARGETS ${PROJECT_NAME}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

if (UNIX AND NOT APPLE AND NOT ANDROID)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.desktop
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications
    )
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/dev.crowell.app.template.metainfo.xml
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/metainfo
    )
    # Install icons if present
    file(GLOB _linux_icons "platforms/linux/icons/*.png" "platforms/linux/icons/*.svg")
    foreach (_icon ${_linux_icons})
        get_filename_component(_icon_name "${_icon}" NAME_WE)
        # Expect filenames like 48x48.png, 256x256.png, scalable.svg
        if (_icon_name MATCHES "^([0-9]+)x([0-9]+)$")
            install(FILES "${_icon}"
                DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/${_icon_name}/apps
                RENAME dev.crowell.app.template.png
            )
        elseif (_icon_name STREQUAL "scalable")
            install(FILES "${_icon}"
                DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/apps
                RENAME dev.crowell.app.template.svg
            )
        endif ()
    endforeach ()
endif ()
