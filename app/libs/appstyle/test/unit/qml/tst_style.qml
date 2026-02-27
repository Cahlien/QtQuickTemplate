import QtQuick
import QtTest
import dev.crowell.AppTheme

TestCase {
    name: "AppStyle"

    function test_primaryColorIsNonEmpty() {
        verify(Theme.primary !== "", "Theme.primary should be a non-empty color string")
    }

    function test_surfaceColorIsNonEmpty() {
        verify(Theme.surface !== "", "Theme.surface should be a non-empty color string")
    }

    function test_textColorIsNonEmpty() {
        verify(Theme.text !== "", "Theme.text should be a non-empty color string")
    }

    function test_spacingMdIsPositive() {
        verify(Theme.spacingMd > 0, "Theme.spacingMd should be positive")
    }

    function test_radiusMdIsPositive() {
        verify(Theme.radiusMd > 0, "Theme.radiusMd should be positive")
    }

    function cleanup() {
        Theme.darkMode = true
    }

    function test_darkModeDefaultIsTrue() {
        compare(Theme.darkMode, true)
    }

    function test_darkModePrimaryColor() {
        compare(Theme.primary, "#40e0d0")
    }

    function test_lightModePrimaryColor() {
        const darkPrimary = "" + Theme.primary
        Theme.darkMode = false
        const lightPrimary = "" + Theme.primary
        verify(lightPrimary !== darkPrimary)
    }
}
