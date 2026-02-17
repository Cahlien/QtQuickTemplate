pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import dev.crowell.AppTheme

/*!
    \qmltype Main
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits ApplicationWindow
    \brief Root application window with adaptive portrait/landscape layouts.

    Main is the entry point of the application. It creates a
    \l NavigationController, a NavBar for page switching,
    and Header/Footer instances. A StackView switches between
    \l MainPortraitLayout and \l MainLandscapeLayout based on the
    window's aspect ratio.

    \sa NavigationController, MainPortraitLayout, MainLandscapeLayout
*/
ApplicationWindow {
    id: root

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

    NavigationController {
        id: navigationController
        loader: pageLoader
        defaultContentSource: Qt.resolvedUrl("Readme.qml")
    }

    Header {
        id: headerItem
        title: root.title
        visible: false
    }

    NavBar {
        id: navBarItem
        visible: false
        onReadmeRequested: navigationController.navigate(Qt.resolvedUrl("Readme.qml"))
        onControlsRequested: navigationController.navigate(Qt.resolvedUrl("StyleShowcase.qml"))
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

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: root.width < root.height ? portraitLayout : landscapeLayout
        visible: true
    }

    Connections {
        function onLicenseRequested() {
            navigationController.navigate(Qt.resolvedUrl("License.qml"));
        }
        target: footerItem
    }

    MainPortraitLayout {
        id: portraitLayout
        content: contentArea
        footer: footerItem
        header: headerItem
        navBar: navBarItem
        navigation: navigationController
        visible: false
    }

    MainLandscapeLayout {
        id: landscapeLayout
        content: contentArea
        footer: footerItem
        header: headerItem
        navBar: navBarItem
        navigation: navigationController
        visible: false
    }
}
