foreach (_req IN ITEMS XCRUN_EXECUTABLE EXPORT_PATH ARTIFACT_GLOB ASC_API_KEY_ID ASC_API_ISSUER_ID)
    if (NOT DEFINED ENV{${_req}} OR "$ENV{${_req}}" STREQUAL "")
        message(FATAL_ERROR "${_req} env var is required")
    endif ()
endforeach ()

file(GLOB _artifacts "$ENV{EXPORT_PATH}/$ENV{ARTIFACT_GLOB}")
list(SORT _artifacts)
list(GET _artifacts -1 _artifact)

if (NOT EXISTS "${_artifact}")
    message(FATAL_ERROR "Artifact not found in $ENV{EXPORT_PATH}")
endif ()

message(STATUS "Uploading ${_artifact} to App Store Connect...")

execute_process(
    COMMAND "$ENV{XCRUN_EXECUTABLE}" altool
        --upload-app
        -f "${_artifact}"
        --api-key "$ENV{ASC_API_KEY_ID}"
        --api-issuer "$ENV{ASC_API_ISSUER_ID}"
    RESULT_VARIABLE _upload_rv
    OUTPUT_VARIABLE _upload_out
    ERROR_VARIABLE _upload_err
)

set(_upload_combined "${_upload_out}${_upload_err}")

if (NOT _upload_rv EQUAL 0 OR _upload_combined MATCHES "UPLOAD FAILED")
    message(FATAL_ERROR "Upload to App Store Connect failed:\n${_upload_combined}")
endif ()

message(STATUS "Upload to App Store Connect succeeded")
message(STATUS "${_upload_combined}")
