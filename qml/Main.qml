pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Window
import dev.crowell.AppTheme

/*!
    \qmltype Main
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits ApplicationWindow
    \brief Root application window with adaptive portrait/landscape layouts.

    Main is the entry point of the application. It creates a
    \l NavigationController, a hidden Loader for page content,
    and Header/Footer instances. A StackView switches between
    \l MainPortraitLayout and \l MainLandscapeLayout based on the
    window's aspect ratio.

    \sa NavigationController, MainPortraitLayout, MainLandscapeLayout
*/
ApplicationWindow {
    id: root

    /*!
        \qmlproperty url Main::initialPage
        The page loaded on startup. Defaults to \c StyleShowcase.qml.
    */
    property url initialPage: Qt.resolvedUrl("StyleShowcase.qml")

    /*!
        \qmlproperty bool Main::isMobile
        \readonly
        \c true on Android and iOS platforms; \c false otherwise.
    */
    property bool isMobile: Qt.platform.os === "android" || Qt.platform.os === "ios"

    /*!
        \qmlproperty NavigationController Main::navigation
        Alias exposing the internal \l NavigationController.
    */
    property alias navigation: navigationController

    /*!
        \qmlsignal Main::navigateTo(url resourceUrl)
        Emitted to request navigation to \a resourceUrl. A Connections
        handler forwards this to the \l NavigationController.
    */
    signal navigateTo(url resourceUrl)

    color: Theme.background

    palette {
        window: Theme.background
        windowText: Theme.text
        base: Theme.surface
        text: Theme.text
        button: Theme.surface
        buttonText: Theme.text
        highlight: Theme.primary
        highlightedText: Theme.onPrimary
        placeholderText: Theme.mutedText
        mid: Theme.border
        dark: Theme.surface2
        light: Theme.surface
    }

    flags: Qt.Window | Qt.MaximizeUsingFullscreenGeometryHint | Qt.ExpandedClientAreaHint
    height: isMobile ? Screen.height : 844
    minimumHeight: 568
    minimumWidth: 320
    title: qsTr("QtQuick Template")
    visible: true
    width: isMobile ? Screen.width : 390

    Component.onCompleted: {
        if (root.initialPage && root.initialPage !== "") {
            navigationController.navigate(root.initialPage);
        }
    }

    NavigationController {
        id: navigationController
        loader: pageLoader
    }

    Loader {
        id: pageLoader
        visible: false
    }

    Header {
        id: headerItem
        title: root.title
        visible: false
    }

    Footer {
        id: footerItem
        visible: false
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: root.width < root.height ? portraitLayout : landscapeLayout
        visible: true
    }

    Connections {
        function onNavigateTo(resourceUrl) {
            navigationController.navigate(resourceUrl);
        }
        target: root
    }

    MainPortraitLayout {
        id: portraitLayout
        content: pageLoader
        footer: footerItem
        header: headerItem
        navigation: navigationController
        visible: false
    }

    MainLandscapeLayout {
        id: landscapeLayout
        content: pageLoader
        footer: footerItem
        header: headerItem
        navigation: navigationController
        visible: false
    }
}
