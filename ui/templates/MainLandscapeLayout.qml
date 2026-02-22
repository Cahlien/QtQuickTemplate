import QtQuick
import QtQuick.Layouts
import dev.crowell.AppTheme

/*!
    \qmltype MainLandscapeLayout
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits Rectangle
    \brief Side-navigation layout shell for landscape orientation.

    MainLandscapeLayout places the \l header and \l footer in a narrow
    side column on the left, with the page \l content filling the
    remaining width. It is activated automatically by \l Main when the
    window width exceeds its height.

    \sa MainPortraitLayout, Header, Footer
*/
Rectangle {
    id: root

    /*!
        \qmlproperty Item MainLandscapeLayout::footer
        The footer item placed at the bottom of the side column.
    */
    property Item footer

    /*!
        \qmlproperty Item MainLandscapeLayout::header
        The header item placed at the top of the side column.
    */
    property Item header

    /*!
        \qmlproperty Item MainLandscapeLayout::navBar
        The navigation bar placed below the header in the side column.
    */
    property Item navBar

    /*!
        \qmlproperty Item MainLandscapeLayout::content
        The main content area filling the right portion of the layout.
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
        color: Theme.surface

        RowLayout {
            anchors.fill: parent
            spacing: 0

            ColumnLayout {
                Layout.preferredWidth: 200
                Layout.fillHeight: true
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

                Item {
                    Layout.fillHeight: true
                }

                LayoutItemProxy {
                    target: root.footer
                    visible: root.showChrome
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                }
            }

            LayoutItemProxy {
                target: root.content
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
