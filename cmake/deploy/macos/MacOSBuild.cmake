include_guard(GLOBAL)

# MacOSBuild.cmake — Configures the MacDeployQt target that deploys Qt
# frameworks into the macOS app bundle for direct (DMG) distribution.

include("${CMAKE_CURRENT_LIST_DIR}/../apple/FindMacDeployQt.cmake")

option(QTQUICKTEMPLATE_MACOS_USE_MACDEPLOYQT "Use macdeployqt for macOS app deployment" ON)

function(configure_macos_build target)
    if (NOT APPLE OR IOS OR NOT QTQUICKTEMPLATE_MACOS_USE_MACDEPLOYQT)
        return()
    endif ()

    find_macdeployqt(MACDEPLOYQT_EXECUTABLE)
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
            QML_DIR=${CMAKE_CURRENT_SOURCE_DIR}/qml
            MACOS_APP_SIGN_IDENTITY=${QTQUICKTEMPLATE_MACOS_APP_SIGN_IDENTITY}
            ${CMAKE_COMMAND} -P "${_deploy_script}"
        COMMENT "Deploying macOS app bundle with macdeployqt"
        VERBATIM
    )

    register_help_target(
        NAME MacDeployQt
        GROUP "macOS (DMG)"
        DESCRIPTION "Deploy Qt frameworks into the macOS app bundle"
        COMMAND "cmake --build <dir> --target MacDeployQt"
    )

    message(STATUS "MacDeployQt target configured -> cmake --build . --target MacDeployQt")
endfunction()
