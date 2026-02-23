import QtQuick
import QtQuick.Templates as T

/*!
    \qmltype TextField
    \inqmlmodule dev.crowell.AppStyle
    \inherits QtQuick.Templates::TextField
    \brief Styled single-line text input with focus and hover borders.

    TextField provides a surface-colored rounded input. The border
    transitions to the primary color on hover and to the focus-outline
    color when the field has active focus.
*/
T.TextField {
    id: control

    implicitWidth: implicitBackgroundWidth + leftInset + rightInset
                   || Math.max(contentWidth, placeholder.implicitWidth) + leftPadding + rightPadding
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding,
                             placeholder.implicitHeight + topPadding + bottomPadding,
                             36)

    padding: Theme.spacingSm
    leftPadding: Theme.spacingMd
    rightPadding: Theme.spacingMd
    color: Theme.text
    selectionColor: Theme.primary
    selectedTextColor: Theme.onPrimary
    placeholderTextColor: Theme.mutedText
    verticalAlignment: TextInput.AlignVCenter
    font: Theme.bodyMedium
    opacity: control.enabled ? 1.0 : Theme.disabledOpacity

    Text {
        id: placeholder
        x: control.leftPadding
        y: control.topPadding
        width: control.width - control.leftPadding - control.rightPadding
        height: control.height - control.topPadding - control.bottomPadding
        text: control.placeholderText
        font: control.font
        color: Theme.mutedText
        verticalAlignment: control.verticalAlignment
        visible: !control.length && !control.preeditText
                 && (!control.activeFocus || control.horizontalAlignment !== Qt.AlignHCenter)
        elide: Text.ElideRight
        renderType: control.renderType
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 36
        radius: Theme.radiusMd
        color: Theme.surface
        border.width: control.activeFocus ? Theme.focusWidth : 1
        border.color: {
            if (control.activeFocus)
                return Theme.focusOutline;
            if (control.hovered)
                return Theme.primary;
            return Theme.border;
        }

        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    }
}
