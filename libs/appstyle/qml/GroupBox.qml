import QtQuick
import QtQuick.Templates as T
import dev.crowell.AppTheme

/*!
    \qmltype GroupBox
    \inqmlmodule dev.crowell.AppStyle
    \inherits QtQuick.Templates::GroupBox
    \brief Styled container with a title label and bordered background.

    GroupBox wraps its content in a rounded, bordered rectangle and
    displays a title using the \c labelLarge font token.
*/
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
