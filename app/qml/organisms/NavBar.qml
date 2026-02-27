import QtQuick
import QtQuick.Controls
import dev.crowell.AppTheme

/*!
    \qmltype NavBar
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits Item
    \brief Tab-based navigation bar for switching between app pages.

    NavBar renders a surface-colored bar with a top border separator
    and a TabBar containing Readme and Controls tabs.

    \sa Header, Footer, MainPortraitLayout, MainLandscapeLayout
*/
Item {
    id: root

    /*!
        \qmlproperty int NavBar::currentIndex
        The index of the currently selected tab. Bound to the
        internal TabBar's currentIndex.
    */
    property alias currentIndex: tabBar.currentIndex

    signal readmeRequested()
    signal controlsRequested()

    height: 48
    z: 1

    Rectangle {
        anchors.fill: parent
        color: Theme.surface

        TabBar {
            id: tabBar
            anchors.fill: parent

            TabButton {
                objectName: "readmeTab"
                text: qsTr("Readme")
                onClicked: root.readmeRequested()
            }

            TabButton {
                objectName: "controlsTab"
                text: qsTr("Controls")
                onClicked: root.controlsRequested()
            }
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
