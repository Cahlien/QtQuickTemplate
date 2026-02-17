cmake_minimum_required(VERSION 3.28)

# Seed clang-scan-deps as early as possible so first configure pass has it.
# This avoids requiring a second configure/build cycle in some Android setups.
if (NOT CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS OR CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS MATCHES "-NOTFOUND$")
    set(_scan_hints)
    foreach(_ndk_var ANDROID_NDK_ROOT ANDROID_NDK_HOME ANDROID_NDK)
        if (DEFINED ENV{${_ndk_var}})
            list(APPEND _scan_hints "$ENV{${_ndk_var}}/toolchains/llvm/prebuilt/linux-x86_64/bin")
        endif ()
    endforeach ()
    find_program(_bootstrap_clang_scan_deps clang-scan-deps HINTS ${_scan_hints})
    if (_bootstrap_clang_scan_deps)
        set(CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS "${_bootstrap_clang_scan_deps}" CACHE FILEPATH "`clang-scan-deps` dependency scanner" FORCE)
    endif ()
endif ()

project(QtQuickTemplate VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_SCAN_FOR_MODULES ON)

find_package(Qt6 6.10 REQUIRED COMPONENTS Core Quick QuickControls2 Qml)
qt_policy(SET QTP0004 NEW)
qt_standard_project_setup(REQUIRES 6.10)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

if(CONAN_GENERATORS_FOLDER)
    list(PREPEND CMAKE_PREFIX_PATH "${CONAN_GENERATORS_FOLDER}")
    list(PREPEND CMAKE_MODULE_PATH "${CONAN_GENERATORS_FOLDER}")
endif()

# Ensure clang module scanning tool is configured for Clang builds.
# Some toolchains leave CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS unset.
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    if (NOT CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS OR CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS MATCHES "-NOTFOUND$")
        get_filename_component(_cxx_compiler_dir "${CMAKE_CXX_COMPILER}" DIRECTORY)
        find_program(_clang_scan_deps clang-scan-deps HINTS "${_cxx_compiler_dir}")
        if (NOT _clang_scan_deps)
            find_program(_clang_scan_deps clang-scan-deps)
        endif ()
        if (_clang_scan_deps)
            set(CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS "${_clang_scan_deps}" CACHE FILEPATH "" FORCE)
        else ()
            message(FATAL_ERROR
                "clang-scan-deps is required for C++20 modules with Clang but was not found. "
                "Install it or ensure it is available next to the selected compiler (${CMAKE_CXX_COMPILER})."
            )
        endif ()
    endif ()
endif ()

add_subdirectory(libs)

# ─────────────────────────────────────────────
# Module 3: Main application
# ─────────────────────────────────────────────
qt_add_executable(${PROJECT_NAME}
    src/main/common/main.cpp
)

target_compile_definitions(${PROJECT_NAME} PRIVATE
    APP_VERSION_STRING="${PROJECT_VERSION}"
)

# Flatten ALL qml/ paths into the module root via QT_RESOURCE_ALIAS.
# Without this, files under qml/ keep the prefix in the resource tree
# (e.g. qrc:/qt/qml/QtQuickTemplate/qml/Main.qml) and Qt.resolvedUrl()
# breaks across differently-nested files.
set(QML_ALL_FILES
    qml/Main.qml
    qml/NavigationController.qml
    qml/organisms/Header.qml
    qml/organisms/Footer.qml
    qml/templates/MainPortraitLayout.qml
    qml/templates/MainLandscapeLayout.qml
    qml/pages/Home.qml
    qml/pages/SamplePage.qml
    qml/pages/StyleShowcase.qml
)
foreach(_file ${QML_ALL_FILES})
    get_filename_component(_name "${_file}" NAME)
    set_source_files_properties("${_file}" PROPERTIES QT_RESOURCE_ALIAS "${_name}")
endforeach()

qt_add_qml_module(${PROJECT_NAME}
    URI QtQuickTemplate
    VERSION 1.0
    QML_FILES
        ${QML_ALL_FILES}
    SOURCES
        src/main/common/app_info.cpp
        include/main/common/app_info.h
    DEPENDENCIES
        AppTheme
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
    QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/platforms/android
)

# ─────────────────────────────────────────────
# Platform-specific sources & configuration
# ─────────────────────────────────────────────
if (ANDROID)
    target_sources(${PROJECT_NAME} PRIVATE
        src/main/android/platform_init_android.cpp
    )

    target_include_directories(${PROJECT_NAME} PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include/main/android
    )
