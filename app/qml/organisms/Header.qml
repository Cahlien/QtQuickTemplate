import QtQuick
import dev.crowell.AppTheme

/*!
    \qmltype Header
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits Item
    \brief Application header bar displaying a centered title.

    Header renders a surface-colored bar with a bottom border separator
    and a centered title label. It is designed to be placed at the top of
    a layout via \l MainPortraitLayout or \l MainLandscapeLayout.

    \sa Footer, MainPortraitLayout, MainLandscapeLayout
*/
Item {
    id: root

    /*!
        \qmlproperty string Header::title
        The text displayed in the center of the header bar.
    */
    property string title: ""

    height: 48
    z: 1

    Rectangle {
        anchors.fill: parent
        color: Theme.surface

        MouseArea { anchors.fill: parent }

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
