import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

BaseContainer {
    id: root

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false

    padding: Globals.geometry.padding.small
    implicitWidth: layout.implicitWidth + (paddingHorizontal * 2)
    hoverEnabled: false
    clickable: true
    onClicked: {
        IslandService.toggleDashboardPopout();
    }

    component TimeSegment: Item {
        id: segment
        property string text: ""
        property int pixelSize: 18
        property int fontWeight: Globals.typography.weights.bold
        property color textColor: Globals.colors.text

        implicitWidth: widthDummy.implicitWidth + 6
        implicitHeight: widthDummy.implicitHeight + 12
        clip: true

        BaseText {
            id: widthDummy
            visible: false
            text: "88"
            pixelSize: segment.pixelSize
            weight: segment.fontWeight
        }

        readonly property real centerY: Math.max(0, (segment.height - currentText.height) / 2)
        property string displayedText: text

        onTextChanged: {
            nextText.text = text;
            anim.restart();
        }

        BaseText {
            id: currentText
            anchors.horizontalCenter: segment.horizontalCenter
            y: segment.centerY
            text: segment.displayedText
            pixelSize: segment.pixelSize
            weight: segment.fontWeight
            color: segment.textColor
        }

        BaseText {
            id: nextText
            anchors.horizontalCenter: segment.horizontalCenter
            y: segment.centerY - segment.height
            opacity: 0
            text: segment.text
            pixelSize: segment.pixelSize
            weight: segment.fontWeight
            color: segment.textColor
        }

        SequentialAnimation {
            id: anim

            ParallelAnimation {
                BaseAnimation {
                    target: currentText
                    property: "y"
                    to: segment.centerY + segment.height
                    duration: 250
                    easing.type: Easing.OutCubic
                }
                BaseAnimation {
                    target: currentText
                    property: "opacity"
                    to: 0
                    duration: 250
                    easing.type: Easing.OutCubic
                }
                BaseAnimation {
                    target: nextText
                    property: "y"
                    from: segment.centerY - segment.height
                    to: segment.centerY
                    duration: 250
                    easing.type: Easing.OutCubic
                }
                BaseAnimation {
                    target: nextText
                    property: "opacity"
                    to: 1
                    duration: 250
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

    component DotSeparator: Column {
        id: dots
        spacing: 4
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined

        Repeater {
            model: 2
            delegate: Rectangle {
                width: 6
                height: 6
                radius: 3
                color: Globals.colors.secondary
                opacity: 0.8
                property int itemIndex: index

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: true
                    PauseAnimation { duration: itemIndex * 200 }
                    NumberAnimation { to: 0.2; duration: 400; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.8; duration: 400; easing.type: Easing.InOutSine }
                    PauseAnimation { duration: (1 - itemIndex) * 200 + 500 }
                }
            }
        }
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Seconds
    }

    readonly property string hoursFormat: Preferences.timedate.format === "12" ? "hh" : "HH"

    Row {
        id: layout
        spacing: Globals.geometry.spacing.medium
        anchors.verticalCenter: parent.verticalCenter

        TimeSegment {
            text: Qt.formatDateTime(systemClock.date, root.hoursFormat)
        }

        DotSeparator {}

        TimeSegment {
            text: Qt.formatDateTime(systemClock.date, "mm")
        }

        DotSeparator {}

        TimeSegment {
            text: Qt.formatDateTime(systemClock.date, "ss")
        }
    }
}
