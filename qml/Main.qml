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
    All navigation flows through the C++ \c NavigationController singleton via
    three methods: \c push(), \c pop(), and \c replace().  Each call stores only
    a URL, optional initial properties, and a chrome-visibility flag — no
    QQuickItem references are retained.

    A pair of \c Loader items (\l loaderA and \l loaderB) alternate as the
    active page.  When \c NavigationController.currentChanged fires, the
    inactive loader receives the new URL and props via \c Loader::setSource()
    (which delivers properties before \c Component.onCompleted), then slides or
    fades into view while the active loader animates away.

    Chrome visibility (header / nav-bar / footer) is controlled per-page via the
    \c showChrome flag stored in each navigation entry.  When \c false the
    chrome proxies collapse inside the active layout and the page fills the
    available space.

    Portrait / landscape adaptation
    --------------------------------
    A \l Loader switches between \l MainPortraitLayout and
    \l MainLandscapeLayout as the window aspect ratio changes.  The chrome
    items and page-area container are always declared here and are merely
    positioned by the active layout via \c LayoutItemProxy.

    Back gesture routing
    --------------------
    \list
    \li \b Android 13+: Kotlin's \c OnBackInvokedCallback calls the JNI
        function \c nativeBackRequested(), which invokes
        \c NavigationController.pop() on the Qt main thread via a queued
        connection.  \c Qt.Key_Back is still accepted in QML (without
        popping) so that Qt's unhandled-key fallback never closes the
        window.  \c MainActivity.onBackPressed() is overridden as a no-op
        to prevent \c QtActivity from finishing the Activity.
    \li \b Android <13: \c MainActivity.onBackPressed() routes through
        the same JNI bridge.
    \li \b Desktop / iOS: \c Item.Keys.onPressed handles Backspace and the
        dedicated Back key.  Mouse Button 4 (browser-back) is handled by a
        \c TapHandler.
    \endlist

    \sa MainPortraitLayout, MainLandscapeLayout, NavigationController
