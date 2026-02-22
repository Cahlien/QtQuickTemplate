include_guard(GLOBAL)

function(is_apple_target out_var)
    # When CMAKE_SYSTEM_NAME is defined (e.g. by a cross-compilation toolchain
    # file), use it as the source of truth.  The APPLE variable reflects the
    # *host* platform before project() is called, so checking it first would
    # incorrectly flag an Android target as Apple when building on macOS.
    if (DEFINED CMAKE_SYSTEM_NAME)
        if (CMAKE_SYSTEM_NAME STREQUAL "Darwin"
            OR CMAKE_SYSTEM_NAME STREQUAL "iOS"
            OR CMAKE_SYSTEM_NAME STREQUAL "tvOS"
            OR CMAKE_SYSTEM_NAME STREQUAL "watchOS"
            OR CMAKE_SYSTEM_NAME STREQUAL "visionOS")
            set(${out_var} TRUE PARENT_SCOPE)
        else ()
            set(${out_var} FALSE PARENT_SCOPE)
        endif ()
    elseif (APPLE)
        set(${out_var} TRUE PARENT_SCOPE)
    else ()
        set(${out_var} FALSE PARENT_SCOPE)
    endif ()
endfunction()

function(is_cxx_modules_supported out_var)
    set(_generator_supports_modules OFF)
    if (CMAKE_GENERATOR MATCHES "^Ninja" OR CMAKE_GENERATOR MATCHES "^Visual Studio 17")
        set(_generator_supports_modules ON)
    endif ()

    set(_compiler_supports_modules OFF)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang"
        OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU"
        OR CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        set(_compiler_supports_modules ON)
    endif ()

    is_apple_target(_is_apple_target)

    if (_generator_supports_modules
        AND _compiler_supports_modules
        AND NOT _is_apple_target
        AND NOT ANDROID)
        set(${out_var} TRUE PARENT_SCOPE)
    else ()
        set(${out_var} FALSE PARENT_SCOPE)
    endif ()
endfunction()

macro(configure_cxx_modules)
    is_cxx_modules_supported(_cxx_modules_supported)
    set(QTQUICKTEMPLATE_CXX_MODULES_SUPPORTED ${_cxx_modules_supported})

    if (_cxx_modules_supported)
        set(CMAKE_CXX_SCAN_FOR_MODULES ON)
    else ()
        set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
    endif ()
endmacro()
