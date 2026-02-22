import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import dev.crowell.AppTheme

Item {
    id: root

    property string licenseContent: ""
    signal closeRequested

    Component.onCompleted: {
        let xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0)
                    root.licenseContent = xhr.responseText
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
            ShaderEffectSource {
                id: backgroundProxy
                sourceItem: flickable
                sourceRect: Qt.rect(closeButton.x, closeButton.y,
                                    closeButton.width, closeButton.height)
                live: true
                recursive: false
            }

            MultiEffect {
                id: glassEffect
                anchors.fill: parent
                source: backgroundProxy

                blurEnabled: true
                blurMax: 32
                blur: 1.0

                maskEnabled: true
                maskSource: maskShape

                autoPaddingEnabled: false
            }

            Rectangle {
                id: maskShape
                anchors.fill: parent
                radius: width / 2
                visible: false
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
