include("${CMAKE_SOURCE_DIR}/cmake/testing/TestTargets.cmake")

add_qt_test(
    NAME tst_cpp
    SOURCES
        src/main.cpp
        src/common/navigation/tst_navigation_controller.cpp
        include/common/navigation/tst_navigation_controller.h
    LINK_LIBRARIES
        QtQuickTemplateNavigation
    INCLUDE_DIRECTORIES
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)
