# generate_android_version.cmake  (thin wrapper kept for backwards compat)
#
# Delegates to generate_version.cmake with PLATFORM=android.
# Expected arguments (passed via -D):
#   MAJOR, MINOR, PATCH  – semantic version components
#   OUT_FILE             – absolute path to the output version.properties

set(PLATFORM "android")
include("${CMAKE_CURRENT_LIST_DIR}/generate_version.cmake")
