include_guard(GLOBAL)

# PlatformSources.cmake — Adds platform-specific source files, resources,
# Info.plists, icons, and desktop entries to the main app target.

include("${CMAKE_CURRENT_LIST_DIR}/../deploy/ios/IOSResources.cmake")

# Add platform-specific sources, resources, and configuration to the given target.
function(add_platform_sources target)
    set(_src_dir "${CMAKE_CURRENT_SOURCE_DIR}")

    if (ANDROID)
        target_sources(${target} PRIVATE
            src/main/android/platform_init_android.cpp
            src/main/android/android_back_handler.cpp
        )
        target_include_directories(${target} PRIVATE
            ${_src_dir}/include/main/android
        )
    elseif (WIN32)
        configure_file(
            ${_src_dir}/platforms/windows/app.rc.in
            ${CMAKE_CURRENT_BINARY_DIR}/app.rc
            @ONLY
        )
        target_sources(${target} PRIVATE
            src/main/common/platform_init_default.cpp
            ${CMAKE_CURRENT_BINARY_DIR}/app.rc
            ${_src_dir}/platforms/windows/app.manifest
        )
    elseif (IOS)
        target_sources(${target} PRIVATE
            src/main/common/platform_init_default.cpp
        )
        set_target_properties(${target} PROPERTIES
            MACOSX_BUNDLE_INFO_PLIST ${_src_dir}/platforms/ios/Info.plist
            XCODE_ATTRIBUTE_MARKETING_VERSION "${PROJECT_VERSION}"
            XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION "${PROJECT_VERSION}.${QTQUICKTEMPLATE_BUILD_NUMBER}"
        )
        configure_ios_asset_catalog(${target})
        configure_ios_launch_screen(${target})
    elseif (APPLE AND NOT IOS)
        target_sources(${target} PRIVATE
            src/main/common/platform_init_default.cpp
        )
        set_target_properties(${target} PROPERTIES
            MACOSX_BUNDLE_INFO_PLIST ${_src_dir}/platforms/macos/Info.plist
        )
        if (EXISTS "${_src_dir}/platforms/macos/app.icns")
            set_source_files_properties(platforms/macos/app.icns PROPERTIES
                MACOSX_PACKAGE_LOCATION "Resources"
            )
            target_sources(${target} PRIVATE platforms/macos/app.icns)
            set_target_properties(${target} PROPERTIES
                MACOSX_BUNDLE_ICON_FILE app.icns
            )
        endif ()
    elseif (UNIX AND NOT APPLE AND NOT ANDROID)
        target_sources(${target} PRIVATE
            src/main/common/platform_init_default.cpp
        )
        configure_file(
            ${_src_dir}/platforms/linux/QtQuickTemplate.desktop.in
            ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.desktop
            @ONLY
        )
        configure_file(
            ${_src_dir}/platforms/linux/dev.crowell.qtquicktemplate.metainfo.xml.in
            ${CMAKE_CURRENT_BINARY_DIR}/dev.crowell.qtquicktemplate.metainfo.xml
            @ONLY
        )
    else ()
        target_sources(${target} PRIVATE
            src/main/common/platform_init_default.cpp
        )
    endif ()
endfunction()
