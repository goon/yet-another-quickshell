import QtQuick
import QtQuick.Layouts
import Qt.labs.platform
import qs

BaseFloatingWindow {
    id: root

    title: "File Browser"
    implicitWidth: 1210
    implicitHeight: 810

    minimumSize: Qt.size(910, 585)

    property string currentFolder: StandardPaths.writableLocation(StandardPaths.HomeLocation)
    property var callback: null

    function open(initialPath, onSelected) {
        if (initialPath) {
            var p = initialPath.toString();
            if (p.indexOf("file://") === 0) p = p.substring(7);
            root.currentFolder = p;
        }
        root.callback = onSelected;
        
        // Force a visibility toggle if it was already true but hidden by compositor
        root.visible = false; 
        Qt.callLater(() => { root.visible = true; });
    }

    function close() {
        root.visible = false;
        root.callback = null;
    }

    function selectCurrent() {
        var cb = root.callback;
        var path = root.currentFolder;
        
        root.close();
        
        if (cb) {
            try {
                cb(path);
            } catch (e) {
                console.warn("[FileDialog] Callback execution failed: " + e);
            }
        }
    }

    function getParent(p) {
        if (p.endsWith("/")) p = p.substring(0, p.length - 1);
        var lastSlash = p.lastIndexOf("/");
        if (lastSlash >= 0) {
            return p.substring(0, lastSlash) || "/";
        }
        return "/";
    }

    body: Item {
        // The body Item will be resized by BaseFloatingWindow's Loader logic
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.geometry.spacing.large
            spacing: Theme.geometry.spacing.medium

            FileDialogNav {
                id: navBar
                Layout.fillWidth: true
                currentPath: root.currentFolder
                showHidden: content.showHidden
                onNavigateUp: root.currentFolder = root.getParent(root.currentFolder)
                onNavigateTo: (path) => root.currentFolder = path
                onToggleHiddenClicked: content.showHidden = !content.showHidden
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.geometry.spacing.medium

                FileDialogSidebar {
                    id: sidebar
                    Layout.preferredWidth: 300
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onPlaceClicked: (path) => root.currentFolder = path
                }

                FileDialogContent {
                    id: content
                    Layout.preferredWidth: 900
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    folder: root.currentFolder
                    onFolderClicked: (path) => root.currentFolder = path
                    onSelectCurrentRequested: root.selectCurrent()
                }
            }
        }
    }
}
