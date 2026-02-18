import QtQuick
import QtQuick.Controls
import QtQuick.Window
import dev.crowell.AppTheme


/*!
    \qmltype Main
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits ApplicationWindow
    \brief Root application window with adaptive portrait/landscape layouts
    and a unified back-navigation system.

    Navigation architecture
    -----------------------
    All page pushes flow through the C++ \c Router singleton:

    \code
    Router.push("qrc:/qt/qml/dev/crowell/QtQuickTemplate/License.qml")
    Router.pop()
    \endcode

    \c Router emits \c pushRequested / \c popRequested which the
    \c routerConnections handler translates into \c StackView operations.
    The QML \l NavigationController continues to own the content-level
    history (Readme ↔ StyleShowcase) inside the layout.

    Back gesture routing
    --------------------
    \list
    \li \b Android 13+: The Kotlin \c OnBackInvokedCallback calls the JNI
        function \c nativeBackRequested(), which invokes \c Router.pop() on
        the Qt main thread via a queued connection.  \c onClosing is NOT used
        because Qt 6.10 has a regression where it is bypassed when
        \c enableOnBackInvokedCallback=true.
    \li \b Desktop / iOS: \c Item.Keys.onPressed handles Backspace and the
        dedicated Back key.  Mouse Button 4 (browser-back) is handled by a
        \c TapHandler.
    \endlist

    \sa NavigationController, MainPortraitLayout, MainLandscapeLayout, Router
*/
ApplicationWindow {
    id: root

    // ── Platform helpers ──────────────────────────────────────────────────

    /*!
        \qmlproperty bool Main::isMobile
        \readonly
        \c true on Android and iOS; \c false otherwise.
    */
    property bool isMobile: Qt.platform.os === "android"
                            || Qt.platform.os === "ios"

    /*!
        \qmlproperty NavigationController Main::navigation
        Alias exposing the internal QML \l NavigationController.
    */
    property alias navigation: navigationController

    // ── Window setup ──────────────────────────────────────────────────────

    color: Theme.background

    // onClosing intentionally omitted:
    //   • Android 13+ with enableOnBackInvokedCallback=true: the signal is
    //     never delivered by Qt 6 (known regression). Back is handled via JNI.
    //   • Desktop: the window close button should quit the app normally.

    palette {
        window:          Theme.background
        windowText:      Theme.text
        base:            Theme.surface
        text:            Theme.text
        button:          Theme.surface
        buttonText:      Theme.text
        highlight:       Theme.primary
        highlightedText: Theme.onPrimary
        placeholderText: Theme.mutedText
        mid:             Theme.border
        dark:            Theme.surface2
        light:           Theme.surface
    }

    flags:         Qt.Window | Qt.MaximizeUsingFullscreenGeometryHint | Qt.ExpandedClientAreaHint
    height:        isMobile ? Screen.height : 844
    minimumHeight: 568
    minimumWidth:  320
    title:         qsTr("QtQuick Template")
    visible:       true
    width:         isMobile ? Screen.width : 390

    // ── Navigation ────────────────────────────────────────────────────────

    NavigationController {
        id: navigationController
        loader: pageLoader
        defaultContentSource: Qt.resolvedUrl("Readme.qml")
    }

    /*!
        \qmlmethod void Main::handleBack()
        \internal
        Single entry-point for all back-navigation decisions.

        Priority order:
        1. A fullscreen page (e.g. License) is on the StackView → pop it.
        2. The QML NavigationController has a content history entry → go back.
        3. We are at the root screen.
              Android: move the task to the background.
              Desktop: do nothing (user must use the window close button).
    */
    function handleBack() {
        if (stackView.depth > 1) {
            // A Router-pushed page sits on top of the layout template.
            stackView.pop()
            // No need to call Router.pop() here — pop() was already called
            // by whoever triggered handleBack (JNI path or key handler),
            // which in turn emitted popRequested and landed us here.
        } else if (navigationController.canGoBack) {
            navigationController.goBack()
        } else if (Qt.platform.os === "android") {
            Router.minimizeApp()
        }
        // Desktop: fall through silently — the window close button quits.
    }

    // ── Router → StackView bridge ─────────────────────────────────────────

    Connections {
        id: routerConnections
        target: Router

        /// Respond to C++ Router.push(): push the page onto the StackView
        /// and wire the page's optional closeRequested signal back to
        /// Router.pop() so the page's own close button also goes through
        /// the Router.
        function onPushRequested(path, props) {
            const item = stackView.push(path, props)
            if (item && typeof item['closeRequested'] !== 'undefined') {
                item['closeRequested'].connect(() => Router.pop())
            }
        }

        /// Respond to C++ Router.pop() (triggered by JNI, key, or mouse).
        function onPopRequested() {
            root.handleBack()
        }

        function onReplaceRequested(path, props) {
            stackView.replace(stackView.currentItem, path, props)
        }
    }

    // ── Desktop & iOS back — keyboard ─────────────────────────────────────

    Item {
        // Must be visible and have focus to receive key events.
        anchors.fill: parent
        focus:        true
        // Give this item focus whenever it (or a non-input child) is clicked.
        TapHandler { onTapped: parent.forceActiveFocus() }

        Keys.onPressed: event => {
            // Backspace and the dedicated hardware Back key both navigate back.
            // Ignore on Android — back is handled exclusively through JNI.
            if (Qt.platform.os !== "android") {
                if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Back) {
                    event.accepted = true
                    Router.pop()
                }
            }
        }

        // Mouse Button 4 = XButton1 = browser "Back" button on most mice.
        TapHandler {
            acceptedButtons: Qt.BackButton
            onTapped: {
                if (Qt.platform.os !== "android")
                    Router.pop()
            }
        }
    }

    // ── App chrome (hidden until placed by a layout) ──────────────────────

    Header {
        id: headerItem
        title: root.title
        visible: false
    }

    NavBar {
        id: navBarItem
        visible: false
        onReadmeRequested:   navigationController.navigate(Qt.resolvedUrl("Readme.qml"))
        onControlsRequested: navigationController.navigate(Qt.resolvedUrl("StyleShowcase.qml"))
    }

    // Keep the NavBar tab highlight in sync with every navigation event,
    // including goBack() / goForward() which bypass the user's tab click.
    Connections {
        target: navigationController
        function onNavigationRequested(target, properties) {
            if (target.indexOf("Readme.qml") !== -1)
                navBarItem.currentIndex = 0
            else if (target.indexOf("StyleShowcase.qml") !== -1)
                navBarItem.currentIndex = 1
        }
    }

    Item {
        id: contentArea
        visible: false

        Loader {
            id: pageLoader
            anchors.fill: parent
            source: navigationController.defaultContentSource
        }
    }

    Footer {
        id: footerItem
        visible: false
    }

    // ── StackView (layout template + pushed pages) ────────────────────────

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: root.width < root.height ? portraitLayout : landscapeLayout
        visible: true
    }

    // ── Footer → Router bridge ────────────────────────────────────────────

    Connections {
        target: footerItem

        // Route through Router so Android back and Desktop back both work.
        function onLicenseRequested() {
            Router.push(Qt.resolvedUrl("License.qml").toString())
        }
    }

    // ── Layout templates (off-screen until adopted by StackView) ─────────

    MainPortraitLayout {
        id: portraitLayout
        content:    contentArea
        footer:     footerItem
        header:     headerItem
        navBar:     navBarItem
        navigation: navigationController
        visible:    false
    }

    MainLandscapeLayout {
        id: landscapeLayout
        content:    contentArea
        footer:     footerItem
        header:     headerItem
        navBar:     navBarItem
        navigation: navigationController
        visible:    false
    }
}
