include_guard(GLOBAL)

# Must be a macro so enable_testing() runs in the caller's directory scope.
macro(configure_testing)
    if (IOS OR ANDROID)
        set(_testing_default OFF)
    else ()
        set(_testing_default ON)
    endif ()

    option(QTQUICKTEMPLATE_ENABLE_TESTING
        "Build and register unit tests (Qt Test + Qt Quick Test)"
        ${_testing_default})

    unset(_testing_default)

    if (NOT QTQUICKTEMPLATE_ENABLE_TESTING)
        message(STATUS "[testing] Unit tests disabled")
    else ()
        enable_testing()
        find_package(Qt6 6.10 REQUIRED COMPONENTS Test QuickTest)
        message(STATUS "[testing] Unit tests enabled")
    endif ()
endmacro()
