import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs

BaseBlock {
    id: weather
    Layout.preferredWidth: 320
    Layout.fillWidth: false
    Layout.fillHeight: true

    ColumnLayout {
        id: weatherWidget

        readonly property bool isDay: Weather.isDay
        readonly property int code: Weather.weatherCode
        readonly property string temp: Weather.temperature

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
            const days = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
            return days[date.getDay()];
        }

        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.geometry.spacing.medium

        // Current Weather Top Section
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.medium

            BaseIcon {
                icon: weatherWidget.getIcon(weatherWidget.code, weatherWidget.isDay)
                size: Theme.dimensions.iconExtraLarge
                color: Theme.colors.primary
                Layout.alignment: Qt.AlignVCenter
            }

            BaseText {
                text: weatherWidget.temp
                font.pixelSize: Theme.typography.size.display
                weight: Theme.typography.weights.bold
                color: Theme.colors.text
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            BaseText {
                text: Preferences.weatherLocationName.split(",")[0]
                font.pixelSize: Theme.typography.size.large
                color: Theme.colors.text
                visible: Preferences.weatherShowLocation && Preferences.weatherLocationName !== ""
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Horizontal Separator
        BaseSeparator {
            orientation: BaseSeparator.Horizontal
            Layout.fillWidth: true
            Layout.topMargin: Theme.geometry.spacing.medium
            Layout.bottomMargin: Theme.geometry.spacing.medium
        }

        // 5-Day Forecast
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.geometry.spacing.medium

            Repeater {
                model: Weather.dailyForecast ? Math.min(5, Weather.dailyForecast.time.length) : 0
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.geometry.spacing.medium

                    BaseText {
                        Layout.alignment: Qt.AlignHCenter
                        text: weatherWidget.getDayName(index)
                        font.pixelSize: Theme.typography.size.medium
                        color: Theme.colors.muted
                        weight: Theme.typography.weights.bold
                    }

                    BaseIcon {
                        Layout.alignment: Qt.AlignHCenter
                        icon: weatherWidget.getIcon(Weather.dailyForecast.weathercode[index], true)
                        size: Theme.dimensions.iconExtraLarge
                        color: Theme.colors.primary
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4
                        BaseText {
                            text: Math.round(Weather.dailyForecast.temperature_2m_max[index]) + "°"
                            font.pixelSize: Theme.typography.size.medium
                            color: Theme.colors.text
                            weight: Theme.typography.weights.bold
                        }
                        BaseText {
                            text: Math.round(Weather.dailyForecast.temperature_2m_min[index]) + "°"
                            font.pixelSize: Theme.typography.size.small
                            color: Theme.colors.muted
                        }
                    }
                }
            }
        }

        // Error and Refresh
        ColumnLayout {
            Layout.fillWidth: true
            visible: Weather.error !== ""
            spacing: 4

            BaseButton {
                Layout.alignment: Qt.AlignHCenter
                width: 80
                text: "Refresh"
                icon: "refresh"
                onClicked: Weather.fetchWeather()
            }

            BaseText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Weather.error
                font.pixelSize: Theme.typography.size.small
                color: Theme.colors.error
            }
        }
    }
}
