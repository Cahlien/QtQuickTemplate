include("${CMAKE_SOURCE_DIR}/cmake/testing/TestTargets.cmake")

add_qt_quick_test(
    NAME tst_qml_appstyle
    SOURCES
        tst_qml_main.cpp
    QML_TEST_DIR
        ${CMAKE_CURRENT_SOURCE_DIR}
    LINK_LIBRARIES
        appstyleplugin
        appstyle
        appthemeplugin
        apptheme
    QML_IMPORT_PATHS
        ${CMAKE_BINARY_DIR}
)
