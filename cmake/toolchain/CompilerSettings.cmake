include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/CxxModules.cmake")

# Project-wide compiler settings. Must be a macro so set() propagates to the
# calling directory scope.
macro(configure_compiler_settings)
    set(CMAKE_CXX_STANDARD 23)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_EXTENSIONS OFF)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

    configure_cxx_modules()
endmacro()

# Enable interprocedural optimisation for Release builds on the given target.
function(configure_ipo target)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT _ipo_ok OUTPUT _ipo_msg)
    if (_ipo_ok)
        set_property(TARGET ${target} PROPERTY INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE)
    endif ()
endfunction()
