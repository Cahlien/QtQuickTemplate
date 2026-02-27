include("${CMAKE_SOURCE_DIR}/cmake/DevcroVersion.cmake")
read_devcro_version(_app_version)
project(QtQuickTemplate VERSION ${_app_version} LANGUAGES CXX)
set(QTQUICKTEMPLATE_APP_VERSION "${PROJECT_VERSION}" CACHE INTERNAL "Application version")

add_subdirectory(libs)

include("${CMAKE_SOURCE_DIR}/cmake/MainApp.cmake")
configure_main_app()

if (QTQUICKTEMPLATE_ENABLE_TESTING)
    add_subdirectory(test)
endif ()
