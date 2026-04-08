import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

BaseBlock {
    id: root
    
    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false
    // Explicitly bind width for stable hover and layout in the bar
    implicitWidth: layout.implicitWidth + (paddingHorizontal * 2)
    implicitHeight: Theme.dimensions.barItemHeight
    paddingVertical: 0
    hoverEnabled: false
    clickable: true
    
    Component.onCompleted: PopoutService.clockItem = root
    Component.onDestruction: PopoutService.clockItem = null

    onClicked: {
        PopoutService.toggleCalendarPopout();
    }
    popoutOnHover: true
    onHoverAction: PopoutService.openCalendarPopout

    onMiddleClicked: {
        Weather.fetchWeather();
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    // Centering wrapper to ensure proper alignment and hover area
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitWidth: layout.implicitWidth
        implicitHeight: layout.implicitHeight

        RowLayout {
            id: layout
            anchors.centerIn: parent
            spacing: Theme.geometry.spacing.medium

            // Time with bold hour
            BaseText {
                text: "<b>" + Qt.formatDateTime(systemClock.date, "hh") + "</b>" + " " + Qt.formatDateTime(systemClock.date, "mm")
                textFormat: Text.RichText
                pixelSize: Theme.typography.size.medium
                weight: Theme.typography.weights.normal
                color: root.containsMouse ? Theme.colors.primary : Theme.colors.text
            }

            BaseSeparator {
                orientation: BaseSeparator.Vertical
                fill: false
                thickness: 1
                Layout.preferredHeight: Theme.dimensions.iconSmall
                Layout.preferredWidth: 1
                opacity: 0.3
                color: Theme.colors.text
            }

            // Temperature
            BaseText {
                text: Weather.temperature
                pixelSize: Theme.typography.size.medium
                weight: Theme.typography.weights.normal
                color: root.containsMouse ? Theme.colors.primary : Theme.colors.text
            }
        }
    }
}
