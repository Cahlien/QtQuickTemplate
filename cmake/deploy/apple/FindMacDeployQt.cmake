include_guard(GLOBAL)

# Locates macdeployqt via the Qt6::qmake target's bin directory.
# Sets ${out_var} in the caller's scope.
function(find_macdeployqt out_var)
    get_target_property(_qmake_path Qt6::qmake IMPORTED_LOCATION)
    if (_qmake_path)
        get_filename_component(_qt_bin_dir "${_qmake_path}" DIRECTORY)
    else ()
        set(_qt_bin_dir "")
    endif ()
    find_program(_macdeployqt macdeployqt HINTS ${_qt_bin_dir})
    set(${out_var} "${_macdeployqt}" PARENT_SCOPE)
endfunction()
