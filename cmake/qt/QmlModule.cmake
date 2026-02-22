include_guard(GLOBAL)

# Keep QML resource aliases relative to the ui/ source root.
# This yields stable paths such as pages/Readme.qml and
# pages/content/ReadmeContent.qml under the module resource root.
function(set_qml_resource_aliases file_list)
    foreach (_file ${${file_list}})
        if (_file MATCHES "^ui/")
            string(REGEX REPLACE "^ui/" "" _alias "${_file}")
        else ()
            get_filename_component(_alias "${_file}" NAME)
        endif ()
        set_source_files_properties("${_file}" PROPERTIES QT_RESOURCE_ALIAS "${_alias}")
    endforeach ()
endfunction()

# Create the application QML module with all sources, resources, and dependencies.
function(setup_app_qml_module target)
    set(_src_dir "${CMAKE_CURRENT_SOURCE_DIR}")

    set(_app_icon_resource platforms/linux/icons/256x256.png)
    set_source_files_properties(${_app_icon_resource} PROPERTIES QT_RESOURCE_ALIAS "app_icon.png")

    set(_qml_all_files
        ui/Main.qml
        ui/organisms/Header.qml
        ui/organisms/Footer.qml
        ui/organisms/NavBar.qml
        ui/organisms/NavigationStack.qml
        ui/templates/AdaptiveLayout.qml
        ui/templates/MainPortraitLayout.qml
        ui/templates/MainLandscapeLayout.qml
        ui/pages/BasePage.qml
        ui/pages/Readme.qml
        ui/pages/License.qml
        ui/pages/StyleShowcase.qml
        ui/pages/content/ReadmeContent.qml
        ui/pages/content/LicenseContent.qml
        ui/pages/content/StyleShowcaseContent.qml
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
