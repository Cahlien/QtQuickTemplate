include("${CMAKE_SOURCE_DIR}/cmake/testing/TestTargets.cmake")

set(LIB_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../..")

add_qt_test(
    NAME tst_helloworld
    SOURCES
        main.cpp
        tst_helloworld.cpp
        ${LIB_ROOT}/include/test/helloworld/tst_helloworld.h
    LINK_LIBRARIES
        helloworld
    INCLUDE_DIRECTORIES
        ${LIB_ROOT}/include/test
)
