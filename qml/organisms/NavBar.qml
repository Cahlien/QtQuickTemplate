import QtQuick
import QtQuick.Controls
import dev.crowell.AppTheme

/*!
    \qmltype NavBar
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits Item
    \brief Tab-based navigation bar for switching between app pages.

    NavBar renders a surface-colored bar with a top border separator
    and a TabBar containing Home and Controls tabs. The \l currentIndex
    property drives which page is displayed in the content area.

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

    height: 48
    z: 1

    Rectangle {
        anchors.fill: parent
        color: Theme.surface

        TabBar {
            id: tabBar
            anchors.fill: parent

            TabButton {
                text: qsTr("Home")
            }

            TabButton {
                text: qsTr("Controls")
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
