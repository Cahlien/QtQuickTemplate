include_guard(GLOBAL)

function(configure_ios_package target)
    if (NOT APPLE OR NOT IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()

    if (NOT TARGET IOSArchive)
        return()
    endif ()

    find_program(XCODEBUILD_EXECUTABLE xcodebuild)
    if (NOT XCODEBUILD_EXECUTABLE)
        return()
    endif ()

    set(_archive_path "${CMAKE_BINARY_DIR}/ios/${PROJECT_NAME}.xcarchive")
    set(_export_path "${CMAKE_BINARY_DIR}/ios/export")
    set(_export_options "${CMAKE_CURRENT_BINARY_DIR}/${target}_ExportOptions.plist")

    if (NOT TARGET IOSExportIPA)
        add_custom_target(IOSExportIPA
            DEPENDS IOSArchive
            COMMAND ${CMAKE_COMMAND} -E make_directory "${_export_path}"
            COMMAND "${XCODEBUILD_EXECUTABLE}"
                -exportArchive
                -archivePath "${_archive_path}"
                -exportPath "${_export_path}"
                -exportOptionsPlist "${_export_options}"
                -allowProvisioningUpdates
            COMMENT "Exporting signed iOS IPA for App Store submission"
            VERBATIM
        )
        message(STATUS "IOSExportIPA target configured -> cmake --build . --target IOSExportIPA")
    endif ()
endfunction()
