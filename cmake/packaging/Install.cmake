include_guard(GLOBAL)

# Standard install rules for the application target.
function(configure_install target)
    include(GNUInstallDirs)

    install(TARGETS ${target}
        BUNDLE DESTINATION .
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )

    if (UNIX AND NOT APPLE AND NOT ANDROID)
        install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.desktop
            DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications
        )
        install(FILES ${CMAKE_CURRENT_BINARY_DIR}/dev.crowell.app.template.metainfo.xml
            DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/metainfo
        )

        # Install icons if present
        file(GLOB _linux_icons "platforms/linux/icons/*.png" "platforms/linux/icons/*.svg")
        foreach (_icon ${_linux_icons})
            get_filename_component(_icon_name "${_icon}" NAME_WE)
            # Expect filenames like 48x48.png, 256x256.png, scalable.svg
            if (_icon_name MATCHES "^([0-9]+)x([0-9]+)$")
                install(FILES "${_icon}"
                    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/${_icon_name}/apps
                    RENAME dev.crowell.app.template.png
                )
            elseif (_icon_name STREQUAL "scalable")
                install(FILES "${_icon}"
                    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/apps
                    RENAME dev.crowell.app.template.svg
                )
            endif ()
        endforeach ()
    endif ()
endfunction()
