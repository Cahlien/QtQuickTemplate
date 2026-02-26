project(QtQuickTemplate VERSION 0.2.0 LANGUAGES CXX)
set(QTQUICKTEMPLATE_APP_VERSION "${PROJECT_VERSION}" CACHE INTERNAL "Application version")

add_subdirectory(libs)

include("${CMAKE_SOURCE_DIR}/cmake/MainApp.cmake")
configure_main_app()

if (QTQUICKTEMPLATE_ENABLE_TESTING)
    add_subdirectory(src/test)
endif ()
