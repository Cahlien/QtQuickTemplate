include("${CMAKE_SOURCE_DIR}/cmake/testing/TestTargets.cmake")

add_qt_test(
    NAME tst_cpp
    SOURCES
        main.cpp
        common/navigation/tst_navigation_controller.cpp
        common/navigation/tst_navigation_controller.h
    LINK_LIBRARIES
        QtQuickTemplateNavigation
    INCLUDE_DIRECTORIES
        ${CMAKE_CURRENT_SOURCE_DIR}
)
