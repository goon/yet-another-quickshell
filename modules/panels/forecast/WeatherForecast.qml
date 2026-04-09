import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs

BaseBlock {
    id: weather
    Layout.preferredWidth: 400
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        id: weatherWidget
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.geometry.spacing.medium

        property int currentView: 0 // 0: Hourly, 1: Daily
        property int targetView: 0
        property bool editMode: false
        readonly property bool isDay: Weather.isDay
        readonly property int code: Weather.weatherCode

        function switchView() {
            viewTransition.restart();
        }

        SequentialAnimation {
            id: viewTransition
            
            ParallelAnimation {
                BaseAnimation { target: forecastStrip; property: "opacity"; to: 0; speed: "fast" }
                BaseAnimation { target: forecastStrip; property: "scale"; to: 0.95; speed: "fast" }
            }

            ScriptAction {
                script: weatherWidget.currentView = weatherWidget.currentView === 0 ? 1 : 0
            }

            ParallelAnimation {
                BaseAnimation { target: forecastStrip; property: "opacity"; to: 1; speed: "fast" }
                BaseAnimation { target: forecastStrip; property: "scale"; to: 1.0; speed: "fast"; easing.type: Easing.OutBack }
            }
        }

        function getIcon(code, isDay) {
            if (code === 0)
                return isDay ? "clear_day" : "clear_night";
            if (code >= 1 && code <= 3)
                return isDay ? "partly_cloudy_day" : "partly_cloudy_night";
            if (code >= 45 && code <= 48)
                return "foggy";
            if (code >= 51 && code <= 67)
                return "rainy";
            if (code >= 71 && code <= 77)
                return "weather_snowy";
            if (code >= 80 && code <= 82)
                return "rainy";
            if (code >= 85 && code <= 86)
                return "weather_snowy";
            if (code >= 95 && code <= 99)
                return "thunderstorm";
            return "question_mark";
        }

        function getDayName(index) {
            if (!Weather.dailyForecast || !Weather.dailyForecast.time) return "";
            const date = new Date(Weather.dailyForecast.time[index]);
            const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
            return days[date.getDay()];
        }

        // Top Header: Location and Units
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            
            // Location Section (Static or Search)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // 1. Static View (Click to Edit)
                BaseButton {
                    id: locationButton
                    anchors.fill: parent
                    visible: !weatherWidget.editMode
                    hoverEnabled: false
                    normalColor: Theme.colors.transparent
                    onClicked: weatherWidget.editMode = true
                    
                    RowLayout {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.geometry.spacing.small
                        
                        BaseIcon { 
                            id: locIcon
                            icon: locationButton.containsMouse ? "edit" : "location_on"
                            size: 16 
                            color: Theme.colors.primary 

                            onIconChanged: iconAnim.restart()

                            SequentialAnimation {
                                id: iconAnim
                                BaseAnimation { target: locIcon; property: "scale"; from: 1.0; to: 0.7; speed: "fast" }
                                BaseAnimation { target: locIcon; property: "scale"; to: 1.0; speed: "fast"; easing.type: Easing.OutBack }
                            }
                        }
                        
                        BaseText {
                            text: Preferences.weatherLocationName.split(",")[0]
                            font.pixelSize: Theme.typography.size.medium
                            weight: Theme.typography.weights.bold
                            color: Theme.colors.text
                            elide: Text.ElideRight
                        }
                    }
                }

                // 2. Search View (Activated)
                BaseComboBox {
                    id: locationSearch
                    anchors.fill: parent
                    visible: weatherWidget.editMode
                    opacity: visible ? 1 : 0
                    model: Weather.searchResults
                    textRole: "full_name"
                    searchable: true
                    filterLocally: false
                    displayText: Preferences.weatherLocationName || "Search location..."
                    
                    onSearchTextChanged: Weather.searchLocation(searchText)
                    
                    onActivated: (index) => {
                        var item = Weather.searchResults[index];
                        if (item) {
                            Preferences.weatherLat = item.latitude.toString();
                            Preferences.weatherLong = item.longitude.toString();
                            Preferences.weatherLocationName = item.full_name;
                            weatherWidget.editMode = false;
                        }
                    }

                    Behavior on opacity { BaseAnimation { speed: "fast" } }
                    
                    // Auto-focus logic when becoming visible
                    onVisibleChanged: {
                        if (visible) {
                            forceActiveFocus();
                        }
                    }
                }
            }

            // Unit Switcher
            BaseButton {
                id: unitSwitcher
                visible: !weatherWidget.editMode
                Layout.preferredWidth: 50
                Layout.preferredHeight: 24
                hoverEnabled: false
                normalColor: Theme.colors.transparent
                onClicked: Preferences.weatherUnit = Preferences.weatherUnit === "celsius" ? "fahrenheit" : "celsius"
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    enabled: false
                    
                    BaseText {
                        text: "°C"
                        pixelSize: Theme.typography.size.base
                        color: Preferences.weatherUnit === "celsius" ? Theme.colors.text : Theme.colors.muted
                        weight: Theme.typography.weights.bold
                    }

                    BaseText {
                        text: "/"
                        pixelSize: Theme.typography.size.base
                        color: Theme.colors.muted
                        weight: Theme.typography.weights.bold
                    }

                    BaseText {
                        text: "°F"
                        pixelSize: Theme.typography.size.base
                        color: Preferences.weatherUnit === "fahrenheit" ? Theme.colors.text : Theme.colors.muted
                        weight: Theme.typography.weights.bold
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true }

        // Main Weather Section
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.large
            Layout.alignment: Qt.AlignHCenter

            // Left: Humidity (Moved from Grid)
            RowLayout {
                spacing: Theme.geometry.spacing.medium
                BaseIcon { icon: "humidity_mid"; size: 24; color: Theme.colors.primary }
                ColumnLayout {
                    spacing: 0
                    BaseText { text: "Humidity"; font.pixelSize: 10; color: Theme.colors.muted; weight: Theme.typography.weights.bold }
                    BaseText { text: Weather.humidity; font.pixelSize: 14; color: Theme.colors.text; weight: Theme.typography.weights.bold }
                }
            }

            Item { Layout.fillWidth: true } // Spacer

            RowLayout {
                spacing: Theme.geometry.spacing.large
                
                BaseIcon {
                    id: mainIcon
                    icon: weatherWidget.getIcon(weatherWidget.code, weatherWidget.isDay)
                    size: 64
                    color: Theme.colors.primary
                }

                ColumnLayout {
                    spacing: -Theme.geometry.spacing.small
                    BaseText {
                        text: Weather.temperature
                        font.pixelSize: 42
                        weight: Theme.typography.weights.bold
                        color: Theme.colors.text
                    }
                    BaseText {
                        text: "FEELS LIKE " + Weather.feelsLike
                        font.pixelSize: Theme.typography.size.small
                        weight: Theme.typography.weights.bold
                        color: Theme.colors.muted
                    }
                }
            }

            Item { Layout.fillWidth: true } // Spacer

            // Right: Wind (Moved from Grid)
            RowLayout {
                spacing: Theme.geometry.spacing.medium
                ColumnLayout {
                    spacing: 0
                    BaseText { text: "Wind"; font.pixelSize: 10; color: Theme.colors.muted; weight: Theme.typography.weights.bold; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
                    BaseText { text: Weather.windSpeed; font.pixelSize: 14; color: Theme.colors.text; weight: Theme.typography.weights.bold; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
                }
                BaseIcon { icon: "air"; size: 24; color: Theme.colors.primary }
            }
        }


        Item { Layout.fillHeight: true }

        BaseSeparator { Layout.fillWidth: true }

        // Forecast View Switcher
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.small

            BaseButton {
                id: switcherButton
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                hoverEnabled: false
                normalColor: Theme.colors.transparent
                onClicked: weatherWidget.switchView()
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    enabled: false
                    
                    BaseText {
                        text: "HOURLY"
                        pixelSize: Theme.typography.size.base
                        color: weatherWidget.currentView === 0 ? Theme.colors.text : Theme.colors.muted
                        weight: Theme.typography.weights.bold
                        font.letterSpacing: 2
                    }

                    BaseText {
                        text: "/"
                        pixelSize: Theme.typography.size.base
                        color: Theme.colors.muted
                        weight: Theme.typography.weights.bold
                    }

                    BaseText {
                        text: "7 DAY FORECAST"
                        pixelSize: Theme.typography.size.base
                        color: weatherWidget.currentView === 1 ? Theme.colors.text : Theme.colors.muted
                        weight: Theme.typography.weights.bold
                        font.letterSpacing: 2
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 85
            clip: false

            RowLayout {
                id: forecastStrip
                anchors.fill: parent
                spacing: Theme.geometry.spacing.small
                opacity: 1
                scale: 1

            Repeater {
                model: (Weather.hourlyForecast && Weather.dailyForecast) ? 7 : 0
                
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    readonly property int hourIndex: new Date().getHours() + index

                    BaseText {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            if (weatherWidget.currentView === 0) {
                                var h = hourIndex % 24;
                                return (h < 10 ? "0" + h : h) + ":00"
                            } else {
                                return index === 0 ? "Today" : weatherWidget.getDayName(index)
                            }
                        }
                        font.pixelSize: Theme.typography.size.base
                        color: Theme.colors.muted
                        weight: Theme.typography.weights.normal
                        font.letterSpacing: 0
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }

                    BaseIcon {
                        Layout.alignment: Qt.AlignHCenter
                        icon: {
                            if (weatherWidget.currentView === 0) {
                                return weatherWidget.getIcon(Weather.hourlyForecast.weather_code[hourIndex], (hourIndex % 24 >= 6 && hourIndex % 24 <= 18))
                            } else {
                                return weatherWidget.getIcon(Weather.dailyForecast.weather_code[index], true)
                            }
                        }
                        size: Theme.dimensions.iconLarge
                        color: Theme.colors.primary
                    }

                    BaseText {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            if (weatherWidget.currentView === 0) {
                                return Math.round(Weather.hourlyForecast.temperature_2m[hourIndex]) + "°"
                            } else {
                                return Math.round(Weather.dailyForecast.temperature_2m_max[index]) + "°"
                            }
                        }
                        font.pixelSize: Theme.typography.size.large
                        color: Theme.colors.text
                        weight: Theme.typography.weights.bold
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }
                }
                }
            }
        }

        // Error message if any
        BaseText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Weather.error
            visible: Weather.error !== ""
            font.pixelSize: Theme.typography.size.small
            color: Theme.colors.error
        }
    }
}
