import QtQuick

Item {
    id: root

    property Item footer
    property Item header
    property Item navBar
    property Item content
    property bool showChrome: true

    Loader {
        id: layoutLoader
        anchors.fill: parent
        source: root.width <= root.height ? "MainPortraitLayout.qml"
                                          : "MainLandscapeLayout.qml"

        onLoaded: {
            item.content = root.content
            item.header = root.header
            item.navBar = root.navBar
            item.footer = root.footer
            item.showChrome = Qt.binding(() => root.showChrome)
        }
    }
}
