foreach (_req IN ITEMS ANDROID_PACKAGE_DIR APKSIGNER_EXECUTABLE)
    if (NOT DEFINED ENV{${_req}} OR "$ENV{${_req}}" STREQUAL "")
        message(FATAL_ERROR "${_req} env var is required")
    endif ()
endforeach ()

set(_apk_dir "$ENV{ANDROID_PACKAGE_DIR}/build/outputs/apk/release")
if (NOT EXISTS "${_apk_dir}")
    message(FATAL_ERROR "APK output directory not found: ${_apk_dir}")
endif ()

file(GLOB _apk_files "${_apk_dir}/*.apk")
list(LENGTH _apk_files _count)
if (_count EQUAL 0)
    message(FATAL_ERROR "No APK files found in ${_apk_dir}")
endif ()

list(SORT _apk_files)
list(GET _apk_files -1 _apk)

execute_process(
    COMMAND "$ENV{APKSIGNER_EXECUTABLE}" verify --verbose --print-certs "${_apk}"
    RESULT_VARIABLE _rv OUTPUT_VARIABLE _out ERROR_VARIABLE _err
)
if (NOT _rv EQUAL 0)
    message(FATAL_ERROR "APK signature verification failed:\n${_out}\n${_err}")
endif ()

message(STATUS "Signed Android APK verified: ${_apk}")
