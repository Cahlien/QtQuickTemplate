include_guard(GLOBAL)

# Flatten all QML file paths into the module root via QT_RESOURCE_ALIAS.
# Without this, files under qml/ keep the prefix in the resource tree
# (e.g. qrc:/qt/qml/QtQuickTemplate/qml/Main.qml) and Qt.resolvedUrl()
# breaks across differently-nested files.
function(set_qml_resource_aliases file_list)
    foreach (_file ${${file_list}})
        get_filename_component(_name "${_file}" NAME)
        set_source_files_properties("${_file}" PROPERTIES QT_RESOURCE_ALIAS "${_name}")
    endforeach ()
endfunction()

# Create the application QML module with all sources, resources, and dependencies.
function(setup_app_qml_module target)
    set(_src_dir "${CMAKE_CURRENT_SOURCE_DIR}")

    set(_app_icon_resource platforms/linux/icons/256x256.png)
    set_source_files_properties(${_app_icon_resource} PROPERTIES QT_RESOURCE_ALIAS "app_icon.png")

    set(_qml_all_files
        qml/Main.qml
        qml/organisms/Header.qml
        qml/organisms/Footer.qml
        qml/organisms/NavBar.qml
        qml/templates/AdaptiveLayout.qml
        qml/templates/NavigationStack.qml
        qml/templates/MainPortraitLayout.qml
        qml/templates/MainLandscapeLayout.qml
        qml/pages/BasePage.qml
        qml/pages/Readme.qml
        qml/pages/License.qml
        qml/pages/StyleShowcase.qml
        qml/pages/content/ReadmeContent.qml
        qml/pages/content/LicenseContent.qml
        qml/pages/content/StyleShowcaseContent.qml
    )
    set_qml_resource_aliases(_qml_all_files)

    set_source_files_properties(README.md PROPERTIES QT_RESOURCE_ALIAS "README.md")
    set_source_files_properties(LICENSE PROPERTIES QT_RESOURCE_ALIAS "LICENSE")

    qt_add_qml_module(${target}
        URI dev.crowell.${PROJECT_NAME}
        VERSION 1.0
        QML_FILES
            ${_qml_all_files}
        RESOURCES
            README.md
            LICENSE
            ${_app_icon_resource}
        SOURCES
            src/main/common/app_info.cpp
            include/main/common/app_info.h
            src/main/common/navigation/navigation_controller.cpp
            include/main/common/navigation/navigation_controller.h
        DEPENDENCIES
            dev.crowell.AppTheme
    )
endfunction()
