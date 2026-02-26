include("${CMAKE_SOURCE_DIR}/cmake/testing/TestTargets.cmake")

add_qt_test(
    NAME tst_helloworld
    SOURCES
        tst_helloworld.cpp
    LINK_LIBRARIES
        helloworld
)
