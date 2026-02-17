import QtQuick
import QtQuick.Layouts
import AppTheme

Rectangle {
    id: root

    property Item footer
    property Item header
    property Item content
    property NavigationController navigation

    color: Theme.background

    Rectangle {
        id: safeAreaContent

        anchors.fill: parent
        anchors.topMargin: root.SafeArea.margins.top
        anchors.bottomMargin: root.SafeArea.margins.bottom
        anchors.leftMargin: root.SafeArea.margins.left
        anchors.rightMargin: root.SafeArea.margins.right
        color: Theme.surface

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            LayoutItemProxy {
                target: root.header
                Layout.fillWidth: true
                Layout.preferredHeight: 48
            }

            LayoutItemProxy {
                target: root.content
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            LayoutItemProxy {
                target: root.footer
                Layout.fillWidth: true
                Layout.preferredHeight: 56
            }
        }
    }
}
