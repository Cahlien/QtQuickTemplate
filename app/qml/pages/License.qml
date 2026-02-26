pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import dev.crowell.QtQuickTemplate 1.0

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

    Component {
        id: licenseContentComponent

        LicenseContent {
            onCloseRequested: root.closeRequested()
        }
    }

    Loader {
        id: contentLoader
        anchors.fill: parent
        active: root.StackView.status !== StackView.Inactive

        sourceComponent: licenseContentComponent
    }
}
