qt_add_library(appstyle STATIC)

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

qt_add_qml_module(appstyle
    URI dev.crowell.AppStyle
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/dev/crowell/AppStyle
    QML_FILES
        ${APPSTYLE_QML_FILES}
    DEPENDENCIES
        dev.crowell.AppTheme
)
