import QtQuick
import dev.crowell.AppTheme

/*!
    \qmltype Footer
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits Item
    \brief Application footer bar with a top border separator.

    Footer renders a surface-colored bar with a top border line and
    a centered "Footer" label. It is designed to be placed at the
    bottom of a layout via \l MainPortraitLayout or \l MainLandscapeLayout.

    \sa Header, MainPortraitLayout, MainLandscapeLayout
*/
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
            color: Theme.border
        }

        Text {
            anchors.centerIn: parent
            text: qsTr("Footer")
            color: Theme.mutedText
            font: Theme.labelLarge
        }
    }
}
