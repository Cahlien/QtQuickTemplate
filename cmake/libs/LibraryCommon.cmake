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
        # Prevent the dylib from being installed as a separate component in the
        # xcarchive Products directory (e.g. Products/@rpath/libfoo.dylib).
        # productbuild rejects @rpath as a component install path.  macdeployqt
        # embeds the library in the app bundle during the archive step instead.
        if (APPLE AND NOT IOS AND CMAKE_GENERATOR STREQUAL "Xcode")
            set_target_properties(${target} PROPERTIES XCODE_ATTRIBUTE_SKIP_INSTALL YES)
        endif ()
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
        if (APPLE AND NOT IOS AND CMAKE_GENERATOR STREQUAL "Xcode")
            set_target_properties(${target} PROPERTIES XCODE_ATTRIBUTE_SKIP_INSTALL YES)
        endif ()
    endif ()
endfunction()

function(apply_android_max_page_size target)
    if (ANDROID AND (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU"))
        target_link_options(${target} PRIVATE "LINKER:-z,max-page-size=16384")
    endif ()
endfunction()
