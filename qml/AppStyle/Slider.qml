import QtQuick
import QtQuick.Templates as T
import AppTheme

T.Slider {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitHandleWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitHandleHeight + topPadding + bottomPadding)

    padding: Theme.spacingSm

    handle: Rectangle {
        x: control.leftPadding + (control.horizontal
           ? control.visualPosition * (control.availableWidth - width) : (control.availableWidth - width) / 2)
        y: control.topPadding + (control.horizontal
           ? (control.availableHeight - height) / 2 : control.visualPosition * (control.availableHeight - height))
        implicitWidth: 20
        implicitHeight: 20
        radius: Theme.radiusFull
        color: control.pressed ? Theme.primaryPressed
             : control.hovered ? Theme.primaryHover
             : Theme.primary
        border.width: control.visualFocus ? Theme.focusWidth : 0
        border.color: Theme.focusOutline
        opacity: control.enabled ? 1.0 : Theme.disabledOpacity

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    background: Rectangle {
        x: control.leftPadding + (control.horizontal ? 0 : (control.availableWidth - width) / 2)
        y: control.topPadding + (control.horizontal ? (control.availableHeight - height) / 2 : 0)
        implicitWidth: control.horizontal ? 200 : 4
        implicitHeight: control.horizontal ? 4 : 200
        width: control.horizontal ? control.availableWidth : implicitWidth
        height: control.horizontal ? implicitHeight : control.availableHeight
        radius: 2
        color: Theme.surface2
        opacity: control.enabled ? 1.0 : Theme.disabledOpacity

        Rectangle {
            y: control.horizontal ? 0 : control.visualPosition * parent.height
            width: control.horizontal ? control.position * parent.width : parent.width
            height: control.horizontal ? parent.height : control.position * parent.height
            radius: 2
            color: Theme.primary
        }
    }
}
