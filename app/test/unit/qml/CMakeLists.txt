include("${CMAKE_SOURCE_DIR}/cmake/testing/TestTargets.cmake")

add_qt_quick_test(
    NAME tst_qml_navigation
    SOURCES
        tst_qml_main.cpp
    QML_TEST_DIR
        ${CMAKE_CURRENT_SOURCE_DIR}
)
