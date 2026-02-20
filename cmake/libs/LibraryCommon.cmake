include_guard(GLOBAL)

function(add_portable_cpp_library target base_name export_header_out)
    if (IOS)
        add_library(${target} STATIC)
        set(${export_header_out} "" PARENT_SCOPE)
    else ()
        add_library(${target} SHARED)
        include(GenerateExportHeader)
        set(_export_header "${CMAKE_CURRENT_BINARY_DIR}/include/${target}_export.h")
        generate_export_header(${target}
            BASE_NAME ${base_name}
            EXPORT_FILE_NAME ${_export_header}
        )
        set(${export_header_out} ${_export_header} PARENT_SCOPE)
    endif ()
endfunction()

function(add_portable_qt_library target base_name export_header_out)
    if (IOS)
        qt_add_library(${target} STATIC)
        set(${export_header_out} "" PARENT_SCOPE)
    else ()
        qt_add_library(${target} SHARED)
        include(GenerateExportHeader)
        set(_export_header "${CMAKE_CURRENT_BINARY_DIR}/include/${target}_export.h")
        generate_export_header(${target}
            BASE_NAME ${base_name}
            EXPORT_FILE_NAME ${_export_header}
        )
        set(${export_header_out} ${_export_header} PARENT_SCOPE)
    endif ()
endfunction()

function(apply_android_max_page_size target)
    if (ANDROID AND (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU"))
        target_link_options(${target} PRIVATE "LINKER:-z,max-page-size=16384")
    endif ()
endfunction()
