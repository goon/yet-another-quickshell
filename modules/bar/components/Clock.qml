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

    // Individual segment for animated time units
    component TimeSegment: Item {
        id: segment
        property string text: ""
        property bool bold: false
        property color textColor: root.containsMouse ? Theme.colors.primary : Theme.colors.text
        
        implicitWidth: widthDummy.implicitWidth
        implicitHeight: widthDummy.implicitHeight
        clip: true

        BaseText {
            id: widthDummy
            visible: false
            text: segment.bold ? "<b>00</b>" : "00"
            textFormat: Text.RichText
            pixelSize: Theme.typography.size.medium
            weight: Theme.typography.weights.normal
        }

        readonly property real centerY: (segment.height - currentText.height) / 2

        property string displayedText: text

        onTextChanged: {
            nextText.text = text;
            anim.restart();
        }

        BaseText {
            id: currentText
            anchors.horizontalCenter: segment.horizontalCenter
            y: segment.centerY
            text: segment.bold ? "<b>" + segment.displayedText + "</b>" : segment.displayedText
            textFormat: Text.RichText
            pixelSize: Theme.typography.size.medium
            weight: Theme.typography.weights.normal
            color: segment.textColor
        }

        BaseText {
            id: nextText
            anchors.horizontalCenter: segment.horizontalCenter
            y: segment.centerY - segment.height
            opacity: 0
            text: segment.bold ? "<b>" + segment.text + "</b>" : segment.text
            textFormat: Text.RichText
            pixelSize: Theme.typography.size.medium
            weight: Theme.typography.weights.normal
            color: segment.textColor
        }

        SequentialAnimation {
            id: anim
            
            ParallelAnimation {
                BaseAnimation {
                    target: currentText
                    property: "y"
                    to: segment.centerY + segment.height
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                BaseAnimation {
                    target: currentText
                    property: "opacity"
                    to: 0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                BaseAnimation {
                    target: nextText
                    property: "y"
                    from: segment.centerY - segment.height
                    to: segment.centerY
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                BaseAnimation {
                    target: nextText
                    property: "opacity"
                    to: 1
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            ScriptAction {
                script: {
                    segment.displayedText = segment.text;
                    currentText.y = segment.centerY;
                    currentText.opacity = 1;
                    nextText.y = segment.centerY - segment.height;
                    nextText.opacity = 0;
                }
            }
        }
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

            // Time Segments
            RowLayout {
                spacing: 0

                TimeSegment {
                    text: Qt.formatDateTime(systemClock.date, "hh")
                    bold: true
                }

                TimeSegment {
                    text: Qt.formatDateTime(systemClock.date, "mm")
                }
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
