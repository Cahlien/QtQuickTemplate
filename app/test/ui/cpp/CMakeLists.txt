if (NOT QTQUICKTEMPLATE_ENABLE_TESTING)
    return()
endif ()

include("${CMAKE_SOURCE_DIR}/cmake/testing/FetchSpix.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/qt/QmlModule.cmake")

fetch_spix()

# Build a test-only STATIC library that mirrors the app's QML module.
# The main app compiles the QML module into its executable; this library
# lets the Spix test load the same UI without touching the app target.
set(_app_dir "${CMAKE_SOURCE_DIR}/app")

qt_add_library(QtQuickTemplateTestQml STATIC)

target_compile_definitions(QtQuickTemplateTestQml PRIVATE
    APP_VERSION_STRING="${QTQUICKTEMPLATE_APP_VERSION}.${QTQUICKTEMPLATE_BUILD_NUMBER}"
)

# QML file list — must match the app's setup_app_qml_module()
set(_qml_files
    ${_app_dir}/qml/Main.qml
    ${_app_dir}/qml/organisms/Header.qml
    ${_app_dir}/qml/organisms/Footer.qml
    ${_app_dir}/qml/organisms/NavBar.qml
    ${_app_dir}/qml/organisms/NavigationStack.qml
    ${_app_dir}/qml/templates/AdaptiveLayout.qml
    ${_app_dir}/qml/templates/MainPortraitLayout.qml
    ${_app_dir}/qml/templates/MainLandscapeLayout.qml
    ${_app_dir}/qml/pages/BasePage.qml
    ${_app_dir}/qml/pages/Readme.qml
    ${_app_dir}/qml/pages/License.qml
    ${_app_dir}/qml/pages/StyleShowcase.qml
    ${_app_dir}/qml/pages/content/ReadmeContent.qml
    ${_app_dir}/qml/pages/content/LicenseContent.qml
    ${_app_dir}/qml/pages/content/StyleShowcaseContent.qml
)

# Apply the same resource aliases as the production module
foreach (_file ${_qml_files})
    file(RELATIVE_PATH _rel "${_app_dir}" "${_file}")
    if (_rel MATCHES "^qml/")
        string(REGEX REPLACE "^qml/" "" _alias "${_rel}")
    else ()
        get_filename_component(_alias "${_rel}" NAME)
    endif ()
    set_source_files_properties("${_file}" PROPERTIES QT_RESOURCE_ALIAS "${_alias}")
endforeach ()

set(_app_icon "${_app_dir}/platforms/linux/icons/256x256.png")
set_source_files_properties(${_app_icon} PROPERTIES QT_RESOURCE_ALIAS "app_icon.png")
set_source_files_properties(${_app_dir}/README.md PROPERTIES QT_RESOURCE_ALIAS "README.md")
set_source_files_properties(${_app_dir}/LICENSE PROPERTIES QT_RESOURCE_ALIAS "LICENSE")

qt_add_qml_module(QtQuickTemplateTestQml
    URI dev.crowell.QtQuickTemplate
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/dev/crowell/QtQuickTemplate/"
    QML_FILES
        ${_qml_files}
    RESOURCES
        ${_app_dir}/README.md
        ${_app_dir}/LICENSE
        ${_app_icon}
    SOURCES
        ${_app_dir}/src/main/common/app_info.cpp
        ${_app_dir}/include/main/common/app_info.h
        ${_app_dir}/include/main/common/navigation/navigation_controller.h
    DEPENDENCIES
        dev.crowell.AppTheme
)

target_include_directories(QtQuickTemplateTestQml PUBLIC
    ${_app_dir}/include/main/common
    ${_app_dir}/include/main/common/navigation
)

target_link_libraries(QtQuickTemplateTestQml PUBLIC
    QtQuickTemplateNavigation
    Qt6::Qml
    Qt6::Quick
)
target_compile_features(QtQuickTemplateTestQml PUBLIC cxx_std_23)

# Test executable
add_executable(tst_ui_navigation
    src/main.cpp
    src/tst_navigation_ui.cpp
    include/tst_navigation_ui.h
)

target_include_directories(tst_ui_navigation PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(tst_ui_navigation PRIVATE
    QtQuickTemplateTestQml
    QtQuickTemplateTestQmlplugin
    apptheme
    appthemeplugin
    appstyle
    appstyleplugin
    Spix
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Qml
    Qt6::Gui
)

qt_import_qml_plugins(tst_ui_navigation)

add_test(NAME tst_ui_navigation COMMAND tst_ui_navigation)
set_tests_properties(tst_ui_navigation PROPERTIES
    TIMEOUT 30
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen"
)
