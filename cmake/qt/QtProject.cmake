include_guard(GLOBAL)

# Find Qt, apply project-wide Qt settings, and enable AUTOMOC / AUTORCC / AUTOUIC.
# Must be a macro because qt_standard_project_setup() and AUTOMOC/etc. set
# directory-scoped variables.
macro(setup_qt_project)
    find_package(Qt6 6.10 REQUIRED COMPONENTS Core Quick QuickControls2 Qml)
    qt_policy(SET QTP0004 NEW)
    qt_standard_project_setup(REQUIRES 6.10)

    set(CMAKE_AUTOMOC ON)
    set(CMAKE_AUTORCC ON)
    set(CMAKE_AUTOUIC ON)
endmacro()
