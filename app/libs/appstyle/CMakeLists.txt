set(TARGET appstyle)

qt_add_library(${TARGET} STATIC)

set(APPSTYLE_QML_FILES
    qml/Button.qml
    qml/CheckBox.qml
    qml/ComboBox.qml
    qml/GroupBox.qml
    qml/MenuItem.qml
    qml/ProgressBar.qml
    qml/ScrollBar.qml
    qml/Slider.qml
    qml/Switch.qml
    qml/TabButton.qml
    qml/TextField.qml
    qml/ToolTip.qml
)

foreach(_file ${APPSTYLE_QML_FILES})
    get_filename_component(_name "${_file}" NAME)
    set_source_files_properties("${_file}" PROPERTIES QT_RESOURCE_ALIAS "${_name}")
endforeach()

qt_add_qml_module(${TARGET}
    URI dev.crowell.AppStyle
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/dev/crowell/AppStyle
    QML_FILES
        ${APPSTYLE_QML_FILES}
    DEPENDENCIES
        dev.crowell.AppTheme
    IMPORT_PATH ${CMAKE_BINARY_DIR}
    ENABLE_TYPE_COMPILER
    NO_GENERATE_EXTRA_QMLDIRS
)

target_link_libraries(${TARGET}
    PRIVATE
        Qt6::QmlPrivate
        Qt6::QuickPrivate
        Qt6::QuickTemplates2Private
)

if (QTQUICKTEMPLATE_ENABLE_TESTING)
    add_subdirectory(src/test)
endif ()
