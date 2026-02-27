include_guard(GLOBAL)

# IOSResources.cmake — iOS asset catalog and launch screen configuration.
# Provides configure_ios_asset_catalog() and configure_ios_launch_screen().

set(_IOS_RESOURCES_DIR "${CMAKE_CURRENT_LIST_DIR}")

# Configures the iOS asset catalog (AppIcon) for App Store submissions.
function(configure_ios_asset_catalog target)
    set(_src_dir "${CMAKE_CURRENT_SOURCE_DIR}")
    set(_xcassets "${_src_dir}/platforms/ios/Assets.xcassets")

    if (NOT EXISTS "${_xcassets}")
        return()
    endif ()

    target_sources(${target} PRIVATE "${_xcassets}")
    set_source_files_properties("${_xcassets}" PROPERTIES
        MACOSX_PACKAGE_LOCATION Resources
    )
    set_target_properties(${target} PROPERTIES
        XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME AppIcon
    )
endfunction()

# Generates LaunchScreen.storyboard from template with version text.
function(configure_ios_launch_screen target)
    set(_src_dir "${CMAKE_CURRENT_SOURCE_DIR}")
    set(_ls_template "${_src_dir}/platforms/ios/LaunchScreen.storyboard.in")
    set(_ls_output "${CMAKE_CURRENT_BINARY_DIR}/platforms/ios/LaunchScreen.storyboard")

    if (NOT EXISTS "${_ls_template}")
        return()
    endif ()

    configure_file("${_ls_template}" "${_ls_output}" @ONLY)
    add_custom_target(GenerateLaunchScreen ALL
        COMMAND ${CMAKE_COMMAND}
            -DPROJECT_VERSION=${PROJECT_VERSION}
            -DAPP_BUILD_NUMBER=auto
            -DTEMPLATE=${_ls_template}
            -DOUTPUT=${_ls_output}
            -P ${_IOS_RESOURCES_DIR}/GenerateLaunchScreen.cmake
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
endfunction()
