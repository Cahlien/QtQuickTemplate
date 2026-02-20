include_guard(GLOBAL)

# Prepend Conan generator paths when CONAN_GENERATORS_FOLDER is set.
# Must be a macro so CMAKE_PREFIX_PATH / CMAKE_MODULE_PATH changes propagate.
macro(configure_conan)
    if (CONAN_GENERATORS_FOLDER)
        list(PREPEND CMAKE_PREFIX_PATH "${CONAN_GENERATORS_FOLDER}")
        list(PREPEND CMAKE_MODULE_PATH "${CONAN_GENERATORS_FOLDER}")
    endif ()
endmacro()
