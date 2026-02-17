qt_add_library(apptheme STATIC)

set_source_files_properties(qml/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
    QT_RESOURCE_ALIAS "Theme.qml"
)

qt_add_qml_module(apptheme
    URI dev.crowell.AppTheme
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/dev/crowell/AppTheme
    QML_FILES
        qml/Theme.qml
)
