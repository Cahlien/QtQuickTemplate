include_guard(GLOBAL)

option(QTQUICKTEMPLATE_MACOS_USE_MACDEPLOYQT "Use macdeployqt for macOS app deployment" ON)

function(configure_macos_deployqt target)
    if (NOT APPLE OR IOS OR NOT QTQUICKTEMPLATE_MACOS_USE_MACDEPLOYQT)
        return()
    endif ()

    get_target_property(_qmake_path Qt6::qmake IMPORTED_LOCATION)
    if (_qmake_path)
        get_filename_component(_qt_bin_dir "${_qmake_path}" DIRECTORY)
    else ()
        set(_qt_bin_dir "")
    endif ()

    find_program(MACDEPLOYQT_EXECUTABLE
        NAMES macdeployqt
        HINTS ${_qt_bin_dir}
    )

    if (NOT MACDEPLOYQT_EXECUTABLE)
        message(WARNING "macdeployqt not found; MacDeployQt target is unavailable.")
        return()
    endif ()

    set(_deploy_script "${CMAKE_CURRENT_BINARY_DIR}/run_macdeployqt.cmake")
    file(WRITE "${_deploy_script}" [=[
if (NOT DEFINED ENV{MACDEPLOYQT_EXECUTABLE} OR "$ENV{MACDEPLOYQT_EXECUTABLE}" STREQUAL "")
    message(FATAL_ERROR "MACDEPLOYQT_EXECUTABLE env var is required")
endif ()

if (NOT DEFINED ENV{APP_BUNDLE_PATH} OR "$ENV{APP_BUNDLE_PATH}" STREQUAL "")
    message(FATAL_ERROR "APP_BUNDLE_PATH env var is required")
endif ()

set(_bundle "$ENV{APP_BUNDLE_PATH}")
if (NOT EXISTS "${_bundle}")
    message(FATAL_ERROR "App bundle not found for macdeployqt: ${_bundle}")
endif ()

set(_cmd "$ENV{MACDEPLOYQT_EXECUTABLE}" "${_bundle}" "-always-overwrite" "-verbose=1")

if (DEFINED ENV{QML_DIR} AND EXISTS "$ENV{QML_DIR}")
    list(APPEND _cmd "-qmldir=$ENV{QML_DIR}")
endif ()

if (DEFINED ENV{MACOS_APP_SIGN_IDENTITY} AND NOT "$ENV{MACOS_APP_SIGN_IDENTITY}" STREQUAL "")
    list(APPEND _cmd "-codesign=$ENV{MACOS_APP_SIGN_IDENTITY}" "-hardened-runtime" "-timestamp")
    if (DEFINED ENV{MACOS_RELEASE_ENTITLEMENTS} AND EXISTS "$ENV{MACOS_RELEASE_ENTITLEMENTS}")
        list(APPEND _cmd "-entitlements=$ENV{MACOS_RELEASE_ENTITLEMENTS}")
    endif ()
endif ()

execute_process(
    COMMAND ${_cmd}
    RESULT_VARIABLE _deploy_rv
    OUTPUT_VARIABLE _deploy_out
    ERROR_VARIABLE _deploy_err
)

if (NOT _deploy_rv EQUAL 0)
    message(FATAL_ERROR "macdeployqt failed:\n${_deploy_out}\n${_deploy_err}")
endif ()

message(STATUS "macdeployqt completed successfully")
]=])

    if (TARGET MacDeployQt)
        message(STATUS "MacDeployQt target already exists; skipping duplicate creation.")
        return()
    endif ()

    get_target_property(_release_entitlements ${target} QTQUICKTEMPLATE_MACOS_RELEASE_ENTITLEMENTS)
    if (NOT _release_entitlements)
        set(_release_entitlements "")
    endif ()

    add_custom_target(MacDeployQt
        DEPENDS ${target}
        COMMAND ${CMAKE_COMMAND} -E env
            MACDEPLOYQT_EXECUTABLE=${MACDEPLOYQT_EXECUTABLE}
            APP_BUNDLE_PATH=$<TARGET_BUNDLE_DIR:${target}>
            QML_DIR=${CMAKE_CURRENT_SOURCE_DIR}/qml
            MACOS_APP_SIGN_IDENTITY=${QTQUICKTEMPLATE_MACOS_APP_SIGN_IDENTITY}
            MACOS_RELEASE_ENTITLEMENTS=${_release_entitlements}
            ${CMAKE_COMMAND} -P "${_deploy_script}"
        COMMENT "Deploying macOS app bundle with macdeployqt"
        VERBATIM
    )

    message(STATUS "MacDeployQt target configured -> cmake --build . --target MacDeployQt")
endfunction()
