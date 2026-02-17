# generate_android_version.cmake
#
# Generates platforms/android/version.properties from the CMake project
# version and a git-derived build number (commit count).
#
# Expected arguments (passed via -D):
#   MAJOR, MINOR, PATCH  – semantic version components
#   OUT_FILE             – absolute path to the output version.properties

execute_process(
    COMMAND git rev-list --count HEAD
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    OUTPUT_VARIABLE BUILD
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
)
if (NOT BUILD)
    set(BUILD 1)
endif ()

set(VERSION_NAME "${MAJOR}.${MINOR}.${PATCH}.${BUILD}")

math(EXPR _VC_MAJOR "${MAJOR} * 100000000")
math(EXPR _VC_MINOR "${MINOR} * 1000000")
math(EXPR _VC_PATCH "${PATCH} * 10000")
math(EXPR _VC_BUILD "${BUILD} % 10000")
math(EXPR VERSION_CODE "${_VC_MAJOR} + ${_VC_MINOR} + ${_VC_PATCH} + ${_VC_BUILD}")

if (VERSION_CODE LESS 1 OR VERSION_CODE GREATER 2147483647)
    message(FATAL_ERROR "VERSION_CODE=${VERSION_CODE} out of 32-bit range")
endif ()

file(WRITE "${OUT_FILE}" "versionName=${VERSION_NAME}\n")
file(APPEND "${OUT_FILE}" "versionCode=${VERSION_CODE}\n")
