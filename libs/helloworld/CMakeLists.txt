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

get_target_property(_qt_bin_dir Qt6::qmake IMPORTED_LOCATION)
cmake_path(GET _qt_bin_dir PARENT_PATH _qt_bin_dir)
find_program(QDOC_EXECUTABLE qdoc HINTS "${_qt_bin_dir}" NO_DEFAULT_PATH)
if (QDOC_EXECUTABLE)
    add_custom_target(helloworld_docs
        COMMAND ${QDOC_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/doc/helloworld.qdocconf
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/doc
        COMMENT "Generating HelloWorld documentation with QDoc"
    )
endif ()
