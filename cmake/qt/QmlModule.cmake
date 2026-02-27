include_guard(GLOBAL)

# Keep QML resource aliases relative to the qml/ source root.
# This yields stable paths such as pages/Readme.qml and
# pages/content/ReadmeContent.qml under the module resource root.
function(set_qml_resource_aliases file_list)
    foreach (_file ${${file_list}})
        if (_file MATCHES "^qml/")
            string(REGEX REPLACE "^qml/" "" _alias "${_file}")
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
        qml/Main.qml
        qml/organisms/Header.qml
        qml/organisms/Footer.qml
        qml/organisms/NavBar.qml
        qml/organisms/NavigationStack.qml
        qml/templates/AdaptiveLayout.qml
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

    set_source_files_properties(${CMAKE_CURRENT_SOURCE_DIR}/README.md PROPERTIES QT_RESOURCE_ALIAS "README.md")
    set_source_files_properties(${CMAKE_CURRENT_SOURCE_DIR}/LICENSE PROPERTIES QT_RESOURCE_ALIAS "LICENSE")

    qt_add_qml_module(${target}
        URI dev.crowell.${PROJECT_NAME}
        VERSION 1.0
        OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/dev/crowell/${PROJECT_NAME}/"
        QML_FILES
            ${_qml_all_files}
        RESOURCES
            ${CMAKE_CURRENT_SOURCE_DIR}/README.md
            ${CMAKE_CURRENT_SOURCE_DIR}/LICENSE
            ${_app_icon_resource}
        SOURCES
            src/main/common/app_info.cpp
            include/main/common/app_info.h
            include/main/common/navigation/navigation_controller.h
        DEPENDENCIES
            dev.crowell.AppTheme
    )
endfunction()
