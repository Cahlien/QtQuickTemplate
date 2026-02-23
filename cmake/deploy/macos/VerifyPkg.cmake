if (NOT DEFINED ENV{MACOS_EXPORT_PATH} OR "$ENV{MACOS_EXPORT_PATH}" STREQUAL "")
    message(FATAL_ERROR "MACOS_EXPORT_PATH env var is required")
endif ()

file(GLOB _pkgs "$ENV{MACOS_EXPORT_PATH}/*.pkg")
list(LENGTH _pkgs _pkg_count)
if (_pkg_count EQUAL 0)
    message(FATAL_ERROR "No .pkg file found in $ENV{MACOS_EXPORT_PATH}")
endif ()

list(SORT _pkgs)
list(GET _pkgs -1 _pkg)
message(STATUS "Exported macOS PKG: ${_pkg}")
