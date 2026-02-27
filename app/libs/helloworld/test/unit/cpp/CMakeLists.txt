include("${CMAKE_SOURCE_DIR}/cmake/testing/TestTargets.cmake")

add_qt_test(
    NAME tst_helloworld
    SOURCES
        main.cpp
        tst_helloworld.cpp
        tst_helloworld.h
    LINK_LIBRARIES
        helloworld
    INCLUDE_DIRECTORIES
        ${CMAKE_CURRENT_SOURCE_DIR}
)
