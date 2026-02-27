include_guard(GLOBAL)

function(read_devcro_version out_var)
    set(_devcro_file "${CMAKE_SOURCE_DIR}/devcro.toml")

    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${_devcro_file}")

    file(READ "${_devcro_file}" _devcro_contents)

    string(REGEX MATCH "version[ \t]*=[ \t]*\"([0-9]+\\.[0-9]+\\.[0-9]+)\"" _match "${_devcro_contents}")

    if(NOT _match)
        message(FATAL_ERROR "read_devcro_version: could not parse version from ${_devcro_file}")
    endif()

    set(${out_var} "${CMAKE_MATCH_1}" PARENT_SCOPE)
endfunction()
