foreach (_req IN ITEMS ANDROID_PACKAGE_DIR JARSIGNER_EXECUTABLE
        QT_ANDROID_KEYSTORE_PATH QT_ANDROID_KEYSTORE_PASSWORD
        QT_ANDROID_KEY_ALIAS QT_ANDROID_KEY_PASSWORD)
    if (NOT DEFINED ENV{${_req}} OR "$ENV{${_req}}" STREQUAL "")
        message(FATAL_ERROR "${_req} env var is required")
    endif ()
endforeach ()

if (NOT EXISTS "$ENV{QT_ANDROID_KEYSTORE_PATH}")
    message(FATAL_ERROR "Android keystore does not exist: $ENV{QT_ANDROID_KEYSTORE_PATH}")
endif ()

set(_aab_dir "$ENV{ANDROID_PACKAGE_DIR}/build/outputs/bundle/release")
if (NOT EXISTS "${_aab_dir}")
    message(FATAL_ERROR "AAB output directory not found: ${_aab_dir}")
endif ()

file(GLOB _aab_files "${_aab_dir}/*.aab")
list(LENGTH _aab_files _count)
if (_count EQUAL 0)
    message(FATAL_ERROR "No AAB files found in ${_aab_dir}")
endif ()

list(SORT _aab_files)
list(GET _aab_files -1 _aab)

execute_process(
    COMMAND "$ENV{JARSIGNER_EXECUTABLE}" -verify -verbose -certs "${_aab}"
    RESULT_VARIABLE _rv OUTPUT_VARIABLE _out ERROR_VARIABLE _err
)
if (NOT _rv EQUAL 0)
    message(FATAL_ERROR "AAB signature verification failed:\n${_out}\n${_err}")
endif ()

message(STATUS "Signed Android AAB verified: ${_aab}")
