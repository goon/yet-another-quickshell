import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import "../lib/gowall.js" as GowallLib
pragma Singleton

/**
 * Gowall Service
 * 
 * Manages the integration with 'gowall' to themify wallpapers.
 * - Updates ~/.config/gowall/config.yml with the current system theme.
 * - Converts the current wallpaper using the active theme.
 */
QtObject {
    id: root

    // ── STATE ─────────────────────────────────────────────────────────
    property bool processing: false

    // ── DEPENDENCIES ──────────────────────────────────────────────────
    property bool enabled: Preferences.wallpaper.gowallEnabled
    property var currentColors: Theme.currentColors
    property string currentThemeId: Preferences.currentTheme
    property string currentWallpaper: Wallpaper.currentWallpaper
    
    // Add colorHash so QML knows the colors actually changed and reloads the image!
    property string colorHash: {
        if (!currentColors || Object.keys(currentColors).length === 0) return "none";
        return (currentColors.base00 || "none").replace("#", "") + "_" + (currentColors.base0D || "none").replace("#", "");
    }
    
    // ── PATHS ─────────────────────────────────────────────────────────
    readonly property string gowallConfigDir: Globals.homeDir + "/.config/gowall"
    readonly property string gowallConfigFile: gowallConfigDir + "/config.yml"
    readonly property string cacheDir: Globals.cacheDir + "/wallpapers"

    // ── COMPONENTS ────────────────────────────────────────────────────

    // 1. Config Writer Process (Local, no StdioCollector needed)
    property Process configWriter: Process {
        id: configWriter
        command: [] 
        onExited: (exitCode) => {
             if (exitCode === 0) {
                 convertTimer.restart(); 
             } else {
                 root.processing = false;
             }
        }
    }

    function writeGowallConfig() {
        if (!currentColors || Object.keys(currentColors).length === 0) {
            processing = false;
            return;
        }

        var c = currentColors;
        var colorList = [];
        
        // Try Base16 standard keys first
        for (var i = 0; i <= 15; i++) {
            var hex = i.toString(16).toUpperCase();
            var key = "base0" + hex;
            if (c[key]) colorList.push(c[key]);
        }
        
        // Fallback to legacy/custom named keys
        if (colorList.length === 0) {
            var fallbackKeys = ["background", "surface", "surfaceAlt", "primary", "secondary", "accent", "text", "textDim", "muted", "success", "warning", "error"];
            for (var j = 0; j < fallbackKeys.length; j++) {
                if (c[fallbackKeys[j]]) colorList.push(c[fallbackKeys[j]]);
            }
        }
        
        colorList = colorList.filter(c => c && c.startsWith("#"));

        var yaml = "themes:\n  - name: \"" + currentThemeId + "\"\n    colors:\n";
        for (var i = 0; i < colorList.length; i++) {
            yaml += "      - \"" + colorList[i] + "\"\n";
        }
        
        // Write using sh
        configWriter.running = false; // Quickshell quirk: Must reset running before restarting
        configWriter.command = GowallLib.buildConfigWriteCommand(yaml, gowallConfigFile);
        configWriter.running = true;
    }
    
    property Timer convertTimer: Timer {
        interval: 100
        repeat: false
        onTriggered: root.convertWallpaper()
    }

    function convertWallpaper() {
        // Unique filename per theme to force QML to reload the image
        var ext = currentWallpaper.split(".").pop();
        var baseName = currentWallpaper.split("/").pop().split(".").shift();
        var fileName = baseName + "_" + currentThemeId + "_" + colorHash + "." + ext;

        var targetPath = cacheDir + "/" + fileName;

        // Clean old variants for this base name (quoted for paths containing spaces/quotes).
        ProcessService.runDetached(GowallLib.buildCleanupCommand(cacheDir, baseName, fileName));

        // Cancel any in-flight conversion before starting a new one
        if (convertProc.running) {
            convertProc.running = false;
        }

        // argv-only: paths flow as positional args to a single-quoted shell template,
        // so user-controlled values can never reach a shell parser.
        convertProc.command = GowallLib.buildConvertCommand(currentWallpaper, currentThemeId, targetPath);
        convertProc.running = true;

        root.targetPollFile = targetPath;
    }

    // Convert Process - foreground, signals completion via onExited
    property Process convertProc: Process {
        id: convertProc
        stdout: null
        stderr: null
        onExited: (code) => {
            root.processing = false;
            if (code === 0) {
                Wallpaper.processedWallpaper = root.targetPollFile;
            } else {
                console.warn("[Gowall] convert exited with code", code, "for", root.targetPollFile);
                ProcessService.runDetached(["notify-send", "-a", "Gowall", "-i", "symbol:image-error", "Gowall", "Conversion failed for " + root.targetPollFile.split("/").pop()]);
            }
        }
    }

    property string targetPollFile: ""

    // ── LOGIC ─────────────────────────────────────────────────────────

    // Watch for changes
    onEnabledChanged: update()
    onCurrentThemeIdChanged: update()
    onCurrentWallpaperChanged: update()
    onCurrentColorsChanged: update()

    property Timer updateDebounce: Timer {
        interval: 150
        repeat: false
        onTriggered: root._doUpdate()
    }

    function getExpectedFileName() {
        var ext = currentWallpaper.split(".").pop();
        var baseName = currentWallpaper.split("/").pop().split(".").shift();
        return baseName + "_" + currentThemeId + "_" + colorHash + "." + ext;
    }

    function update() {
        updateDebounce.restart();
    }

    function _doUpdate() {
        if (!enabled) {
            Wallpaper.processedWallpaper = "";
            return;
        }

        if (currentWallpaper === "") return;
        if (!currentColors || Object.keys(currentColors).length === 0) return; // Wait for colors

        // If we are already displaying the correct processed file for this theme/wallpaper combination, do nothing.
        var expectedPath = cacheDir + "/" + getExpectedFileName();

        if (Wallpaper.processedWallpaper === expectedPath) {
             return;
        }

        process();
    }

    function process() {
        if (processing) return; 
        processing = true;

        // Ensure directories (Fast, fire and forget)
        ProcessService.runDetached(["mkdir", "-p", gowallConfigDir]);
        ProcessService.runDetached(["mkdir", "-p", cacheDir]);

        // Write Config
        writeGowallConfig();
    }
}
