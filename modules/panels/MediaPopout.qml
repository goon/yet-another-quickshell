import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs

BasePopoutWindow {
    id: root

    panelNamespace: "quickshell:media-popout"
    property real parallaxFactor: 30
    property real mouseX: 0.5
    property real mouseY: 0.5

    body: Item {
        implicitWidth: 380
        implicitHeight: 380 // Fixed height for media

        // Catch clicks so they don't fall through to the close-window background
        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => mouse.accepted = true
            onPressed: (mouse) => mouse.accepted = true
        }

        HoverHandler {
            id: hoverTracker
            onPointChanged: {
                if (parent.width > 0 && parent.height > 0) {
                    root.mouseX = point.position.x / parent.width;
                    root.mouseY = point.position.y / parent.height;
                }
            }
            onHoveredChanged: {
                if (!hovered) {
                    root.mouseX = 0.5;
                    root.mouseY = 0.5;
                }
            }
        }

        // Mask shape for album art rounded corners
        Rectangle {
            id: albumArtMask
            anchors.fill: parent
            radius: Preferences.cornerRadius
            color: Theme.colors.text
            visible: false
            layer.enabled: true
            layer.smooth: true
            layer.samples: 8
        }

        // Outer Layer: Handles Masking (sharp corners)
        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: albumArtMask
            }

            // Inner Layer: Handles Image + Blur
            Item {
                id: albumArtContainer
                anchors.fill: parent

                property bool useArt2: false
                property string currentUrl: Media.albumArtUrl

                // Handle URL changes: load the new URL into the hidden image
                Connections {
                    target: Media
                    function onAlbumArtUrlChanged() {
                        if (albumArtContainer.useArt2) {
                            // Currently using art2, so prepare art1
                            if (art1.source !== Media.albumArtUrl) {
                                art1.source = Media.albumArtUrl;
                                // Wait for Ready status in art1.onStatusChanged
                            }
                        } else {
                            // Currently using art1, so prepare art2
                            if (art2.source !== Media.albumArtUrl) {
                                art2.source = Media.albumArtUrl;
                                // Wait for Ready status in art2.onStatusChanged
                            }
                        }
                    }
                }

                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 0.5
                }

                // Shared breath scale property to keep images in sync
                property real breathScale: 1.0
                SequentialAnimation {
                    id: breathAnim
                    loops: Animation.Infinite
                    running: true
                    paused: Media.playbackState !== MprisPlaybackState.Playing

                    NumberAnimation { target: albumArtContainer; property: "breathScale"; to: 1.05; duration: 8000; easing.type: Easing.InOutSine }
                    NumberAnimation { target: albumArtContainer; property: "breathScale"; to: 1.0; duration: 8000; easing.type: Easing.InOutSine }
                }

                Image {
                    id: art1
                    anchors.centerIn: parent
                    width: parent.width * 1.25
                    height: parent.height * 1.25
                    source: Media.albumArtUrl // Initial source
                    fillMode: Image.PreserveAspectCrop
                    opacity: !albumArtContainer.useArt2 ? 0.45 : 0.0
                    visible: opacity > 0.01

                    Behavior on opacity { BaseAnimation { speed: "slow" } }

                    transform: Translate {
                        x: (root.mouseX - 0.5) * -40
                        y: (root.mouseY - 0.5) * -40
                        Behavior on x { BaseAnimation { duration: Theme.animations.slow } }
                        Behavior on y { BaseAnimation { duration: Theme.animations.slow } }
                    }

                    scale: albumArtContainer.breathScale

                    onStatusChanged: {
                        if (status === Image.Ready && albumArtContainer.useArt2) {
                            albumArtContainer.useArt2 = false;
                        }
                    }
                }

                Image {
                    id: art2
                    anchors.centerIn: parent
                    width: parent.width * 1.25
                    height: parent.height * 1.25
                    source: ""
                    fillMode: Image.PreserveAspectCrop
                    opacity: albumArtContainer.useArt2 ? 0.45 : 0.0
                    visible: opacity > 0.01

                    Behavior on opacity { BaseAnimation { speed: "slow" } }

                    transform: Translate {
                        x: (root.mouseX - 0.5) * -40
                        y: (root.mouseY - 0.5) * -40
                        Behavior on x { BaseAnimation { duration: Theme.animations.slow } }
                        Behavior on y { BaseAnimation { duration: Theme.animations.slow } }
                    }

                    scale: albumArtContainer.breathScale

                    onStatusChanged: {
                        if (status === Image.Ready && !albumArtContainer.useArt2) {
                            albumArtContainer.useArt2 = true;
                        }
                    }
                }
            }
        }

        ColumnLayout {
            width: parent.width
            anchors.centerIn: parent
            spacing: 24

            // Song Details
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                // Animated Title
                Item {
                    id: animatedTitle
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    clip: true

                    property string currentText: Media.activePlayer ? Media.trackTitle : "No Media Playing"
                    property bool useText2: false

                    onCurrentTextChanged: {
                        if (useText2) {
                            title1.text = currentText;
                        } else {
                            title2.text = currentText;
                        }
                        useText2 = !useText2;
                    }

                    BaseText {
                        id: title1
                        width: parent.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.colors.primary
                        text: animatedTitle.currentText
                        weight: Theme.typography.weights.bold
                        pixelSize: Theme.typography.size.large
                        horizontalAlignment: Text.AlignHCenter
                        shadow: true
                        
                        opacity: !animatedTitle.useText2 ? 1 : 0
                        y: !animatedTitle.useText2 ? 0 : -20
                        Behavior on opacity { BaseAnimation { speed: "normal" } }
                        Behavior on y { BaseAnimation { speed: "normal" } }
                    }

                    BaseText {
                        id: title2
                        width: parent.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.colors.primary
                        text: ""
                        weight: Theme.typography.weights.bold
                        pixelSize: Theme.typography.size.large
                        horizontalAlignment: Text.AlignHCenter
                        shadow: true

                        opacity: animatedTitle.useText2 ? 1 : 0
                        y: animatedTitle.useText2 ? 0 : 20
                        Behavior on opacity { BaseAnimation { speed: "normal" } }
                        Behavior on y { BaseAnimation { speed: "normal" } }
                    }
                }

                // Animated Artist
                Item {
                    id: animatedArtist
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    clip: true
                    visible: Media.activePlayer !== null && Media.trackArtist !== ""

                    property string currentText: Media.trackArtist
                    property bool useText2: false

                    onCurrentTextChanged: {
                        if (useText2) {
                            artist1.text = currentText;
                        } else {
                            artist2.text = currentText;
                        }
                        useText2 = !useText2;
                    }

                    BaseText {
                        id: artist1
                        width: parent.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: animatedArtist.currentText
                        pixelSize: Theme.typography.size.medium
                        horizontalAlignment: Text.AlignHCenter
                        shadow: true

                        opacity: !animatedArtist.useText2 ? 1 : 0
                        y: !animatedArtist.useText2 ? 0 : -15
                        Behavior on opacity { BaseAnimation { speed: "normal" } }
                        Behavior on y { BaseAnimation { speed: "normal" } }
                    }

                    BaseText {
                        id: artist2
                        width: parent.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: ""
                        pixelSize: Theme.typography.size.medium
                        horizontalAlignment: Text.AlignHCenter
                        shadow: true

                        opacity: animatedArtist.useText2 ? 1 : 0
                        y: animatedArtist.useText2 ? 0 : 15
                        Behavior on opacity { BaseAnimation { speed: "normal" } }
                        Behavior on y { BaseAnimation { speed: "normal" } }
                    }
                }
            }

            // Progress
            Slider {
                id: progressSlider

                property real wavePhase: 0
                property real waveAmplitude: 4
                property real waveFrequency: 0.15

                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Layout.leftMargin: 60
                Layout.rightMargin: 60
                
                Connections {
                    target: Media
                    function onProgressRatioChanged() {
                        if (!progressSlider.pressed) {
                            progressSlider.value = Media.progressRatio;
                        }
                    }
                }
                
                enabled: Media.activePlayer !== null
                
                onMoved: Media.seek(value * Media.trackLength)

                onPressedChanged: {
                    if (!pressed) {
                        if (Media.trackLength > 0) {
                            Media.seek(value * Media.trackLength);
                        }
                    }
                }

                BaseAnimation {
                    from: 0
                    to: -Math.PI * 2
                    speed: "slow"
                    loops: Animation.Infinite
                    running: Media.playbackState === MprisPlaybackState.Playing
                    target: progressSlider
                    property: "wavePhase"
                    easing.type: Easing.Linear
                }

                background: Item {
                    x: progressSlider.leftPadding
                    y: progressSlider.topPadding + (progressSlider.availableHeight / 2) - (height / 2)
                    width: progressSlider.availableWidth
                    height: 24

                    Canvas {
                        id: waveCanvas

                        property real progress: progressSlider.visualPosition
                        Behavior on progress { BaseAnimation.Spring { profile: "snappy" } }

                        property color activeColor: Theme.colors.text
                        property color inactiveColor: Theme.colors.surface
                        property real phase: progressSlider.wavePhase

                        anchors.fill: parent
                        onProgressChanged: requestPaint()
                        onPhaseChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var midY = height / 2;
                            var amplitude = progressSlider.waveAmplitude;
                            var frequency = progressSlider.waveFrequency;
                            var progressX = progress * (width - 2);
                            var lineWidth = 4;
                            ctx.beginPath();
                            ctx.strokeStyle = inactiveColor;
                            ctx.lineWidth = lineWidth;
                            ctx.lineCap = "round";
                            ctx.moveTo(progressX, midY);
                            ctx.lineTo(width, midY);
                            ctx.stroke();
                            ctx.beginPath();
                            if (progressX > 0) {
                                var gradient = ctx.createLinearGradient(0, 0, progressX, 0);
                                gradient.addColorStop(0, Theme.colors.primary);
                                gradient.addColorStop(1, Theme.colors.secondary);
                                ctx.strokeStyle = gradient;
                            } else {
                                ctx.strokeStyle = activeColor;
                            }
                            ctx.lineWidth = lineWidth;
                            ctx.lineCap = "round";
                            if (progressX > 0) {
                                ctx.moveTo(0, midY + Math.sin(phase) * amplitude);
                                for (var x = 1; x <= progressX; x++) {
                                    var y = midY + Math.sin(x * frequency + phase) * amplitude;
                                    ctx.lineTo(x, y);
                                }
                                ctx.stroke();
                            }
                        }
                    }

                    Rectangle {
                        x: 0
                        y: parent.height / 2 - 10
                        width: 4
                        height: Theme.dimensions.iconMedium
                        radius: Math.max(2, Theme.geometry.radius * 0.5)
                        color: Theme.colors.text
                    }
                }

                handle: Rectangle {
                    z: 1
                    x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                    Behavior on x { BaseAnimation.Spring { profile: "snappy" } }
                    
                    y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                    width: 4
                    height: Theme.dimensions.iconMedium
                    radius: Math.max(2, Theme.geometry.radius * 0.5)
                    color: Theme.colors.text
                }
            }

            // Controls
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 24

                BaseButton {
                    id: prevBtn
                    size: Theme.dimensions.iconBase
                    hoverGradient: true
                    icon: "skip_previous"
                    enabled: Media.canGoPrevious
                    onClicked: {
                        prevAnim.restart()
                        Media.previous()
                    }

                    NumberAnimation {
                        id: prevAnim
                        target: prevBtn
                        property: "iconRotation"
                        from: 0
                        to: -360
                        duration: 500
                        easing.type: Easing.OutBack
                    }
                }

                BaseButton {
                    size: Theme.dimensions.iconBase
                    hoverGradient: true
                    icon: Media.playbackState === MprisPlaybackState.Playing ? "pause" : "play_arrow"
                    enabled: Media.activePlayer !== null
                    onClicked: Media.togglePlayPause()
                    
                    iconRotation: Media.playbackState === MprisPlaybackState.Playing ? 180 : 0
                    Behavior on iconRotation { BaseAnimation { speed: "fast"; easing.type: Easing.InOutBack } }
                }

                BaseButton {
                    id: nextBtn
                    size: Theme.dimensions.iconBase
                    hoverGradient: true
                    icon: "skip_next"
                    enabled: Media.canGoNext
                    onClicked: {
                        nextAnim.restart()
                        Media.next()
                    }

                    NumberAnimation {
                        id: nextAnim
                        target: nextBtn
                        property: "iconRotation"
                        from: 0
                        to: 360
                        duration: 500
                        easing.type: Easing.OutBack
                    }
                }
            }
        }
    }
}
