include_guard(GLOBAL)

option(ENABLE_WAYLAND "Bundle Qt Wayland platform plugin into AppImage" ON)
set(GPG_KEY_ID "" CACHE STRING "GPG Key ID for AppImage signing")

function(configure_linux_package target)
    if (NOT (UNIX AND NOT APPLE AND NOT ANDROID))
        return()
    endif ()

    find_program(LINUXDEPLOY_EXECUTABLE
        NAMES linuxdeploy linuxdeploy-x86_64.AppImage linuxdeploy-x86_64.appimage
        HINTS "$ENV{HOME}/applications" "$ENV{HOME}/.local/bin" /usr/local/bin
    )
    find_program(LINUXDEPLOY_PLUGIN_QT_EXECUTABLE
        NAMES linuxdeploy-plugin-qt linuxdeploy-plugin-qt-x86_64.AppImage linuxdeploy-plugin-qt-x86_64.appimage
        HINTS "$ENV{HOME}/applications" "$ENV{HOME}/.local/bin" /usr/local/bin
    )
    find_program(LINUXDEPLOY_PLUGIN_APPIMAGE_EXECUTABLE
        NAMES linuxdeploy-plugin-appimage linuxdeploy-plugin-appimage-x86_64.AppImage linuxdeploy-plugin-appimage-x86_64.appimage
        HINTS "$ENV{HOME}/applications" "$ENV{HOME}/.local/bin" /usr/local/bin
    )

    foreach (_tool LINUXDEPLOY_EXECUTABLE LINUXDEPLOY_PLUGIN_QT_EXECUTABLE LINUXDEPLOY_PLUGIN_APPIMAGE_EXECUTABLE)
        if (NOT ${_tool})
            message(STATUS "${_tool} not found -- AppImage target unavailable")
            return()
        endif ()
    endforeach ()

    get_target_property(_qmake_path Qt6::qmake IMPORTED_LOCATION)
    get_filename_component(_qt_bin_dir "${_qmake_path}" DIRECTORY)
    get_filename_component(_qt_prefix "${_qt_bin_dir}" DIRECTORY)
    set(_qt_plugins_dir "${_qt_prefix}/plugins")
    set(_qt_lib_dir "${_qt_prefix}/lib")

    get_filename_component(_ld_dir "${LINUXDEPLOY_EXECUTABLE}" DIRECTORY)
    get_filename_component(_qt_plugin_dir "${LINUXDEPLOY_PLUGIN_QT_EXECUTABLE}" DIRECTORY)
    get_filename_component(_ai_plugin_dir "${LINUXDEPLOY_PLUGIN_APPIMAGE_EXECUTABLE}" DIRECTORY)

    set(_build_dir "${CMAKE_BINARY_DIR}/AppImageBuild")
    set(_appdir "${_build_dir}/AppDir")
    set(_appimage_out "${_build_dir}/${PROJECT_NAME}-${PROJECT_VERSION}-x86_64.AppImage")
    set(_icon_name "dev.crowell.qtquicktemplate")
    set(_icon_staging "${_build_dir}/${_icon_name}.png")

    file(MAKE_DIRECTORY "${_build_dir}")
    file(WRITE "${_build_dir}/qt.conf"
        "[Paths]\nPrefix=..\nPlugins=plugins\nQml2Imports=qml\nLibraries=lib\n")
    file(REMOVE "${CMAKE_CURRENT_BINARY_DIR}/qt.conf")

    set(_stage_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/linux/StageWaylandSupport.cmake")
    set(_verify_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/linux/VerifyWaylandDeps.cmake")

    add_custom_target(AppImage
        DEPENDS ${target}
        COMMAND ${CMAKE_COMMAND} -E rm -rf "${_appdir}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${_appdir}/usr/lib"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${_build_dir}"
        COMMAND ${CMAKE_COMMAND} -E copy
            "${CMAKE_CURRENT_SOURCE_DIR}/platforms/linux/icons/256x256.png"
            "${_icon_staging}"
        COMMAND ${CMAKE_COMMAND} -E copy /usr/lib/libtiff.so.6 "${_appdir}/usr/lib/libtiff.so.5"

        COMMAND ${CMAKE_COMMAND} -E env
            QT_PLUGINS_DIR=${_qt_plugins_dir} QT_LIB_DIR=${_qt_lib_dir} APPDIR=${_appdir}
            ${CMAKE_COMMAND} -P "${_stage_script}"

        COMMAND ${CMAKE_COMMAND} -E env
            QMAKE=${_qmake_path}
            QML_SOURCES_PATHS=${CMAKE_CURRENT_SOURCE_DIR}/ui
            LINUXDEPLOY_PLUGIN_DIR=${_ld_dir}:${_qt_plugin_dir}:${_ai_plugin_dir}
            ARCH=x86_64 NO_STRIP=1
            ${LINUXDEPLOY_EXECUTABLE}
                --appdir "${_appdir}"
                --executable "$<TARGET_FILE:${target}>"
                --desktop-file "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.desktop"
                --icon-file "${_icon_staging}"
                --plugin qt

        COMMAND ${CMAKE_COMMAND} -E make_directory "${_appdir}/usr/bin"
        COMMAND ${CMAKE_COMMAND} -E copy "${_build_dir}/qt.conf" "${_appdir}/usr/bin/qt.conf"

        COMMAND ${CMAKE_COMMAND} -E env APPDIR=${_appdir}
            ${CMAKE_COMMAND} -P "${_verify_script}"

        COMMAND ${CMAKE_COMMAND} -E env
            LINUXDEPLOY_PLUGIN_DIR=${_ld_dir}:${_qt_plugin_dir}:${_ai_plugin_dir}
            ARCH=x86_64
            OUTPUT=${_appimage_out} SIGN=1 SIGN_KEY=${GPG_KEY_ID}
            LDAI_OUTPUT=${_appimage_out} LDAI_SIGN=1 LDAI_SIGN_KEY=${GPG_KEY_ID}
            NO_STRIP=1
            ${LINUXDEPLOY_EXECUTABLE}
                --appdir "${_appdir}"
                --output appimage

        COMMENT "Packaging ${PROJECT_NAME} ${PROJECT_VERSION} as AppImage"
        VERBATIM
    )

    message(STATUS "AppImage target configured -> cmake --build . --target AppImage")
endfunction()
