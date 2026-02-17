import QtQuick
import dev.crowell.AppTheme

/*!
    \qmltype SamplePage
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits Item
    \brief Placeholder page used for navigation testing.
*/
Item {
    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Text {
            anchors.centerIn: parent
            color: Theme.text
            font: Theme.bodyLarge
            text: qsTr("Sample Page")
        }
    }
}
