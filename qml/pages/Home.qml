import QtQuick
import dev.crowell.AppTheme

/*!
    \qmltype Home
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits Item
    \brief Home page displaying the project README in scrollable markdown.
*/
Item {
    id: root

    property string readmeContent: ""

    Component.onCompleted: {
        let xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    root.readmeContent = xhr.responseText;
                }
            }
        };
        xhr.open("GET", Qt.resolvedUrl("README.md"));
        xhr.send();
    }

    Flickable {
        anchors.fill: parent
        contentHeight: readmeText.implicitHeight + Theme.spacingXl * 2
        clip: true

        Text {
            id: readmeText
            width: parent.width - Theme.spacingMd * 2
            x: Theme.spacingMd
            y: Theme.spacingMd
            text: root.readmeContent
            textFormat: Text.MarkdownText
            wrapMode: Text.WrapAnywhere
            color: Theme.text
            font: Theme.bodyMedium
            linkColor: Theme.primary
            onLinkActivated: function(link) {
                Qt.openUrlExternally(link);
            }
        }
    }
}
