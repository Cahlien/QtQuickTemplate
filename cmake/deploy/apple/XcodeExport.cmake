include_guard(GLOBAL)

# XcodeExport.cmake — Unified xcodebuild -exportArchive for Apple pipelines.
# Provides configure_ios_package() and configure_macos_appstore_package() which
# create targets to export signed IPA or PKG from an xcarchive.

# Private helper shared by iOS and macOS App Store export targets.
function(_configure_xcode_export target_name depends_target archive_path export_path export_options comment)
    find_program(XCODEBUILD_EXECUTABLE xcodebuild)
    if (NOT XCODEBUILD_EXECUTABLE)
        return()
    endif ()

    if (NOT TARGET ${target_name})
        add_custom_target(${target_name}
            DEPENDS ${depends_target}
            COMMAND ${CMAKE_COMMAND} -E make_directory "${export_path}"
            COMMAND "${XCODEBUILD_EXECUTABLE}"
                -exportArchive
                -archivePath "${archive_path}"
                -exportPath "${export_path}"
                -exportOptionsPlist "${export_options}"
                -allowProvisioningUpdates
            COMMENT "${comment}"
            VERBATIM
        )
        message(STATUS "${target_name} target configured -> cmake --build . --target ${target_name}")
    endif ()
endfunction()

function(configure_ios_package target)
    if (NOT APPLE OR NOT IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()
    if (NOT TARGET IOSArchive)
        return()
    endif ()
    _configure_xcode_export(IOSExportIPA IOSArchive
        "${CMAKE_BINARY_DIR}/ios/${PROJECT_NAME}.xcarchive"
        "${CMAKE_BINARY_DIR}/ios/export"
        "${CMAKE_CURRENT_BINARY_DIR}/${target}_ExportOptions.plist"
        "Exporting signed iOS IPA for App Store submission")

    if (TARGET IOSExportIPA)
        register_help_target(
            NAME IOSExportIPA
            GROUP "iOS"
            DESCRIPTION "Export signed iOS IPA from xcarchive for App Store submission"
            COMMAND "cmake --build <dir> --target IOSExportIPA"
        )
    endif ()
endfunction()

function(configure_macos_appstore_package target)
    if (NOT APPLE OR IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()
    if (NOT TARGET MacAppStoreArchive)
        return()
    endif ()
    _configure_xcode_export(MacExportPkg MacAppStoreArchive
        "${CMAKE_BINARY_DIR}/macos/${PROJECT_NAME}.xcarchive"
        "${CMAKE_BINARY_DIR}/macos/export"
        "${CMAKE_CURRENT_BINARY_DIR}/${target}_MacAppStoreExportOptions.plist"
        "Exporting signed macOS PKG for App Store submission")

    if (TARGET MacExportPkg)
        register_help_target(
            NAME MacExportPkg
            GROUP "macOS (App Store)"
            DESCRIPTION "Export signed macOS PKG from xcarchive for App Store submission"
            COMMAND "cmake --build <dir> --target MacExportPkg"
        )
    endif ()
endfunction()
