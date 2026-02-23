import QtQuick
import QtQuick.Templates as T

/*!
    \qmltype ProgressBar
    \inqmlmodule dev.crowell.AppStyle
    \inherits QtQuick.Templates::ProgressBar
    \brief Styled progress indicator with determinate and indeterminate modes.

    ProgressBar draws a thin rounded track with a primary-colored fill.
    In indeterminate mode the fill rectangle animates back and forth
    continuously.
*/
T.ProgressBar {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 0

    contentItem: Item {
        implicitWidth: 200
        implicitHeight: 6
        clip: true

        Rectangle {
            width: control.indeterminate ? parent.width * 0.4
                 : control.position * parent.width
            height: parent.height
            radius: 3
            color: Theme.primary

            NumberAnimation on x {
                running: control.indeterminate && control.visible
                from: -parent.width * 0.4
                to: parent.width
                duration: 1200
                loops: Animation.Infinite
            }
        }
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 6
        radius: 3
        color: Theme.surface2
        opacity: control.enabled ? 1.0 : Theme.disabledOpacity
    }
}
