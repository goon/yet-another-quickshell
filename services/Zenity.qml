import QtQuick
import Quickshell
import qs.services

pragma Singleton

// A global singleton service for selecting files/folders via Zenity through the XDG portal.
// This service lives for the entire lifecycle of Quickshell, preventing garbage collection
// or object destruction when individual Settings pages or panels are closed.
Singleton {
    id: root

    function selectFolder(callback) {
        ProcessService.run(
            ["zenity", "--file-selection", "--directory", "--title=Select Folder"],
            function(stdout, exitCode) {
                if (exitCode === 0) {
                    var path = stdout.trim();
                    if (path !== "" && callback) {
                        callback(path);
                    }
                }
            }
        );
    }
}
