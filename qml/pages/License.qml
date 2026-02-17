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

    Component.onCompleted: {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    root.licenseContent = xhr.responseText;
                }
            }
        };
        xhr.open("GET", Qt.resolvedUrl("LICENSE"));
        xhr.send();
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
