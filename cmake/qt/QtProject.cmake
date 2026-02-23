include_guard(GLOBAL)

# Find Qt, apply project-wide Qt settings, and enable AUTOMOC / AUTORCC / AUTOUIC.
# Must be a macro because qt_standard_project_setup() and AUTOMOC/etc. set
# directory-scoped variables.
macro(setup_qt_project)
    find_package(Qt6 6.10 REQUIRED COMPONENTS Core CorePrivate Quick QuickPrivate QuickControls2 QuickControls2Private Qml QmlPrivate)
    qt_policy(SET QTP0004 NEW)
    qt_standard_project_setup(REQUIRES 6.10)

    # Qt 6.10's static iOS build requires FFmpeg xcframeworks to be explicitly
    # linked.  Finding Qt6::Multimedia makes qt_add_ios_ffmpeg_libraries()
    # available; the actual call happens in MainApp.cmake on the app target.
    if (IOS)
        find_package(Qt6 6.10 QUIET COMPONENTS Multimedia)
    endif ()

    set(CMAKE_AUTOMOC ON)
    set(CMAKE_AUTORCC ON)
    set(CMAKE_AUTOUIC ON)
endmacro()
