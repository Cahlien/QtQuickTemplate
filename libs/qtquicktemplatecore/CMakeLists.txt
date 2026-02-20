set(TARGET qtquicktemplatecore)

if (IOS)
    qt_add_library(${TARGET} STATIC)
else ()
    qt_add_library(${TARGET} SHARED)
    include(GenerateExportHeader)
    generate_export_header(${TARGET}
        BASE_NAME QTQUICKTEMPLATECORE
        EXPORT_FILE_NAME ${CMAKE_CURRENT_BINARY_DIR}/include/qtquicktemplatecore_export.h
    )
endif ()

set(CORE_HEADERS
    include/app_info.h
    include/navigation/navigation_controller.h
)

if (NOT IOS)
    list(APPEND CORE_HEADERS ${CMAKE_CURRENT_BINARY_DIR}/include/qtquicktemplatecore_export.h)
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

if (ANDROID)
    set_target_properties(${TARGET} PROPERTIES
        LINK_FLAGS "-Wl,-z,max-page-size=16384"
    )
endif ()
