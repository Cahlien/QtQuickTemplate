import QtQuick
import QtQuick.Controls


/*!
    \qmltype License
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits Item
    \brief Page displaying the project LICENSE in scrollable markdown.
*/
BasePage {
    id: root
    showChrome: false
    requiredPageProps: ({})

    signal closeRequested

    Loader {
        id: contentLoader
        anchors.fill: parent
        active: root.StackView.status === StackView.Active
             || root.StackView.status === StackView.Activating
             || root.StackView.status === StackView.Deactivating
        source: Qt.resolvedUrl("LicenseContent.qml")

        onLoaded: {
            if (item && typeof item.closeRequested !== "undefined")
                item.closeRequested.connect(root.closeRequested)
        }
    }
}
