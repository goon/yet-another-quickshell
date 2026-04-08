import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs

BasePopoutWindow {
    id: root

    panelNamespace: "quickshell:audio-popout"
    
    property bool outputsExpanded: false
    property bool inputsExpanded: false

    body: ScrollView {
        implicitWidth: 420
        contentWidth: availableWidth
        implicitHeight: col.implicitHeight
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            id: col
            width: parent.width
            spacing: Theme.geometry.spacing.large

            // Master Controls Section
            BaseBlock {
                Layout.fillWidth: true
                spacing: Theme.geometry.spacing.large
                paddingVertical: Theme.geometry.spacing.large

                // Centered "MASTER" Label
                BaseText {
                    text: "MASTER"
                    color: Theme.colors.muted
                    pixelSize: Theme.typography.size.base
                    weight: Theme.typography.weights.bold
                    Layout.alignment: Qt.AlignHCenter
                    font.letterSpacing: 2
                }

                // Master Volume Slider
                BaseSlider {
                    id: outputSlider
                    Layout.fillWidth: true
                    trackHeight: 38
                    icon: Volume.volumeIcon
                    suffix: Math.round(Volume.volume * 100)
                    iconColor: Theme.colors.text
                    suffixColor: Theme.colors.text
                    iconSize: Theme.dimensions.iconMedium
                    from: 0
                    to: 1
                    stepSize: 0.01
                    onValueChangedByUser: Volume.setVolume(value)
                    onIconClicked: Volume.toggleMute()
                    Binding on value {
                        value: Volume.volume
                        when: !outputSlider.pressed
                        restoreMode: Binding.RestoreBinding
                    }
                }

                // Output Device Switcher
                BaseButton {
                    id: playbackSwitcher
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    hoverEnabled: false
                    normalColor: Theme.colors.transparent
                    onClicked: root.outputsExpanded = !root.outputsExpanded
                    
                    RowLayout {
                        anchors.fill: parent
                        spacing: Theme.geometry.spacing.small

                        BaseIcon {
                            icon: "volume_up"
                            size: Theme.dimensions.iconSmall
                            color: playbackSwitcher.containsMouse ? Theme.colors.text : Theme.colors.muted
                            Behavior on color { BaseAnimation { duration: Theme.animations.fast } }
                        }

                        BaseText {
                            text: Volume.getNodeName(Volume.audioSink)
                            color: playbackSwitcher.containsMouse ? Theme.colors.text : Theme.colors.muted
                            pixelSize: Theme.typography.size.base
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Behavior on color { BaseAnimation { duration: Theme.animations.fast } }
                        }

                        BaseIcon {
                            icon: root.outputsExpanded ? "expand_less" : "expand_more"
                            size: Theme.dimensions.iconBase
                            color: playbackSwitcher.containsMouse ? Theme.colors.text : Theme.colors.muted
                            Behavior on color { BaseAnimation { duration: Theme.animations.fast } }
                        }
                    }
                }

                // Output Device List
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.outputsExpanded ? outputsRepeaterContent.implicitHeight : 0
                    clip: true
                    opacity: root.outputsExpanded ? 1 : 0
                    visible: opacity > 0
                    Behavior on Layout.preferredHeight { BaseAnimation { duration: Theme.animations.fast } }
                    Behavior on opacity { BaseAnimation { duration: Theme.animations.fast } }

                    ColumnLayout {
                        id: outputsRepeaterContent
                        width: parent.width
                        spacing: Theme.geometry.spacing.small
                        
                        Repeater {
                            model: Volume.sinks
                            delegate: BaseButton {
                                id: sinkButton
                                Layout.fillWidth: true
                                Layout.preferredHeight: 50
                                gradient: true
                                selected: (Volume.audioSink && Volume.audioSink.id === modelData.id) || containsMouse
                                hoverColor: Theme.colors.transparent
                                contentAlignment: Qt.AlignLeft
                                paddingHorizontal: Theme.geometry.spacing.dynamicPadding
                                onClicked: Volume.selectSink(modelData.id)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: parent.paddingHorizontal
                                    anchors.rightMargin: parent.paddingHorizontal
                                    spacing: Theme.geometry.spacing.medium

                                    BaseIcon {
                                        readonly property bool isActive: Volume.audioSink && Volume.audioSink.id === modelData.id
                                        icon: isActive ? "task_alt" : "circle"
                                        fill: isActive
                                        color: sinkButton.iconColor
                                        size: Theme.dimensions.iconBase
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Layout.alignment: Qt.AlignVCenter

                                        BaseText {
                                            text: Volume.getNodeName(modelData)
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            color: sinkButton.textColor
                                            weight: sinkButton.weight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                BaseSeparator { Layout.fillWidth: true; opacity: 0.1 }

                // Mic Volume Slider
                BaseSlider {
                    id: inputSlider
                    Layout.fillWidth: true
                    trackHeight: 38
                    icon: Volume.inputMuted ? "mic_off" : "mic"
                    suffix: Math.round(Volume.inputVolume * 100)
                    iconColor: Theme.colors.text
                    suffixColor: Theme.colors.text
                    iconSize: Theme.dimensions.iconMedium
                    from: 0
                    to: 1
                    stepSize: 0.01
                    onValueChangedByUser: Volume.setInputVolume(value)
                    onIconClicked: Volume.toggleInputMute()
                    Binding on value {
                        value: Volume.inputVolume
                        when: !inputSlider.pressed
                        restoreMode: Binding.RestoreBinding
                    }
                }

                // Input Device Switcher
                BaseButton {
                    id: recordingSwitcher
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    hoverEnabled: false
                    normalColor: Theme.colors.transparent
                    onClicked: root.inputsExpanded = !root.inputsExpanded
                    
                    RowLayout {
                        anchors.fill: parent
                        spacing: Theme.geometry.spacing.small

                        BaseIcon {
                            icon: "mic"
                            size: Theme.dimensions.iconSmall
                            color: recordingSwitcher.containsMouse ? Theme.colors.text : Theme.colors.muted
                            Behavior on color { BaseAnimation { duration: Theme.animations.fast } }
                        }

                        BaseText {
                            text: Volume.getNodeName(Volume.audioSource)
                            color: recordingSwitcher.containsMouse ? Theme.colors.text : Theme.colors.muted
                            pixelSize: Theme.typography.size.base
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Behavior on color { BaseAnimation { duration: Theme.animations.fast } }
                        }

                        BaseIcon {
                            icon: root.inputsExpanded ? "expand_less" : "expand_more"
                            size: Theme.dimensions.iconBase
                            color: recordingSwitcher.containsMouse ? Theme.colors.text : Theme.colors.muted
                            Behavior on color { BaseAnimation { duration: Theme.animations.fast } }
                        }
                    }
                }

                // Input Device List
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.inputsExpanded ? inputsRepeaterContent.implicitHeight : 0
                    clip: true
                    opacity: root.inputsExpanded ? 1 : 0
                    visible: opacity > 0
                    Behavior on Layout.preferredHeight { BaseAnimation { duration: Theme.animations.fast } }
                    Behavior on opacity { BaseAnimation { duration: Theme.animations.fast } }

                    ColumnLayout {
                        id: inputsRepeaterContent
                        width: parent.width
                        spacing: Theme.geometry.spacing.small
                        
                        Repeater {
                            model: Volume.sources
                            delegate: BaseButton {
                                id: sourceButton
                                Layout.fillWidth: true
                                Layout.preferredHeight: 50
                                gradient: true
                                selected: (Volume.audioSource && Volume.audioSource.id === modelData.id) || containsMouse
                                hoverColor: Theme.colors.transparent
                                contentAlignment: Qt.AlignLeft
                                paddingHorizontal: Theme.geometry.spacing.dynamicPadding
                                onClicked: Volume.selectSource(modelData.id)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: parent.paddingHorizontal
                                    anchors.rightMargin: parent.paddingHorizontal
                                    spacing: Theme.geometry.spacing.medium

                                    BaseIcon {
                                        readonly property bool isActive: Volume.audioSource && Volume.audioSource.id === modelData.id
                                        icon: isActive ? "task_alt" : "circle"
                                        fill: isActive
                                        color: sourceButton.iconColor
                                        size: Theme.dimensions.iconBase
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    BaseText {
                                        text: Volume.getNodeName(modelData)
                                        weight: sourceButton.weight
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        color: sourceButton.textColor
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Application Volume Control
            BaseBlock {
                Layout.fillWidth: true
                visible: Volume.apps.length > 0
                spacing: Theme.geometry.spacing.large
                paddingVertical: Theme.geometry.spacing.large

                BaseText {
                    text: "APPLICATIONS"
                    color: Theme.colors.muted
                    pixelSize: Theme.typography.size.base
                    weight: Theme.typography.weights.bold
                    Layout.alignment: Qt.AlignHCenter
                    font.letterSpacing: 2
                }

                Repeater {
                    model: Volume.apps
                    delegate: ColumnLayout {
                        id: appDelegate
                        Layout.fillWidth: true
                        spacing: Theme.geometry.spacing.medium
                        visible: modelData.ready && Volume.getAppName(modelData) !== ""

                        PwObjectTracker { objects: [modelData] }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.geometry.spacing.medium

                            // Left: Icon
                            Item {
                                Layout.preferredWidth: Theme.dimensions.iconLarge
                                Layout.preferredHeight: Theme.dimensions.iconLarge
                                Layout.alignment: Qt.AlignVCenter

                                BaseIcon {
                                    anchors.fill: parent
                                    color: Theme.colors.text
                                    text: Volume.getAppName(modelData)
                                    showFallback: true
                                    fallbackChar: {
                                        var name = Volume.getAppName(modelData);
                                        return (name && name.length > 0) ? name.charAt(0).toUpperCase() : "?";
                                    }
                                    size: Theme.dimensions.iconLarge
                                    visible: !appIcon.visible
                                }

                                Image {
                                    id: appIcon
                                    anchors.fill: parent
                                    source: LauncherService.resolveIcon(Volume.getAppIcon(modelData))
                                    fillMode: Image.PreserveAspectFit
                                    visible: status === Image.Ready && width > 0
                                }
                            }

                            // Right: Stacked Controls
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                // Top: Title and Mute
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.geometry.spacing.small

                                    BaseText {
                                        text: {
                                            var name = Volume.getAppName(modelData);
                                            return (name && name.length > 0) ? name.charAt(0).toUpperCase() + name.slice(1) : "";
                                        }
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        color: Theme.colors.text
                                        weight: Theme.typography.weights.medium
                                        pixelSize: Theme.typography.size.base
                                    }

                                    BaseButton {
                                        Layout.preferredWidth: 24
                                        Layout.preferredHeight: 24
                                        hoverEnabled: true
                                        normalColor: Theme.colors.transparent
                                        icon: (modelData.audio && modelData.audio.muted) ? "volume_off" : "volume_up"
                                        iconColor: (modelData.audio && modelData.audio.muted) ? Theme.colors.error : Theme.colors.muted
                                        iconSize: Theme.dimensions.iconSmall
                                        onClicked: Volume.toggleAppMute(modelData.id)
                                    }
                                }

                                // Bottom: Slider and Percentage
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.geometry.spacing.medium

                                    BaseSlider {
                                        id: appVolumeSlider
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        iconColor: Theme.colors.text
                                        suffixColor: Theme.colors.text
                                        from: 0
                                        to: 1
                                        stepSize: 0.01
                                        enabled: modelData.audio !== null && modelData.ready
                                        onValueChangedByUser: {
                                            if (modelData.audio && modelData.ready)
                                                modelData.audio.volume = value;
                                        }

                                        Binding on value {
                                            value: (modelData.audio) ? modelData.audio.volume : 0
                                            when: !appVolumeSlider.pressed
                                            restoreMode: Binding.RestoreBinding
                                        }
                                    }

                                    BaseText {
                                        text: Math.round(appVolumeSlider.value * 100) + "%"
                                        Layout.preferredWidth: 35
                                        horizontalAlignment: Text.AlignRight
                                        Layout.alignment: Qt.AlignVCenter
                                        color: Theme.colors.muted
                                        pixelSize: Theme.typography.size.small
                                    }
                                }
                            }
                        }

                        // Separator between apps
                        BaseSeparator {
                            Layout.fillWidth: true
                            opacity: 0.05
                            visible: index < Volume.apps.length - 1
                            Layout.topMargin: Theme.geometry.spacing.small
                            Layout.bottomMargin: Theme.geometry.spacing.small
                        }
                    }
                }
            }
        }
    }
}
