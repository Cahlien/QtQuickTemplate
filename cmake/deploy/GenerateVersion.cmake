# generate_version.cmake
#
# Computes a git-derived build number and writes version information in
# a platform-appropriate format.  iOS and Android use the same four-part
# version string (MAJOR.MINOR.PATCH.BUILD); macOS uses three parts
# (MAJOR.MINOR.PATCH), omitting the build number.
#
# Expected arguments (passed via -D):
#   MAJOR, MINOR, PATCH  – semantic version components
#   PLATFORM             – "android", "ios", or "macos"
#   OUT_FILE             – absolute path to the output file

# ── Build number from git commit count ──────────────────────────────
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

# ── Android: version.properties ─────────────────────────────────────
if (PLATFORM STREQUAL "android")
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

# ── iOS: version.xcconfig (4-part, like Android) ──────────────────────
elseif (PLATFORM STREQUAL "ios")
    # MARKETING_VERSION  = CFBundleShortVersionString (shown on App Store)
    # CURRENT_PROJECT_VERSION = CFBundleVersion (must increment per upload)
    file(WRITE "${OUT_FILE}" "MARKETING_VERSION = ${MAJOR}.${MINOR}.${PATCH}\n")
    file(APPEND "${OUT_FILE}" "CURRENT_PROJECT_VERSION = ${VERSION_NAME}\n")

# ── macOS: version.xcconfig (3-part) ──────────────────────────────────
elseif (PLATFORM STREQUAL "macos")
    file(WRITE "${OUT_FILE}" "MARKETING_VERSION = ${MAJOR}.${MINOR}.${PATCH}\n")
    file(APPEND "${OUT_FILE}" "CURRENT_PROJECT_VERSION = ${MAJOR}.${MINOR}.${PATCH}\n")

else ()
    message(FATAL_ERROR "Unknown PLATFORM '${PLATFORM}'; expected 'android', 'ios', or 'macos'")
endif ()

if (PLATFORM STREQUAL "macos")
    message(STATUS "[${PLATFORM}] version ${MAJOR}.${MINOR}.${PATCH}")
else ()
    message(STATUS "[${PLATFORM}] version ${VERSION_NAME} (build ${BUILD})")
endif ()
