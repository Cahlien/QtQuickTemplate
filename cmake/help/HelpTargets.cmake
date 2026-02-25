include_guard(GLOBAL)

# HelpTargets.cmake — Target registry and help-targets build target.
# Provides register_help_target() to record metadata and finalize_help_targets()
# to write the metadata file and create the help-targets custom target.

# Counter for registered targets, used to key per-target properties.
set_property(GLOBAL PROPERTY QTQUICKTEMPLATE_HELP_TARGET_COUNT 0)

# Register a target with the help system.
#
# Usage:
#   register_help_target(
#       NAME <target_name>
#       GROUP <group_label>
#       DESCRIPTION <one_line_description>
#       COMMAND <invocation_command>
#       [VARIABLES <var_line>...]
#   )
function(register_help_target)
    cmake_parse_arguments(_ht "" "NAME;GROUP;DESCRIPTION;COMMAND" "VARIABLES" ${ARGN})

    if (NOT _ht_NAME OR NOT _ht_GROUP OR NOT _ht_DESCRIPTION OR NOT _ht_COMMAND)
        message(FATAL_ERROR "register_help_target: NAME, GROUP, DESCRIPTION, and COMMAND are required")
    endif ()

    get_property(_count GLOBAL PROPERTY QTQUICKTEMPLATE_HELP_TARGET_COUNT)

    # Join variable lines with "|" as sub-delimiter
    set(_vars "")
    if (_ht_VARIABLES)
        list(JOIN _ht_VARIABLES "|" _vars)
    endif ()

    # Store each field as a separate global property to avoid CMake list-separator issues
    set_property(GLOBAL PROPERTY _QTQT_HELP_${_count}_NAME "${_ht_NAME}")
    set_property(GLOBAL PROPERTY _QTQT_HELP_${_count}_GROUP "${_ht_GROUP}")
    set_property(GLOBAL PROPERTY _QTQT_HELP_${_count}_DESC "${_ht_DESCRIPTION}")
    set_property(GLOBAL PROPERTY _QTQT_HELP_${_count}_CMD "${_ht_COMMAND}")
    set_property(GLOBAL PROPERTY _QTQT_HELP_${_count}_VARS "${_vars}")

    math(EXPR _next "${_count} + 1")
    set_property(GLOBAL PROPERTY QTQUICKTEMPLATE_HELP_TARGET_COUNT ${_next})
endfunction()

# Write the metadata file and create the help-targets custom target.
# Call once after all register_help_target() calls are complete.
function(finalize_help_targets)
    # Always register help-targets itself
    register_help_target(
        NAME help-targets
        GROUP "Utilities"
        DESCRIPTION "Show this help message"
        COMMAND "cmake --build <dir> --target help-targets"
    )

    get_property(_count GLOBAL PROPERTY QTQUICKTEMPLATE_HELP_TARGET_COUNT)

    set(_metadata_file "${CMAKE_BINARY_DIR}/help-targets.txt")
    set(_content "")
    set(_i 0)
    while (_i LESS _count)
        get_property(_name GLOBAL PROPERTY _QTQT_HELP_${_i}_NAME)
        get_property(_group GLOBAL PROPERTY _QTQT_HELP_${_i}_GROUP)
        get_property(_desc GLOBAL PROPERTY _QTQT_HELP_${_i}_DESC)
        get_property(_cmd GLOBAL PROPERTY _QTQT_HELP_${_i}_CMD)
        get_property(_vars GLOBAL PROPERTY _QTQT_HELP_${_i}_VARS)
        string(APPEND _content "${_name}\t${_group}\t${_desc}\t${_cmd}\t${_vars}\n")
        math(EXPR _i "${_i} + 1")
    endwhile ()
    file(WRITE "${_metadata_file}" "${_content}")

    set(_print_script "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/PrintHelp.cmake")

    if (NOT TARGET help-targets)
        add_custom_target(help-targets
            COMMAND ${CMAKE_COMMAND}
                -DMETADATA_FILE=${_metadata_file}
                -DPROJECT_NAME=${PROJECT_NAME}
                -P "${_print_script}"
            COMMENT "Printing available build targets"
            VERBATIM
        )
    endif ()
endfunction()
