include_guard(GLOBAL)

set(QTQUICKTEMPLATE_ASC_API_KEY_ID "" CACHE STRING
    "App Store Connect API key ID used for IPA upload (e.g. NV3YP3T2C5)"
)

set(QTQUICKTEMPLATE_ASC_API_ISSUER_ID "" CACHE STRING
    "App Store Connect API issuer ID (UUID) used for IPA upload"
)

# configure_ios_upload_asc(target)
#
# Adds an IOSUploadASC custom target that uploads the exported IPA to
# App Store Connect using xcrun altool.  Depends on VerifyIOSIPA so it
# runs only after the full archive/export/verify chain completes.
#
# Requires:
#   QTQUICKTEMPLATE_ASC_API_KEY_ID    -- App Store Connect API key ID
#   QTQUICKTEMPLATE_ASC_API_ISSUER_ID -- App Store Connect API issuer UUID
#   AuthKey_<key_id>.p8               -- in ~/.appstoreconnect/private_keys/
#
function(configure_ios_upload_asc target)
    if (NOT APPLE OR NOT IOS OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()

    if (NOT TARGET VerifyIOSIPA)
        message(WARNING "VerifyIOSIPA target not found; IOSUploadASC target is unavailable.")
        return()
    endif ()

    if (NOT QTQUICKTEMPLATE_ASC_API_KEY_ID OR NOT QTQUICKTEMPLATE_ASC_API_ISSUER_ID)
        message(WARNING
            "QTQUICKTEMPLATE_ASC_API_KEY_ID and QTQUICKTEMPLATE_ASC_API_ISSUER_ID are not set; "
            "IOSUploadASC target is unavailable."
        )
        return()
    endif ()

    find_program(XCRUN_EXECUTABLE xcrun)
    if (NOT XCRUN_EXECUTABLE)
        message(WARNING "xcrun not found; IOSUploadASC target is unavailable.")
        return()
    endif ()

    set(_export_path "${CMAKE_BINARY_DIR}/ios/export")

    set(_upload_script "${CMAKE_CURRENT_BINARY_DIR}/upload_ios_asc.cmake")
    file(WRITE "${_upload_script}" [=[
if (NOT DEFINED ENV{XCRUN_EXECUTABLE})
    message(FATAL_ERROR "XCRUN_EXECUTABLE env var is required")
endif ()

if (NOT DEFINED ENV{IOS_EXPORT_PATH} OR "$ENV{IOS_EXPORT_PATH}" STREQUAL "")
    message(FATAL_ERROR "IOS_EXPORT_PATH env var is required")
endif ()

if (NOT DEFINED ENV{ASC_API_KEY_ID} OR "$ENV{ASC_API_KEY_ID}" STREQUAL "")
    message(FATAL_ERROR "ASC_API_KEY_ID env var is required")
endif ()

if (NOT DEFINED ENV{ASC_API_ISSUER_ID} OR "$ENV{ASC_API_ISSUER_ID}" STREQUAL "")
    message(FATAL_ERROR "ASC_API_ISSUER_ID env var is required")
endif ()

file(GLOB _ipas "$ENV{IOS_EXPORT_PATH}/*.ipa")
list(SORT _ipas)
list(GET _ipas -1 _ipa)

if (NOT EXISTS "${_ipa}")
    message(FATAL_ERROR "IPA not found in $ENV{IOS_EXPORT_PATH}")
endif ()

message(STATUS "Uploading ${_ipa} to App Store Connect...")

execute_process(
    COMMAND "$ENV{XCRUN_EXECUTABLE}" altool
        --upload-app
        -f "${_ipa}"
        --api-key "$ENV{ASC_API_KEY_ID}"
        --api-issuer "$ENV{ASC_API_ISSUER_ID}"
    RESULT_VARIABLE _upload_rv
    OUTPUT_VARIABLE _upload_out
    ERROR_VARIABLE _upload_err
)

if (NOT _upload_rv EQUAL 0)
    message(FATAL_ERROR "IPA upload to App Store Connect failed:\n${_upload_out}\n${_upload_err}")
endif ()

message(STATUS "Upload to App Store Connect succeeded")
message(STATUS "${_upload_out}${_upload_err}")
]=])

    if (NOT TARGET IOSUploadASC)
        add_custom_target(IOSUploadASC
            DEPENDS VerifyIOSIPA
            COMMAND ${CMAKE_COMMAND} -E env
                XCRUN_EXECUTABLE=${XCRUN_EXECUTABLE}
                IOS_EXPORT_PATH=${_export_path}
                ASC_API_KEY_ID=${QTQUICKTEMPLATE_ASC_API_KEY_ID}
                ASC_API_ISSUER_ID=${QTQUICKTEMPLATE_ASC_API_ISSUER_ID}
                ${CMAKE_COMMAND} -P "${_upload_script}"
            COMMENT "Uploading signed iOS IPA to App Store Connect"
            VERBATIM
        )
        message(STATUS "IOSUploadASC target configured -> cmake --build . --target IOSUploadASC")
    endif ()
endfunction()
