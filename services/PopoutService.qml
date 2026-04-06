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
    property var calendarPopoutLoader: null
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
    readonly property var calendarPopout: calendarPopoutLoader ? calendarPopoutLoader.item : null
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

    function toggleCalendarPopout(screenX, barLeft, barRight) {
        if (screenX === undefined && clockItem) {
            var coords = _getCoordinatesFromItem(clockItem);
            if (coords) { screenX = coords.screenX; barLeft = coords.barLeft; barRight = coords.barRight; }
        }
        _applyAnchors(calendarPopoutLoader, screenX, barLeft, barRight);
        _toggle(calendarPopoutLoader);
    }

    function togglePowerPopout(screenX, barLeft, barRight) {
        if (screenX === undefined && systemControlItem) {
            var coords = _getCoordinatesFromItem(systemControlItem);
            if (coords) { screenX = coords.screenX; barLeft = coords.barLeft; barRight = coords.barRight; }
        }
        _applyAnchors(systemControlPopoutLoader, screenX, barLeft, barRight);
        _toggle(systemControlPopoutLoader);
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

    function closeAll() {
        if (activePanelLoader) { activePanelLoader.close(); activePanelLoader = null; }
    }
}
