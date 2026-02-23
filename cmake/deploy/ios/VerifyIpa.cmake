if (NOT DEFINED ENV{IOS_EXPORT_PATH} OR "$ENV{IOS_EXPORT_PATH}" STREQUAL "")
    message(FATAL_ERROR "IOS_EXPORT_PATH env var is required")
endif ()

file(GLOB _ipas "$ENV{IOS_EXPORT_PATH}/*.ipa")
list(LENGTH _ipas _ipa_count)
if (_ipa_count EQUAL 0)
    message(FATAL_ERROR "No .ipa file found in $ENV{IOS_EXPORT_PATH}")
endif ()

list(SORT _ipas)
list(GET _ipas -1 _ipa)
message(STATUS "Exported iOS IPA: ${_ipa}")
