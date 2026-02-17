import QtQuick
import QtQuick.Templates as T
import AppTheme

T.GroupBox {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding,
                            implicitLabelWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)

    spacing: Theme.spacingSm
    padding: Theme.spacingMd
    topPadding: padding + (implicitLabelHeight > 0 ? implicitLabelHeight + spacing : 0)

    label: Text {
        x: control.leftPadding
        width: control.availableWidth
        text: control.title
        font: Theme.labelLarge
        color: Theme.text
        elide: Text.ElideRight
    }

    background: Rectangle {
        y: control.topPadding - control.bottomPadding
        width: parent.width
        height: parent.height - control.topPadding + control.bottomPadding
        radius: Theme.radiusMd
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
    }
}
