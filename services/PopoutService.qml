import QtQuick
import Quickshell
import qs
pragma Singleton

QtObject {
    id: root

    // Pointers to the various loaders injected by shell.qml
    property var launcherLoader: null
    property var settingsLoader: null
    property var mediaPopoutLoader: null
    property var systemPopoutLoader: null
    property var audioPopoutLoader: null
    property var forecastLoader: null
    property var notificationPopoutLoader: null
    property var notificationManager: null
    property var powerPopoutLoader: null
    property var systemControlPopoutLoader: null
    property var fileDialogLoader: null

    // Helper properties
    readonly property var launcher: launcherLoader ? launcherLoader.item : null
    readonly property var settings: settingsLoader ? settingsLoader.item : null
    readonly property var mediaPopout: mediaPopoutLoader ? mediaPopoutLoader.item : null
    readonly property var systemPopout: systemPopoutLoader ? systemPopoutLoader.item : null
    readonly property var audioPopout: audioPopoutLoader ? audioPopoutLoader.item : null
    readonly property var forecast: forecastLoader ? forecastLoader.item : null
    readonly property var notificationPopout: notificationPopoutLoader ? notificationPopoutLoader.item : null
    readonly property var powerPopout: powerPopoutLoader ? powerPopoutLoader.item : null
    readonly property var systemControlPopout: systemControlPopoutLoader ? systemControlPopoutLoader.item : null
    readonly property var fileDialog: fileDialogLoader ? fileDialogLoader.item : null

    property Item launcherItem: null
    property Item systemResourcesItem: null
    property Item systemControlItem: null
    property Item volumeItem: null
    property Item notificationsItem: null
    property Item nowPlayingItem: null
    property Item clockItem: null

    property var activePanelLoader: null
    property int barWidth: 0


    // --- COORDINATE MATH ---
    function _getCoordinatesFromItem(item) {
        if (!item) return undefined;
        try {
            var posInWindow = item.mapToItem(null, item.width / 2, 0);
            var topParent = item;
            while (topParent.parent) topParent = topParent.parent;
            var bW = topParent.width;
            var screen = Quickshell.screens[0];
            var barScreenX = Preferences.barFitToContent ? (screen.width - bW) / 2 : Preferences.barMarginSide;
            return { screenX: barScreenX + posInWindow.x, barLeft: barScreenX, barRight: barScreenX + bW };
        } catch (e) { return undefined; }
    }

    // --- TOGGLE ACTIONS ---
    function toggleLauncher() { _toggle(launcherLoader); }

    function toggleWallpaper() {
        if (!launcherLoader) return;
        if (activePanelLoader && activePanelLoader !== launcherLoader) activePanelLoader.close();
        
        if (!launcherLoader.active || (launcherLoader.item && launcherLoader.item.panelState !== "Open")) {
            launcherLoader.toggle();
            activePanelLoader = launcherLoader;
        }
        launcherLoader.runWhenReady(() => { launcherLoader.item.switchToTab(2); });
    }

    function toggleClipboard() {
        if (!launcherLoader) return;
        if (activePanelLoader && activePanelLoader !== launcherLoader) activePanelLoader.close();
        
        if (!launcherLoader.active || (launcherLoader.item && launcherLoader.item.panelState !== "Open")) {
            launcherLoader.toggle();
            activePanelLoader = launcherLoader;
        }
        launcherLoader.runWhenReady(() => { launcherLoader.item.switchToTab(1); });
    }

    function toggleSettings() { _toggle(settingsLoader); }

    function toggleMediaPopout(screenX, barLeft, barRight) {
        if (screenX === undefined && nowPlayingItem) {
            var coords = _getCoordinatesFromItem(nowPlayingItem);
            if (coords) { screenX = coords.screenX; barLeft = coords.barLeft; barRight = coords.barRight; }
        }
        _applyAnchors(mediaPopoutLoader, screenX, barLeft, barRight);
        _toggle(mediaPopoutLoader);
    }

    function toggleNotificationPopout(screenX, barLeft, barRight) {
        if (screenX === undefined && notificationsItem) {
            var coords = _getCoordinatesFromItem(notificationsItem);
            if (coords) { screenX = coords.screenX; barLeft = coords.barLeft; barRight = coords.barRight; }
        }
        _applyAnchors(notificationPopoutLoader, screenX, barLeft, barRight);
        _toggle(notificationPopoutLoader);
    }

    function toggleSystemPopout(screenX, barLeft, barRight) {
        if (screenX === undefined && systemResourcesItem) {
            var coords = _getCoordinatesFromItem(systemResourcesItem);
            if (coords) { screenX = coords.screenX; barLeft = coords.barLeft; barRight = coords.barRight; }
        }
        _applyAnchors(systemPopoutLoader, screenX, barLeft, barRight);
        _toggle(systemPopoutLoader);
    }

    function toggleAudioPopout(screenX, barLeft, barRight) {
        if (screenX === undefined && volumeItem) {
            var coords = _getCoordinatesFromItem(volumeItem);
            if (coords) { screenX = coords.screenX; barLeft = coords.barLeft; barRight = coords.barRight; }
        }
        _applyAnchors(audioPopoutLoader, screenX, barLeft, barRight);
        _toggle(audioPopoutLoader);
    }

    function toggleForecast(screenX, barLeft, barRight) {
        if (screenX === undefined && clockItem) {
            var coords = _getCoordinatesFromItem(clockItem);
            if (coords) { screenX = coords.screenX; barLeft = coords.barLeft; barRight = coords.barRight; }
        }
        _applyAnchors(forecastLoader, screenX, barLeft, barRight);
        _toggle(forecastLoader);
    }

    function togglePowerPopout(screenX, barLeft, barRight) {
        if (screenX === undefined && systemControlItem) {
            var coords = _getCoordinatesFromItem(systemControlItem);
            if (coords) { screenX = coords.screenX; barLeft = coords.barLeft; barRight = coords.barRight; }
        }
        _applyAnchors(systemControlPopoutLoader, screenX, barLeft, barRight);
        _toggle(systemControlPopoutLoader);
    }

    // --- OPEN ACTIONS (FOR HOVER) ---
    function openMediaPopout() {
        var sx, bl, br;
        if (nowPlayingItem) {
            var c = _getCoordinatesFromItem(nowPlayingItem);
            if (c) { sx = c.screenX; bl = c.barLeft; br = c.barRight; }
        }
        _ensureOpen(mediaPopoutLoader, sx, bl, br);
    }
    
    function openNotificationPopout() {
        var sx, bl, br;
        if (notificationsItem) {
            var c = _getCoordinatesFromItem(notificationsItem);
            if (c) { sx = c.screenX; bl = c.barLeft; br = c.barRight; }
        }
        _ensureOpen(notificationPopoutLoader, sx, bl, br);
    }

    function openSystemPopout() {
        var sx, bl, br;
        if (systemResourcesItem) {
            var c = _getCoordinatesFromItem(systemResourcesItem);
            if (c) { sx = c.screenX; bl = c.barLeft; br = c.barRight; }
        }
        _ensureOpen(systemPopoutLoader, sx, bl, br);
    }

    function openAudioPopout() {
        var sx, bl, br;
        if (volumeItem) {
            var c = _getCoordinatesFromItem(volumeItem);
            if (c) { sx = c.screenX; bl = c.barLeft; br = c.barRight; }
        }
        _ensureOpen(audioPopoutLoader, sx, bl, br);
    }

    function openForecast() {
        var sx, bl, br;
        if (clockItem) {
            var c = _getCoordinatesFromItem(clockItem);
            if (c) { sx = c.screenX; bl = c.barLeft; br = c.barRight; }
        }
        _ensureOpen(forecastLoader, sx, bl, br);
    }

    function openPowerPopout() {
        var sx, bl, br;
        if (systemControlItem) {
            var c = _getCoordinatesFromItem(systemControlItem);
            if (c) { sx = c.screenX; bl = c.barLeft; br = c.barRight; }
        }
        _ensureOpen(systemControlPopoutLoader, sx, bl, br);
    }

    function toggleSystemControl(screenX, barLeft, barRight, initialTab) {
        if (screenX === undefined && systemControlItem) {
            var coords = _getCoordinatesFromItem(systemControlItem);
            if (coords) { screenX = coords.screenX; barLeft = coords.barLeft; barRight = coords.barRight; }
        }
        _applyAnchors(systemControlPopoutLoader, screenX, barLeft, barRight);
        
        if (systemControlPopoutLoader) {
            systemControlPopoutLoader.runWhenReady(() => {
                if (systemControlPopoutLoader.item.panelState !== "Open") {
                    if (initialTab !== undefined) systemControlPopoutLoader.item.switchToTab(initialTab);
                }
            });
        }
        _toggle(systemControlPopoutLoader);
    }

    function openFileDialog(initialPath, callback) {
        if (fileDialogLoader) {
            fileDialogLoader.active = true;
            fileDialogLoader.runWhenReady(() => { fileDialogLoader.item.open(initialPath, callback); });
        }
    }

    function _applyAnchors(loader, screenX, barLeft, barRight) {
        if (!loader) return;
        loader.runWhenReady(() => {
            var item = loader.item;
            item.anchorX = (screenX !== undefined) ? screenX : -1;
            item.anchorMinX = (barLeft !== undefined) ? barLeft : -1;
            item.anchorMaxX = (barRight !== undefined) ? barRight : -1;
        });
    }

    function _toggle(loader) {
        if (!loader) return;
        TrayService.closeCurrentMenu();
        if (activePanelLoader === loader) {
            loader.toggle();
            activePanelLoader = null;
            return;
        }
        if (activePanelLoader) activePanelLoader.close();
        loader.toggle();
        activePanelLoader = loader;
    }

    function _ensureOpen(loader, screenX, barLeft, barRight) {
        if (!loader) return;
        
        // If the current active panel was closed independently (e.g. Escape or click outside),
        // reset the pointer so we can re-open it or open a new one.
        if (activePanelLoader && activePanelLoader.item && 
            activePanelLoader.item.panelState !== "Open" && 
            activePanelLoader.item.panelState !== "Opening") {
            activePanelLoader = null;
        }

        if (activePanelLoader === loader) return; // Already open

        TrayService.closeCurrentMenu();
        if (activePanelLoader) activePanelLoader.close();

        _applyAnchors(loader, screenX, barLeft, barRight);
        loader.active = true;
        loader.runWhenReady(() => {
            if (loader.item.panelState !== "Open" && loader.item.panelState !== "Opening") {
                loader.item.open();
            }
        });
        activePanelLoader = loader;
    }

    function closeAll() {
        if (activePanelLoader) { activePanelLoader.close(); activePanelLoader = null; }
    }
}
