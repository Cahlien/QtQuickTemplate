include_guard(GLOBAL)

# add_qt_test(NAME <name> SOURCES <src...> [LINK_LIBRARIES <lib...>] [INCLUDE_DIRECTORIES <dir...>])
#
# Creates a Qt Test executable, links Qt6::Test, and registers it with CTest.
function(add_qt_test)
    if (NOT QTQUICKTEMPLATE_ENABLE_TESTING)
        return()
    endif ()

    cmake_parse_arguments(ARG "" "NAME" "SOURCES;LINK_LIBRARIES;INCLUDE_DIRECTORIES" ${ARGN})

    add_executable(${ARG_NAME} ${ARG_SOURCES})

    target_link_libraries(${ARG_NAME} PRIVATE
        Qt6::Test
        ${ARG_LINK_LIBRARIES}
    )

    if (ARG_INCLUDE_DIRECTORIES)
        target_include_directories(${ARG_NAME} PRIVATE ${ARG_INCLUDE_DIRECTORIES})
    endif ()

    add_test(NAME ${ARG_NAME} COMMAND ${ARG_NAME})
    set_tests_properties(${ARG_NAME} PROPERTIES TIMEOUT 60)
endfunction()

# add_qt_quick_test(NAME <name> SOURCES <src...> QML_TEST_DIR <dir>
#                   [LINK_LIBRARIES <lib...>] [QML_IMPORT_PATHS <path...>])
#
# Creates a Qt Quick Test executable, links Qt6::QuickTest/Quick/Qml,
# sets QUICK_TEST_SOURCE_DIR, and registers it with CTest.
function(add_qt_quick_test)
    if (NOT QTQUICKTEMPLATE_ENABLE_TESTING)
        return()
    endif ()

    cmake_parse_arguments(ARG "" "NAME;QML_TEST_DIR" "SOURCES;LINK_LIBRARIES;QML_IMPORT_PATHS" ${ARGN})

    add_executable(${ARG_NAME} ${ARG_SOURCES})

    target_link_libraries(${ARG_NAME} PRIVATE
        Qt6::QuickTest
        Qt6::Quick
        Qt6::Qml
        ${ARG_LINK_LIBRARIES}
    )

    target_compile_definitions(${ARG_NAME} PRIVATE
        QUICK_TEST_SOURCE_DIR="${ARG_QML_TEST_DIR}"
    )

    add_test(NAME ${ARG_NAME} COMMAND ${ARG_NAME})
    set_tests_properties(${ARG_NAME} PROPERTIES TIMEOUT 60)

    if (ARG_QML_IMPORT_PATHS)
        cmake_path(CONVERT "${ARG_QML_IMPORT_PATHS}" TO_NATIVE_PATH_LIST _import_paths)
        set_tests_properties(${ARG_NAME} PROPERTIES
            ENVIRONMENT "QML_IMPORT_PATH=${_import_paths}")
    endif ()
endfunction()
