include_guard(GLOBAL)

function(configure_macos_appstore_package target)
    if (NOT APPLE OR IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()

    if (NOT TARGET MacAppStoreArchive)
        return()
    endif ()

    find_program(XCODEBUILD_EXECUTABLE xcodebuild)
    if (NOT XCODEBUILD_EXECUTABLE)
        return()
    endif ()

    set(_archive_path "${CMAKE_BINARY_DIR}/macos/${PROJECT_NAME}.xcarchive")
    set(_export_path "${CMAKE_BINARY_DIR}/macos/export")
    set(_export_options "${CMAKE_CURRENT_BINARY_DIR}/${target}_MacAppStoreExportOptions.plist")

    if (NOT TARGET MacExportPkg)
        add_custom_target(MacExportPkg
            DEPENDS MacAppStoreArchive
            COMMAND ${CMAKE_COMMAND} -E make_directory "${_export_path}"
            COMMAND "${XCODEBUILD_EXECUTABLE}"
                -exportArchive
                -archivePath "${_archive_path}"
                -exportPath "${_export_path}"
                -exportOptionsPlist "${_export_options}"
                -allowProvisioningUpdates
            COMMENT "Exporting signed macOS PKG for App Store submission"
            VERBATIM
        )
        message(STATUS "MacExportPkg target configured -> cmake --build . --target MacExportPkg")
    endif ()
endfunction()
