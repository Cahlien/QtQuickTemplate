import QtQuick
import AppTheme

/*!
    \qmltype Home
    \inqmlmodule QtQuickTemplate
    \inherits Item
    \brief Default home page displaying a centered heading.
*/
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
