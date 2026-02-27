import QtQuick
import QtQuick.Controls
import QtQuick.Window
import dev.crowell.AppTheme

ApplicationWindow {
    id: root
    objectName: "mainWindow"

    readonly property bool isMobile: Qt.platform.os === "android"
                                  || Qt.platform.os === "ios"
    readonly property string currentNavigationUrl: NavigationController.currentUrl
    property bool _displayedShowChrome: navigationStack.displayedShowChrome

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

    onClosing: function(close) {
        if (Qt.platform.os === "android")
            close.accepted = false
    }

    Component.onCompleted: NavigationController.push(Qt.resolvedUrl("pages/Readme.qml").toString())

    Connections {
        target: NavigationController

        function onBackAtRoot() {
            if (Qt.platform.os === "android")
                NavigationController.minimizeApp()
        }
    }

    Item {
        anchors.fill: parent
        focus:        true

        TapHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onTapped: parent.forceActiveFocus()
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Back) {
                event.accepted = true
                if (Qt.platform.os !== "android")
                    NavigationController.pop()
            } else if (event.key === Qt.Key_Backspace
                       && Qt.platform.os !== "android") {
                event.accepted = true
                NavigationController.pop()
            }
        }

        TapHandler {
            acceptedButtons: Qt.BackButton
            acceptedDevices: PointerDevice.Mouse
            onTapped: {
                if (Qt.platform.os !== "android")
                    NavigationController.pop()
            }
        }
    }

    Header {
        id: headerItem
        title: root.title
        visible: root._displayedShowChrome
    }

    NavBar {
        id: navBarItem
        visible: root._displayedShowChrome

        onReadmeRequested:   NavigationController.replace(Qt.resolvedUrl("pages/Readme.qml").toString())
        onControlsRequested: NavigationController.replace(Qt.resolvedUrl("pages/StyleShowcase.qml").toString())
    }

    Binding {
        target:   navBarItem
        property: "currentIndex"
        when:     NavigationController.currentUrl.indexOf("Readme.qml")        !== -1
               || NavigationController.currentUrl.indexOf("StyleShowcase.qml") !== -1
        value:    NavigationController.currentUrl.indexOf("StyleShowcase.qml") !== -1 ? 1 : 0
        restoreMode: Binding.RestoreNone
    }

    Footer {
        id: footerItem
        visible: root._displayedShowChrome
    }

    Connections {
        target: footerItem
        function onLicenseRequested() {
            NavigationController.push(Qt.resolvedUrl("pages/License.qml").toString(), {}, false)
        }
    }

    NavigationStack {
        id: navigationStack
    }

    AdaptiveLayout {
        anchors.fill: parent
        content: navigationStack
        header: headerItem
        navBar: navBarItem
        footer: footerItem
        showChrome: root._displayedShowChrome
    }
}
