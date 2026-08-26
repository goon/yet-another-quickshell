import QtQuick
import Quickshell
import Quickshell.Io
import qs
pragma Singleton

QtObject {
    id: root

    property ListModel history
    readonly property string cliphistDb: Globals.cacheDir + "/cliphist/db"
    property bool cliphistAvailable: false
    property var firstSeenTimes: ({})
    property bool firstSeenLoaded: false
    property int firstSeenVersion: 0
    property string _currentImageTemp: ""
    readonly property string timestampFile: Globals.cacheDir + "/clipboard_timestamp.json"

    property FileView firstSeenFileView: FileView {
        path: root.timestampFile
        watchChanges: false
        onLoadedChanged: {
            if (loaded) {
                try {
                    var data = JSON.parse(text() || "{}");
                    if (data && typeof data === "object") {
                        for (var k in data) {
                            if (typeof data[k] === "string") {
                                var d = new Date(data[k]);
                                if (!isNaN(d.getTime())) {
                                    root.firstSeenTimes[k] = d;
                                }
                            }
                        }
                    }
                } catch (e) {
                    console.warn("[Clipboard] Failed to parse first-seen file:", e.message);
                }
            }
            root.firstSeenLoaded = true;
            root.firstSeenVersion++;
        }
    }

    function reloadCliphist() {
        var limit = Preferences.clipboard.displayLimit || 50;
        ProcessService.run(["sh", "-c", "cliphist list | head -n " + limit], function(out) {
            if (out === undefined || out === null) {
                return;
            }
            if (out === "") {
                root.history.clear();
                return;
            }
            
            var lines = out.split("\n");
            var newHistory = [];
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i];
                if (!line) continue;
                
                var match = line.match(/^([0-9]+)\s+(.*)$/);
                if (!match) continue;
                
                var idStr = match[1];
                var content = match[2];
                var isImg = content.indexOf("[[ binary data") !== -1;
                
                var itemText = content.replace(/\\n/g, "\n").replace(/\\t/g, "\t");

                if (!root.firstSeenTimes[idStr]) {
                    root.firstSeenTimes[idStr] = new Date();
                }

                newHistory.push({
                    "id": idStr,
                    "text": itemText,
                    "isImage": isImg,
                    "rawLine": line
                });
            }
            root.firstSeenVersion++;

            // Model-diffing: Only update if the new list is actually different
            var isDifferent = newHistory.length !== root.history.count;
            if (!isDifferent) {
                for (var k = 0; k < newHistory.length; k++) {
                    if (newHistory[k].id !== root.history.get(k).id) {
                        isDifferent = true;
                        break;
                    }
                }
            }

            if (isDifferent) {
                root.history.clear();
                for (var j = 0; j < newHistory.length; j++) {
                    root.history.append(newHistory[j]);
                }
            }
            root.requestFirstSeenSave();
        });
    }



    function copyToClipboard(text) {
        if (!text)
            return;
        // Text copied normally via UI (if needed anywhere, though the UI mostly pastes)
        ProcessService.runDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "--", text]);
    }

    // copyToClipboard but natively via cliphist (fixes image pasting)
    function pasteCliphistItem(rawLine) {
        if (!rawLine || !root.cliphistAvailable) return;
        ProcessService.runDetached(["sh", "-c", "printf '%s\n' \"$1\" | cliphist decode | wl-copy", "--", rawLine]);
    }

    function decodeItem(rawLine, callback) {
        if (!rawLine || !root.cliphistAvailable) { callback(""); return; }
        ProcessService.run(["sh", "-c", "printf '%s\n' \"$1\" | cliphist decode", "--", rawLine], function(out) {
            callback(out || "");
        });
    }

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function parseImagePreview(line) {
        var m = line.match(/\[\[ binary data (\d+(?:\.\d+)?)\s*(B|KiB|MiB|GiB|KB|MB|GB)\s+(\w+)\s+(\d+)x(\d+) \]\]/);
        if (!m) return null;
        return {
            sizeValue: parseFloat(m[1]),
            sizeUnit: m[2],
            format: m[3],
            width: parseInt(m[4]),
            height: parseInt(m[5])
        };
    }

    function getImageTitle(item) {
        if (!item || !item.isImage) return "";
        var meta = root.parseImagePreview(item.rawLine);
        if (!meta) return "Image";
        return meta.format.toUpperCase() + " " + meta.width + "×" + meta.height;
    }

    function _cleanImageTemp() {
        if (root._currentImageTemp && root._currentImageTemp.length > 0) {
            var p = root._currentImageTemp;
            root._currentImageTemp = "";
            ProcessService.runDetached(["sh", "-c",
                "rm -f " + shellQuote(p)
                + " && rmdir --ignore-fail-on-non-empty " + shellQuote(Globals.cacheDir + "/cliphist") + " 2>/dev/null || true"
            ]);
        }
    }

    function decodeImage(rawLine, callback) {
        if (!rawLine || !root.cliphistAvailable) { callback(""); return; }
        root._cleanImageTemp();
        var dir = Globals.cacheDir + "/cliphist";
        var stamp = Date.now() + "_" + Math.floor(Math.random() * 1e9);
        var out = dir + "/img_" + stamp;
        var script = "mkdir -p " + shellQuote(dir)
                   + " && printf '%s\\n' \"$1\" | cliphist decode > " + shellQuote(out)
                   + " && echo " + shellQuote(out);
        ProcessService.run(["sh", "-c", script, "--", rawLine], function(stdout) {
            var path = (stdout || "").trim();
            if (path.length > 0) {
                root._currentImageTemp = path;
                callback(path);
            } else {
                callback("");
            }
        });
    }

    function deleteCliphistItem(rawLine) {
        if (!rawLine || !root.cliphistAvailable) return;
        
        // Optimistic UI removal
        for (var i = 0; i < history.count; i++) {
            if (history.get(i).rawLine === rawLine) {
                history.remove(i);
                break;
            }
        }

        ProcessService.runDetached(["sh", "-c", "printf '%s\n' \"$1\" | cliphist delete", "--", rawLine]);
    }



    function clearHistory() {
        if (!root.cliphistAvailable) return;
        ProcessService.runDetached(["sh", "-c", "cliphist wipe"]);
    }

    function saveFirstSeen() {
        if (!root.firstSeenLoaded) return;
        var data = {};
        for (var k in root.firstSeenTimes) {
            data[k] = root.firstSeenTimes[k].toISOString();
        }
        var jsonContent = JSON.stringify(data);
        var tempFile = root.timestampFile + ".tmp";
        var cmd = `printf '%s' "$1" > "$2" && mv "$2" "$3"`;
        ProcessService.runDetached(["sh", "-c", cmd, "--", jsonContent, tempFile, root.timestampFile]);
    }

    property Timer firstSeenSaveTimer: Timer {
        interval: 500
        repeat: false
        onTriggered: root.saveFirstSeen()
    }

    property Timer firstSeenSafetyTimer: Timer {
        interval: 2000
        running: true
        repeat: false
        onTriggered: {
            if (!root.firstSeenLoaded) {
                root.firstSeenLoaded = true;
                root.requestFirstSeenSave();
            }
        }
    }

    function requestFirstSeenSave() {
        if (firstSeenLoaded) firstSeenSaveTimer.restart();
    }

    function getFirstSeen(id) {
        return root.firstSeenTimes[id] || null;
    }

    function getSize(item) {
        if (!item) return "0 B";
        if (item.isImage) {
            var match = (item.rawLine || "").match(/\[\[ binary data (\d+(?:\.\d+)?)\s*([A-Za-z]+)/);
            if (match) {
                var value = parseFloat(match[1]);
                var unit = match[2];
                var mult = 1;
                if (unit === "KiB" || unit === "KB") mult = 1024;
                else if (unit === "MiB" || unit === "MB") mult = 1024 * 1024;
                else if (unit === "GiB" || unit === "GB") mult = 1024 * 1024 * 1024;
                return Stats.formatBytes(Math.round(value * mult));
            }
            return "?";
        }
        return Stats.formatBytes((item.text || "").length);
    }

    function isCode(text) {
        if (!text) return false;
        var lines = text.split("\n");

        if (lines.length >= 2) {
            var indented = 0;
            for (var i = 0; i < lines.length; i++) {
                var l = lines[i];
                if (l.length > 0 && /^\s{2,}\S/.test(l)) indented++;
            }
            if (indented >= 2) return true;
        }

        var markerRe = /(\bfunction\b|\bdef\b|\bvar\b|\blet\b|\bconst\b|\bimport\b|\breturn\b|=>|<\/\w+>|<\w+[ >]|\{\s*$|^\s*\}|\$\(|::|^#!\/|\bconsole\.\w|\bprint\s*\(|;\s*$)/m;
        return markerRe.test(text);
    }

    function getCodeLanguage(text) {
        if (!text) return "text";
        if (/^\s*</m.test(text) && /<\/\w+>/m.test(text)) return "html";
        if (/^\s*</m.test(text) && /<\?xml/i.test(text)) return "xml";
        if (/^\s*[\{\[]/m.test(text) && /"\s*:\s*/m.test(text)) return "json";
        if (/^\s*(def |class |import |from |print\()/m.test(text)) return "python";
        if (/^\s*(function |const |let |var |import |export |=>)/m.test(text)) return "javascript";
        if (/^\s*(#include|int main|void |printf|std::)/m.test(text)) return "cpp";
        if (/^\s*#\!/m.test(text)) return "shell";
        if (/^\s*([\w-]+:\s*$|[\w-]+:\s+.+)/m.test(text) && /^\s+/m.test(text)) return "yaml";
        return "text";
    }

    function formatTimeAgo(date) {
        if (!date) return "";
        var now = new Date();
        var diffMs = now - date;
        if (diffMs < 0) diffMs = 0;
        var diffSec = Math.floor(diffMs / 1000);
        if (diffSec < 45) return "Just now";
        var diffMin = Math.floor(diffSec / 60);
        if (diffMin < 60) return diffMin + "m ago";
        var diffHr = Math.floor(diffMin / 60);
        if (diffHr < 24) return diffHr + "h ago";
        var diffDay = Math.floor(diffHr / 24);
        if (diffDay === 1) return "Yesterday";
        if (diffDay < 7) return diffDay + "d ago";
        return Qt.formatDateTime(date, "dd MMM");
    }

    Component.onCompleted: {
        // Sweep leftover temp files from previous shell sessions.
        ProcessService.runDetached(["sh", "-c",
            "rm -rf " + shellQuote(Globals.cacheDir + "/cliphist") + " 2>/dev/null || true"
        ]);

        ProcessService.run(["sh", "-c", "command -v cliphist"], function(out, exitCode) {
            if (exitCode === 0) {
                root.cliphistAvailable = true;
                ProcessService.runDetached(["systemctl", "--user", "start", "cliphist.service", "cliphist-images.service"]);
                root.firstSeenFileView.reload();
                root.reloadCliphist();
            }
        });
    }

    history: ListModel {
    }

    property string _lastFirstId: ""

    property Timer pollTimer: Timer {
        interval: 1000
        repeat: true
        running: root.cliphistAvailable
        onTriggered: {
            ProcessService.run(["sh", "-c", "cliphist list | head -n 1"], function(out) {
                if (out && out !== "") {
                    var match = out.match(/^([0-9]+)\s+/);
                    if (match && match[1] !== root._lastFirstId) {
                        root._lastFirstId = match[1];
                        root.reloadCliphist();
                    }
                } else if (out === "" && root._lastFirstId !== "") {
                    root._lastFirstId = "";
                    root.reloadCliphist();
                }
            });
        }
    }

    function runCleanup() {
        var days = Preferences.clipboard.cleanupDays;
        if (!days || days <= 0 || !root.cliphistAvailable || !root.firstSeenLoaded) return;
        
        var cutoff = new Date();
        cutoff.setDate(cutoff.getDate() - days);

        ProcessService.run(["sh", "-c", "cliphist list"], function(out) {
            if (!out) return;
            var lines = out.split("\n");
            var toDelete = [];
            
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i];
                if (!line) continue;
                var match = line.match(/^([0-9]+)\s+/);
                if (!match) continue;
                var idStr = match[1];
                
                var seen = root.firstSeenTimes[idStr];
                if (seen && seen < cutoff) {
                    toDelete.push(line);
                }
            }
            
            if (toDelete.length > 0) {
                var script = "";
                for (var j = 0; j < toDelete.length; j++) {
                    script += "printf '%s\\n' " + root.shellQuote(toDelete[j]) + " | cliphist delete\n";
                }
                ProcessService.runDetached(["sh", "-c", script]);
                console.log("[Clipboard] Cleaned up " + toDelete.length + " old items.");
            }
        });
    }

    property Timer cleanupTimer: Timer {
        interval: 3600000 // 1 hour
        repeat: true
        running: root.cliphistAvailable
        onTriggered: root.runCleanup()
    }

    // Run initial cleanup slightly after startup to avoid blocking
    property Timer initialCleanupTimer: Timer {
        interval: 5000
        repeat: false
        running: true
        onTriggered: root.runCleanup()
    }

}
