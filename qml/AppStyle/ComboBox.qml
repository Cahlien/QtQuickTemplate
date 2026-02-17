import QtQuick
import QtQuick.Templates as T
import QtQuick.Window
import AppTheme

/*!
    \qmltype ComboBox
    \inqmlmodule AppStyle
    \inherits QtQuick.Templates::ComboBox
    \brief Styled drop-down selector with a themed popup list.

    ComboBox provides a surface-colored input with a down-arrow indicator
    and a popup list of delegates styled with AppTheme tokens. The
    currently highlighted delegate receives the primary color.
*/
T.ComboBox {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding,
                             36)

    leftPadding: Theme.spacingMd
    rightPadding: Theme.spacingMd + (indicator ? indicator.width + spacing : 0)
    padding: Theme.spacingSm
    spacing: Theme.spacingSm

    indicator: Text {
        x: control.mirrored ? control.leftPadding : control.width - width - control.rightPadding + control.spacing
        y: control.topPadding + (control.availableHeight - height) / 2
        text: "\u25BE"
        font.pixelSize: 14
        color: Theme.mutedText
        opacity: control.enabled ? 1.0 : Theme.disabledOpacity
    }

    contentItem: T.TextField {
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        text: control.editable ? control.editText : control.displayText
        enabled: control.editable
        autoScroll: control.editable
        readOnly: control.down
        inputMethodHints: control.inputMethodHints
        validator: control.validator
        selectByMouse: control.selectTextByMouse
        font: Theme.bodyMedium
        color: Theme.text
        selectionColor: Theme.primary
        selectedTextColor: Theme.onPrimary
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitWidth: 140
        implicitHeight: 36
        radius: Theme.radiusMd
        color: Theme.surface
        border.width: control.visualFocus ? Theme.focusWidth : 1
        border.color: {
            if (control.visualFocus)
                return Theme.focusOutline;
            if (control.hovered)
                return Theme.primary;
            return Theme.border;
        }
        opacity: control.enabled ? 1.0 : Theme.disabledOpacity

        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    }

    popup: T.Popup {
        y: control.height + Theme.spacingXs
        width: control.width
        height: Math.min(contentItem.implicitHeight + topPadding + bottomPadding,
                         control.Window.height - topMargin - bottomMargin)
        padding: Theme.spacingXs
        topMargin: Theme.spacingSm
        bottomMargin: Theme.spacingSm

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0

            T.ScrollIndicator.vertical: T.ScrollIndicator {}
        }

        background: Rectangle {
            radius: Theme.radiusMd
            color: Theme.surface
            border.width: 1
            border.color: Theme.border
        }
    }

    delegate: T.ItemDelegate {
        width: ListView.view ? ListView.view.width : implicitWidth
        height: 36
        padding: Theme.spacingSm
        leftPadding: Theme.spacingMd

        contentItem: Text {
            text: control.textRole
                  ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole])
                  : modelData
            font: Theme.bodyMedium
            color: highlighted ? Theme.onPrimary : Theme.text
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: Theme.radiusSm
            color: highlighted ? Theme.primary : "transparent"

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        highlighted: control.highlightedIndex === index
    }
}
