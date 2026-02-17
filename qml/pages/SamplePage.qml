import QtQuick

Item {
    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Text {
            anchors.centerIn: parent
            color: Theme.onSurface
            font: Theme.bodyLarge
            text: qsTr("Sample Page")
        }
    }
}
