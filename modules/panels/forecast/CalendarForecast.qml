import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs

BaseBlock {
    id: cal
    Layout.fillWidth: true
    Layout.fillHeight: true

    Item {
        id: calendarWidget

        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitWidth: contentColumn.width
        implicitHeight: contentColumn.height

        Column {
            id: contentColumn
            anchors.centerIn: parent
            spacing: Theme.geometry.spacing.medium
            width: Theme.dimensions.calendarBlockWidth

            // Month navigation header
            Item {
                id: navHeader

                width: parent.width
                height: 60

                // Previous month button
                BaseButton {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.dimensions.calendarCellSize
                    height: parent.height
                    icon: "chevron_left"
                    iconSize: Theme.dimensions.iconBase
                    hoverColor: Theme.colors.surface
                    scale: pressed ? 0.92 : (containsMouse ? 1.05 : 1.0)
                    clickRotate: true
                    onClicked: {
                        gridContainer.triggerSlide(-1);
                    }
                }

                // Centered overlapping text
                Item {
                    id: headerContainer
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - (Theme.dimensions.calendarCellSize * 2)
                    height: parent.height
                    scale: headerMouseArea.pressed ? 0.98 : 1.0

                    Behavior on scale { BaseAnimation { speed: "fast" } }

                    MouseArea {
                        id: headerMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var now = new Date();
                            var currentVal = Calendar.displayYear * 12 + Calendar.displayMonth;
                            var targetVal = now.getFullYear() * 12 + now.getMonth();

                            if (currentVal !== targetVal) {
                                var dir = (targetVal > currentVal) ? 1 : -1;
                                gridContainer.triggerSlide(dir, true);
                            }
                        }
                    }

                    BaseText {
                        id: monthLabel
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.horizontalCenterOffset: -20
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -8
                        color: Theme.colors.text
                        weight: Theme.typography.weights.bold
                        pixelSize: Theme.typography.size.display * 0.6 // Approximate for 28px
                        text: Calendar.monthNames[Calendar.displayMonth].toUpperCase()
                        z: 1
                        opacity: 1.0

                        transform: Translate { id: monthTranslate }
                    }

                    BaseText {
                        id: yearLabel
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.horizontalCenterOffset: 30
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: 12
                        color: Theme.colors.primary
                        weight: Theme.typography.weights.bold
                        pixelSize: Theme.typography.size.display * 0.75 // Approximate for 36px
                        text: Calendar.displayYear
                        z: 2
                        opacity: 0.85

                        // Cutout Effect
                        shadow: true
                        shadowColor: Theme.colors.surface
                        shadowRadius: 10

                        transform: Translate { id: yearTranslate }
                    }
                }

                // Next month button
                BaseButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.dimensions.calendarCellSize
                    height: parent.height
                    icon: "chevron_right"
                    iconSize: Theme.dimensions.iconBase
                    hoverColor: Theme.colors.surface
                    scale: pressed ? 0.92 : (containsMouse ? 1.05 : 1.0)
                    clickRotate: true
                    onClicked: {
                        gridContainer.triggerSlide(1);
                    }
                }
            }

            // Day headers (Sun, Mon, Tue, etc.)
            Row {
                id: dayHeaders

                width: parent.width
                spacing: Theme.geometry.spacing.small

                Repeater {
                    model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                    Item {
                        width: (parent.width - (6 * Theme.geometry.spacing.small)) / 7
                        implicitHeight: headerText.implicitHeight + Theme.geometry.spacing.small
                        height: implicitHeight

                        BaseText {
                            id: headerText

                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: new Date().getDay() === index ? Theme.colors.primary : Theme.colors.muted
                            text: modelData
                        }
                    }
                }
            }

            Item {
                id: gridContainer
                width: parent.width
                implicitHeight: grid.height
                clip: true

                property int _animDirection: 0
                property bool _isResetting: false
                
                function triggerSlide(dir, reset) {
                    _animDirection = dir;
                    _isResetting = !!reset;
                    slideAnim.restart();
                }

                SequentialAnimation {
                    id: slideAnim
                    ParallelAnimation {
                        BaseAnimation {
                            targets: [gridTranslate]
                            property: "x"
                            from: 0
                            to: -gridContainer._animDirection * 30
                            speed: "fast"
                            easing.type: Easing.OutCubic
                        }
                        BaseAnimation {
                            targets: [grid, monthLabel, yearLabel]
                            property: "opacity"
                            to: 0
                            speed: "fast"
                        }
                        BaseAnimation {
                            targets: [monthLabel, yearLabel]
                            property: "scale"
                            to: 0.7
                            speed: "fast"
                        }
                    }

                    ScriptAction { 
                        script: {
                            if (gridContainer._isResetting) 
                                Calendar.resetToCurrentMonth();
                            else 
                                Calendar.changeMonth(gridContainer._animDirection);
                        }
                    }
                    PropertyAction { targets: [gridTranslate]; property: "x"; value: gridContainer._animDirection * 30 }
                    
                    ParallelAnimation {
                        BaseAnimation {
                            targets: [gridTranslate]
                            to: 0
                            property: "x"
                            speed: "fast"
                            easing.type: Easing.OutBack
                        }
                        BaseAnimation {
                            targets: [grid, monthLabel]
                            property: "opacity"
                            to: 1
                            speed: "fast"
                        }
                        BaseAnimation {
                            target: yearLabel
                            property: "opacity"
                            to: 0.85
                            speed: "fast"
                        }
                        BaseAnimation {
                            targets: [monthLabel, yearLabel]
                            property: "scale"
                            to: 1.0
                            speed: "fast"
                        }
                    }
                }

                Grid {
                    id: grid

                    width: parent.width
                    columns: 7
                    spacing: Theme.geometry.spacing.small
                    
                    transform: Translate { id: gridTranslate }

                    Repeater {
                        model: Calendar.calendarDays

                        Item {
                            id: dayButton
                            required property var modelData

                            width: (parent.width - (6 * Theme.geometry.spacing.small)) / 7
                            implicitHeight: dayText.implicitHeight + Theme.geometry.spacing.medium
                            height: implicitHeight

                            scale: dayMouseArea.pressed ? 0.95 : 1.0

                            Behavior on scale {
                                BaseAnimation {
                                    speed: "fast"
                                }
                            }

                            // Today/Selection Highlight (Matches LauncherItemDelegate)
                            Item {
                                anchors.fill: parent
                                visible: modelData.isToday

                                // 1. Premium Selection Gradient Border
                                Rectangle {
                                    anchors.fill: parent
                                    radius: Theme.geometry.radius
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0; color: Theme.colors.primary }
                                        GradientStop { position: 1; color: Theme.colors.secondary }
                                    }
                                }

                                // 2. Inner "Cutout" and Selection Tint
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 1.5
                                    radius: Theme.geometry.radius - 1.5
                                    color: Theme.colors.surface

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        color: Qt.alpha(Theme.colors.primary, 0.08)
                                    }
                                }

                                // 3. Permanent Inner Glass Highlight
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: Theme.geometry.radius - 1
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: Theme.alpha(Theme.colors.text, 0.05) }
                                        GradientStop { position: 1.0; color: Theme.colors.transparent }
                                    }
                                }
                            }

                            BaseText {
                                id: dayText

                                anchors.centerIn: parent
                                color: {
                                    if (!modelData.isCurrentMonth) return Theme.colors.muted;
                                    return Theme.colors.text;
                                }
                                pixelSize: Theme.typography.size.medium - 1
                                weight: modelData.isToday ? Theme.typography.weights.bold : Theme.typography.weights.normal
                                text: modelData.day < 10 ? "0" + modelData.day : modelData.day
                            }

                            MouseArea {
                                id: dayMouseArea
                                anchors.fill: parent
                                hoverEnabled: false
                                cursorShape: Qt.ArrowCursor
                                enabled: modelData.isCurrentMonth
                            }
                        }
                    }
                }
            }
        }
    }
}
