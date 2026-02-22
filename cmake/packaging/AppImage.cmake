include_guard(GLOBAL)

# AppImage packaging for Linux desktop builds.
#
# Defines an "AppImage" custom target when linuxdeploy, linuxdeploy-plugin-qt,
# and linuxdeploy-plugin-appimage are all found on the system.
#
# Usage:
#   cmake --build <build-dir> --target AppImage
#
# Output:
#   <build-dir>/AppImageBuild/<PROJECT_NAME>-<VERSION>-x86_64.AppImage
#
# Required tools (place in ~/applications, ~/.local/bin, or /usr/local/bin):
#   linuxdeploy                 https://github.com/linuxdeploy/linuxdeploy/releases
#   linuxdeploy-plugin-qt       https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases
#   linuxdeploy-plugin-appimage https://github.com/linuxdeploy/linuxdeploy-plugin-appimage/releases

# ──────────────────────────────────────────────────────────────────────────────
# Options (file scope — outside function so cache vars are always registered)
# ──────────────────────────────────────────────────────────────────────────────

option(ENABLE_WAYLAND "Bundle Qt Wayland platform plugin into AppImage" ON)

# Set the GPG Key ID for signing (optional).
# If not set, linuxdeploy-plugin-appimage uses the default key.
set(GPG_KEY_ID "" CACHE STRING "GPG Key ID for AppImage signing")

# ──────────────────────────────────────────────────────────────────────────────

