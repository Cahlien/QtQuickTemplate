pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Window

ApplicationWindow {
    id: root

    property url initialPage: Qt.resolvedUrl("Home.qml")
    property bool isMobile: Qt.platform.os === "android" || Qt.platform.os === "ios"
    property alias navigation: navigationController

    signal navigateTo(url resourceUrl)

    color: Theme.background
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
