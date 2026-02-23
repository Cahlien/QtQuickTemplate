if (NOT DEFINED ENV{APPDIR})
    message(FATAL_ERROR "APPDIR env var is required")
endif ()

set(_plugin "$ENV{APPDIR}/usr/plugins/platforms/libqwayland.so")

if (NOT EXISTS "${_plugin}")
    message(FATAL_ERROR "Expected Wayland platform plugin not found at: ${_plugin}")
endif ()

execute_process(
    COMMAND ldd "${_plugin}"
    RESULT_VARIABLE _rv OUTPUT_VARIABLE _out ERROR_VARIABLE _err
)
if (NOT _rv EQUAL 0)
    message(FATAL_ERROR "ldd failed for ${_plugin}\n${_err}")
endif ()

string(FIND "${_out}" "not found" _idx)
if (_idx GREATER -1)
    message(FATAL_ERROR "Wayland platform plugin has missing dependencies:\n${_out}")
else ()
    message(STATUS "Wayland platform plugin dependencies look OK")
endif ()
