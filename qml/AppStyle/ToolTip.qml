import QtQuick
import QtQuick.Templates as T
import AppTheme

T.ToolTip {
    id: control

    x: parent ? (parent.width - implicitWidth) / 2 : 0
    y: -implicitHeight - Theme.spacingSm

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)

    margins: Theme.spacingSm
    padding: Theme.spacingSm
    leftPadding: Theme.spacingMd
    rightPadding: Theme.spacingMd

    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutsideParent | T.Popup.CloseOnReleaseOutsideParent

    contentItem: Text {
        text: control.text
        font: Theme.bodySmall
        color: Theme.text
        wrapMode: Text.Wrap
    }

    background: Rectangle {
        radius: Theme.radiusSm
        color: Theme.surface2
        border.width: 1
        border.color: Theme.border
    }
}
