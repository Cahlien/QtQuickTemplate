cmake_minimum_required(VERSION 4.2.1)

set(CMAKE_POLICY_DEFAULT_CMP0174 NEW)

include(cmake/toolchain/ClangScanDeps.cmake)
bootstrap_clang_scan_deps()

project(QtQuickTemplate LANGUAGES CXX)          # no VERSION — app/ owns it

include(cmake/ProjectSetup.cmake)

configure_project()
add_subdirectory(app)
