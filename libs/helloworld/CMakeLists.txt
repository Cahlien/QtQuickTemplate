set(TARGET helloworld)

include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/libs/LibraryCommon.cmake")

add_portable_cpp_library(${TARGET} HELLOWORLD HELLOWORLD_EXPORT_HEADER)

set(HELLOWORLD_MODULES_ENABLED ${QTQUICKTEMPLATE_CXX_MODULES_SUPPORTED})
set_property(GLOBAL PROPERTY QTQUICKTEMPLATE_HELLOWORLD_MODULE_ENABLED ${HELLOWORLD_MODULES_ENABLED})

set(HELLOWORLD_SOURCES
    src/helloworld.cpp
)

set(HELLOWORLD_HEADERS
    include/helloworld.h
)

if (HELLOWORLD_EXPORT_HEADER)
    list(APPEND HELLOWORLD_HEADERS ${HELLOWORLD_EXPORT_HEADER})
endif ()

if (HELLOWORLD_MODULES_ENABLED)
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
else ()
    target_sources(${TARGET}
        PRIVATE
            ${HELLOWORLD_SOURCES}
        PUBLIC
            FILE_SET HEADERS
                BASE_DIRS include ${CMAKE_CURRENT_BINARY_DIR}/include
                FILES
                    ${HELLOWORLD_HEADERS}
    )
endif ()

if (HELLOWORLD_MODULES_ENABLED)
    message(STATUS "[helloworld] Linking C++20 module with traditional backing library")
else ()
    get_target_property(_lib_type ${TARGET} TYPE)
    message(STATUS "[helloworld] Linking backing library (${_lib_type})")
endif ()

target_include_directories(${TARGET} PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_BINARY_DIR}/include
)

target_compile_features(${TARGET} PUBLIC cxx_std_26)

apply_android_max_page_size(${TARGET})

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
