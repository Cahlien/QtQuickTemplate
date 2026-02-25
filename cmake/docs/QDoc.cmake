include_guard(GLOBAL)

# Add a QDoc documentation target if the qdoc tool is available.
#   name          – custom target name (e.g. "docs")
#   qdocconf_path – absolute path to the .qdocconf file
function(add_qdoc_target name qdocconf_path)
    get_target_property(_qt_bin_dir Qt6::qmake IMPORTED_LOCATION)
    cmake_path(GET _qt_bin_dir PARENT_PATH _qt_bin_dir)
    find_program(QDOC_EXECUTABLE qdoc HINTS "${_qt_bin_dir}" NO_DEFAULT_PATH)

    if (QDOC_EXECUTABLE)
        get_filename_component(_qdocconf_dir "${qdocconf_path}" DIRECTORY)
        add_custom_target(${name}
            COMMAND ${CMAKE_COMMAND} -E rm -rf ${CMAKE_CURRENT_BINARY_DIR}/doc/html
            COMMAND ${QDOC_EXECUTABLE}
                ${qdocconf_path}
                -outputdir ${CMAKE_CURRENT_BINARY_DIR}/doc/html
            WORKING_DIRECTORY ${_qdocconf_dir}
            COMMENT "Generating documentation with QDoc"
        )

        register_help_target(
            NAME ${name}
            GROUP "Utilities"
            DESCRIPTION "Generate project documentation with QDoc"
            COMMAND "cmake --build <dir> --target ${name}"
        )
    endif ()
endfunction()
