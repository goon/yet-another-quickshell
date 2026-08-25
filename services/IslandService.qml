import QtQuick
import Quickshell
import qs
pragma Singleton

QtObject {
    id: root

    // ── STATE PROPERTIES ──────────────────────────────────────────────
    property string activePanelName: ""
    property var activeScreen: null
    property Item activePanelItem: null
    property bool indicatorsHovered: false
    property bool isIslandHovered: false

    property real anchorX: -1
    property real anchorMinX: -1
    property real anchorMaxX: -1

    // Callback Queue for panel-specific navigation on load
    property var _pendingCallbacks: []

    function runWhenPanelReady(callback) {
        if (activePanelItem && (activePanelItem.panelState === "Opening" || activePanelItem.panelState === "Open")) {
            Qt.callLater(callback);
        } else {
            _pendingCallbacks.push(callback);
        }
    }

    onActivePanelItemChanged: {
        if (activePanelItem) {
            if (typeof activePanelItem.panelStateChanged === "undefined") {
                while (_pendingCallbacks.length > 0) {
                    var cb = _pendingCallbacks.shift();
                    if (typeof cb === "function") Qt.callLater(cb);
                }
                return;
            }
            var checkState = () => {
                if (activePanelItem && (activePanelItem.panelState === "Opening" || activePanelItem.panelState === "Open")) {
                    while (_pendingCallbacks.length > 0) {
                        var cb = _pendingCallbacks.shift();
                        if (typeof cb === "function") Qt.callLater(cb);
                    }
                    activePanelItem.panelStateChanged.disconnect(checkState);
                }
            };
            activePanelItem.panelStateChanged.connect(checkState);
            checkState();
        }
    }

    // ── PANEL REGISTRY ──────────────────────────────────────────────────

    readonly property var panelRegistry: ({
        "launcher":      { source: "../modules/launcher/Launcher.qml" },
        "settings":      { source: "../modules/settings/Settings.qml" },
        "dashboard":     { source: "../modules/dashboard/Dashboard.qml" },
        "wallpaper":     { source: "../modules/wallpaper/Wallpaper.qml" },
        "fullbar":       { source: "../modules/bar/Full.qml" },
        "power":         { source: "../modules/power/Power.qml" },
        "mixer":         { source: "../modules/mixer/Mixer.qml" },
        "network":       { source: "../modules/network/Network.qml" },
        "notifications_island": { source: "../modules/notifications/NotificationsIsland.qml" },
        "clipboard":     { source: "../modules/clipboard/ClipboardIsland.qml", width: 760, height: 600 },
        "volumetoast":   { source: "../modules/toasts/VolumeToast.qml" },
        "notificationtoast": { source: "../modules/toasts/NotificationToast.qml" }
    })

    // ── CONTROL APIS ──────────────────────────────────────────────────
    function togglePanel(name, screenX, barLeft, barRight, screen) {
        if (activePanelName === name) {
            closeAll();
        } else {
            activePanelName = name;
            activeScreen = screen || Quickshell.screens[0];
            anchorX = (screenX !== undefined) ? screenX : -1;
            anchorMinX = (barLeft !== undefined) ? barLeft : -1;
            anchorMaxX = (barRight !== undefined) ? barRight : -1;
        }
    }

    function openPanel(name, screenX, barLeft, barRight, screen) {
        if (activePanelName === name) return;
        activePanelName = name;
        activeScreen = screen || Quickshell.screens[0];
        anchorX = (screenX !== undefined) ? screenX : -1;
        anchorMinX = (barLeft !== undefined) ? barLeft : -1;
        anchorMaxX = (barRight !== undefined) ? barRight : -1;
    }

    function closeAll() {
        activePanelName = "";
        activeScreen = null;
        activePanelItem = null;
        anchorX = -1;
        anchorMinX = -1;
        anchorMaxX = -1;
    }

    // ── PANEL WRAPPER APIS ────────────────────────────────────────────
    function toggleLauncher() {
        togglePanel("launcher");
    }

    function toggleWallpaper() {
        togglePanel("wallpaper");
    }

    function toggleClipboard() {
        togglePanel("clipboard");
    }

    function toggleSettings(pageName) {
        var isCurrentlyOpen = (activePanelName === "settings");

        if (isCurrentlyOpen) {
            if (pageName !== undefined) {
                if (activePanelItem) {
                    if (activePanelItem.selectedPage === pageName) {
                        closeAll();
                    } else if (typeof activePanelItem.changePage === "function") {
                        activePanelItem.changePage(pageName);
                    }
                }
            } else {
                closeAll();
            }
        } else {
            openPanel("settings");
            if (pageName !== undefined) {
                runWhenPanelReady(() => {
                    if (activePanelItem && typeof activePanelItem.changePage === "function") {
                        activePanelItem.changePage(pageName);
                    }
                });
            }
        }
    }

    function toggleDashboardPopout() {
        togglePanel("dashboard");
    }

    function toggleNetworkPopout() {
        togglePanel("network");
    }

    function toggleBluetoothPopout() {
        var isCurrentlyOpen = (activePanelName === "network");
        
        if (isCurrentlyOpen) {
            if (activePanelItem && activePanelItem.pageStack && activePanelItem.pageStack.currentItem && activePanelItem.pageStack.currentItem.objectName === "NetworkBluetooth.qml") {
                closeAll();
            } else {
                if (activePanelItem && typeof activePanelItem.pushPage === "function") {
                    activePanelItem.pushPage("bluetooth");
                }
            }
        } else {
            openPanel("network");
            runWhenPanelReady(() => {
                if (activePanelItem && typeof activePanelItem.pushPage === "function") {
                    activePanelItem.pushPage("bluetooth");
                }
            });
        }
    }

    function togglePowerPopout() {
        togglePanel("power");
    }

    function toggleMixerPopout() {
        togglePanel("mixer");
    }

    function toggleNotificationsPopout() {
        togglePanel("notifications_island");
    }



    // ── VOLUME TOAST LOGIC ────────────────────────────────────────────
    property bool _startupDelayFinished: false
    property Timer _startupTimer: Timer {
        running: true
        interval: 1000
        onTriggered: _startupDelayFinished = true
    }

    property Timer _volumeToastTimer: Timer {
        interval: 2000
        onTriggered: {
            if (activePanelName === "volumetoast" && !isIslandHovered) {
                closeAll();
            }
        }
    }

    property Connections _volumeConnections: Connections {
        target: Volume
        function onVolumeChanged() {
            if (!_startupDelayFinished) return;
            
            // Only open toast if no other panel is open, or if the toast is already open
            if (activePanelName === "" || activePanelName === "volumetoast") {
                openPanel("volumetoast");
                _volumeToastTimer.restart();
            }
        }
        function onMutedChanged() {
            if (!_startupDelayFinished) return;
            
            if (activePanelName === "" || activePanelName === "volumetoast") {
                openPanel("volumetoast");
                _volumeToastTimer.restart();
            }
        }
    }

    // ── WORKSPACE SWITCH (FULLBAR) ────────────────────────────────────
    property Timer _workspaceFullBarTimer: Timer {
        interval: 2000
        onTriggered: {
            if (activePanelName === "fullbar" && !isIslandHovered) {
                closeAll();
            }
        }
    }

    property Connections _workspaceConnections: Connections {
        target: Compositor
        function onActiveWorkspaceIdChanged() {
        }
    }
}

