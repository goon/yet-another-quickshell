import QtQuick
import Quickshell
import Quickshell.Io
import qs
pragma Singleton

/**
 * Wallpaper Service
 *
 * Maintains a scanned list of wallpapers (`wallpapers`) with pre-generated
 * 512px thumbnails. Each entry: { path, name, mtime, thumb }. The shell start
 * triggers scanWallpapers(), which runs `lib/thumbnailer.sh` synchronously to
 * regenerate any missing or stale thumbs into `~/.cache/yaks/thumbnails/`,
 * then reads the directory listing newest-first and emits the entries.
 * Thumbs persist across reloads; only files whose source mtime is newer than
 * the thumb get regenerated. The carousel reads `tile.modelData.thumb` with a
 * `?v=<mtime>` cache-buster so a replaced wallpaper file forces a reload.
 */
Item {
    id: root

    property var wallpapers: []
    property string currentWallpaper: ""

    property bool isLoading: false
    property bool hasScanned: false

    property string processedWallpaper: ""
    readonly property string displayWallpaper: (Preferences.wallpaper.gowallEnabled && processedWallpaper !== "") ? processedWallpaper : currentWallpaper

    readonly property string wallpaperListFile: Globals.cacheDir + "/wallpaper.json"
    readonly property string thumbDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/yaks/thumbnails"
    readonly property string thumbScript: Globals.rootDir + "/lib/thumbnailer.sh"

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
                    scanWallpapers();
                }
            }
        }
    }

    Connections {
        target: Preferences.wallpaper
        function onDirectoryChanged() {
            if (Preferences.loaded) {
                refreshWallpapers();
            }
        }
    }

    signal wallpaperSet(string path)

    function setWallpaper(path) {
        if (!path || path === "" || root.currentWallpaper === path) return;

        root.currentWallpaper = path;

        Preferences.currentWallpaper = path;

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

    function expandPath(path) {
        var home = Globals.homeDir;
        if (path.indexOf("$HOME") === 0) return home + path.substring(5);
        if (path.indexOf("~") === 0) return home + path.substring(1);
        return path;
    }

    /**
     * One shell pipeline: ensure cache dir exists, run thumbnailer to fill
     * missing/stale thumbs, list files newest-first with thumb paths appended.
     * The thumbnailer is sync within the pipeline so the list step is guaranteed
     * to see up-to-date thumb files for every source it returns.
     */
    function scanWallpapers() {
        if (isLoading) return;

        var dir = expandPath(Preferences.wallpaper.directory);
        if (!dir || dir === "") {
            console.warn("[WallpaperService] No valid directory to scan");
            root.wallpapers = [];
            root.hasScanned = true;
            return;
        }

        var wpdirJson = JSON.stringify(dir);
        var thumbdirJson = JSON.stringify(root.thumbDir);
        var scriptJson = JSON.stringify(root.thumbScript);

        var cmd = ["sh", "-c",
            "export PATH=\"/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:/nix/var/nix/profiles/default/bin:$HOME/.local/bin:$PATH\"; " +
            "thumbdir=" + thumbdirJson + "; " +
            "mkdir -p \"$thumbdir\"; " +
            "sh " + scriptJson + " " + wpdirJson + " \"$thumbdir\"; " +
            "find " + wpdirJson + " -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -printf '%T@\\t%p\\n' | sort -rn | " +
            "while IFS=$'\\t' read -r mtime path; do " +
            "  printf '%s\\t%s\\t%s\\n' \"$mtime\" \"$path\" \"$thumbdir/$(basename \"$path\").png\"; " +
            "done"];

        isLoading = true;
        var proc = ProcessService.run(cmd, function(output, exitCode) {
            isLoading = false;
            hasScanned = true;

            if (exitCode !== 0) {
                root.wallpapers = [];
                console.warn("[WallpaperService] scan failed for", dir, "exit code", exitCode);
                ProcessService.runDetached(["notify-send", "-a", "Wallpaper", "-i", "symbol:image-error", "Wallpaper", "Could not scan directory: " + dir]);
                return;
            }

            var lines = output.trim().split("\n").filter(l => l.length > 0);
            var entries = [];
            for (var i = 0; i < lines.length; i++) {
                var t1 = lines[i].indexOf("\t");
                if (t1 < 1) continue;
                var t2 = lines[i].indexOf("\t", t1 + 1);
                if (t2 < 0) continue;
                var path = lines[i].substring(t1 + 1, t2);
                entries.push({
                    path: path,
                    name: path.substring(path.lastIndexOf("/") + 1),
                    mtime: parseFloat(lines[i].substring(0, t1)),
                    thumb: lines[i].substring(t2 + 1)
                });
            }
            root.wallpapers = entries;

            ProcessService.runDetached(["sh", "-c", "printf '%s' \"$1\" > \"$2\"", "--", JSON.stringify(entries), root.wallpaperListFile]);

            if (root.currentWallpaper === "" && entries.length > 0) {
                setWallpaper(entries[0].path);
            }
        });

        if (!proc) {
            isLoading = false;
            hasScanned = true;
            scanRetryTimer.start();
        }
    }

    property Timer scanRetryTimer: Timer {
        interval: 1000
        repeat: false
        onTriggered: root.scanWallpapers()
    }

    Component.onCompleted: {
        if (Preferences.loaded) {
            scanWallpapers();
        }
    }
}
