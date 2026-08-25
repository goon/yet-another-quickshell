import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

BaseContainer {
    id: root
    
    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false
    
    implicitWidth: 200
    implicitHeight: Globals.dimensions.barItemHeight

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    Item {
        id: layout
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        Layout.fillWidth: false
        implicitWidth: Math.max(timeText.implicitWidth, dateText.implicitWidth - dateText.font.letterSpacing)
        implicitHeight: timeText.implicitHeight + dateText.implicitHeight - 2

        BaseText {
            id: timeText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: font.letterSpacing / 2
            text: Preferences.timedate.format === "12" ? Qt.formatDateTime(systemClock.date, "hh mm AP") : Qt.formatDateTime(systemClock.date, "HH mm")
            pixelSize: Globals.typography.size.large * 0.9
            weight: Globals.typography.weights.bold
            font.letterSpacing: 3
        }

        BaseText {
            id: dateText
            anchors.top: timeText.bottom
            anchors.topMargin: -2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: font.letterSpacing / 2
            text: Qt.formatDateTime(systemClock.date, "ddd dd MMM").toUpperCase()
            pixelSize: Globals.typography.size.small * 0.9
            font.letterSpacing: 3
        }
    }
}
