import QtQuick
import AppTheme

Item {
    id: root

    property string title: ""

    height: 48
    z: 1

    Rectangle {
        anchors.fill: parent
        color: Theme.surface

        Text {
            anchors.centerIn: parent
            text: root.title
            color: Theme.text
            font: Theme.titleLarge
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Theme.border
        }
    }
}
