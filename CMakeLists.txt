cmake_minimum_required(VERSION 3.16)

project(QtQuickTemplate VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 6.10 REQUIRED COMPONENTS Core Quick QuickControls2 Qml)

qt_policy(SET QTP0004 NEW)
qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(${PROJECT_NAME}
    src/main.cpp
)

target_compile_definitions(${PROJECT_NAME} PRIVATE
    APP_VERSION_STRING="${PROJECT_VERSION}"
)

# ── Theme singleton ──
set_source_files_properties(qml/Theme.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

# ── Flatten atomic-design subdirectories into the module root ──
set(QML_SUBDIRECTORY_FILES
    qml/organisms/Header.qml
    qml/organisms/Footer.qml
    qml/templates/MainPortraitLayout.qml
    qml/templates/MainLandscapeLayout.qml
    qml/pages/Home.qml
    qml/pages/SamplePage.qml
)
foreach(_file ${QML_SUBDIRECTORY_FILES})
    get_filename_component(_name "${_file}" NAME)
    set_source_files_properties("${_file}" PROPERTIES QT_RESOURCE_ALIAS "${_name}")
endforeach()

qt_add_qml_module(${PROJECT_NAME}
    URI QtQuickTemplate
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/NavigationController.qml
        qml/Theme.qml
        ${QML_SUBDIRECTORY_FILES}
    SOURCES
        src/app_info.cpp
        include/app_info.h
)

if (NOT ANDROID AND NOT APPLE)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        OUTPUT_NAME app${PROJECT_NAME}
    )
endif ()

set_target_properties(${PROJECT_NAME} PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
)

target_link_libraries(${PROJECT_NAME}
    PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Qml
)

target_include_directories(${PROJECT_NAME}
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

include(CheckIPOSupported)
check_ipo_supported(RESULT ipo_ok OUTPUT ipo_msg)
if (ipo_ok)
    set_property(TARGET ${PROJECT_NAME} PROPERTY INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE)
endif ()

include(GNUInstallDirs)
install(TARGETS ${PROJECT_NAME}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
