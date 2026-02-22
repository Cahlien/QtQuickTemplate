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
            Component.onCompleted: {
                console.log('[ ' + Qt.formatDateTime(new Date(), "ddMMMyyyy hh:mm:ss.zzz").toUpperCase() + ' ] License page loaded.')

            }

            Component.onDestruction: {
                console.log('[ ' + Qt.formatDateTime(new Date(), "ddMMMyyyy hh:mm:ss.zzz").toUpperCase() + ' ] License page destroyed.')
            }

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
