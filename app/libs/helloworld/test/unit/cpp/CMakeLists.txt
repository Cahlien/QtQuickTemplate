include("${CMAKE_SOURCE_DIR}/cmake/testing/TestTargets.cmake")

add_qt_test(
    NAME tst_helloworld
    SOURCES
        src/main.cpp
        src/tst_helloworld.cpp
        include/tst_helloworld.h
    LINK_LIBRARIES
        helloworld
    INCLUDE_DIRECTORIES
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)
