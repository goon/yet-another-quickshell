import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import qs

BaseBlock {
    id: root

    property string folder: ""
    property bool showHidden: false
    signal folderClicked(string path)
    signal fileClicked(string path)

    signal selectCurrentRequested()

    FolderListModel {
        id: folderModel
        folder: root.folder.indexOf("file://") === 0 ? root.folder : "file://" + root.folder
        showFiles: true
        showDirs: true
        showDotAndDotDot: false
        showHidden: root.showHidden
        sortField: FolderListModel.Name
    }

    ListView {
        id: listView
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: 2
        model: folderModel
        clip: true
        spacing: 2
        
        delegate: BaseBlock {
            width: listView.width
            implicitHeight: 44
            backgroundColor: "transparent"
            hoverColor: Theme.alpha(Theme.colors.primary, 0.1)
            blockRadius: Theme.geometry.radius
            clickable: true
            hoverEnabled: true
            premiumHover: true
            padding: 0
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: Theme.geometry.spacing.dynamicPadding
                Layout.rightMargin: Theme.geometry.spacing.dynamicPadding
                spacing: Theme.geometry.spacing.medium

                Image {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    opacity: fileName.startsWith(".") ? 0.8 : 1.0
                    source: {
                        if (fileIsDir) return Quickshell.iconPath("folder") || "";
                        
                        var lowerName = fileName.toLowerCase();
                        if (lowerName.endsWith(".jpg") || lowerName.endsWith(".png") || 
                            lowerName.endsWith(".webp") || lowerName.endsWith(".jpeg") ||
                            lowerName.endsWith(".gif") || lowerName.endsWith(".svg")) {
                            return fileUrl;
                        }
                        
                        // Fallback to system file icon
                        return Quickshell.iconPath("text-x-generic") || "";
                    }
                }

                BaseText {
                    text: fileName
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    elide: Text.ElideRight
                    color: Theme.colors.text
                    pixelSize: Theme.typography.size.medium
                }
                
                BaseText {
                    text: fileIsDir ? "Folder" : root.formatSize(fileSize)
                    Layout.alignment: Qt.AlignVCenter
                    color: Theme.colors.muted
                    pixelSize: Theme.typography.size.small
                    visible: listView.width > 400
                }
            }

            onClicked: {
                if (fileIsDir) {
                    root.folderClicked(fileUrl);
                } else {
                    root.fileClicked(fileUrl);
                }
            }
        }
        
        // Use standard ScrollBar
        ScrollBar.vertical: ScrollBar {
            implicitWidth: 8
            visible: listView.contentHeight > listView.height
        }
    }

    // Footer bar with Select button (reserves space)
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        Layout.leftMargin: Theme.geometry.spacing.large
        Layout.rightMargin: Theme.geometry.spacing.large
        Layout.bottomMargin: Theme.geometry.spacing.medium
        
        Item { Layout.fillWidth: true } // Spacer
        
        BaseButton {
            text: "Select Current Folder"
            normalColor: Theme.colors.primary
            textColor: Theme.colors.base
            weight: Theme.typography.weights.bold
            paddingHorizontal: Theme.geometry.spacing.large
            visible: folderModel.status === FolderListModel.Ready
            onClicked: root.selectCurrentRequested()
        }
    }

    function formatSize(bytes) {
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB";
        return (bytes / (1024 * 1024)).toFixed(1) + " MB";
    }

    BaseText {
        Layout.alignment: Qt.AlignCenter
        text: "This folder is empty"
        color: Theme.colors.muted
        visible: folderModel.count === 0 && folderModel.status === FolderListModel.Ready
    }
}
