include("${CMAKE_SOURCE_DIR}/cmake/testing/TestTargets.cmake")

add_qt_test(
    NAME tst_cpp
    SOURCES
        main.cpp
        common/navigation/tst_navigation_controller.cpp
        ${CMAKE_SOURCE_DIR}/app/src/main/common/navigation/navigation_controller.cpp
        ${CMAKE_SOURCE_DIR}/app/include/test/common/navigation/tst_navigation_controller.h
        ${CMAKE_SOURCE_DIR}/app/include/main/common/navigation/navigation_controller.h
    LINK_LIBRARIES
        Qt6::Qml
    INCLUDE_DIRECTORIES
        ${CMAKE_SOURCE_DIR}/app/include/test
        ${CMAKE_SOURCE_DIR}/app/include/main/common
)
