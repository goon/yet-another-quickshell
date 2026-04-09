import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

BasePopoutWindow {
    id: root

    panelNamespace: "quickshell:forecast"

    RowLayout {
        anchors.fill: parent
        spacing: Theme.geometry.spacing.large

        CalendarForecast {
            id: cal
        }

        WeatherForecast {
            id: weather
        }
    }
}
