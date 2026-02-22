include_guard(GLOBAL)

# Note: QTQUICKTEMPLATE_ASC_API_KEY_ID and QTQUICKTEMPLATE_ASC_API_ISSUER_ID are
# defined in IOSAppStoreConnect.cmake.  If this file is included without it,
# define them here as a fallback so the cache variables always exist.
if (NOT DEFINED CACHE{QTQUICKTEMPLATE_ASC_API_KEY_ID})
    set(QTQUICKTEMPLATE_ASC_API_KEY_ID "" CACHE STRING
        "App Store Connect API key ID used for upload (e.g. ABCD123456)"
    )
endif ()

if (NOT DEFINED CACHE{QTQUICKTEMPLATE_ASC_API_ISSUER_ID})
    set(QTQUICKTEMPLATE_ASC_API_ISSUER_ID "" CACHE STRING
        "App Store Connect API issuer ID (UUID) used for upload"
    )
endif ()

# configure_macos_upload_asc(target)
#
# Adds a MacUploadASC custom target that uploads the exported .pkg to
# App Store Connect using xcrun altool.  Depends on VerifyMacPkg so it
# runs only after the full archive/export/verify chain completes.
#
function(configure_macos_upload_asc target)
    if (NOT APPLE OR IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()

    if (NOT TARGET VerifyMacPkg)
        message(WARNING "VerifyMacPkg target not found; MacUploadASC target is unavailable.")
        return()
    endif ()

    if (NOT QTQUICKTEMPLATE_ASC_API_KEY_ID OR NOT QTQUICKTEMPLATE_ASC_API_ISSUER_ID)
        message(WARNING
            "QTQUICKTEMPLATE_ASC_API_KEY_ID and QTQUICKTEMPLATE_ASC_API_ISSUER_ID are not set; "
            "MacUploadASC target is unavailable."
        )
        return()
    endif ()

    find_program(XCRUN_EXECUTABLE xcrun)
    if (NOT XCRUN_EXECUTABLE)
        message(WARNING "xcrun not found; MacUploadASC target is unavailable.")
        return()
    endif ()

    set(_export_path "${CMAKE_BINARY_DIR}/macos/export")

    set(_upload_script "${CMAKE_CURRENT_BINARY_DIR}/upload_macos_asc.cmake")
    file(WRITE "${_upload_script}" [=[
if (NOT DEFINED ENV{XCRUN_EXECUTABLE})
    message(FATAL_ERROR "XCRUN_EXECUTABLE env var is required")
endif ()

if (NOT DEFINED ENV{MACOS_EXPORT_PATH} OR "$ENV{MACOS_EXPORT_PATH}" STREQUAL "")
    message(FATAL_ERROR "MACOS_EXPORT_PATH env var is required")
endif ()

if (NOT DEFINED ENV{ASC_API_KEY_ID} OR "$ENV{ASC_API_KEY_ID}" STREQUAL "")
    message(FATAL_ERROR "ASC_API_KEY_ID env var is required")
endif ()

if (NOT DEFINED ENV{ASC_API_ISSUER_ID} OR "$ENV{ASC_API_ISSUER_ID}" STREQUAL "")
    message(FATAL_ERROR "ASC_API_ISSUER_ID env var is required")
endif ()

file(GLOB _pkgs "$ENV{MACOS_EXPORT_PATH}/*.pkg")
list(SORT _pkgs)
list(GET _pkgs -1 _pkg)

if (NOT EXISTS "${_pkg}")
    message(FATAL_ERROR "PKG not found in $ENV{MACOS_EXPORT_PATH}")
endif ()

message(STATUS "Uploading ${_pkg} to App Store Connect...")

execute_process(
    COMMAND "$ENV{XCRUN_EXECUTABLE}" altool
        --upload-app
        -f "${_pkg}"
        --api-key "$ENV{ASC_API_KEY_ID}"
        --api-issuer "$ENV{ASC_API_ISSUER_ID}"
    RESULT_VARIABLE _upload_rv
    OUTPUT_VARIABLE _upload_out
    ERROR_VARIABLE _upload_err
)

set(_upload_combined "${_upload_out}${_upload_err}")

# altool occasionally returns exit code 0 even for validation/upload failures.
# Detect "UPLOAD FAILED" in the combined output as a belt-and-suspenders check.
if (NOT _upload_rv EQUAL 0 OR _upload_combined MATCHES "UPLOAD FAILED")
    message(FATAL_ERROR "PKG upload to App Store Connect failed:\n${_upload_combined}")
endif ()

message(STATUS "Upload to App Store Connect succeeded")
message(STATUS "${_upload_combined}")
]=])

    if (NOT TARGET MacUploadASC)
        add_custom_target(MacUploadASC
            DEPENDS VerifyMacPkg
            COMMAND ${CMAKE_COMMAND} -E env
                XCRUN_EXECUTABLE=${XCRUN_EXECUTABLE}
                MACOS_EXPORT_PATH=${_export_path}
                ASC_API_KEY_ID=${QTQUICKTEMPLATE_ASC_API_KEY_ID}
                ASC_API_ISSUER_ID=${QTQUICKTEMPLATE_ASC_API_ISSUER_ID}
                ${CMAKE_COMMAND} -P "${_upload_script}"
            COMMENT "Uploading signed macOS PKG to App Store Connect"
            VERBATIM
        )
        message(STATUS "MacUploadASC target configured -> cmake --build . --target MacUploadASC")
    endif ()
endfunction()
