import QtQuick
import QtQuick.Controls

/*!
    \qmltype Readme
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits Item
    \brief Readme page displaying the project README in scrollable markdown.
*/
BasePage {
    id: root
    requiredPageProps: ({})

    Loader {
        id: contentLoader
        anchors.fill: parent
        active: root.StackView.status !== StackView.Inactive
        source: Qt.resolvedUrl("content/ReadmeContent.qml")
    }
}