function(configure_appimage target)
    if (NOT (UNIX AND NOT APPLE AND NOT ANDROID))
        return()
    endif ()

    find_program(LINUXDEPLOY_EXECUTABLE
        NAMES linuxdeploy linuxdeploy-x86_64.AppImage linuxdeploy-x86_64.appimage
        HINTS "$ENV{HOME}/applications" "$ENV{HOME}/.local/bin" /usr/local/bin
        DOC "linuxdeploy AppDir/AppImage tool"
    )
    find_program(LINUXDEPLOY_PLUGIN_QT_EXECUTABLE
        NAMES linuxdeploy-plugin-qt linuxdeploy-plugin-qt-x86_64.AppImage linuxdeploy-plugin-qt-x86_64.appimage
        HINTS "$ENV{HOME}/applications" "$ENV{HOME}/.local/bin" /usr/local/bin
        DOC "linuxdeploy Qt plugin"
    )
    find_program(LINUXDEPLOY_PLUGIN_APPIMAGE_EXECUTABLE
        NAMES linuxdeploy-plugin-appimage linuxdeploy-plugin-appimage-x86_64.AppImage linuxdeploy-plugin-appimage-x86_64.appimage
        HINTS "$ENV{HOME}/applications" "$ENV{HOME}/.local/bin" /usr/local/bin
        DOC "linuxdeploy AppImage plugin"
    )

    set(_required LINUXDEPLOY_EXECUTABLE LINUXDEPLOY_PLUGIN_QT_EXECUTABLE LINUXDEPLOY_PLUGIN_APPIMAGE_EXECUTABLE)
    foreach (_tool ${_required})
        if (NOT ${_tool})
            message(STATUS "${_tool} not found — AppImage target unavailable")
        endif ()
    endforeach ()

    foreach (_tool ${_required})
        if (NOT ${_tool})
            return()
        endif ()
    endforeach ()

    # Derive Qt prefix from qmake location (works with commercial installs)
    get_target_property(_qmake_path Qt6::qmake IMPORTED_LOCATION)
    get_filename_component(_qt_bin_dir "${_qmake_path}" DIRECTORY)
    get_filename_component(_qt_prefix "${_qt_bin_dir}" DIRECTORY)
    set(_qt_plugins_dir "${_qt_prefix}/plugins")
    set(_qt_lib_dir "${_qt_prefix}/lib")

    get_filename_component(_ld_dir "${LINUXDEPLOY_EXECUTABLE}" DIRECTORY)
    get_filename_component(_qt_plugin_dir "${LINUXDEPLOY_PLUGIN_QT_EXECUTABLE}" DIRECTORY)
    get_filename_component(_ai_plugin_dir "${LINUXDEPLOY_PLUGIN_APPIMAGE_EXECUTABLE}" DIRECTORY)

    set(_appimage_build_dir "${CMAKE_BINARY_DIR}/AppImageBuild")
    set(_appdir "${_appimage_build_dir}/AppDir")
    set(_appimage_out "${_appimage_build_dir}/${PROJECT_NAME}-${PROJECT_VERSION}-x86_64.AppImage")

    set(_icon_name "dev.crowell.qtquicktemplate")
    set(_icon_staging "${_appimage_build_dir}/${_icon_name}.png")

    # qt.conf generated at configure time
    file(MAKE_DIRECTORY "${_appimage_build_dir}")
    set(_qt_conf_template "${_appimage_build_dir}/qt.conf")
    file(WRITE "${_qt_conf_template}"
"[Paths]\n"
"Prefix=..\n"
"Plugins=plugins\n"
"Qml2Imports=qml\n"
"Libraries=lib\n"
    )

    # Remove legacy qt.conf in the top-level build dir if present.
    # That file causes unpackaged runs from the build tree to search
    # for plugins under <build>/plugins instead of the Qt installation.
    file(REMOVE "${CMAKE_CURRENT_BINARY_DIR}/qt.conf")

    # Stage Wayland plugins + QtWayland libs into AppDir BEFORE linuxdeploy harvests dependencies.
    set(_stage_wayland_script "${CMAKE_CURRENT_BINARY_DIR}/stage_wayland_support.cmake")
    file(WRITE "${_stage_wayland_script}" "
if(NOT DEFINED ENV{QT_PLUGINS_DIR} OR NOT DEFINED ENV{QT_LIB_DIR} OR NOT DEFINED ENV{APPDIR})
  message(FATAL_ERROR \"QT_PLUGINS_DIR, QT_LIB_DIR and APPDIR env vars are required\")
endif()

set(qt_plugins_dir \"\$ENV{QT_PLUGINS_DIR}\")
set(qt_lib_dir \"\$ENV{QT_LIB_DIR}\")
set(appdir \"\$ENV{APPDIR}\")

file(MAKE_DIRECTORY \"\${appdir}/usr/plugins/platforms\")
file(MAKE_DIRECTORY \"\${appdir}/usr/plugins\")
file(MAKE_DIRECTORY \"\${appdir}/usr/lib\")

# 1) Platform plugin
if(EXISTS \"\${qt_plugins_dir}/platforms/libqwayland.so\")
  file(COPY \"\${qt_plugins_dir}/platforms/libqwayland.so\" DESTINATION \"\${appdir}/usr/plugins/platforms\")
  message(STATUS \"Staged: platforms/libqwayland.so\")
else()
  message(WARNING \"Wayland platform plugin not found: \${qt_plugins_dir}/platforms/libqwayland.so\")
endif()

# 2) Wayland integration plugin directories (if present)
set(integration_dirs
  wayland-graphics-integration-client
  wayland-shell-integration
  wayland-decoration-client
)

foreach(d IN LISTS integration_dirs)
  if(EXISTS \"\${qt_plugins_dir}/\${d}\")
    file(MAKE_DIRECTORY \"\${appdir}/usr/plugins/\${d}\")
    file(GLOB children \"\${qt_plugins_dir}/\${d}/*\")
    foreach(child IN LISTS children)
      file(COPY \"\${child}\" DESTINATION \"\${appdir}/usr/plugins/\${d}\")
    endforeach()
    message(STATUS \"Staged: plugins/\${d}/\")
  else()
    message(STATUS \"Wayland integration dir not present (skipping): \${qt_plugins_dir}/\${d}\")
  endif()
endforeach()

# 3) QtWayland runtime libs (the usual missing link that makes 'found but not loadable')
file(GLOB qt_wayland_libs
  \"\${qt_lib_dir}/libQt6WaylandClient.so*\"
  \"\${qt_lib_dir}/libQt6WaylandCompositor.so*\"
)
foreach(lib IN LISTS qt_wayland_libs)
  file(COPY \"\${lib}\" DESTINATION \"\${appdir}/usr/lib\")
endforeach()

if(qt_wayland_libs)
  message(STATUS \"Staged QtWayland libs into usr/lib\")
else()
  message(WARNING \"No QtWayland libs found in \${qt_lib_dir} (qtwayland module may be missing?)\")
endif()
")

    # Verify that libqwayland.so is loadable (no missing deps) inside the staged AppDir
    set(_verify_wayland_script "${CMAKE_CURRENT_BINARY_DIR}/verify_wayland_deps.cmake")
    file(WRITE "${_verify_wayland_script}" "
if(NOT DEFINED ENV{APPDIR})
  message(FATAL_ERROR \"APPDIR env var is required\")
endif()
set(appdir \"\$ENV{APPDIR}\")
set(plugin \"\${appdir}/usr/plugins/platforms/libqwayland.so\")

if(NOT EXISTS \"\${plugin}\")
  message(FATAL_ERROR \"Expected Wayland platform plugin not found at: \${plugin}\")
endif()

execute_process(COMMAND ldd \"\${plugin}\"
  RESULT_VARIABLE rv
  OUTPUT_VARIABLE out
  ERROR_VARIABLE err
)

if(NOT rv EQUAL 0)
  message(FATAL_ERROR \"ldd failed for \${plugin}\\n\${err}\")
endif()

string(FIND \"\${out}\" \"not found\" idx)
if(idx GREATER -1)
  message(FATAL_ERROR \"Wayland platform plugin has missing dependencies:\\n\${out}\")
else()
  message(STATUS \"Wayland platform plugin dependencies look OK\")
endif()
")

    add_custom_target(AppImage
        DEPENDS ${target}

        COMMAND ${CMAKE_COMMAND} -E rm -rf "${_appdir}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${_appdir}/usr/lib"

        # Stage icon under its desktop-file name so linuxdeploy resolves Icon= correctly
        COMMAND ${CMAKE_COMMAND} -E make_directory "${_appimage_build_dir}"
        COMMAND ${CMAKE_COMMAND} -E copy
            "${CMAKE_CURRENT_SOURCE_DIR}/platforms/linux/icons/256x256.png"
            "${_icon_staging}"

        # Arch ships libtiff.so.6; Qt imageformat plugin may be linked against libtiff.so.5
        COMMAND ${CMAKE_COMMAND} -E copy /usr/lib/libtiff.so.6 "${_appdir}/usr/lib/libtiff.so.5"

        # ─────────────────────────────────────────────────────────────────────────
        # PRE-STAGE WAYLAND (so linuxdeploy-plugin-qt will harvest its dependencies)
        # ─────────────────────────────────────────────────────────────────────────
        COMMAND ${CMAKE_COMMAND} -E env
            QT_PLUGINS_DIR=${_qt_plugins_dir}
            QT_LIB_DIR=${_qt_lib_dir}
            APPDIR=${_appdir}
            ${CMAKE_COMMAND} -P "${_stage_wayland_script}"

        # ─────────────────────────────────────────────────────────────────────────
        # Phase 1: Populate AppDir (no AppImage output yet)
        # ─────────────────────────────────────────────────────────────────────────
        COMMAND ${CMAKE_COMMAND} -E env
            QMAKE=${_qmake_path}
            QML_SOURCES_PATHS=${CMAKE_CURRENT_SOURCE_DIR}/qml
            LINUXDEPLOY_PLUGIN_DIR=${_ld_dir}:${_qt_plugin_dir}:${_ai_plugin_dir}
            ARCH=x86_64
            NO_STRIP=1
            ${LINUXDEPLOY_EXECUTABLE}
                --appdir "${_appdir}"
                --executable "$<TARGET_FILE:${target}>"
                --desktop-file "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.desktop"
                --icon-file "${_icon_staging}"
                --plugin qt

        # Ensure qt.conf exists next to the executable inside AppDir/usr/bin
        COMMAND ${CMAKE_COMMAND} -E make_directory "${_appdir}/usr/bin"
        COMMAND ${CMAKE_COMMAND} -E copy "${_qt_conf_template}" "${_appdir}/usr/bin/qt.conf"

        # Verify Wayland plugin deps are satisfied *inside the AppDir*
        COMMAND ${CMAKE_COMMAND} -E env
            APPDIR=${_appdir}
            ${CMAKE_COMMAND} -P "${_verify_wayland_script}"

        # ─────────────────────────────────────────────────────────────────────────
        # Phase 2: Create the AppImage from the populated + verified AppDir
        # ─────────────────────────────────────────────────────────────────────────
        COMMAND ${CMAKE_COMMAND} -E env
            LINUXDEPLOY_PLUGIN_DIR=${_ld_dir}:${_qt_plugin_dir}:${_ai_plugin_dir}
            ARCH=x86_64

            OUTPUT=${_appimage_out}
            SIGN=1
            SIGN_KEY=${GPG_KEY_ID}

            LDAI_OUTPUT=${_appimage_out}
            LDAI_SIGN=1
            LDAI_SIGN_KEY=${GPG_KEY_ID}

            NO_STRIP=1
            ${LINUXDEPLOY_EXECUTABLE}
                --appdir "${_appdir}"
                --output appimage

        COMMENT "Packaging ${PROJECT_NAME} ${PROJECT_VERSION} as AppImage (Wayland staged + deps verified)"
        VERBATIM
    )

    message(STATUS "AppImage target configured → cmake --build . --target AppImage")
endfunction()
