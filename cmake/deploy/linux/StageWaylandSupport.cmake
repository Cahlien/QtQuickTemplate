foreach (_req IN ITEMS QT_PLUGINS_DIR QT_LIB_DIR APPDIR)
    if (NOT DEFINED ENV{${_req}})
        message(FATAL_ERROR "${_req} env var is required")
    endif ()
endforeach ()

set(_plugins "$ENV{QT_PLUGINS_DIR}")
set(_lib "$ENV{QT_LIB_DIR}")
set(_appdir "$ENV{APPDIR}")

file(MAKE_DIRECTORY "${_appdir}/usr/plugins/platforms")
file(MAKE_DIRECTORY "${_appdir}/usr/plugins")
file(MAKE_DIRECTORY "${_appdir}/usr/lib")

if (EXISTS "${_plugins}/platforms/libqwayland.so")
    file(COPY "${_plugins}/platforms/libqwayland.so" DESTINATION "${_appdir}/usr/plugins/platforms")
    message(STATUS "Staged: platforms/libqwayland.so")
else ()
    message(WARNING "Wayland platform plugin not found: ${_plugins}/platforms/libqwayland.so")
endif ()

set(_integration_dirs
    wayland-graphics-integration-client
    wayland-shell-integration
    wayland-decoration-client
)
foreach (_d IN LISTS _integration_dirs)
    if (EXISTS "${_plugins}/${_d}")
        file(MAKE_DIRECTORY "${_appdir}/usr/plugins/${_d}")
        file(GLOB _children "${_plugins}/${_d}/*")
        foreach (_child IN LISTS _children)
            file(COPY "${_child}" DESTINATION "${_appdir}/usr/plugins/${_d}")
        endforeach ()
        message(STATUS "Staged: plugins/${_d}/")
    else ()
        message(STATUS "Wayland integration dir not present (skipping): ${_plugins}/${_d}")
    endif ()
endforeach ()

file(GLOB _qt_wayland_libs
    "${_lib}/libQt6WaylandClient.so*"
    "${_lib}/libQt6WaylandCompositor.so*"
)
foreach (_wl_lib IN LISTS _qt_wayland_libs)
    file(COPY "${_wl_lib}" DESTINATION "${_appdir}/usr/lib")
endforeach ()

if (_qt_wayland_libs)
    message(STATUS "Staged QtWayland libs into usr/lib")
else ()
    message(WARNING "No QtWayland libs found in ${_lib}")
endif ()
