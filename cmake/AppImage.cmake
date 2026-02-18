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

# Set the GPG Key ID for signing (optional).
# If not set, linuxdeploy uses the default key.
set(GPG_KEY_ID "" CACHE STRING "GPG Key ID for AppImage signing")

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

get_target_property(_qmake_path Qt6::qmake IMPORTED_LOCATION)
get_filename_component(_ld_dir "${LINUXDEPLOY_EXECUTABLE}" DIRECTORY)
get_filename_component(_qt_plugin_dir "${LINUXDEPLOY_PLUGIN_QT_EXECUTABLE}" DIRECTORY)
get_filename_component(_ai_plugin_dir "${LINUXDEPLOY_PLUGIN_APPIMAGE_EXECUTABLE}" DIRECTORY)

set(_appimage_build_dir "${CMAKE_BINARY_DIR}/AppImageBuild")
set(_appdir "${_appimage_build_dir}/AppDir")
set(_appimage_out "${_appimage_build_dir}/${PROJECT_NAME}-${PROJECT_VERSION}-x86_64.AppImage")

set(_icon_name "dev.crowell.app.template")
set(_icon_staging "${_appimage_build_dir}/${_icon_name}.png")

add_custom_target(AppImage
    DEPENDS ${PROJECT_NAME}
    COMMAND ${CMAKE_COMMAND} -E rm -rf "${_appdir}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${_appdir}/usr/lib"
    # Stage the icon under its desktop-file name so linuxdeploy resolves Icon= correctly.
    COMMAND ${CMAKE_COMMAND} -E copy
        "${CMAKE_CURRENT_SOURCE_DIR}/platforms/linux/icons/256x256.png"
        "${_icon_staging}"
    # Arch ships libtiff.so.6; Qt's bundled imageformat plugin was linked against libtiff.so.5.
    # Pre-seed AppDir/usr/lib so linuxdeploy-plugin-qt sees it as already present and skips
    # the system library search — LD_LIBRARY_PATH doesn't reach inside plugin AppImages.
    COMMAND ${CMAKE_COMMAND} -E copy /usr/lib/libtiff.so.6 "${_appdir}/usr/lib/libtiff.so.5"
    COMMAND ${CMAKE_COMMAND} -E env
        QMAKE=${_qmake_path}
        QML_SOURCES_PATHS=${CMAKE_CURRENT_SOURCE_DIR}/qml
        LINUXDEPLOY_PLUGIN_DIR=${_ld_dir}:${_qt_plugin_dir}:${_ai_plugin_dir}
        ARCH=x86_64
        OUTPUT=${_appimage_out}
        SIGN=1
        SIGN_KEY=${GPG_KEY_ID}
        NO_STRIP=1
        ${LINUXDEPLOY_EXECUTABLE}
            --appdir "${_appdir}"
            --executable "$<TARGET_FILE:${PROJECT_NAME}>"
            --desktop-file "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.desktop"
            --icon-file "${_icon_staging}"
            --plugin qt
            --output appimage
    COMMENT "Packaging ${PROJECT_NAME} ${PROJECT_VERSION} as AppImage"
    VERBATIM
)
message(STATUS "AppImage target configured → cmake --build . --target AppImage")
