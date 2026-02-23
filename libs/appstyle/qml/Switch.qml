import QtQuick
import QtQuick.Templates as T

/*!
    \qmltype Switch
    \inqmlmodule dev.crowell.AppStyle
    \inherits QtQuick.Templates::Switch
    \brief Styled toggle switch with animated thumb and track.

    Switch displays a pill-shaped track that transitions to the primary
    color when checked. The circular thumb slides between positions with
    an eased animation.
*/
T.Switch {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    padding: Theme.spacingXs
    spacing: Theme.spacingSm

    indicator: Rectangle {
        implicitWidth: 44
        implicitHeight: 24
        x: control.text ? (control.mirrored ? control.width - width - control.rightPadding
                                             : control.leftPadding)
                        : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2
        radius: Theme.radiusFull
        color: control.checked ? Theme.primary : Theme.surface2
        border.width: control.visualFocus ? Theme.focusWidth : 1
        border.color: control.visualFocus ? Theme.focusOutline
                    : control.checked ? Theme.primary : Theme.border
        opacity: control.enabled ? 1.0 : Theme.disabledOpacity

        Behavior on color { ColorAnimation { duration: Theme.animNormal } }

        Rectangle {
            x: control.checked ? parent.width - width - 3 : 3
            y: (parent.height - height) / 2
            width: 18
            height: 18
            radius: Theme.radiusFull
            color: control.checked ? Theme.onPrimary : Theme.mutedText

            Behavior on x { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.InOutQuad } }
            Behavior on color { ColorAnimation { duration: Theme.animNormal } }
        }
    }

    contentItem: Text {
        leftPadding: control.indicator && !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.indicator && control.mirrored ? control.indicator.width + control.spacing : 0
        text: control.text
        font: Theme.bodyMedium
        color: Theme.text
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        opacity: control.enabled ? 1.0 : Theme.disabledOpacity
    }
}
