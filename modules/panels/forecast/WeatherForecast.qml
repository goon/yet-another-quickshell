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
        readonly property bool isDay: Weather.isDay
        readonly property int code: Weather.weatherCode

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
            
            RowLayout {
                spacing: Theme.geometry.spacing.small
                BaseIcon { icon: "location_on"; size: 16; color: Theme.colors.primary }
                BaseText {
                    text: Preferences.weatherLocationName.split(",")[0]
                    font.pixelSize: Theme.typography.size.medium
                    weight: Theme.typography.weights.bold
                    color: Theme.colors.text
                    elide: Text.ElideRight
                    Layout.maximumWidth: 150
                }
            }

            Item { Layout.fillWidth: true }

            BaseMultiButton {
                Layout.preferredWidth: 60
                buttonHeight: 24
                padding: 2
                model: [ { text: "C", value: "celsius" }, { text: "F", value: "fahrenheit" } ]
                selectedIndex: Preferences.weatherUnit === "celsius" ? 0 : 1
                onButtonClicked: (index) => { Preferences.weatherUnit = model[index].value; }
            }
        }

        // Main Weather Section
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.large
            Layout.alignment: Qt.AlignHCenter

            BaseIcon {
                id: mainIcon
                icon: weatherWidget.getIcon(weatherWidget.code, weatherWidget.isDay)
                size: 80
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

        // Conditions Grid
        GridLayout {
            columns: 2
            Layout.fillWidth: true
            rowSpacing: Theme.geometry.spacing.medium
            columnSpacing: Theme.geometry.spacing.medium

            RowLayout {
                spacing: Theme.geometry.spacing.medium
                Layout.fillWidth: true
                BaseIcon { icon: "humidity_mid"; size: 24; color: Theme.colors.primary }
                ColumnLayout {
                    spacing: 0
                    BaseText { text: "Humidity"; font.pixelSize: 10; color: Theme.colors.muted; weight: Theme.typography.weights.bold }
                    BaseText { text: Weather.humidity; font.pixelSize: 14; color: Theme.colors.text; weight: Theme.typography.weights.bold }
                }
            }

            RowLayout {
                spacing: Theme.geometry.spacing.medium
                Layout.fillWidth: true
                BaseIcon { icon: "air"; size: 24; color: Theme.colors.primary }
                ColumnLayout {
                    spacing: 0
                    BaseText { text: "Wind"; font.pixelSize: 10; color: Theme.colors.muted; weight: Theme.typography.weights.bold }
                    BaseText { text: Weather.windSpeed; font.pixelSize: 14; color: Theme.colors.text; weight: Theme.typography.weights.bold }
                }
            }
        }

        BaseSeparator { Layout.fillWidth: true }

        // Forecast View Switcher
        RowLayout {
            Layout.fillWidth: true
            
            BaseText {
                text: weatherWidget.currentView === 0 ? "NEXT 7 HOURS" : "7-DAY FORECAST"
                font.pixelSize: 10
                color: Theme.colors.muted
                weight: Theme.typography.weights.bold
                Layout.fillWidth: true
            }

            BaseMultiButton {
                Layout.preferredWidth: 100
                buttonHeight: 22
                padding: 2
                model: [ { text: "Hours" }, { text: "Days" } ]
                selectedIndex: weatherWidget.currentView
                onButtonClicked: (index) => { weatherWidget.currentView = index; }
            }
        }

        // Forecast Strip (7 slots)
        RowLayout {
            id: forecastStrip
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            spacing: Theme.geometry.spacing.small

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
                        font.pixelSize: 10
                        color: Theme.colors.muted
                        weight: Theme.typography.weights.bold
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
                        size: 28
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
                        font.pixelSize: 11
                        color: Theme.colors.text
                        weight: Theme.typography.weights.bold
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
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
