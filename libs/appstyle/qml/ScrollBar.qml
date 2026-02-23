import QtQuick
import QtQuick.Templates as T

/*!
    \qmltype ScrollBar
    \inqmlmodule dev.crowell.AppStyle
    \inherits QtQuick.Templates::ScrollBar
    \brief Minimal styled scroll bar with fade-in/out behavior.

    ScrollBar renders a thin rounded thumb that fades in when the
    view is actively scrolling and fades out when idle. Pressed and
    hovered states progressively darken the thumb color.
*/
T.ScrollBar {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 2
    visible: control.policy !== T.ScrollBar.AlwaysOff
    minimumSize: 0.1

    contentItem: Rectangle {
        implicitWidth: control.interactive ? 6 : 4
        implicitHeight: control.interactive ? 6 : 4
        radius: width / 2
        color: control.pressed ? Theme.mutedText
             : control.hovered ? Theme.outline
             : Theme.border
        opacity: control.policy === T.ScrollBar.AlwaysOn
                 || (control.active && control.size < 1.0) ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    background: Rectangle {
        implicitWidth: control.interactive ? 10 : 8
        implicitHeight: control.interactive ? 10 : 8
        color: "transparent"
    }
}
