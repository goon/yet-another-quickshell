import QtQuick
import Quickshell
import Quickshell.Io
import qs
pragma Singleton

/**
 * Wallpaper Service
 * 
 * Handles wallpaper selection and persistence.
 */
Item {
    id: root

    // ── STATE PROPERTIES ────────────────────────────────────────────
    property var wallpapers: []
    property string currentWallpaper: ""
    
    // UI State
    property bool isLoading: false
    property bool hasScanned: false
    
    // ── COMPUTED SOURCE ─────────────────────────────────────────────
    // This is the SINGLE source of truth for the UI.
    property string processedWallpaper: ""
    property string displayWallpaper: (Preferences.wallpaper.gowallEnabled && processedWallpaper !== "") ? processedWallpaper : currentWallpaper

    // ── CHILD COMPONENTS ────────────────────────────────────────────
    readonly property string wallpaperListFile: Globals.cacheDir + "/wallpaper.json"

    FileView {
        id: listCacheView
        path: root.wallpaperListFile
        onLoadedChanged: {
            if (loaded && !root.hasScanned) {
                try {
                    var json = JSON.parse(text());
                    if (Array.isArray(json)) root.wallpapers = json;
                } catch (e) {}
            }
        }
    }

    Connections {
        target: Preferences
        function onLoadedChanged() {
            if (Preferences.loaded) {
                if (root.currentWallpaper === "") {
                    root.currentWallpaper = Preferences.currentWallpaper;
                }
                if (!root.hasScanned) {
                    root.scanWallpapers();
                }
            }
        }
    }

    Connections {
        target: Preferences.wallpaper
        function onDirectoryChanged() {
            if (Preferences.loaded) {
                root.refreshWallpapers();
            }
        }
    }

    signal wallpaperSet(string path)

    // ── PUBLIC API ──────────────────────────────────────────────────

    /**
     * Updates the current wallpaper. 
     */
    function setWallpaper(path) {
        if (!path || path === "" || root.currentWallpaper === path) return;

        root.currentWallpaper = path;

        // 1. Persist selection immediately via Preferences service
        Preferences.currentWallpaper = path;

        // 2. Notify system
        root.wallpaperSet(path);
        ProcessService.runDetached(["notify-send", "-a", "Wallpaper", "-i", "symbol:image", "Wallpaper", "The <b>" + path.split("/").pop() + "</b> wallpaper has been applied."]);
    }

    function ensureScanned() { 
        if (!hasScanned) {
            if (Preferences.loaded) {
                scanWallpapers(); 
            } else {
                console.log("[WallpaperService] ensureScanned called before Preferences loaded, skipping until load");
            }
        }
    }
    function refreshWallpapers() { hasScanned = false; scanWallpapers(); }
    

    function shuffleWallpapers() {
        if (!wallpapers || wallpapers.length <= 1) return;
        
        var shuffled = [...wallpapers];
        for (var i = shuffled.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1));
            [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
        }
        wallpapers = shuffled;
    }

    // ── INTERNAL LOGIC ──────────────────────────────────────────────

    property Timer scanRetryTimer: Timer {
        interval: 1000
        repeat: false
        onTriggered: root.scanWallpapers()
    }

    // Expand $HOME and ~ in a path string to the actual home directory
    function expandPath(path) {
        var home = Globals.homeDir;
        if (path.indexOf("$HOME") === 0) return home + path.substring(5);
        if (path.indexOf("~") === 0) return home + path.substring(1);
        return path;
    }

    function scanWallpapers() {
        if (isLoading) return; 
        
        // Expand $HOME and ~ in the directory path
        var dir = expandPath(Preferences.wallpaper.directory);
        if (!dir || dir === "") {
            console.warn("[WallpaperService] No valid directory to scan");
            root.wallpapers = [];
            root.hasScanned = true;
            return;
        }
        
        // Use multiple -iname arguments for better portability and robustness
        var cmd = ["find", dir, "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")"];
        
        var proc = ProcessService.run(cmd, function(output, exitCode) {
            if (exitCode !== 0) {
                // find exited non-zero (missing dir, permission error, etc.). Don't retry forever.
                root.wallpapers = [];
                root.isLoading = false;
                root.hasScanned = true;
                console.warn("[WallpaperService] find exited with code", exitCode, "for", dir);
                ProcessService.runDetached(["notify-send", "-a", "Wallpaper", "-i", "symbol:image-error", "Wallpaper", "Could not scan directory: " + dir]);
                return;
            }

            var list = output.trim().split("\n").filter(l => l.length > 0);

            root.wallpapers = list;
            root.isLoading = false;
            root.hasScanned = true;

            // Provide variety from the start
            root.shuffleWallpapers();

            // Sync list cache
            ProcessService.runDetached(["sh", "-c", "printf '%s' \"$1\" > \"$2\"", "--", JSON.stringify(list), root.wallpaperListFile]);

            // First-run branch: only fires when nothing was previously selected.
            if (root.currentWallpaper === "" && list.length > 0) {
                setWallpaper(list[Math.floor(Math.random() * list.length)]);
            }
        });

        if (proc) {
            isLoading = true;
        } else {
            scanRetryTimer.start();
        }
    }

    Component.onCompleted: {
        if (Preferences.loaded) {
            scanWallpapers();
        } 
    }
}