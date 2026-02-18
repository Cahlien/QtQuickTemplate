import QtQuick
import QtQuick.Controls
import QtQuick.Effects
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

        // Position the button in the upper right
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 12
        width: 36
        height: 36
        z: 100

        onClicked: root.closeRequested()

        contentItem: Item {
            Rectangle {
                anchors.centerIn: parent
                width: 18
                height: 2
                rotation: 45
                antialiasing: true
                radius: 1
                color: closeButton.hovered ? "#40E0D0" : "#E0F2F1"
            }
            Rectangle {
                anchors.centerIn: parent
                width: 18
                height: 2
                rotation: -45
                antialiasing: true
                radius: 1
                color: closeButton.hovered ? "#40E0D0" : "#E0F2F1"
            }
        }

        background: Item {
            Rectangle {
                id: maskRect
                anchors.fill: parent
                radius: width / 2
                visible: false
            }

            // The Glass Blur Effect
            MultiEffect {
                id: glassEffect
                source: licenseFlickable
                anchors.fill: parent
                maskSource: maskRect
                blurEnabled: true
                blur: 1.0
                autoPaddingEnabled: false
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: closeButton.pressed ? "#4440E0D0" : closeButton.hovered ? "#2240E0D0" : "#11ffffff"
                border.color: closeButton.hovered ? "#8840E0D0" : "#33ffffff"
                border.width: 1
            }
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
