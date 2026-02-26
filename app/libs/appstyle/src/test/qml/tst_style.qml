import QtQuick
import QtTest
import dev.crowell.AppTheme

TestCase {
    name: "AppStyle"

    // AppStyle depends on AppTheme; verify the dependency is accessible and
    // exposes the expected design-token properties.

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

    function test_darkModeDefaultIsTrue() {
        compare(Theme.darkMode, true)
    }

    function test_darkModeToggleChangesPrimaryColor() {
        const darkPrimary = Theme.primary
        Theme.darkMode = false
        const lightPrimary = Theme.primary
        Theme.darkMode = true
        verify(darkPrimary !== lightPrimary,
               "primary color should differ between dark and light mode")
    }
}
