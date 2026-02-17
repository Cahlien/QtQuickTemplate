import QtQuick
import AppTheme

Item {
    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Text {
            anchors.centerIn: parent
            color: Theme.text
            font: Theme.headlineMedium
            text: qsTr("Home")
        }
    }
}
