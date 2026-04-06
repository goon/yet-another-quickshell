import QtQuick
import QtQuick.Layouts
import Qt.labs.platform
import Quickshell
import qs

BaseBlock {
    id: root

    signal placeClicked(string path)

    width: 200
    Layout.fillHeight: true
    blockRadius: Theme.geometry.radius
    backgroundColor: Theme.colors.surface // Use solid surface color

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.geometry.spacing.small

        Repeater {
            model: [
                { text: "Home", icon: "user-home", path: StandardPaths.writableLocation(StandardPaths.HomeLocation) },
                { text: "Desktop", icon: "user-desktop", path: StandardPaths.writableLocation(StandardPaths.DesktopLocation) },
                { text: "Documents", icon: "folder-documents", path: StandardPaths.writableLocation(StandardPaths.DocumentsLocation) },
                { text: "Downloads", icon: "folder-download", path: StandardPaths.writableLocation(StandardPaths.DownloadLocation) },
                { text: "Pictures", icon: "folder-pictures", path: StandardPaths.writableLocation(StandardPaths.PicturesLocation) },
                { text: "Videos", icon: "folder-videos", path: StandardPaths.writableLocation(StandardPaths.MoviesLocation) }
            ]

            delegate: BaseBlock {
                Layout.fillWidth: true
                implicitHeight: 48 
                backgroundColor: "transparent"
                blockRadius: Theme.geometry.radius
                clickable: true
                hoverEnabled: true
                premiumHover: true
                padding: 0
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: Theme.geometry.spacing.dynamicPadding
                    Layout.rightMargin: Theme.geometry.spacing.dynamicPadding
                    spacing: Theme.geometry.spacing.medium

                    Image {
                        source: Quickshell.iconPath(modelData.icon) || ""
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        Layout.alignment: Qt.AlignVCenter
                        fillMode: Image.PreserveAspectFit
                    }

                    BaseText {
                        text: modelData.text
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        color: Theme.colors.text
                        pixelSize: Theme.typography.size.medium
                        weight: Theme.typography.weights.medium
                    }
                }

                onClicked: root.placeClicked(modelData.path)
            }
        }
        Item { Layout.fillHeight: true } // Spacer
    }
}
