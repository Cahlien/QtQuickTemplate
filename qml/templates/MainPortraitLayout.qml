import QtQuick
import QtQuick.Layouts
import dev.crowell.AppTheme

/*!
    \qmltype MainPortraitLayout
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits Rectangle
    \brief Column-based layout shell for portrait orientation.

    MainPortraitLayout arranges a \l header, page \l content, and \l footer
    in a vertical ColumnLayout within safe-area margins. It is activated
    automatically by \l Main when the window height exceeds its width.

    \sa MainLandscapeLayout, Header, Footer
*/
Rectangle {
    id: root

    /*!
        \qmlproperty Item MainPortraitLayout::footer
        The footer item placed at the bottom of the column.
    */
    property Item footer

    /*!
        \qmlproperty Item MainPortraitLayout::header
        The header item placed at the top of the column.
    */
    property Item header

    /*!
        \qmlproperty Item MainPortraitLayout::navBar
        The navigation bar placed between the header and content.
    */
    property Item navBar

    /*!
        \qmlproperty Item MainPortraitLayout::content
        The main content area that fills the remaining vertical space.
    */
    property Item content

    color: Theme.background

    Rectangle {
        id: safeAreaContent

        anchors.fill: parent
        anchors.topMargin: root.SafeArea.margins.top
        anchors.bottomMargin: root.SafeArea.margins.bottom
        anchors.leftMargin: root.SafeArea.margins.left
        anchors.rightMargin: root.SafeArea.margins.right
        color: Theme.surface

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            LayoutItemProxy {
                target: root.header
                Layout.fillWidth: true
                Layout.preferredHeight: 48
            }

            LayoutItemProxy {
                target: root.navBar
                Layout.fillWidth: true
                Layout.preferredHeight: 48
            }

            LayoutItemProxy {
                target: root.content
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            LayoutItemProxy {
                target: root.footer
                Layout.fillWidth: true
                Layout.preferredHeight: 56
            }
        }
    }
}
