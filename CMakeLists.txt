cmake_minimum_required(VERSION 3.28)

include(cmake/toolchain/ClangScanDeps.cmake)
bootstrap_clang_scan_deps()

project(QtQuickTemplate VERSION 0.1.0 LANGUAGES CXX)

include(cmake/ProjectSetup.cmake)
include(cmake/MainApp.cmake)

configure_project()
add_subdirectory(libs)
configure_main_app()
