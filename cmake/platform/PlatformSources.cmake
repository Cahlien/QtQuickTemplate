include_guard(GLOBAL)

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
        # CURRENT_PROJECT_VERSION is overridden at archive time by the
        # version xcconfig (generate_version.cmake) so App Store uploads
        # auto-increment with each commit.  The value here is a fallback.
        set_target_properties(${target} PROPERTIES
            MACOSX_BUNDLE_INFO_PLIST ${_src_dir}/platforms/ios/Info.plist
            XCODE_ATTRIBUTE_MARKETING_VERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}"
            XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION "${PROJECT_VERSION}"
        )
        # Asset catalog for app icons (required by App Store).
        set(_xcassets "${_src_dir}/platforms/ios/Assets.xcassets")
        if (EXISTS "${_xcassets}")
            target_sources(${target} PRIVATE "${_xcassets}")
            set_source_files_properties("${_xcassets}" PROPERTIES
                MACOSX_PACKAGE_LOCATION Resources
            )
            set_target_properties(${target} PROPERTIES
                XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME AppIcon
            )
        endif ()
        # Generate LaunchScreen.storyboard from template with version text.
        set(_ls_template "${_src_dir}/platforms/ios/LaunchScreen.storyboard.in")
        set(_ls_output "${CMAKE_CURRENT_BINARY_DIR}/platforms/ios/LaunchScreen.storyboard")
        if (EXISTS "${_ls_template}")
            configure_file("${_ls_template}" "${_ls_output}" @ONLY)
            add_custom_target(GenerateLaunchScreen ALL
                COMMAND ${CMAKE_COMMAND}
                    -DPROJECT_VERSION=${PROJECT_VERSION}
                    -DAPP_BUILD_NUMBER=auto
                    -DTEMPLATE=${_ls_template}
                    -DOUTPUT=${_ls_output}
                    -P ${_src_dir}/scripts/generate_launchscreen.cmake
                BYPRODUCTS "${_ls_output}"
                VERBATIM
            )
            add_dependencies(${target} GenerateLaunchScreen)
            set_source_files_properties("${_ls_output}" PROPERTIES
                MACOSX_PACKAGE_LOCATION Resources
                XCODE_EXPLICIT_FILE_TYPE "file.storyboard"
            )
            target_sources(${target} PRIVATE "${_ls_output}")
            set_target_properties(${target} PROPERTIES
                QT_IOS_LAUNCH_SCREEN "${_ls_output}"
            )
        endif ()
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
            ${_src_dir}/platforms/linux/dev.crowell.app.template.metainfo.xml.in
            ${CMAKE_CURRENT_BINARY_DIR}/dev.crowell.app.template.metainfo.xml
            @ONLY
        )
    else ()
        target_sources(${target} PRIVATE
            src/main/common/platform_init_default.cpp
        )
    endif ()
endfunction()
