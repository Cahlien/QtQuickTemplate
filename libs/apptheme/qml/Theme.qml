pragma Singleton

import QtQuick

/*!
    \qmltype Theme
    \inqmlmodule dev.crowell.AppTheme
    \inherits QtObject
    \brief Singleton providing all design tokens for the application.

    Theme exposes color palettes (dark and light), an MD3 typography scale,
    spacing constants, border radii, animation durations, and accessibility
    values. Every visual component in the application references \c Theme.*
    for its styling.

    Toggle \l darkMode to switch between the dark and light palettes.
    Colors are derived from the \l {https://www.crowell.dev}{crowell.dev}
    arcane and circuit color palettes.
*/
QtObject {
    id: theme

    /*!
        \qmlproperty bool Theme::darkMode
        When \c true the dark palette is active; when \c false the light
        palette is used. Defaults to \c true.
    */
    property bool darkMode: true

    // ── Colors (from crowell.dev arcane + circuit palettes) ──
    readonly property color background: darkMode ? "#0a0a0c" : "#f4f4f5"
    readonly property color surface: darkMode ? "#141416" : "#ffffff"
    readonly property color surface2: darkMode ? "#1c1c1e" : "#e4e4e7"
    readonly property color primary: darkMode ? "#40e0d0" : "#2eb8a8"
    readonly property color primaryHover: darkMode ? "#4dfce6" : "#40e0d0"
    readonly property color primaryPressed: darkMode ? "#2eb8a8" : "#207068"
    readonly property color secondary: darkMode ? "#2eb8a8" : "#207068"
    readonly property color text: darkMode ? "#e4e4e7" : "#141416"
    readonly property color mutedText: darkMode ? "#a1a1aa" : "#3f3f46"
    readonly property color border: darkMode ? "#27272a" : "#d4d4d8"
    readonly property color onPrimary: darkMode ? "#081a19" : "#042f2e"
    readonly property color success: darkMode ? "#4ade80" : "#16a34a"
    readonly property color warning: darkMode ? "#facc15" : "#ca8a04"
    readonly property color danger: darkMode ? "#f87171" : "#dc2626"
    readonly property color focusOutline: darkMode ? "#40e0d0" : "#2eb8a8"
    readonly property color outline: darkMode ? "#3f3f46" : "#a1a1aa"
    readonly property color surfaceHover: darkMode ? "#1c1c1e" : "#e4e4e7"

    // ── Typography (Material Design 3 type scale) ──
    readonly property font displayLarge: Qt.font({pixelSize: 57, weight: Font.Normal})
    readonly property font displayMedium: Qt.font({pixelSize: 45, weight: Font.Normal})
    readonly property font displaySmall: Qt.font({pixelSize: 36, weight: Font.Normal})
    readonly property font headlineLarge: Qt.font({pixelSize: 32, weight: Font.Normal})
    readonly property font headlineMedium: Qt.font({pixelSize: 28, weight: Font.Normal})
    readonly property font headlineSmall: Qt.font({pixelSize: 24, weight: Font.Normal})
    readonly property font titleLarge: Qt.font({pixelSize: 22, weight: Font.Medium})
    readonly property font titleMedium: Qt.font({pixelSize: 16, weight: Font.Medium})
    readonly property font titleSmall: Qt.font({pixelSize: 14, weight: Font.Medium})
    readonly property font bodyLarge: Qt.font({pixelSize: 16, weight: Font.Normal})
    readonly property font bodyMedium: Qt.font({pixelSize: 14, weight: Font.Normal})
    readonly property font bodySmall: Qt.font({pixelSize: 12, weight: Font.Normal})
    readonly property font labelLarge: Qt.font({pixelSize: 14, weight: Font.Medium})
    readonly property font labelMedium: Qt.font({pixelSize: 12, weight: Font.Medium})
    readonly property font labelSmall: Qt.font({pixelSize: 11, weight: Font.Medium})

    // ── Spacing ──
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 16
    readonly property int spacingLg: 24
    readonly property int spacingXl: 32

    // ── Shape ──
    readonly property int radiusSm: 4
    readonly property int radiusMd: 8
    readonly property int radiusLg: 12
    readonly property int radiusXl: 16
    readonly property int radiusFull: 9999

    // ── Animation ──
    readonly property int animFast: 100
    readonly property int animNormal: 200

    // ── Accessibility ──
    readonly property real disabledOpacity: 0.5
    readonly property int focusWidth: 2
}