*/
ApplicationWindow {
    id: root

    // ── Platform helper ───────────────────────────────────────────────────

    /*!
        \qmlproperty bool Main::isMobile
        \readonly
        \c true on Android and iOS; \c false otherwise.
    */
    readonly property bool isMobile: Qt.platform.os === "android"
                                  || Qt.platform.os === "ios"

    // Lags one navigation behind NavigationController.currentShowChrome.
    // Updated in pageLoader.onLoaded (when opacity is already 0) so the
    // layout resize that hides/shows chrome is never visible mid-transition.
    property bool _displayedShowChrome: true

    // Persist the last tab selected on chrome pages. Full-screen pages
    // (showChrome=false, e.g. License) should not force the tab highlight.
    property int _navTabIndex: 0

    // ── Window setup ──────────────────────────────────────────────────────

    color: Theme.background

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

    // ── Android close-event guard ─────────────────────────────────────────
    //
    // Qt's unhandled-Key_Back fallback posts a QCloseEvent to the window.
    // When a focusable chrome widget (TabButton, etc.) holds active focus,
    // the Keys.onPressed handler below never sees the event, so Qt's
    // fallback fires.  Rejecting the close here is the focus-independent
    // safety net that keeps the Activity alive.  Actual back navigation is
    // handled by the JNI OnBackInvokedCallback / onBackPressed() override.
    // moveTaskToBack() does not trigger onClosing, so the backAtRoot
    // minimize path is unaffected.
    onClosing: function(close) {
        if (Qt.platform.os === "android")
            close.accepted = false
    }

    // Seed the home page.  This is the first push so no back-stack entry is
    // created — pressing back from here fires backAtRoot instead.
    Component.onCompleted: {
        NavigationController.push(Qt.resolvedUrl("Readme.qml").toString())
    }

    // ── Back navigation: root reached ────────────────────────────────────

    Connections {
        target: NavigationController

        /// When the back-stack is empty, minimise on Android; do nothing on
        /// desktop (user must use the window close button).
        function onBackAtRoot() {
            if (Qt.platform.os === "android")
                NavigationController.minimizeApp()
        }
    }

    // ── Back navigation: keyboard & mouse (+ Android Key_Back guard) ────

    Item {
        anchors.fill: parent
        focus:        true

        // Reclaim focus when the user clicks outside an input field.
        TapHandler { onTapped: parent.forceActiveFocus() }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Back) {
                // Always accept Key_Back so Qt's unhandled-key fallback never
                // closes the window / finishes the Activity.
                event.accepted = true
                // On Android the pop is driven by the JNI OnBackInvokedCallback;
                // on every other platform we pop here.
                if (Qt.platform.os !== "android")
                    NavigationController.pop()
            } else if (event.key === Qt.Key_Backspace
                       && Qt.platform.os !== "android") {
                event.accepted = true
                NavigationController.pop()
            }
        }

        // Mouse Button 4 = XButton1 = browser "Back" on most mice.
        TapHandler {
            acceptedButtons: Qt.BackButton
            onTapped: {
                if (Qt.platform.os !== "android")
                    NavigationController.pop()
            }
        }
    }

    // ── Chrome items (positioned by the active layout) ────────────────────

    Header {
        id: headerItem
        title: root.title
        visible: root._displayedShowChrome
    }

    NavBar {
        id: navBarItem
        visible: root._displayedShowChrome
        currentIndex: root._navTabIndex

        onReadmeRequested:   NavigationController.push(Qt.resolvedUrl("Readme.qml").toString())
        onControlsRequested: NavigationController.push(Qt.resolvedUrl("StyleShowcase.qml").toString())
    }

    // Keep the NavBar tab highlight in sync with chrome pages only.
    Connections {
        target: NavigationController
        function onCurrentChanged() {
            if (!NavigationController.currentShowChrome)
                return

            root._navTabIndex = NavigationController.currentUrl.indexOf("StyleShowcase.qml") !== -1 ? 1 : 0
        }
    }

    Footer {
        id: footerItem
        visible: root._displayedShowChrome
    }

    Connections {
        target: footerItem
        function onLicenseRequested() {
            // License is a full-screen page — no chrome.
            NavigationController.push(Qt.resolvedUrl("License.qml").toString(), {}, false)
        }
    }

    // ── Page area ─────────────────────────────────────────────────────────
    //
    // Single Loader — one page in memory at a time.
    //
    // Transition: fade out current page → setSource in onFinished (props are
    // delivered atomically before the new component's Component.onCompleted) →
    // onLoaded fades the new page back in.
    //
    // Rapid navigation is safe: fadeOut.restart() resets the timer each time,
    // and onFinished always reads the latest currentUrl/currentProps.

    Item {
        id: pageArea

        Loader {
            id: pageLoader
            width:  parent.width
            height: parent.height

            onLoaded: {
                // Wire up any page-level close button to NavigationController.pop().
                if (item && typeof item["closeRequested"] !== "undefined")
                    item.closeRequested.connect(NavigationController.pop)

                // Update chrome visibility now that opacity is 0 — the layout
                // resize is invisible and the incoming page sizes itself correctly
                // before fading in.
                root._displayedShowChrome = NavigationController.currentShowChrome
                fadeIn.restart()
            }
        }

        Connections {
            target: NavigationController
            function onCurrentChanged() {
                if (pageLoader.status === Loader.Null) {
                    // Initial load — start transparent so onLoaded fades in.
                    pageLoader.opacity = 0
                    pageLoader.setSource(NavigationController.currentUrl,
                                         NavigationController.currentProps)
                } else {
                    fadeOut.restart()
                }
            }
        }

        // Step 1: fade the current page out, then swap the source.
        NumberAnimation {
            id: fadeOut
            target:   pageLoader
            property: "opacity"
            to:       0
            duration: 120
            easing.type: Easing.InQuad
            onFinished: pageLoader.setSource(NavigationController.currentUrl,
                                             NavigationController.currentProps)
        }

        // Step 2: triggered by Loader.onLoaded — fade the new page in.
        NumberAnimation {
            id: fadeIn
            target:   pageLoader
            property: "opacity"
            to:       1
            duration: 180
            easing.type: Easing.OutQuad
        }
    }

    // ── Layout loader ─────────────────────────────────────────────────────
    //
    // Switches between portrait and landscape layout components as the window
    // aspect ratio changes.  Only one layout is instantiated at a time, so
    // LayoutItemProxy conflicts are impossible.

    Loader {
        id: layoutLoader
        anchors.fill: parent
        source: root.width <= root.height ? "MainPortraitLayout.qml"
                                          : "MainLandscapeLayout.qml"
        onLoaded: {
            item.content    = pageArea
            item.header     = headerItem
            item.navBar     = navBarItem
            item.footer     = footerItem
            item.showChrome = Qt.binding(() => root._displayedShowChrome)
        }
    }
}
