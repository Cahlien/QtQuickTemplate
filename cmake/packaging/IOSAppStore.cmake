include_guard(GLOBAL)

set(QTQUICKTEMPLATE_IOS_ARCHIVE_CONFIGURATION "Release" CACHE STRING
    "Build configuration used for iOS archive/export"
)

function(configure_ios_app_store_release target)
    if (NOT APPLE OR NOT IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()

    if (NOT QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM)
        message(WARNING "QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM is not set; iOS App Store targets are unavailable.")
        return()
    endif ()

    find_program(XCODEBUILD_EXECUTABLE xcodebuild)
    if (NOT XCODEBUILD_EXECUTABLE)
        message(WARNING "xcodebuild not found; iOS App Store targets are unavailable.")
        return()
    endif ()

    set(_archive_path "${CMAKE_BINARY_DIR}/ios/${PROJECT_NAME}.xcarchive")
    set(_export_path "${CMAKE_BINARY_DIR}/ios/export")
    set(_export_options_plist "${CMAKE_CURRENT_BINARY_DIR}/${target}_ExportOptions.plist")

    file(WRITE "${_export_options_plist}" "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    file(APPEND "${_export_options_plist}" "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n")
    file(APPEND "${_export_options_plist}" "<plist version=\"1.0\">\n")
    file(APPEND "${_export_options_plist}" "<dict>\n")
    file(APPEND "${_export_options_plist}" "    <key>method</key>\n")
    file(APPEND "${_export_options_plist}" "    <string>app-store</string>\n")
    file(APPEND "${_export_options_plist}" "    <key>signingStyle</key>\n")
    file(APPEND "${_export_options_plist}" "    <string>automatic</string>\n")
    file(APPEND "${_export_options_plist}" "    <key>teamID</key>\n")
    file(APPEND "${_export_options_plist}" "    <string>${QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM}</string>\n")
    file(APPEND "${_export_options_plist}" "    <key>stripSwiftSymbols</key>\n")
    file(APPEND "${_export_options_plist}" "    <true/>\n")
    file(APPEND "${_export_options_plist}" "    <key>compileBitcode</key>\n")
    file(APPEND "${_export_options_plist}" "    <true/>\n")
    file(APPEND "${_export_options_plist}" "</dict>\n")
    file(APPEND "${_export_options_plist}" "</plist>\n")

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

    set(_archive_dep_target ${target})
    if (MACDEPLOYQT_EXECUTABLE)
        set(_deploy_script "${CMAKE_CURRENT_BINARY_DIR}/run_ios_macdeployqt.cmake")
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

execute_process(
    COMMAND "$ENV{MACDEPLOYQT_EXECUTABLE}" "${_bundle}" "-verbose=1"
    RESULT_VARIABLE _deploy_rv
    OUTPUT_VARIABLE _deploy_out
    ERROR_VARIABLE _deploy_err
)

if (NOT _deploy_rv EQUAL 0)
    message(FATAL_ERROR "macdeployqt failed for iOS app bundle:\n${_deploy_out}\n${_deploy_err}")
endif ()

message(STATUS "macdeployqt completed for iOS app bundle")
]=])

        add_custom_target(IOSDeployQt
            DEPENDS ${target}
            COMMAND ${CMAKE_COMMAND} -E env
                MACDEPLOYQT_EXECUTABLE=${MACDEPLOYQT_EXECUTABLE}
                APP_BUNDLE_PATH=$<TARGET_BUNDLE_DIR:${target}>
                ${CMAKE_COMMAND} -P "${_deploy_script}"
            COMMENT "Deploying iOS app bundle with macdeployqt"
            VERBATIM
        )
        message(STATUS "IOSDeployQt target configured -> cmake --build . --target IOSDeployQt")
        set(_archive_dep_target IOSDeployQt)
    endif ()

    set(_verify_script "${CMAKE_CURRENT_BINARY_DIR}/verify_ios_ipa.cmake")
    file(WRITE "${_verify_script}" [=[
if (NOT DEFINED ENV{IOS_EXPORT_PATH} OR "$ENV{IOS_EXPORT_PATH}" STREQUAL "")
    message(FATAL_ERROR "IOS_EXPORT_PATH env var is required")
endif ()

file(GLOB _ipas "$ENV{IOS_EXPORT_PATH}/*.ipa")
list(LENGTH _ipas _ipa_count)
if (_ipa_count EQUAL 0)
    message(FATAL_ERROR "No .ipa file found in $ENV{IOS_EXPORT_PATH}")
endif ()

list(SORT _ipas)
list(GET _ipas -1 _ipa)
message(STATUS "Exported iOS IPA: ${_ipa}")
]=])

    if (NOT TARGET IOSArchive)
        add_custom_target(IOSArchive
            DEPENDS ${_archive_dep_target}
            COMMAND "${XCODEBUILD_EXECUTABLE}"
                -project "${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}.xcodeproj"
                -scheme "${target}"
                -configuration "${QTQUICKTEMPLATE_IOS_ARCHIVE_CONFIGURATION}"
                -destination "generic/platform=iOS"
                -archivePath "${_archive_path}"
                archive
                -allowProvisioningUpdates
            COMMENT "Archiving iOS app for App Store distribution"
            VERBATIM
        )
        message(STATUS "IOSArchive target configured -> cmake --build . --target IOSArchive")
    endif ()

    if (NOT TARGET IOSExportIPA)
        add_custom_target(IOSExportIPA
            DEPENDS IOSArchive
            COMMAND ${CMAKE_COMMAND} -E make_directory "${_export_path}"
            COMMAND "${XCODEBUILD_EXECUTABLE}"
                -exportArchive
                -archivePath "${_archive_path}"
                -exportPath "${_export_path}"
                -exportOptionsPlist "${_export_options_plist}"
                -allowProvisioningUpdates
            COMMENT "Exporting signed iOS IPA for App Store submission"
            VERBATIM
        )
        message(STATUS "IOSExportIPA target configured -> cmake --build . --target IOSExportIPA")
    endif ()

    if (NOT TARGET VerifyIOSIPA)
        add_custom_target(VerifyIOSIPA
            DEPENDS IOSExportIPA
            COMMAND ${CMAKE_COMMAND} -E env
                IOS_EXPORT_PATH=${_export_path}
                ${CMAKE_COMMAND} -P "${_verify_script}"
            COMMENT "Verifying exported iOS IPA output"
            VERBATIM
        )
        message(STATUS "VerifyIOSIPA target configured -> cmake --build . --target VerifyIOSIPA")
    endif ()
endfunction()
