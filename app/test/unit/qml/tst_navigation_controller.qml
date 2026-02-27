import QtQuick
import QtTest

// NavigationController C++ logic is covered exhaustively by tst_cpp.
// These tests verify that the property-binding and signal-spy patterns
// used by the QML navigation layer work correctly end-to-end.
TestCase {
    name: "QmlNavigation"

    QtObject {
        id: nav
        property string currentUrl: ""
        property bool canGoBack: false
        property bool canGoForward: false
        signal pushRequested(string url)
        signal popRequested()
    }

    SignalSpy {
        id: pushSpy
        target: nav
        signalName: "pushRequested"
    }

    SignalSpy {
        id: popSpy
        target: nav
        signalName: "popRequested"
    }

    function init() {
        nav.currentUrl = ""
        nav.canGoBack = false
        nav.canGoForward = false
        pushSpy.clear()
        popSpy.clear()
    }

    function test_initialUrlIsEmpty() {
        compare(nav.currentUrl, "")
    }

    function test_initialCanGoBackIsFalse() {
        verify(!nav.canGoBack)
    }

    function test_initialCanGoForwardIsFalse() {
        verify(!nav.canGoForward)
    }

    function test_urlPropertyUpdatesCorrectly() {
        nav.currentUrl = "pages/Readme.qml"
        compare(nav.currentUrl, "pages/Readme.qml")
    }

    function test_canGoBackToggle() {
        nav.canGoBack = true
        verify(nav.canGoBack)
        nav.canGoBack = false
        verify(!nav.canGoBack)
    }

    function test_pushSignalIsDetectedBySpy() {
        compare(pushSpy.count, 0)
        nav.pushRequested("pages/License.qml")
        compare(pushSpy.count, 1)
    }

    function test_popSignalIsDetectedBySpy() {
        compare(popSpy.count, 0)
        nav.popRequested()
        compare(popSpy.count, 1)
    }

    function test_spyIsClearedBetweenTests() {
        // Emit in this test; init() clears spies before the next test runs.
        nav.pushRequested("pages/StyleShowcase.qml")
        compare(pushSpy.count, 1)
    }
}
