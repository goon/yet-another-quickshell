import QtQuick
import QtQuick.Layouts
import qs
import ".."
import QtQuick.Effects

BaseContainer {
    id: root
    spacing: 0
    implicitWidth: 240

    property string panelState: "Closed"
    property Item activeHover: null

    component PowerButton: BaseButton {
        id: btn

        Layout.fillWidth: true
        Layout.fillHeight: true
        customRadius: 0
        hoverEnabled: true

        property string actionIcon: ""
        property string actionLabel: ""
        
        property real holdProgress: 0.0
        signal actionTriggered()

        onContainsMouseChanged: {
            if (containsMouse) root.activeHover = btn;
            else if (root.activeHover === btn) root.activeHover = null;
        }

        onPressedChanged: {
            if (pressed) {
                holdAnim.restart()
            } else {
                holdAnim.stop()
                holdAnimReverse.restart()
            }
        }

        NumberAnimation {
            id: holdAnim
            target: btn
            property: "holdProgress"
            to: 1.0
            duration: 2000
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            id: holdAnimReverse
            target: btn
            property: "holdProgress"
            to: 0.0
            duration: Globals.animations.fast
            easing.type: Easing.OutQuad
        }

        onHoldProgressChanged: {
            if (holdProgress >= 1.0 && pressed) {
                btn.actionTriggered()
                holdAnim.stop()
                holdProgress = 0.0
            }
        }

        Item {
            anchors.fill: parent

            RowLayout {
                anchors.fill: parent
                spacing: Globals.geometry.spacing.medium
                
                Item {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignVCenter
                    
                    BaseIcon {
                        anchors.centerIn: parent
                        icon: btn.actionIcon
                        size: Globals.dimensions.iconMedium
                        color: btn.containsMouse ? Globals.colors.primary : Globals.colors.text
                        Behavior on color { BaseAnimation { } }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: baseText.implicitHeight
                        
                        BaseText {
                            id: baseText
                            text: btn.actionLabel
                            color: Globals.colors.text
                            font.weight: Globals.typography.weights.medium
                            font.pixelSize: Globals.typography.size.medium
                            Behavior on color { BaseAnimation { } }
                        }

                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: btn.containsMouse ? subtitleText.implicitHeight : 0
                        clip: true
                        opacity: btn.containsMouse ? 1.0 : 0.0
                        Behavior on opacity { BaseAnimation { } }

                        BaseText {
                            id: subtitleText
                            anchors.top: parent.top
                            anchors.left: parent.left
                            text: "Hold to " + btn.actionLabel.toLowerCase()
                            pixelSize: Globals.typography.size.base
                            muted: true
                        }

                        Canvas {
                            id: waveMask
                            anchors.fill: subtitleText
                            visible: false
                            
                            property real progress: btn.holdProgress
                            property real wavePhase: 0
                            
                            NumberAnimation on wavePhase {
                                from: 0; to: Math.PI * 2
                                duration: 800
                                loops: Animation.Infinite
                                running: btn.pressed
                            }
                            
                            onProgressChanged: requestPaint()
                            onWavePhaseChanged: requestPaint()
                            
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                
                                if (progress <= 0) return;
                                
                                var w = width * progress;
                                var h = height;
                                var amplitude = 3;
                                var frequency = 0.4;
                                
                                ctx.fillStyle = "black";
                                ctx.beginPath();
                                ctx.moveTo(0, 0);
                                ctx.lineTo(0, h);
                                
                                // Draw wavy right edge from bottom to top
                                for (var y = h; y >= 0; y -= 2) {
                                    var xOffset = Math.sin(y * frequency + wavePhase) * amplitude;
                                    ctx.lineTo(w + xOffset, y);
                                }
                                
                                ctx.lineTo(w + Math.sin(wavePhase) * amplitude, 0);
                                ctx.closePath();
                                ctx.fill();
                            }
                        }

                        BaseText {
                            id: subtitleColoredText
                            anchors.fill: subtitleText
                            text: "Hold to " + btn.actionLabel.toLowerCase()
                            pixelSize: Globals.typography.size.base
                            color: Globals.colors.text
                            visible: false
                        }
                        
                        MultiEffect {
                            anchors.fill: subtitleText
                            source: subtitleColoredText
                            maskEnabled: true
                            maskSource: waveMask
                        }
                    }
                }
            }
        }
    }

    readonly property var _actions: [
        { label: "Shutdown", icon: "power_settings_new", onClicked: function() { IslandService.closeAll(); Power.shutdown(); } },
        { label: "Restart",  icon: "rotate_right",        onClicked: function() { IslandService.closeAll(); Power.reboot(); } },
        { label: "Sleep",    icon: "bedtime",            onClicked: function() { IslandService.closeAll(); Power.suspend(); } },
        { label: "Logout",   icon: "move_item",             onClicked: function() { IslandService.closeAll(); Power.logout(); } },
    ]

    Item {
        Layout.fillWidth: true
        implicitHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent

        BaseHeader {
            text: "POWER"
            isActive: root.activeHover !== null
            Layout.bottomMargin: Globals.geometry.spacing.large
        }

        BaseSeparator {
            Layout.fillWidth: true
            Layout.bottomMargin: Globals.geometry.spacing.large
        }

        Repeater {
            model: root._actions
            delegate: PowerButton {
                Layout.fillWidth: true
                implicitHeight: 56
                actionIcon: modelData.icon
                actionLabel: modelData.label
                onActionTriggered: modelData.onClicked()
            }
        }
    }

        BaseIndicator {
            hoverPredicate: function() { return root.activeHover }
        }
    }
}
