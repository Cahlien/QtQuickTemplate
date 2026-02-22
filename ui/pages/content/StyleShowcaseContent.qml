import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import dev.crowell.AppTheme

Item {
    Flickable {
        anchors.fill: parent
        contentHeight: content.implicitHeight + Theme.spacingXl * 2
        clip: true

        ColumnLayout {
            id: content
            width: parent.width
            spacing: Theme.spacingLg

            Item { Layout.preferredHeight: Theme.spacingMd }

            Text {
                text: "Style Showcase"
                font: Theme.headlineMedium
                color: Theme.text
                Layout.leftMargin: Theme.spacingMd
            }

            Text {
                text: "All controls styled by AppStyle with crowell.dev branding"
                font: Theme.bodyMedium
                color: Theme.mutedText
                Layout.leftMargin: Theme.spacingMd
            }

            GroupBox {
                title: "Button"
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMd

                ColumnLayout {
                    spacing: Theme.spacingSm
                    width: parent.width

                    RowLayout {
                        spacing: Theme.spacingSm
                        Button { text: "Default" }
                        Button { text: "Highlighted"; highlighted: true }
                        Button { text: "Disabled"; enabled: false }
                    }
                }
            }

            GroupBox {
                title: "TextField"
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMd

                ColumnLayout {
                    spacing: Theme.spacingSm
                    width: parent.width

                    TextField { placeholderText: "Enter text..."; Layout.fillWidth: true }
                    TextField { text: "With content"; Layout.fillWidth: true }
                    TextField { placeholderText: "Disabled"; enabled: false; Layout.fillWidth: true }
                }
            }

            GroupBox {
                title: "CheckBox"
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMd

                ColumnLayout {
                    spacing: Theme.spacingSm
                    CheckBox { text: "Unchecked" }
                    CheckBox { text: "Checked"; checked: true }
                    CheckBox { text: "Disabled"; enabled: false }
                }
            }

            GroupBox {
                title: "Switch"
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMd

                ColumnLayout {
                    spacing: Theme.spacingSm
                    Switch { text: "Off" }
                    Switch { text: "On"; checked: true }
                    Switch { text: "Disabled"; enabled: false }
                }
            }

            GroupBox {
                title: "Slider"
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMd

                ColumnLayout {
                    spacing: Theme.spacingSm
                    width: parent.width

                    Slider { value: 0.5; Layout.fillWidth: true }
                    Slider { value: 0.75; enabled: false; Layout.fillWidth: true }
                }
            }

            GroupBox {
                title: "ProgressBar"
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMd

                ColumnLayout {
                    spacing: Theme.spacingSm
                    width: parent.width

                    ProgressBar { value: 0.6; Layout.fillWidth: true }
                    ProgressBar { indeterminate: true; Layout.fillWidth: true }
                }
            }

            GroupBox {
                title: "ComboBox"
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMd

                ColumnLayout {
                    spacing: Theme.spacingSm
                    ComboBox { model: ["Option A", "Option B", "Option C"] }
                    ComboBox { model: ["Disabled"]; enabled: false }
                }
            }

            GroupBox {
                title: "TabButton"
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMd

                ColumnLayout {
                    spacing: Theme.spacingSm
                    width: parent.width

                    TabBar {
                        Layout.fillWidth: true
                        TabButton { text: "Tab 1" }
                        TabButton { text: "Tab 2" }
                        TabButton { text: "Tab 3" }
                    }
                }
            }

            GroupBox {
                title: "Theme"
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMd

                Switch {
                    text: Theme.darkMode ? "Dark Mode" : "Light Mode"
                    checked: Theme.darkMode
                    onCheckedChanged: Theme.darkMode = checked
                }
            }

            Item { Layout.preferredHeight: Theme.spacingXl }
        }
    }
}
