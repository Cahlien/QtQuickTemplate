pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Window
import AppTheme

ApplicationWindow {
    id: root

    property url initialPage: Qt.resolvedUrl("StyleShowcase.qml")
    property bool isMobile: Qt.platform.os === "android" || Qt.platform.os === "ios"
    property alias navigation: navigationController

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
