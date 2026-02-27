import QtQuick
import QtTest
import dev.crowell.AppTheme

TestCase {
    name: "AppTheme"

    function test_darkModeDefaultIsTrue() {
        compare(Theme.darkMode, true)
    }

    function test_darkModePrimaryColor() {
        compare(Theme.primary, "#40e0d0")
    }

    function test_lightModePrimaryColor() {
        Theme.darkMode = false
        compare(Theme.primary, "#2eb8a8")
        Theme.darkMode = true
    }

    function test_spacingMdIs16() {
        compare(Theme.spacingMd, 16)
    }

    function test_radiusMdIs8() {
        compare(Theme.radiusMd, 8)
    }

    function test_animNormalIs200() {
        compare(Theme.animNormal, 200)
    }
}
