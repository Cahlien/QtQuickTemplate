set(TARGET qtquicktemplatecore)

include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/libs/LibraryCommon.cmake")

add_portable_qt_library(${TARGET} QTQUICKTEMPLATECORE QTQUICKTEMPLATECORE_EXPORT_HEADER)

set(CORE_HEADERS
    include/app_info.h
    include/navigation/navigation_controller.h
)

if (QTQUICKTEMPLATECORE_EXPORT_HEADER)
    list(APPEND CORE_HEADERS ${QTQUICKTEMPLATECORE_EXPORT_HEADER})
endif ()

target_sources(${TARGET}
    PRIVATE
        src/app_info.cpp
        src/navigation/navigation_controller.cpp
    PUBLIC FILE_SET HEADERS
        BASE_DIRS include ${CMAKE_CURRENT_BINARY_DIR}/include
        FILES
            ${CORE_HEADERS}
)

target_include_directories(${TARGET} PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_BINARY_DIR}/include
)

target_compile_definitions(${TARGET} PRIVATE
    APP_VERSION_STRING="${CMAKE_PROJECT_VERSION}"
)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Qml)
target_link_libraries(${TARGET} PUBLIC
    Qt6::Core
    Qt6::Quick
    Qt6::Qml
)

apply_android_max_page_size(${TARGET})
