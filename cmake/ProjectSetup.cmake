include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/toolchain/ClangScanDeps.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/toolchain/CompilerSettings.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/integration/Conan.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/qt/QtProject.cmake")

# Apply all project-wide settings.
# Must be called after project() and before add_subdirectory(libs).
macro(configure_project)
    configure_clang_scan_deps()
    configure_compiler_settings()
    configure_conan()
    setup_qt_project()
endmacro()
