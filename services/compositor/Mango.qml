import QtQuick
import Quickshell
import Quickshell.Io
import qs
pragma Singleton

Singleton {
    id: root

    // Signals for real-time updates (Unified interface)
    signal workspacesUpdated(var workspaces, int activeId)
    signal windowsUpdated(var windows)
    signal focusedWindowUpdated(var window)

    property var _tagMap: ({}) // output -> { tagId -> { isActive, isOccupied, isUrgent } }
    property string _activeOutput: ""
    property var _focusedWindow: ({ "title": "Desktop", "appId": "" })
    property var _allWindows: []

    Process {
        id: eventStream
        command: ["mmsg", "-w", "-O", "-t", "-c", "-l"]
        running: true
        
        stdout: SplitParser {
            onRead: (line) => {
                if (line.trim()) processLine(line.trim());
            }
        }
    }

    // Periodic safety sync
    Timer {
        id: lswtTimer
        interval: 5000
        running: true
        repeat: true
        onTriggered: queryWindows()
    }

    // Real-time focus sync triggered by mmsg events
    Timer {
        id: focusDebounceTimer
        interval: 50 // Tiny delay to let Wayland protocol catch up
        repeat: false
        onTriggered: queryWindows()
    }

    // Debounce workspace updates so rapid tag lines from mmsg are processed as one block
    Timer {
        id: workspaceUpdateTimer
        interval: 5
        running: false
        repeat: false
        onTriggered: triggerWorkspacesUpdate()
    }

    function processLine(line) {
        var parts = line.split(" ");
        if (parts.length < 2) return;

        var output = parts[0];
        
        if (output === "+") {
            root._activeOutput = parts[1];
            workspaceUpdateTimer.restart();
            return;
        }

        var key = parts[1];
        var values = parts.slice(2);

        if (key === "tag") {
            if (values.length < 4) return;
            var tagId = parseInt(values[0]);
            var isActive = values[1] !== "0";
            var isOccupied = values[2] !== "0";
            var isUrgent = values[3] !== "0";

            if (!root._tagMap[output]) root._tagMap[output] = {};
            root._tagMap[output][tagId] = {
                "isActive": isActive, "isOccupied": isOccupied, "isUrgent": isUrgent
            };
            
            workspaceUpdateTimer.restart();
        } else if (key === "title") {
            root._focusedWindow.title = values.join(" ") || "Desktop";
            triggerFocusedWindowUpdate();
        } else if (key === "appid") {
            root._focusedWindow.appId = values.join(" ") || "";
            triggerFocusedWindowUpdate();
        }
    }

    function triggerWorkspacesUpdate() {
        var workspaces = [];
        var activeId = -1;
        var output = root._activeOutput || Object.keys(root._tagMap)[0];
        if (!output || !root._tagMap[output]) return;

        var tags = root._tagMap[output];

        for (var id = 1; id <= 5; id++) {
            var tag = tags[id] || { "isActive": false, "isOccupied": false, "isUrgent": false };
            if (tag.isActive) activeId = id;
            
            workspaces.push({
                "id": id, "idx": id, "name": id.toString(),
                "isActive": tag.isActive, "isFocused": tag.isActive,
                "hasWindows": tag.isOccupied, "isUrgent": tag.isUrgent
            });
        }
        root.workspacesUpdated(workspaces, activeId);
    }

    function triggerFocusedWindowUpdate() {
        var win = {
            "id": "focused",
            "title": root._focusedWindow.title,
            "appId": root._focusedWindow.appId,
            "isFocused": true
        };
        root.focusedWindowUpdated(win);
        
        // Immediate focus update for the dock:
        // We update the existing window list instantly so the UI responds 
        // to mmsg events without waiting for the lswt poll.
        if (root._allWindows.length > 0) {
            // Count how many windows match the focus info from mmsg
            var matches = root._allWindows.filter(w => w.title === win.title && w.appId === win.appId);
            
            // Only perform an "optimistic" focus update if it's unambiguous.
            // If there are multiple identical windows, we MUST wait for the lswt poll 
            // to be 100% sure which one is focused.
            if (matches.length === 1) {
                var updated = root._allWindows.map(w => {
                    var isNowFocused = (w.title === win.title && w.appId === win.appId);
                    return {
                        "id": w.id,
                        "title": w.title,
                        "appId": w.appId,
                        "isFocused": isNowFocused
                    };
                });
                
                root._allWindows = updated;
                root.windowsUpdated(updated);
            }
        }
        
        // Trigger an immediate verified sync from lswt
        focusDebounceTimer.restart();
    }

    // --- Actions (Unified Interface) ---
    function switchToWorkspace(workspaceIdx) {
        ProcessService.runDetached(["mmsg", "-s", "-t", workspaceIdx.toString()]);
    }

    function focusWindow(windowId) {
        if (!windowId) return;
        
        // windowId is "appId|title|index"
        const parts = windowId.split("|");
        if (parts.length < 3) return;
        
        const appId = parts[0];
        const title = parts[1];
        
        // Use wlrctl to focus by appId and title match
        ProcessService.runDetached(["wlrctl", "toplevel", "focus", `app_id:${appId}`, `title:${title}`]);
    }

    function quit() {
        ProcessService.runDetached(["mmsg", "-q"]);
    }

    // --- Initial Polling / Manual Refresh ---
    function queryWorkspaces(callback) {
        ProcessService.run(["mmsg", "-g", "-O", "-t", "-l"], (data) => {
            var lines = data.split("\n");
            lines.forEach(line => { if (line.trim()) processLine(line.trim()); });
            triggerWorkspacesUpdate();
        });
    }

    function queryWindows(callback) {
        // Try lswt for a full window list
        ProcessService.run(["lswt", "-j"], (data) => {
            if (data && data.trim() !== "" && data.startsWith("{")) {
                try {
                    var json = JSON.parse(data);
                    var tl = json.toplevels || [];
                    var idCounts = {};
                    var windows = tl.map(w => {
                        const appId = w["app-id"] || "";
                        const title = w.title || "";
                        const baseId = appId + "|" + title;
                        
                        idCounts[baseId] = (idCounts[baseId] || 0) + 1;
                        const finalId = baseId + "|" + idCounts[baseId];

                        return {
                            "id": finalId,
                            "title": title,
                            "appId": appId,
                            "isFocused": w.activated === true
                        };
                    });
                    root._allWindows = windows;
                    root.windowsUpdated(windows);
                    if (callback) callback(windows);
                    return;
                } catch (e) {
                    console.warn("Mango: Failed to parse lswt output", e);
                }
            }
            
            // Fallback: Just the focused window from mmsg
            var fallback = [{
                "id": "focused",
                "title": root._focusedWindow.title,
                "appId": root._focusedWindow.appId,
                "isFocused": true
            }];
            root._allWindows = fallback;
            root.windowsUpdated(fallback);
            if (callback) callback(fallback);
        });
    }

    function queryFocusedWindow(callback) {
        ProcessService.run(["mmsg", "-g", "-c"], (data) => {
            var lines = data.split("\n");
            lines.forEach(line => { if (line.trim()) processLine(line.trim()); });
            if (callback) callback({
                "id": "focused",
                "title": root._focusedWindow.title,
                "appId": root._focusedWindow.appId,
                "isFocused": true
            });
        });
    }

    Component.onCompleted: {
        queryWorkspaces();
        queryFocusedWindow();
        queryWindows();
    }
}
