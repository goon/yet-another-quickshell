import QtQuick
import Quickshell
import Quickshell.Io
import qs
pragma Singleton

QtObject {
    id: root

    property ListModel history
    readonly property string cliphistDb: "/home/michael/.cache/cliphist/db"
    readonly property string imagesDir: Config.cacheDir + "/cliphist-thumbnails"
    
    // A FileView to watch the cliphist database
    property FileView dbWatcher
    property Timer throttleTimer

    function reloadCliphist() {
        ProcessService.run(["sh", "-c", "cliphist list | head -n 50"], function(out) {
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
                
                var itemText = content;
                if (isImg) {
                    var thumbFile = root.imagesDir + "/item_" + idStr + ".png";
                    itemText = thumbFile;
                    // Trigger async decode if thumbnail doesn't exist
                    ProcessService.runDetached(["sh", "-c", "mkdir -p \"" + root.imagesDir + "\"; if [ ! -f \"" + thumbFile + "\" ]; then echo '" + idStr + "' | cliphist decode > \"" + thumbFile + "\"; fi"]);
                }
                
                newHistory.push({
                    "id": idStr,
                    "text": itemText,
                    "isImage": isImg,
                    "rawLine": line
                });
            }
            
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
        });
    }

    function addClip(text) {
        // Native copying triggers cliphist watcher automatically.
        copyToClipboard(text);
    }

    function copyToClipboard(text) {
        if (!text)
            return;
        // Text copied normally via UI (if needed anywhere, though the UI mostly pastes)
        ProcessService.runDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "--", text]);
    }

    // copyToClipboard but natively via cliphist (fixes image pasting)
    function pasteCliphistItem(rawLine) {
        if (!rawLine) return;
        ProcessService.runDetached(["sh", "-c", "printf '%s\n' \"$1\" | cliphist decode | wl-copy", "--", rawLine]);
    }

    function deleteCliphistItem(rawLine) {
        if (!rawLine) return;
        
        // Optimistic UI removal
        for (var i = 0; i < history.count; i++) {
            if (history.get(i).rawLine === rawLine) {
                history.remove(i);
                break;
            }
        }

        ProcessService.runDetached(["sh", "-c", "printf '%s\n' \"$1\" | cliphist delete", "--", rawLine]);
    }

    // Compatibility method
    function deleteItem(index) {
        if (index >= 0 && index < history.count) {
            var rawLine = history.get(index).rawLine;
            deleteCliphistItem(rawLine);
        }
    }

    function clearHistory() {
        ProcessService.runDetached(["sh", "-c", "cliphist wipe"]);
    }

    Component.onCompleted: {
        reloadCliphist();
    }

    history: ListModel {
    }

    property string _lastFirstId: ""

    property Timer pollTimer: Timer {
        interval: 1000
        repeat: true
        running: true
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

}
