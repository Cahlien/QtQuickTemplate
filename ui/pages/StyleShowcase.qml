import QtQuick
import QtQuick.Controls

/*!
    \qmltype StyleShowcase
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits Item
    \brief Scrollable gallery demonstrating every AppStyle control.

    StyleShowcase presents grouped examples of Button, TextField,
    CheckBox, Switch, Slider, ProgressBar, ComboBox, TabButton,
    and a dark-mode toggle so that the custom style can be visually
    verified in one place.
*/
BasePage {
    id: root
    requiredPageProps: ({})

    Loader {
        id: contentLoader
        anchors.fill: parent
        active: root.StackView.status !== StackView.Inactive
        source: Qt.resolvedUrl("content/StyleShowcaseContent.qml")
    }
}
