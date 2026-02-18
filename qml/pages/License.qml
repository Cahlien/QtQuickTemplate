import QtQuick
import dev.crowell.AppTheme

/*!
    \qmltype License
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits Item
    \brief Page displaying the project LICENSE in scrollable markdown.
*/
Item {
    id: root

    property string licenseContent: ""
    signal closeRequested

    Component.onCompleted: {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    root.licenseContent = xhr.responseText
                }
            }
        }
        xhr.open("GET", Qt.resolvedUrl("LICENSE"))
        xhr.send()
    }

    ToolButton {
        id: closeButton
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 12

        width: 36
        height: 36
        z: 100

        onClicked: root.closeRequested()

        contentItem: Text {
            text: "\u00D7" // ×
            font.pixelSize: 20
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: "white"
        }

        background: Rectangle {
            radius: width / 2
            color: closeButton.pressed ? "#ffffff33" : closeButton.hovered ? "#ffffff22" : "#00000000"
            border.color: "#ffffff33"
            border.width: 1
        }
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: licenseText.implicitHeight + Theme.spacingXl * 2
        clip: true

        Text {
            id: licenseText
            width: flickable.width - Theme.spacingMd * 2
            x: Theme.spacingMd
            y: Theme.spacingMd
            text: root.licenseContent
            textFormat: Text.MarkdownText
            wrapMode: Text.Wrap
            color: Theme.text
            font: Theme.bodyMedium
            linkColor: Theme.primary
        }
    }
}
