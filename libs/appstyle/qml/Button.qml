import QtQuick
import QtQuick.Templates as T

/*!
    \qmltype Button
    \inqmlmodule dev.crowell.AppStyle
    \inherits QtQuick.Templates::Button
    \brief Styled push button with hover, press, and highlighted states.

    Button applies AppTheme tokens for colors, radii, and typography.
    Set \c highlighted to \c true for a
    filled primary-color variant. Focus, hover, and press states each
    produce distinct visual feedback with animated color transitions.
*/
T.Button {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             36)

    padding: Theme.spacingSm
    leftPadding: Theme.spacingMd
    rightPadding: Theme.spacingMd
    spacing: Theme.spacingSm

    contentItem: Text {
        text: control.text
        font: Theme.labelLarge
        color: control.highlighted
               ? Theme.onPrimary
               : Theme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        opacity: control.enabled ? 1.0 : Theme.disabledOpacity
    }

    background: Rectangle {
        implicitWidth: 80
        implicitHeight: 36
        radius: Theme.radiusMd
        color: {
            if (!control.enabled)
                return Theme.surface;
            if (control.highlighted) {
                if (control.down)
                    return Theme.primaryPressed;
                if (control.hovered)
                    return Theme.primaryHover;
                return Theme.primary;
            }
            if (control.down)
                return Theme.surface2;
            if (control.hovered)
                return Theme.surfaceHover;
            return Theme.surface;
        }
        border.width: control.visualFocus ? Theme.focusWidth : 1
        border.color: {
            if (control.visualFocus)
                return Theme.focusOutline;
            if (control.highlighted)
                return "transparent";
            if (control.hovered)
                return Theme.primary;
            return Theme.border;
        }
        opacity: control.enabled ? 1.0 : Theme.disabledOpacity

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    }
}
