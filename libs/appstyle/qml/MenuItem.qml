import QtQuick
import QtQuick.Templates as T
import dev.crowell.AppTheme

/*!
    \qmltype MenuItem
    \inqmlmodule dev.crowell.AppStyle
    \inherits QtQuick.Templates::MenuItem
    \brief Styled menu item with optional check indicator.

    MenuItem renders text with a highlight background when selected.
    When \c checkable is \c true, a
    check-mark indicator appears on the leading edge.
*/
T.MenuItem {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding,
                             36)

    padding: Theme.spacingSm
    leftPadding: Theme.spacingMd
    rightPadding: Theme.spacingMd
    spacing: Theme.spacingSm

    icon.width: 20
    icon.height: 20
    icon.color: control.enabled ? Theme.text : Theme.mutedText

    contentItem: Text {
        leftPadding: control.checkable ? control.indicator.width + control.spacing : 0
        text: control.text
        font: Theme.bodyMedium
        color: control.highlighted ? Theme.onPrimary
             : control.enabled ? Theme.text : Theme.mutedText
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    indicator: Rectangle {
        x: control.mirrored ? control.width - width - control.rightPadding : control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        implicitWidth: 20
        implicitHeight: 20
        radius: Theme.radiusSm
        color: control.checked ? Theme.primary : "transparent"
        border.width: control.checked ? 0 : 1
        border.color: Theme.border
        visible: control.checkable

        Text {
            anchors.centerIn: parent
            text: "\u2713"
            font.pixelSize: 12
            font.weight: Font.Bold
            color: Theme.onPrimary
            visible: control.checked
        }
    }

    background: Rectangle {
        implicitWidth: 180
        implicitHeight: 36
        color: control.highlighted ? Theme.primary
             : control.down ? Theme.surface2
             : "transparent"
        radius: Theme.radiusSm

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }
}
