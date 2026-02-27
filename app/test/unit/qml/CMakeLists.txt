include("${CMAKE_SOURCE_DIR}/cmake/testing/TestTargets.cmake")

if (QTQUICKTEMPLATE_ENABLE_TESTING)
    include(FetchContent)

    # anyrpc is provided by Conan as anyrpc::anyrpc. spix's FindAnyRPC.cmake
    # expects AnyRPC::anyrpc, so bridge the two before FetchContent populates
    # spix and its find_package(AnyRPC REQUIRED) runs.
    find_package(anyrpc REQUIRED)
    if (NOT TARGET AnyRPC::anyrpc)
        add_library(AnyRPC::anyrpc INTERFACE IMPORTED GLOBAL)
        target_link_libraries(AnyRPC::anyrpc INTERFACE anyrpc::anyrpc)
    endif ()

    set(SPIX_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(SPIX_BUILD_TESTS    OFF CACHE BOOL "" FORCE)

    FetchContent_Declare(
        spix
        GIT_REPOSITORY https://github.com/faaxm/spix.git
        GIT_TAG        v0.7
    )
    set(FETCHCONTENT_QUIET OFF)
    FetchContent_MakeAvailable(spix)
endif ()

add_qt_quick_test(
    NAME tst_qml_navigation
    SOURCES
        tst_qml_main.cpp
    QML_TEST_DIR
        ${CMAKE_CURRENT_SOURCE_DIR}
    LINK_LIBRARIES
        Spix
)
