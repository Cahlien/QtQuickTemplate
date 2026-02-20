include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/CxxModules.cmake")

# Seed clang-scan-deps as early as possible so first configure pass has it.
# This avoids requiring a second configure/build cycle in some Android setups.
# Must be called BEFORE project().
macro(bootstrap_clang_scan_deps)
    is_apple_target(_is_apple_target)
    if (_is_apple_target)
        return()
    endif ()

    if (NOT CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS OR CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS MATCHES "-NOTFOUND$")
        set(_scan_hints)
        foreach (_ndk_var ANDROID_NDK_ROOT ANDROID_NDK_HOME ANDROID_NDK)
            if (DEFINED ENV{${_ndk_var}})
                list(APPEND _scan_hints "$ENV{${_ndk_var}}/toolchains/llvm/prebuilt/linux-x86_64/bin")
            endif ()
        endforeach ()
        find_program(_bootstrap_clang_scan_deps clang-scan-deps HINTS ${_scan_hints})
        if (_bootstrap_clang_scan_deps)
            set(CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS "${_bootstrap_clang_scan_deps}"
                CACHE FILEPATH "`clang-scan-deps` dependency scanner" FORCE)
        endif ()
    endif ()
endmacro()

# Ensure clang module scanning tool is configured for Clang builds.
# Some toolchains leave CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS unset.
# Must be called AFTER project().
macro(configure_clang_scan_deps)
    is_apple_target(_is_apple_target)
    if (_is_apple_target)
        return()
    endif ()

    if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
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
endmacro()
