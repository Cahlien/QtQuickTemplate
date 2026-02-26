import QtQuick
import dev.crowell.AppTheme

Item {
    id: root

    property string readmeContent: ""
    readonly property string moduleRootUrl: "qrc:/qt/qml/dev/crowell/QtQuickTemplate/"

    function truncateCodeLines(text, maxChars) {
        let lines = text.split('\n')
        let inCode = false
        let result = []
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i]
            if (line.trim().startsWith('```')) {
                inCode = !inCode
                result.push(line)
                continue
            }
            if (inCode && line.length > maxChars)
                result.push(line.substring(0, maxChars - 3) + "...")
            else
                result.push(line)
        }
        return result.join('\n')
    }

    FontMetrics {
        id: codeMetrics
        font.family: "monospace"
        font.pixelSize: Theme.bodyMedium.pixelSize
    }

    Component.onCompleted: {
        let xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0)
                    root.readmeContent = xhr.responseText
            }
        }
        xhr.open("GET", root.moduleRootUrl + "README.md")
        xhr.send()
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: readmeText.implicitHeight + Theme.spacingXl * 2
        clip: true

        Text {
            id: readmeText
            width: flickable.width - Theme.spacingMd * 2
            x: Theme.spacingMd
            y: Theme.spacingMd
            text: {
                if (!root.readmeContent)
                    return ""
                let availWidth = flickable.width - Theme.spacingMd * 2
                let charWidth = codeMetrics.averageCharacterWidth
                if (charWidth <= 0)
                    charWidth = 8
                let maxChars = Math.max(20, Math.floor(availWidth / charWidth))
                return root.truncateCodeLines(root.readmeContent, maxChars)
            }
            textFormat: Text.MarkdownText
            wrapMode: Text.Wrap
            color: Theme.text
            font: Theme.bodyMedium
            linkColor: Theme.primary
            onLinkActivated: function(link) {
                Qt.openUrlExternally(link)
            }
        }
    }
}
