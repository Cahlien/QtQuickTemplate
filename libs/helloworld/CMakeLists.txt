set(TARGET helloworld)

if (IOS)
    add_library(${TARGET}  STATIC)
else ()
    add_library(${TARGET}  SHARED)
    include(GenerateExportHeader)
    generate_export_header(${TARGET}
        BASE_NAME HELLOWORLD
        EXPORT_FILE_NAME ${CMAKE_CURRENT_BINARY_DIR}/include/helloworld_export.h
    )
endif ()

set(HELLOWORLD_SOURCES
    src/helloworld.cpp
)

set(HELLOWORLD_HEADERS
    include/helloworld.h
)

if (NOT IOS)
    list(APPEND HELLOWORLD_HEADERS ${CMAKE_CURRENT_BINARY_DIR}/include/helloworld_export.h)
endif ()

target_sources(${TARGET}
    PRIVATE
        ${HELLOWORLD_SOURCES}
    PUBLIC
        FILE_SET CXX_MODULES FILES
            helloworld.cppm
        FILE_SET HEADERS
            BASE_DIRS include ${CMAKE_CURRENT_BINARY_DIR}/include
            FILES
                ${HELLOWORLD_HEADERS}
)

target_include_directories(${TARGET} PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_BINARY_DIR}/include
)

target_compile_features(${TARGET} PUBLIC cxx_std_23)

# ─────────────────────────────────────────────
# ELF alignment for Android 15 (16 KB page size)
# ─────────────────────────────────────────────
if (ANDROID)
    set_target_properties(${TARGET} PROPERTIES LINK_FLAGS "-Wl,-z,max-page-size=16384")
endif()

if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    target_compile_options(${TARGET} PUBLIC -fmodules-ts)
endif ()

find_package(Threads REQUIRED)
target_link_libraries(${TARGET} PUBLIC Threads::Threads)

find_program(QDOC_EXECUTABLE qdoc HINTS "${QT_HOST_PATH}/bin")
if (QDOC_EXECUTABLE)
    add_custom_target(helloworld_docs
        COMMAND ${CMAKE_COMMAND} -E rm -rf ${CMAKE_CURRENT_BINARY_DIR}/doc/html
        COMMAND ${QDOC_EXECUTABLE}
            ${CMAKE_CURRENT_SOURCE_DIR}/doc/helloworld.qdocconf
            -outputdir ${CMAKE_CURRENT_BINARY_DIR}/doc/html
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/doc
        COMMENT "Generating HelloWorld documentation with QDoc"
    )
endif ()
