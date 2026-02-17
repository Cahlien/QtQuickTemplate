pragma Singleton

import QtQuick

QtObject {
    // ── Colors (Material Design 3 — Dark) ──
    readonly property color background: "#121212"
    readonly property color surface: "#1E1E1E"
    readonly property color surfaceVariant: "#2C2C2C"
    readonly property color primary: "#BB86FC"
    readonly property color primaryVariant: "#3700B3"
    readonly property color secondary: "#03DAC6"
    readonly property color secondaryVariant: "#018786"
    readonly property color error: "#CF6679"
    readonly property color onBackground: "#FFFFFF"
    readonly property color onSurface: "#E0E0E0"
    readonly property color onSurfaceVariant: "#A0A0A0"
    readonly property color onPrimary: "#000000"
    readonly property color onSecondary: "#000000"
    readonly property color onError: "#000000"
    readonly property color outline: "#444444"

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
}
