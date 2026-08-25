import QtQuick
import Quickshell
import Quickshell.Io
import qs
pragma Singleton

QtObject {
    id: root

    property bool loaded: false

    // ── USER GROUPS (one per settings page) ──────────────────────────────

    property QtObject notifications: QtObject {
        property int mode: 0 // 0: Normal, 1: DND (Silent)
        property bool soundEnabled: true
        property int soundVolume: 35

        property int timeout: 5000

        onModeChanged: root.requestSave()
        onSoundEnabledChanged: root.requestSave()
        onSoundVolumeChanged: root.requestSave()
        onTimeoutChanged: root.requestSave()
    }

    property QtObject bar: QtObject {
        property string position: "top"
        property int height: 55
        property int marginTop: 10
        property int workspaceCount: 5
        property bool dynamicIsland: true
        property var components: ["workspaces", "dock", "indicators", "clock"]
        property var componentsEnabled: ({"workspaces": true, "dock": true, "indicators": true, "clock": true})

        onPositionChanged: root.requestSave()
        onHeightChanged: root.requestSave()
        onMarginTopChanged: root.requestSave()
        onWorkspaceCountChanged: root.requestSave()
        onDynamicIslandChanged: root.requestSave()
        onComponentsChanged: root.requestSave()
        onComponentsEnabledChanged: root.requestSave()
    }

    property QtObject wallpaper: QtObject {
        property bool gowallEnabled: false
        property double parallaxStrength: 25
        property string directory: ""

        onGowallEnabledChanged: root.requestSave()
        onParallaxStrengthChanged: root.requestSave()
        onDirectoryChanged: root.requestSave()
    }

    property QtObject applications: QtObject {
        property var themedApps: ({
            "gtk": false,
            "kitty": false,
            "vesktop": false,
            "obsidian": false,
            "nvim": false,
            "firefox": false,
            "gowall": false,
            "steam": false,
            "vscodium": false
        })
        property double themedAppsOpacity: 0.85

        onThemedAppsChanged: root.requestSave()
        onThemedAppsOpacityChanged: root.requestSave()
    }

    property QtObject launcher: QtObject {
        property string webSearchUrl: "https://duckduckgo.com/?q="
        property string globalPrefix: ">"
        property bool showAppDescriptions: false

        onWebSearchUrlChanged: root.requestSave()
        onGlobalPrefixChanged: root.requestSave()
        onShowAppDescriptionsChanged: root.requestSave()
    }

    property QtObject globals: QtObject {
        property string themeMode: "dark"
        property string shellFont: "Outfit"
        property int cornerRadius: 30
        property double backgroundOpacity: 1.0
        property bool islandOutline: true
        property string dynamicSeedColor: "#9d99e5"
        property real dynamicBgLightness: 0.08
        property int scale: 1 // 0: 0.9x, 1: 1.0x, 2: 1.1x

        onThemeModeChanged: root.requestSave()
        onShellFontChanged: root.requestSave()
        onCornerRadiusChanged: root.requestSave()
        onBackgroundOpacityChanged: root.requestSave()
        onIslandOutlineChanged: root.requestSave()
        onDynamicSeedColorChanged: root.requestSave()
        onDynamicBgLightnessChanged: root.requestSave()
        onScaleChanged: {
            if (scale === 0) root.bar.height = 50;
            else if (scale === 1) root.bar.height = 55;
            else if (scale === 2) root.bar.height = 60;
            root.requestSave();
        }
    }

    property QtObject weather: QtObject {
        property string lat: "51.50853"
        property string long: "-0.12574"
        property string locationName: "London, England, United Kingdom"

        onLatChanged: root.requestSave()
        onLongChanged: root.requestSave()
        onLocationNameChanged: root.requestSave()
    }

    property QtObject indicators: QtObject {
        property var order: ["notifications", "clipboard", "wifi", "instantmix", "settings", "power"]

        onOrderChanged: root.requestSave()
    }

    property QtObject clipboard: QtObject {
        property bool autoClose: true
        property int cleanupDays: 7
        property int displayLimit: 50

        onAutoCloseChanged: root.requestSave()
        onCleanupDaysChanged: root.requestSave()
        onDisplayLimitChanged: root.requestSave()
    }

    property QtObject animations: QtObject {
        property real speedMultiplier: 1.0 // 0.5x - 2.5x

        onSpeedMultiplierChanged: root.requestSave()
    }

    property QtObject timedate: QtObject {
        property string format: "24" // "12" or "24"

        onFormatChanged: root.requestSave()
    }

    // ── TOP-LEVEL VALUES ─────────────────────────────────────────────────

    property string currentTheme: "tinted"
    property string currentWallpaper: ""

    onCurrentThemeChanged: root.requestSave()
    onCurrentWallpaperChanged: root.requestSave()

    // ── SCHEMA ───────────────────────────────────────────────────────────

    property var _schema: [
        ["notifications", "mode"],
        ["notifications", "soundEnabled"],
        ["notifications", "soundVolume"],
        ["notifications", "timeout"],
        ["bar", "position"],
        ["globals", "scale"],
        ["bar", "height"],
        ["bar", "marginTop"],
        ["bar", "workspaceCount"],
        ["bar", "dynamicIsland"],
        ["bar", "components"],
        ["bar", "componentsEnabled"],
        ["wallpaper", "gowallEnabled"],
        ["wallpaper", "parallaxStrength"],
        ["wallpaper", "directory"],
        ["applications", "themedApps"],
        ["applications", "themedAppsOpacity"],
        ["launcher", "webSearchUrl"],
        ["launcher", "globalPrefix"],
        ["launcher", "showAppDescriptions"],
        ["globals", "themeMode"],
        ["globals", "shellFont"],
        ["globals", "cornerRadius"],
        ["globals", "backgroundOpacity"],
        ["globals", "islandOutline"],
        ["globals", "dynamicSeedColor"],
        ["globals", "dynamicBgLightness"],
        ["weather", "lat"],
        ["weather", "long"],
        ["weather", "locationName"],
        ["indicators", "order"],
        ["clipboard", "autoClose"],
        ["clipboard", "cleanupDays"],
        ["clipboard", "displayLimit"],
        ["animations", "speedMultiplier"],
        ["timedate", "format"],
        ["currentTheme"],
        ["currentWallpaper"]
    ]

    function _get(path) {
        var o = root;
        for (var i = 0; i < path.length - 1; i++) o = o[path[i]];
        return o[path[path.length - 1]];
    }

    function _set(path, val) {
        var o = root;
        for (var i = 0; i < path.length - 1; i++) o = o[path[i]];
        o[path[path.length - 1]] = val;
    }

    function _getData(data, path) {
        for (var i = 0; i < path.length; i++) {
            if (data == null || typeof data !== "object") return undefined;
            data = data[path[i]];
        }
        return data;
    }

    function _setData(data, path, val) {
        for (var i = 0; i < path.length - 1; i++) {
            if (!data[path[i]] || typeof data[path[i]] !== "object") data[path[i]] = {};
            data = data[path[i]];
        }
        data[path[path.length - 1]] = val;
    }

    // ── PERSISTENCE ──────────────────────────────────────────────────────

    readonly property string prefsFile: Globals.cacheDir + "/preferences.json"

    function save() {
        if (!loaded) return;
        var data = {};
        for (var i = 0; i < _schema.length; i++)
            _setData(data, _schema[i], _get(_schema[i]));

        const jsonContent = JSON.stringify(data, null, 2);
        const tempFile = root.prefsFile + ".tmp";
        const cmd = `printf '%s' "$1" > "$2" && mv "$2" "$3"`;
        ProcessService.runDetached(["sh", "-c", cmd, "--", jsonContent, tempFile, root.prefsFile]);
    }

    property Timer saveTimer: Timer {
        interval: 500
        repeat: false
        onTriggered: root.save()
    }

    function requestSave() {
        if (loaded) saveTimer.restart();
    }

    // ── INITIALISATION ──────────────────────────────────────────────────

    Component.onCompleted: { 
        ProcessService.run(["sh", "-c", "test -f " + root.prefsFile], function(out, exitCode) {
            if (exitCode !== 0) {
                console.log("[Preferences] No preferences file found. Booting with defaults immediately.");
                safetyTimer.stop();
                root.loaded = true;
                root.requestSave(); // Create the file
            } else {
                prefsFileView.reload();
            }
        });
    }

    property Timer safetyTimer: Timer {
        interval: 10000
        running: true
        repeat: false
        onTriggered: {
            if (!root.loaded) {
                console.warn("[Preferences] Load timed out, assuming defaults. Manual changes will now be allowed.");
                root.loaded = true;
            }
        }
    }

    property FileView prefsFileView: FileView {
        path: root.prefsFile
        watchChanges: false
        onLoadedChanged: {
            if (loaded) {
                const rawText = text();
                if (rawText.trim().length === 0) {
                    console.log("[Preferences] File is empty, skipping parse.");
                    safetyTimer.stop();
                    root.loaded = true;
                    return;
                }

                try {
                    var data = JSON.parse(rawText);
                    if (!data || typeof data !== "object") throw new Error("Invalid JSON");
                    
                    // Snapshot the default valid components BEFORE overwriting them with user data
                    var defaultValidComponents = root.bar.components.slice();

                    // ── SCHEMA-DRIVEN LOAD ─────────────────────────────────
                    for (var i = 0; i < _schema.length; i++) {
                        var path = _schema[i];
                        // applications.themedApps is handled by merge below
                        if (path.length === 2 && path[0] === "applications" && path[1] === "themedApps") continue;
                        var val = _getData(data, path);
                        if (val !== undefined) _set(path, val);
                    }

                    // ── MERGE DICTIONARIES ─────────────────────────────────
                    var savedApps = _getData(data, ["applications", "themedApps"]);
                    if (savedApps !== undefined && typeof savedApps === "object") {
                        var currentApps = root.applications.themedApps;
                        var appsChanged = false;
                        for (var key in savedApps) {
                            if (currentApps[key] !== savedApps[key]) {
                                currentApps[key] = savedApps[key];
                                appsChanged = true;
                            }
                        }
                        if (appsChanged) {
                            // Reassign to trigger property change
                            root.applications.themedApps = Object.assign({}, currentApps);
                        }
                    }

                    // ── MIGRATIONS ─────────────────────────────────────────
                    // General cleanup: remove any cached components that no longer exist in the system
                    var loadedComponents = root.bar.components;
                    var cleanedComponents = loadedComponents.filter(c => defaultValidComponents.indexOf(c) !== -1);
                    
                    var loadedEnabled = root.bar.componentsEnabled || {};
                    var cleanedEnabled = {};
                    for (var i = 0; i < defaultValidComponents.length; i++) {
                        var c = defaultValidComponents[i];
                        cleanedEnabled[c] = loadedEnabled[c] !== undefined ? loadedEnabled[c] : true;
                    }
                    
                    var migrated = false;
                    if (cleanedComponents.length !== loadedComponents.length || Object.keys(loadedEnabled).length !== defaultValidComponents.length) {
                        root.bar.components = cleanedComponents;
                        root.bar.componentsEnabled = cleanedEnabled;
                        console.log("[Preferences] Cleaned up legacy/invalid components from bar configuration.");
                        // Force property change signal for QML bindings
                        root.bar = Object.assign({}, root.bar);
                        migrated = true;
                    }
                    safetyTimer.stop();
                    root.loaded = true;
                    
                    if (migrated) root.requestSave();
                } catch (e) {
                    console.error("[Preferences] Failed to parse preferences file:", e.message);
                }
            }
        }
    }
}
