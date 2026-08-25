import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services

BaseContainer {
    id: root

    implicitWidth: 400
    spacing: 0

    property string panelState: "Closed"
    property string expandedSide: "" // "", "output", "input"

    // ── SECTION MODEL ───────────────────────────────────────────────────

    readonly property var _sections: [
        { type: "output", header: "AUDIO OUTPUT", hasDevices: true, deviceIcon: "headphones", deviceLabel: "Output Device" },
        { type: "input",  header: "MICROPHONE",   hasDevices: true, deviceIcon: "mic",          deviceLabel: "Input Device" },
        { type: "display",header: "DISPLAY",      hasDevices: false, deviceIcon: "", deviceLabel: "" },
    ]

    function _setVolume(type, val) {
        if (type === "output") Volume.setVolume(val);
        else if (type === "input") Volume.setInputVolume(val);
        else if (type === "display") Display.setBrightness(val);
    }

    function _toggleMute(type) {
        if (type === "output") Volume.toggleMute();
        else if (type === "input") Volume.toggleInputMute();
    }

    Repeater {
        model: root._sections

        delegate: ColumnLayout {
            id: sectionCol
            required property int index
            required property var modelData
            readonly property string sectionType: modelData.type

            Layout.fillWidth: true
            spacing: Globals.geometry.spacing.medium

            BaseSeparator {
                Layout.fillWidth: true
                visible: index > 0
                Layout.topMargin: Globals.geometry.spacing.large * 0.75
                Layout.bottomMargin: Globals.geometry.spacing.large * 0.75
            }

            // ── HEADER ──────────────────────────────────────────────────
            BaseHeader {
                text: modelData.header
                isActive: sectionSlider.isActive || (modelData.hasDevices && (selectorBtn.hovered || deviceListHoverHandler.hovered))
            }

            // ── SLIDER ──────────────────────────────────────────────────
            BaseSlider {
                id: sectionSlider
                Layout.fillWidth: true
                trackHeight: 38
                icon: {
                    if (modelData.type === "output") return Volume.volumeIcon;
                    if (modelData.type === "input") return Volume.inputMuted ? "mic_off" : "mic";
                    return "light_mode";
                }
                suffix: {
                    if (modelData.type === "display") return Math.round(Display.brightness * 100);
                    if (modelData.type === "output") return Math.round(Volume.volume * 100);
                    return Math.round(Volume.inputVolume * 100);
                }
                muted: {
                    if (modelData.type === "output") return Volume.muted;
                    if (modelData.type === "input") return Volume.inputMuted;
                    return false;
                }
                stepSize: 0.01

                Binding on value {
                    value: modelData.type === "output" ? Volume.volume
                        : (modelData.type === "input" ? Volume.inputVolume : Display.brightness)
                    when: !sectionSlider.pressed
                    restoreMode: Binding.RestoreBinding
                }
                onValueChangedByUser: root._setVolume(modelData.type, value)
                onRightClicked: root._toggleMute(modelData.type)
            }

            // ── DEVICE SELECTOR (output/input only) ─────────────────────
            BaseButton {
                id: selectorBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                visible: modelData.hasDevices
                customRadius: Globals.geometry.radius
                hoverColor: Globals.alpha(Globals.colors.surface, 0.4)
                onClicked: root.expandedSide = (root.expandedSide === modelData.type) ? "" : modelData.type

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Globals.geometry.spacing.small
                    anchors.rightMargin: Globals.geometry.spacing.small
                    spacing: Globals.geometry.spacing.medium

                    BaseIcon { icon: modelData.deviceIcon }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        BaseText {
                            text: modelData.type === "output"
                                ? Volume.getNodeName(Volume.audioSink)
                                : Volume.getNodeName(Volume.audioSource)
                            weight: Globals.typography.weights.medium
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        BaseText {
                            text: modelData.deviceLabel
                            pixelSize: Globals.typography.size.small
                            color: Globals.alpha(Globals.colors.text, 0.5)
                        }
                    }

                    BaseIcon {
                        icon: "expand_more"
                        rotation: root.expandedSide === modelData.type ? 180 : 0
                        Behavior on rotation { BaseAnimation { } }
                    }
                }
            }

            // ── DEVICE LIST (expanded dropdown) ─────────────────────────
            Item {
                id: deviceListHover
                HoverHandler { id: deviceListHoverHandler }
                Layout.fillWidth: true
                visible: modelData.hasDevices
                Layout.preferredHeight: root.expandedSide === modelData.type ? deviceListCol.implicitHeight : 0
                opacity: root.expandedSide === modelData.type ? 1 : 0
                clip: true
                Behavior on opacity { PropertyAnimation { duration: Math.max(0, Math.round(Globals.animations.normal / Preferences.animations.speedMultiplier)); easing.type: Globals.animations.easingType } }
                Behavior on Layout.preferredHeight { PropertyAnimation { duration: Math.max(0, Math.round(Globals.animations.normal / Preferences.animations.speedMultiplier)); easing.type: Globals.animations.easingType } }

                ColumnLayout {
                    id: deviceListCol
                    width: parent.width
                    spacing: 4
                    Layout.topMargin: Globals.geometry.spacing.small

                    Repeater {
                        model: sectionCol.sectionType === "output" ? Volume.sinks : Volume.sources

                        delegate: BaseButton {
                            id: deviceButton
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            hoverColor: Globals.alpha(Globals.colors.surface, 0.4)
                            customRadius: Globals.geometry.radius
                            paddingHorizontal: Globals.geometry.spacing.small
                            onClicked: {
                                if (sectionCol.sectionType === "output")
                                    Volume.selectSink(modelData.id);
                                else
                                    Volume.selectSource(modelData.id);
                                root.expandedSide = "";
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: parent.paddingHorizontal
                                anchors.rightMargin: parent.paddingHorizontal
                                spacing: Globals.geometry.spacing.medium

                                BaseIcon {
                                    readonly property bool isActive: sectionCol.sectionType === "output"
                                        ? (Volume.audioSink && Volume.audioSink.id === modelData.id)
                                        : (Volume.audioSource && Volume.audioSource.id === modelData.id)
                                    icon: isActive ? "task_alt" : "circle"
                                    fill: isActive
                                    color: isActive ? Globals.colors.primary : Globals.colors.muted
                                    size: Globals.dimensions.iconSmall
                                }

                                BaseText {
                                    text: Volume.getNodeName(modelData)
                                    color: {
                                        var isCur = sectionCol.sectionType === "output"
                                            ? (Volume.audioSink && Volume.audioSink.id === modelData.id)
                                            : (Volume.audioSource && Volume.audioSource.id === modelData.id);
                                        if (isCur) return Globals.colors.primary;
                                        if (deviceButton.containsMouse) return Globals.colors.text;
                                        return Globals.colors.muted;
                                    }
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
