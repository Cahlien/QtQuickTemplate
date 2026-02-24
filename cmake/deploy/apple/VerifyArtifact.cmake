# VerifyArtifact.cmake  —  -P script
# Verifies that at least one artifact matching the glob exists in the export path.
#
# Expected env vars:
#   EXPORT_PATH    — directory containing the exported artifact
#   ARTIFACT_GLOB  — glob pattern (e.g. *.ipa, *.pkg)

foreach (_req IN ITEMS EXPORT_PATH ARTIFACT_GLOB)
    if (NOT DEFINED ENV{${_req}} OR "$ENV{${_req}}" STREQUAL "")
        message(FATAL_ERROR "${_req} env var is required")
    endif ()
endforeach ()

file(GLOB _artifacts "$ENV{EXPORT_PATH}/$ENV{ARTIFACT_GLOB}")
list(LENGTH _artifacts _count)
if (_count EQUAL 0)
    message(FATAL_ERROR "No $ENV{ARTIFACT_GLOB} file found in $ENV{EXPORT_PATH}")
endif ()

list(SORT _artifacts)
list(GET _artifacts -1 _artifact)
message(STATUS "Verified artifact: ${_artifact}")
