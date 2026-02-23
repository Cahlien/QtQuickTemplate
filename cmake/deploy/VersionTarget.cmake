include_guard(GLOBAL)

# Creates a custom target that generates a version file via GenerateVersion.cmake.
#   target_name  — name of the custom target (e.g. GenerateIOSVersion)
#   platform     — "ios", "macos", or "android"
#   out_file     — absolute path to the generated version file
function(add_version_target target_name platform out_file)
    set(_version_script "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deploy/GenerateVersion.cmake")

    if (NOT TARGET ${target_name})
        add_custom_target(${target_name}
            COMMAND ${CMAKE_COMMAND}
                -DMAJOR=${PROJECT_VERSION_MAJOR}
                -DMINOR=${PROJECT_VERSION_MINOR}
                -DPATCH=${PROJECT_VERSION_PATCH}
                -DPLATFORM=${platform}
                -DOUT_FILE=${out_file}
                -P ${_version_script}
            COMMENT "Generating ${platform} version file"
            VERBATIM
        )
    endif ()
endfunction()
