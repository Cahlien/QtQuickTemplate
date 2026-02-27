import QtQuick
import QtQuick.Layouts
import dev.crowell.AppTheme

/*!
    \qmltype MainLandscapeLayout
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits Rectangle
    \brief Column-based layout shell for landscape orientation.

    MainLandscapeLayout arranges a \l header, \l navBar, page \l content,
    and \l footer in a vertical ColumnLayout — the same stacking order as
    \l MainPortraitLayout — but constrains the column to a maximum width
    and centers it horizontally so wide screens do not stretch content
    edge-to-edge.

    \sa MainPortraitLayout, Header, Footer
*/
Rectangle {
    id: root

    /*!
        \qmlproperty Item MainLandscapeLayout::footer
        The footer item placed at the bottom of the column.
    */
    property Item footer

    /*!
        \qmlproperty Item MainLandscapeLayout::header
        The header item placed at the top of the column.
    */
    property Item header

    /*!
        \qmlproperty Item MainLandscapeLayout::navBar
        The navigation bar placed between the header and content.
    */
    property Item navBar

    /*!
        \qmlproperty Item MainLandscapeLayout::content
        The main content area that fills the remaining vertical space.
    */
    property Item content

    /*!
        \qmlproperty bool MainLandscapeLayout::showChrome
        When \c false the header, navigation bar, and footer proxies collapse so
        the content area expands to fill the full layout.  Defaults to \c true.
    */
    property bool showChrome: true

    color: Theme.background

    Rectangle {
        id: safeAreaContent

        anchors.fill: parent
        anchors.topMargin: root.SafeArea.margins.top
        anchors.bottomMargin: root.SafeArea.margins.bottom
        anchors.leftMargin: root.SafeArea.margins.left
        anchors.rightMargin: root.SafeArea.margins.right
        color: Theme.background

        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.min(parent.width, 768)
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.surface

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    LayoutItemProxy {
                        target: root.header
                        visible: root.showChrome
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                    }

                    LayoutItemProxy {
                        target: root.navBar
                        visible: root.showChrome
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
                        visible: root.showChrome
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                    }
                }
            }
        }
    }
}
