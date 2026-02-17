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
