include_guard(GLOBAL)

option(QTQUICKTEMPLATE_MACOS_USE_MACDEPLOYQT "Use macdeployqt for macOS app deployment" ON)

function(configure_macos_build target)
    if (NOT APPLE OR IOS OR NOT QTQUICKTEMPLATE_MACOS_USE_MACDEPLOYQT)
        return()
    endif ()

    get_target_property(_qmake_path Qt6::qmake IMPORTED_LOCATION)
    if (_qmake_path)
        get_filename_component(_qt_bin_dir "${_qmake_path}" DIRECTORY)
    else ()
        set(_qt_bin_dir "")
    endif ()

    find_program(MACDEPLOYQT_EXECUTABLE macdeployqt HINTS ${_qt_bin_dir})
    if (NOT MACDEPLOYQT_EXECUTABLE)
        message(WARNING "macdeployqt not found; MacDeployQt target unavailable.")
        return()
    endif ()

    set(_deploy_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/macos/RunMacDeployQt.cmake")

    if (TARGET MacDeployQt)
        return()
    endif ()

    add_custom_target(MacDeployQt
        DEPENDS ${target}
        COMMAND ${CMAKE_COMMAND} -E env
            MACDEPLOYQT_EXECUTABLE=${MACDEPLOYQT_EXECUTABLE}
            APP_BUNDLE_PATH=$<TARGET_BUNDLE_DIR:${target}>
            QML_DIR=${CMAKE_CURRENT_SOURCE_DIR}/ui
            MACOS_APP_SIGN_IDENTITY=${QTQUICKTEMPLATE_MACOS_APP_SIGN_IDENTITY}
            ${CMAKE_COMMAND} -P "${_deploy_script}"
        COMMENT "Deploying macOS app bundle with macdeployqt"
        VERBATIM
    )

    message(STATUS "MacDeployQt target configured -> cmake --build . --target MacDeployQt")
endfunction()
