import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs

BaseBento {
    id: root

    implicitWidth: 300 + (paddingHorizontal * 2)
    hoverEnabled: false



    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Globals.geometry.spacing.large

        // 1. CIRCULAR ALBUM ART with CAVA Equalizer
        Item {
            id: albumArtWrapper
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Globals.geometry.spacing.large
            Layout.bottomMargin: Globals.geometry.spacing.large

            readonly property int visualBarsCount: 48
            readonly property real barWidth: (Math.PI * (albumArtCircle.width + 8) / visualBarsCount) * 0.45

            function interpolateColor(color1, color2, factor) {
                var c1 = Qt.color(color1);
                var c2 = Qt.color(color2);
                return Qt.rgba(
                    c1.r + (c2.r - c1.r) * factor,
                    c1.g + (c2.g - c1.g) * factor,
                    c1.b + (c2.b - c1.b) * factor,
                    c1.a + (c2.a - c1.a) * factor
                );
            }

            // Helper for circle dimensions
            Item {
                id: albumArtCircle
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height) - 16
                height: width
            }

            // Radiating Equalizer (CAVA)
            Item {
                anchors.fill: parent
                opacity: Media.playbackState === MprisPlaybackState.Playing ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.InOutQuad
                    }
                }

                Repeater {
                    model: albumArtWrapper.visualBarsCount

                    delegate: Item {
                        id: delegateItem
                        anchors.centerIn: parent
                        
                        property real barVal: {
                            var spec = Cava.spectrum;
                            if (!spec || spec.length < 48) return 0.0;
                            var bandIndex = 0;
                            if (index < 24) {
                                bandIndex = (23 - index) * 2;
                            } else {
                                bandIndex = (index - 24) * 2;
                            }
                            return spec[bandIndex];
                        }
                        
                        width: albumArtWrapper.barWidth
                        height: albumArtCircle.width + 114
                        rotation: (index / albumArtWrapper.visualBarsCount) * 360

                        // Clipped container to keep bottom flat and top rounded
                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height / 2 - (albumArtCircle.width / 2 + 8) - height
                            width: parent.width
                            height: Math.min(Math.pow(delegateItem.barVal, 0.65) * 24, 12)
                            opacity: Math.min(1.0, delegateItem.barVal * 6.0)
                            clip: true

                            Behavior on height {
                                NumberAnimation {
                                    duration: 80
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 80
                                }
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                width: parent.width
                                height: parent.height + 10
                                radius: 0
                                color: {
                                    var factor = index / albumArtWrapper.visualBarsCount;
                                    var symFactor = Math.abs(0.5 - factor) * 2;
                                    return albumArtWrapper.interpolateColor(Globals.colors.secondary, Globals.colors.primary, symFactor);
                                }
                            }
                        }
                    }
                }
            }
            // Rotating Gradient Ring border for Album Art
            Canvas {
                id: ringCanvas
                anchors.centerIn: albumArtCircle
                width: albumArtCircle.width + 10
                height: width

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    var lineWidth = 1.5;
                    var cx = width / 2;
                    var cy = height / 2;
                    var r = (width - lineWidth) / 2;

                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI);

                    var grad = ctx.createLinearGradient(0, 0, width, height);
                    grad.addColorStop(0.0, Globals.colors.primary);
                    grad.addColorStop(1.0, Globals.colors.secondary);

                    ctx.strokeStyle = grad;
                    ctx.lineWidth = lineWidth;
                    ctx.stroke();
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }

            // Mask for circular crop
            Rectangle {
                id: albumArtMask
                width: albumArtCircle.width
                height: albumArtCircle.height
                anchors.centerIn: parent
                radius: width / 2
                color: Globals.colors.text
                visible: false
                layer.enabled: true
                layer.smooth: true
                layer.samples: 8
            }

            // Outer masked layer
            Item {
                anchors.fill: albumArtCircle
                layer.enabled: true
                layer.smooth: true
                layer.samples: 8
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: albumArtMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }


                // Inner layer: images + blur background
                Item {
                    id: albumArtContainer
                    anchors.fill: parent

                    property bool useArt2: false

                    Connections {
                        target: Media
                        function onAlbumArtUrlChanged() {
                            if (albumArtContainer.useArt2) {
                                if (art1.source !== Media.albumArtUrl) art1.source = Media.albumArtUrl;
                            } else {
                                if (art2.source !== Media.albumArtUrl) art2.source = Media.albumArtUrl;
                            }
                        }
                    }

                    // Beating scale shared by both images
                    property real breathScale: 1.0
                    SequentialAnimation {
                        loops: Animation.Infinite
                        running: true
                        paused: Media.playbackState !== MprisPlaybackState.Playing

                        NumberAnimation { target: albumArtContainer; property: "breathScale"; to: 1.04; duration: 1200; easing.type: Easing.InOutSine }
                        NumberAnimation { target: albumArtContainer; property: "breathScale"; to: 1.0;  duration: 1200; easing.type: Easing.InOutSine }
                    }



                    Image {
                        id: art1
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        source: Media.albumArtUrl
                        fillMode: Image.PreserveAspectCrop
                        opacity: !albumArtContainer.useArt2 ? 1.0 : 0.0
                        visible: opacity > 0.01

                        Behavior on opacity { BaseAnimation { } }

                        scale: albumArtContainer.breathScale

                        onStatusChanged: {
                            if (status === Image.Ready && albumArtContainer.useArt2)
                                albumArtContainer.useArt2 = false;
                        }
                    }

                    Image {
                        id: art2
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        source: ""
                        fillMode: Image.PreserveAspectCrop
                        opacity: albumArtContainer.useArt2 ? 1.0 : 0.0
                        visible: opacity > 0.01

                        Behavior on opacity { BaseAnimation { } }

                        scale: albumArtContainer.breathScale

                        onStatusChanged: {
                            if (status === Image.Ready && !albumArtContainer.useArt2)
                                albumArtContainer.useArt2 = true;
                        }
                    }
                }

                // Vignette overlay inside the circle
                Canvas {
                    id: vignetteCanvas
                    anchors.fill: parent
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var cx = width / 2;
                        var cy = height / 2;
                        var r = width / 2;
                        var gradient = ctx.createRadialGradient(cx, cy, r * 0.75, cx, cy, r);
                        gradient.addColorStop(0.0, "transparent");
                        gradient.addColorStop(1.0, "rgba(0, 0, 0, 0.40)");
                        ctx.fillStyle = gradient;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                        ctx.fill();
                    }
                }

                // Inset border overlay for clean circular look
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.color: Globals.alpha(Globals.colors.text, 0.15)
                    border.width: 1.5
                }

                // Interactive Play/Pause Overlay
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Globals.alpha(Globals.colors.background, 0.6)
                    opacity: artMouseArea.containsMouse ? 1.0 : 0.0
                    Behavior on opacity { BaseAnimation { } }

                    BaseText {
                        anchors.centerIn: parent
                        text: Media.playbackState === MprisPlaybackState.Playing ? "PAUSE" : "PLAY"
                        pixelSize: Globals.typography.size.large
                        weight: Globals.typography.weights.bold
                        font.letterSpacing: 1.5
                        color: Globals.colors.text
                    }
                }

                MouseArea {
                    id: artMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.togglePlayPause()
                }
            }


            // Fallback when no art
            Rectangle {
                anchors.fill: albumArtCircle
                radius: width / 2
                color: Globals.alpha(Globals.colors.background, 0.6)
                visible: !Media.activePlayer || Media.albumArtUrl === ""

                BaseIcon {
                    anchors.centerIn: parent
                    icon: "music_note"
                    size: Globals.dimensions.iconExtraLarge
                    color: Globals.alpha(Globals.colors.primary, 0.4)
                }
            }
        }

        // 2. TRACK TITLE + ARTIST
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Globals.geometry.spacing.small

            BaseText {
                Layout.fillWidth: true
                text: Media.activePlayer ? Media.trackTitle : "No Media Playing"
                pixelSize: Globals.typography.size.large
                weight: Globals.typography.weights.bold
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            BaseText {
                Layout.fillWidth: true
                text: Media.activePlayer ? Media.trackArtist : "Standby"
                pixelSize: Globals.typography.size.medium
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                muted: true
            }
        }

        // 3. MEDIA CONTROLS & PROGRESS BAR
        RowLayout {
            Layout.fillWidth: true
            spacing: Globals.geometry.spacing.medium

            BaseButton {
                id: prevBtn
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Globals.geometry.spacing.large * 3
                size: Globals.dimensions.iconMedium
                icon: "skip_previous"
                enabled: Media.canGoPrevious
                opacity: enabled ? 1.0 : 0.5
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

            Slider {
                id: progressSlider

                property real animatedProgress: visualPosition
                Behavior on animatedProgress {
                    BaseAnimation.Spring { profile: "snappy" }
                }

                property real wavePhase: 0
                property real waveAmplitude: 4
                property real waveFrequency: 0.15

                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                
                Connections {
                    target: Media
                    function onProgressRatioChanged() {
                        if (!progressSlider.pressed) {
                            progressSlider.value = Media.progressRatio;
                        }
                    }
                }
                
                enabled: Media.activePlayer !== null
                
                onMoved: {
                    if (Media.trackLength > 0) {
                        Media.seek(value * Media.trackLength);
                    }
                }

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

                        property real progress: progressSlider.animatedProgress

                        property color activeColor: Globals.colors.text
                        property color inactiveColor: Globals.alpha(Globals.colors.text, 0.08)
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
                                gradient.addColorStop(0, Globals.colors.primary);
                                gradient.addColorStop(1, Globals.colors.secondary);
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
                        height: Globals.dimensions.iconMedium
                        radius: Math.max(2, Globals.geometry.radius * 0.5)
                        color: Globals.colors.text
                    }
                }

                handle: Rectangle {
                    z: 1
                    x: progressSlider.leftPadding + progressSlider.animatedProgress * (progressSlider.availableWidth - width)
                    
                    y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                    width: 4
                    height: Globals.dimensions.iconMedium
                    radius: Math.max(2, Globals.geometry.radius * 0.5)
                    color: Globals.colors.text
                }
            }

            BaseButton {
                id: nextBtn
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: Globals.geometry.spacing.large * 3
                size: Globals.dimensions.iconMedium
                icon: "skip_next"
                enabled: Media.canGoNext
                opacity: enabled ? 1.0 : 0.5
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