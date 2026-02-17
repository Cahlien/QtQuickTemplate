import QtQuick
import QtQuick.Templates as T
import AppTheme

/*!
    \qmltype TabButton
    \inqmlmodule AppStyle
    \inherits QtQuick.Templates::TabButton
    \brief Styled tab button with a bottom accent bar when selected.

    TabButton renders text that switches to the primary color when
    checked. A 2px accent bar appears along the bottom edge of the
    active tab. Hover and press produce surface-color feedback.
*/
T.TabButton {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             40)

    padding: Theme.spacingSm
    leftPadding: Theme.spacingMd
    rightPadding: Theme.spacingMd
    spacing: Theme.spacingSm

    contentItem: Text {
        text: control.text
        font: Theme.labelLarge
        color: control.checked ? Theme.primary
             : control.hovered ? Theme.text
             : Theme.mutedText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        opacity: control.enabled ? 1.0 : Theme.disabledOpacity

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    background: Rectangle {
        implicitHeight: 40
        color: control.checked ? Theme.surface
             : control.down ? Theme.surface2
             : control.hovered ? Theme.surfaceHover
             : Theme.background

        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 2
            color: Theme.primary
            visible: control.checked

            Behavior on visible {
                enabled: false
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: control.visualFocus ? Theme.focusWidth : 0
            border.color: Theme.focusOutline
            radius: Theme.radiusSm
        }
    }
}
