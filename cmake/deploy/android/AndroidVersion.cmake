include_guard(GLOBAL)

# AndroidVersion.cmake — Creates the GenerateAndroidVersion target that writes
# platforms/android/version.properties from the project version.

set(_ANDROID_VERSION_DIR "${CMAKE_CURRENT_LIST_DIR}")

# Add a custom target that generates platforms/android/version.properties
# from the project version, and make the given target depend on it.
function(add_android_version_target target)
    set(_ver_file "${CMAKE_CURRENT_SOURCE_DIR}/platforms/android/version.properties")

    add_custom_target(GenerateAndroidVersion ALL
        COMMAND ${CMAKE_COMMAND}
            -DMAJOR=${PROJECT_VERSION_MAJOR}
            -DMINOR=${PROJECT_VERSION_MINOR}
            -DPATCH=${PROJECT_VERSION_PATCH}
            -DOUT_FILE=${_ver_file}
            -P ${_ANDROID_VERSION_DIR}/GenerateVersion.cmake
        COMMENT "Generating Android version.properties -> ${_ver_file}"
        VERBATIM
    )
    add_dependencies(${target} GenerateAndroidVersion)
endfunction()
