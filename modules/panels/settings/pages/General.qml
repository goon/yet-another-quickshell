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

        // --- Weather ---
        BaseText {
            text: "Weather"
            weight: Theme.typography.weights.bold
            color: Theme.colors.primary
            pixelSize: Theme.typography.size.large
            Layout.columnSpan: 2
            Layout.topMargin: Theme.geometry.spacing.small
        }

        ColumnLayout {
            spacing: 0
            BaseText {
                text: "Location Name:"
                pixelSize: Theme.typography.size.medium
            }

            BaseText {
                text: "e.g. London"
                color: Theme.colors.muted
                pixelSize: Theme.typography.size.small
            }
        }

        BaseComboBox {
            id: locationSelector
            Layout.fillWidth: true
            model: Weather.searchResults
            textRole: "full_name"
            searchable: true
            filterLocally: false
            displayText: Preferences.weatherLocationName || "Search location..."
            
            onSearchTextChanged: {
                Weather.searchLocation(searchText);
            }

            onActivated: (index) => {
                var item = Weather.searchResults[index];
                if (item) {
                    Preferences.weatherLat = item.latitude.toString();
                    Preferences.weatherLong = item.longitude.toString();
                    Preferences.weatherLocationName = item.full_name;
                }
            }
        }

        BaseText {
            text: "Show Location in Popout:"
            pixelSize: Theme.typography.size.medium
        }

        BaseSwitch {
            checked: Preferences.weatherShowLocation
            onToggled: Preferences.weatherShowLocation = checked
            Layout.alignment: Qt.AlignLeft
        }

        BaseSeparator {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            Layout.topMargin: Theme.geometry.spacing.medium
            Layout.bottomMargin: Theme.geometry.spacing.medium
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
