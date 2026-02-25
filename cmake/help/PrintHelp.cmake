# PrintHelp.cmake -- Script-mode (-P) printer for help-targets metadata.
# Expected defines: METADATA_FILE, PROJECT_NAME
#
# The metadata file uses tab-delimited records:
#   NAME\tGROUP\tDESCRIPTION\tCOMMAND\tVARIABLES
# where VARIABLES uses "|" as a sub-delimiter between entries.

if (NOT DEFINED METADATA_FILE OR NOT EXISTS "${METADATA_FILE}")
    message(FATAL_ERROR "PrintHelp.cmake: METADATA_FILE not set or does not exist")
endif ()

if (NOT DEFINED PROJECT_NAME)
    set(PROJECT_NAME "Project")
endif ()

file(STRINGS "${METADATA_FILE}" _lines)

# Parse entries into per-group lists
set(_groups "")
set(_entry_count 0)
foreach (_line IN LISTS _lines)
    # Skip empty lines
    if ("${_line}" STREQUAL "")
        continue()
    endif ()

    # Split on tab character
    string(REPLACE "\t" ";" _parts "${_line}")
    list(LENGTH _parts _len)
    if (_len LESS 4)
        continue()
    endif ()

    list(GET _parts 0 _name)
    list(GET _parts 1 _group)
    list(GET _parts 2 _desc)
    list(GET _parts 3 _cmd)
    set(_vars "")
    if (_len GREATER 4)
        list(GET _parts 4 _vars)
    endif ()

    # Track group ordering
    list(FIND _groups "${_group}" _idx)
    if (_idx EQUAL -1)
        list(APPEND _groups "${_group}")
    endif ()

    # Store entry data indexed by group
    string(MAKE_C_IDENTIFIER "${_group}" _gid)
    list(APPEND _group_${_gid}_names "${_name}")
    set(_entry_${_name}_desc "${_desc}")
    set(_entry_${_name}_cmd "${_cmd}")
    set(_entry_${_name}_vars "${_vars}")
    math(EXPR _entry_count "${_entry_count} + 1")
endforeach ()

if (_entry_count EQUAL 0)
    message("")
    message("=== ${PROJECT_NAME} -- No custom targets available ===")
    message("")
    return()
endif ()

# Print formatted output
message("")
message("=== ${PROJECT_NAME} -- Available Targets ===")

foreach (_group IN LISTS _groups)
    message("")
    message("--- ${_group} ---")
    message("")

    string(MAKE_C_IDENTIFIER "${_group}" _gid)
    foreach (_name IN LISTS _group_${_gid}_names)
        message("  ${_name}")
        message("    ${_entry_${_name}_desc}")
        message("    Command:   ${_entry_${_name}_cmd}")

        set(_vars "${_entry_${_name}_vars}")
        if (NOT "${_vars}" STREQUAL "")
            message("    Variables:")
            string(REPLACE "|" ";" _var_list "${_vars}")
            foreach (_v IN LISTS _var_list)
                message("      ${_v}")
            endforeach ()
        endif ()

        message("")
    endforeach ()
endforeach ()
