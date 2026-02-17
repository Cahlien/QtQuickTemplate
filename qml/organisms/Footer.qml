import QtQuick

Item {
    id: root

    height: 56
    z: 1

    Rectangle {
        anchors.fill: parent
        color: Theme.surface

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: Theme.outline
        }

        Text {
            anchors.centerIn: parent
            text: qsTr("Footer")
            color: Theme.onSurfaceVariant
            font: Theme.labelLarge
        }
    }
}
