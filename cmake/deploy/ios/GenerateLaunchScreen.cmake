if (NOT DEFINED TEMPLATE)
    message(FATAL_ERROR "TEMPLATE not set")
endif ()
if (NOT DEFINED OUTPUT)
    message(FATAL_ERROR "OUTPUT not set")
endif ()

if (NOT DEFINED PROJECT_VERSION)
    set(PROJECT_VERSION "0.0.0")
endif ()

if (NOT DEFINED APP_BUILD_NUMBER OR APP_BUILD_NUMBER STREQUAL "auto")
    execute_process(
            COMMAND git rev-list --count HEAD
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            OUTPUT_VARIABLE APP_BUILD_NUMBER
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET
    )
    if (NOT APP_BUILD_NUMBER)
        set(APP_BUILD_NUMBER "1")
    endif ()
endif ()

file(READ "${TEMPLATE}" _tmpl)
string(CONFIGURE "${_tmpl}" _out @ONLY)

get_filename_component(_outdir "${OUTPUT}" DIRECTORY)
file(MAKE_DIRECTORY "${_outdir}")
file(WRITE "${OUTPUT}" "${_out}")
message(STATUS "Generated ${OUTPUT} with Version=${PROJECT_VERSION}.${APP_BUILD_NUMBER}")
