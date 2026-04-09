import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "System & External Services"

    GridLayout {
        columns: 2
        rowSpacing: Theme.geometry.spacing.dynamicPadding
        columnSpacing: Theme.geometry.spacing.dynamicPadding
        Layout.fillWidth: true

        BaseText {
            text: "Manage your system integration, localized services, and external application defaults."
            color: Theme.colors.text
            pixelSize: Theme.typography.size.medium
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.columnSpan: 2
            Layout.bottomMargin: Theme.geometry.spacing.small
        }

        // --- External Services ---
        BaseText {
            text: "External Services"
            weight: Theme.typography.weights.bold
            color: Theme.colors.primary
            pixelSize: Theme.typography.size.large
            Layout.columnSpan: 2
            Layout.topMargin: Theme.geometry.spacing.large
        }

        BaseText { 
            text: "Web Search URL:" 
            pixelSize: Theme.typography.size.medium
        }
        BaseInput {
            Layout.fillWidth: true
            implicitHeight: 42
            inputPadding: 10
            text: Preferences.webSearchUrl
            placeholderText: "e.g. https://google.com/search?q="
            onEditingFinished: Preferences.webSearchUrl = text
        }

        BaseText { 
            text: "Terminal:" 
            pixelSize: Theme.typography.size.medium
        }
        BaseInput {
            id: terminalInput
            Layout.fillWidth: true
            implicitHeight: 42
            inputPadding: 10
            text: Preferences.terminal
            placeholderText: "e.g. alacritty"
            onEditingFinished: Preferences.terminal = text
        }
    }
}