elseif (WIN32)
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/platforms/windows/app.rc.in
        ${CMAKE_CURRENT_BINARY_DIR}/app.rc
        @ONLY
    )
    target_sources(${PROJECT_NAME} PRIVATE
        src/main/common/platform_init_default.cpp
        ${CMAKE_CURRENT_BINARY_DIR}/app.rc
        ${CMAKE_CURRENT_SOURCE_DIR}/platforms/windows/app.manifest
    )
elseif (APPLE AND NOT IOS)
    target_sources(${PROJECT_NAME} PRIVATE
        src/main/common/platform_init_default.cpp
    )
    set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/platforms/macos/Info.plist
    )
    if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/platforms/macos/app.icns")
        set_source_files_properties(platforms/macos/app.icns PROPERTIES
            MACOSX_PACKAGE_LOCATION "Resources"
        )
        target_sources(${PROJECT_NAME} PRIVATE platforms/macos/app.icns)
        set_target_properties(${PROJECT_NAME} PROPERTIES
            MACOSX_BUNDLE_ICON_FILE app.icns
        )
    endif ()
elseif (UNIX AND NOT APPLE AND NOT ANDROID)
    target_sources(${PROJECT_NAME} PRIVATE
        src/main/common/platform_init_default.cpp
    )
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/platforms/linux/QtQuickTemplate.desktop.in
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.desktop
        @ONLY
    )
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/platforms/linux/dev.crowell.app.template.metainfo.xml.in
        ${CMAKE_CURRENT_BINARY_DIR}/dev.crowell.app.template.metainfo.xml
        @ONLY
    )
else ()
    target_sources(${PROJECT_NAME} PRIVATE
        src/main/common/platform_init_default.cpp
    )
endif ()

target_link_libraries(${PROJECT_NAME}
    PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Qml
    apptheme
    appthemeplugin
    appstyle
    appstyleplugin
    helloworld
)

target_include_directories(${PROJECT_NAME}
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include/main/common
    ${CMAKE_CURRENT_SOURCE_DIR}/src/main/common
)

include(CheckIPOSupported)
check_ipo_supported(RESULT ipo_ok OUTPUT ipo_msg)
if (ipo_ok)
    set_property(TARGET ${PROJECT_NAME} PROPERTY INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE)
endif ()

get_target_property(_qt_bin_dir Qt6::qmake IMPORTED_LOCATION)
cmake_path(GET _qt_bin_dir PARENT_PATH _qt_bin_dir)
find_program(QDOC_EXECUTABLE qdoc HINTS "${_qt_bin_dir}" NO_DEFAULT_PATH)
if (QDOC_EXECUTABLE)
    add_custom_target(docs
        COMMAND ${CMAKE_COMMAND} -E rm -rf ${CMAKE_CURRENT_BINARY_DIR}/doc/html
        COMMAND ${QDOC_EXECUTABLE}
            ${CMAKE_CURRENT_SOURCE_DIR}/doc/qtquicktemplate.qdocconf
            -outputdir ${CMAKE_CURRENT_BINARY_DIR}/doc/html
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/doc
        COMMENT "Generating QtQuickTemplate documentation with QDoc"
    )
endif ()

include(GNUInstallDirs)
install(TARGETS ${PROJECT_NAME}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

if (UNIX AND NOT APPLE AND NOT ANDROID)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.desktop
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications
    )
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/dev.crowell.app.template.metainfo.xml
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/metainfo
    )
    # Install icons if present
    file(GLOB _linux_icons "platforms/linux/icons/*.png" "platforms/linux/icons/*.svg")
    foreach (_icon ${_linux_icons})
        get_filename_component(_icon_name "${_icon}" NAME_WE)
        # Expect filenames like 48x48.png, 256x256.png, scalable.svg
        if (_icon_name MATCHES "^([0-9]+)x([0-9]+)$")
            install(FILES "${_icon}"
                DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/${_icon_name}/apps
                RENAME dev.crowell.app.template.png
            )
        elseif (_icon_name STREQUAL "scalable")
            install(FILES "${_icon}"
                DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/apps
                RENAME dev.crowell.app.template.svg
            )
        endif ()
    endforeach ()
endif ()
