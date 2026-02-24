cmake_minimum_required(VERSION 4.2.1)

set(CMAKE_POLICY_DEFAULT_CMP0174 NEW)

include(cmake/toolchain/ClangScanDeps.cmake)
bootstrap_clang_scan_deps()

project(QtQuickTemplate VERSION 0.2.0 LANGUAGES CXX)

include(cmake/ProjectSetup.cmake)
include(cmake/MainApp.cmake)

configure_project()
add_subdirectory(libs)
configure_main_app()
