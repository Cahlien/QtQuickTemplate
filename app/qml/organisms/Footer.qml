import QtQuick
import dev.crowell.AppTheme

/*!
    \qmltype Footer
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits Item
    \brief Application footer bar with copyright and a clickable license link.

    Footer renders a surface-colored bar with a top border line,
    a copyright notice on the left, and a clickable "MIT License"
    link on the right. Clicking the link emits \l licenseRequested.

    \sa Header, MainPortraitLayout, MainLandscapeLayout
*/
Item {
    id: root

    /*!
        \qmlsignal Footer::licenseRequested()
        Emitted when the user taps the license link.
    */
    signal licenseRequested()

    height: 56
    z: 1

    Rectangle {
        anchors.fill: parent
        color: Theme.surface

        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: Theme.border
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingMd
            anchors.verticalCenter: parent.verticalCenter
            text: "\u00A9 " + new Date().getFullYear() + " Matthew Crowell"
            color: Theme.mutedText
            font: Theme.labelLarge
        }

        Text {
            id: licenseLink
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacingMd
            anchors.verticalCenter: parent.verticalCenter
            text: "MIT License"
            color: Theme.primary
            font.family: Theme.labelLarge.family
            font.pixelSize: Theme.labelLarge.pixelSize
            font.weight: Theme.labelLarge.weight
            font.underline: linkMouse.containsMouse

            MouseArea {
                id: linkMouse
                objectName: "licenseLinkArea"
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.licenseRequested()
            }
        }
    }
}
