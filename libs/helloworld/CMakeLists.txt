# HelloWorld C++20 Module Library
add_library(helloworld STATIC)

target_sources(helloworld
    PRIVATE
        src/helloworld.cpp
    PUBLIC
        FILE_SET CXX_MODULES FILES
            helloworld.cppm
        FILE_SET HEADERS FILES
            include/helloworld.h
)

target_include_directories(helloworld PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_compile_features(helloworld PUBLIC cxx_std_20)

if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    target_compile_options(helloworld PUBLIC -fmodules-ts)
endif ()

find_package(Threads REQUIRED)
target_link_libraries(helloworld PUBLIC Threads::Threads)

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
