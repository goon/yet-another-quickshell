import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

/**
 * Wallpaper Background Window
 * 
 * Manages the background layer across all screens.
 * Uses a double-buffering approach with crossfade transitions.
 * Implements "Load-Gated Transitions" to ensure animations only start when textures are ready.
 */
PanelWindow {
    id: root

    // ── CONFIGURATION ──────────────────────────────────────────────────
    property string namespace: "yaks:wallpaper"
    property int exclusiveZone: -1

    // ── STATE ──────────────────────────────────────────────────────────
    property string activePath: ""
    property string pendingPath: ""
    property bool bufferToggle: false // false: A is active, true: B is active
    property bool transitionPending: false

    // ── LOGIC ──────────────────────────────────────────────────────────

    function updateWallpaper(newPath) {
        if (!newPath || newPath === "" || newPath === activePath || newPath === pendingPath) return;

        // 1. Determine target buffer (The one NOT currently visible)
        var targetLoader = !bufferToggle ? loaderB : loaderA;

        // 2. Set source - cancel-and-replace any in-flight load on this buffer
        pendingPath = newPath;
        transitionPending = true;
        targetLoader.source = "file://" + newPath;

        // Handle case where source didn't change or loaded instantly
        if (targetLoader.status === Image.Ready) {
            checkAndTransition();
        }
    }

    function checkAndTransition() {
        if (!transitionPending || pendingPath === "") return;

        var targetLoader = !bufferToggle ? loaderB : loaderA;

        // Only start transition if the image is actually loaded and ready to render
        if (targetLoader.status === Image.Ready) {
            var newPath = pendingPath;

            // Set up transition
            transition.sourceOld = bufferToggle ? loaderB : loaderA;
            transition.sourceNew = targetLoader;

            // Start Animation
            transition.startTransition();

            // Commit Buffer Flip
            bufferToggle = !bufferToggle;
            transitionPending = false;
            activePath = newPath;
            pendingPath = "";
        }
    }

    // ── CONNECTIONS ────────────────────────────────────────────────────

    Connections {
        target: Wallpaper
        function onDisplayWallpaperChanged() {
            root.updateWallpaper(Wallpaper.displayWallpaper);
        }
    }

    Component.onCompleted: {
        if (Wallpaper.displayWallpaper !== "") {
            loaderA.source = "file://" + Wallpaper.displayWallpaper;
            // For initial load, we don't animate, we just show it if ready
            if (loaderA.status === Image.Ready) {
                loaderA.opacity = 1;
                loaderA.visible = true;
            }
            activePath = Wallpaper.displayWallpaper;
        }
    }

    // ── LAYOUT SHELL CONFIG ────────────────────────────────────────────
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: root.namespace
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: root.exclusiveZone
    visible: true
    color: Globals.colors.background

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        top: (Preferences.bar.position === "top") ? -(Preferences.bar.height + Preferences.bar.marginTop) : 0
        bottom: (Preferences.bar.position === "bottom") ? -(Preferences.bar.height + Preferences.bar.marginTop) : 0
    }

    // ── BUFFERS & PARALLAX ─────────────────────────────────────────────

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    Item {
        id: parallaxContainer
        
        property real strength: Preferences.wallpaper.parallaxStrength
        
        x: -currentOffsetX
        y: -currentOffsetY
        width: root.width + (2 * strength)
        height: root.height + (2 * strength)

        property real currentOffsetX: (mouseArea.containsMouse && strength > 0)
            ? (mouseArea.mouseX / Math.max(1, root.width)) * 2 * strength
            : strength
            
        property real currentOffsetY: (mouseArea.containsMouse && strength > 0)
            ? (mouseArea.mouseY / Math.max(1, root.height)) * 2 * strength
            : strength
            
        Behavior on currentOffsetX {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }
        
        Behavior on currentOffsetY {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }

        Image {
            id: loaderA
            anchors.fill: parent
            visible: false
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            
            // Trigger transition when load completes
            onStatusChanged: if (status === Image.Ready) root.checkAndTransition()
        }

        Image {
            id: loaderB
            anchors.fill: parent
            visible: false
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            
            // Trigger transition when load completes
            onStatusChanged: if (status === Image.Ready) root.checkAndTransition()
        }

        // ── INTERNAL TRANSITION LOGIC ──────────────────────────────────
        Item {
            id: transition
            anchors.fill: parent
            
            property Item sourceOld
            property Item sourceNew
            property bool running: false
            property int duration: Globals.animations.slow * 2 // Long crossfade

            signal finished()
            onFinished: {
                if (sourceOld) {
                    sourceOld.source = "";
                    sourceOld = null;
                }
                sourceNew = null;
            }

            function prepare() {
                if (sourceOld) {
                    sourceOld.opacity = 1;
                    sourceOld.x = 0;
                    sourceOld.y = 0;
                    sourceOld.visible = true;
                    sourceOld.scale = 1;
                    sourceOld.z = 1;
                    sourceNew.z = 2;
                }
                if (sourceNew) {
                    sourceNew.opacity = 1;
                    sourceNew.x = 0;
                    sourceNew.y = 0;
                    sourceNew.scale = 1;
                    sourceNew.visible = false;
                }
            }

            function startTransition() {
                prepare();
                sourceNew.opacity = 0;
                sourceNew.visible = true;
                animFade.restart();
                transition.running = true;
            }

            BaseAnimation {
                id: animFade
                target: transition.sourceNew
                property: "opacity"
                from: 0
                to: 1
                duration: transition.duration
                easing.type: Easing.InOutQuad
                onFinished: transition.finished()
            }
        }
    }
}
