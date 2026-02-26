set(TARGET apptheme)

qt_add_library(${TARGET} STATIC)

set_source_files_properties(qml/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
    QT_RESOURCE_ALIAS "Theme.qml"
)

qt_add_qml_module(${TARGET}
    URI dev.crowell.AppTheme
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/dev/crowell/AppTheme
    QML_FILES
        qml/Theme.qml
    ENABLE_TYPE_COMPILER
)

target_link_libraries(${TARGET}
    PUBLIC
        Qt6::Core
        Qt6::Qml
        Qt6::QuickControls2
    PRIVATE
        Qt6::QmlPrivate
        Qt6::QuickPrivate
)

if (QTQUICKTEMPLATE_ENABLE_TESTING)
    add_subdirectory(src/test)
endif ()
