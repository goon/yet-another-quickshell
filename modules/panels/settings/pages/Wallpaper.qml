import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root
    
    title: "Wallpaper & Effects"

    GridLayout {
        columns: 2
        rowSpacing: Theme.geometry.spacing.dynamicPadding
        columnSpacing: Theme.geometry.spacing.dynamicPadding
        Layout.fillWidth: true

        BaseText {
            text: "Configure your desktop background and dynamic theming."
            color: Theme.colors.text
            pixelSize: Theme.typography.size.medium
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.columnSpan: 2
            Layout.bottomMargin: Theme.geometry.spacing.small
        }

        // --- General ---
        BaseText {
            text: "General"
            weight: Theme.typography.weights.bold
            color: Theme.colors.primary
            pixelSize: Theme.typography.size.large
            Layout.columnSpan: 2
            Layout.topMargin: Theme.geometry.spacing.small
        }

        BaseText {
            text: "Enable Gowall Theming:"
            pixelSize: Theme.typography.size.medium
            Layout.fillWidth: true
        }

        BaseSwitch {
            checked: Preferences.gowallEnabled
            onToggled: Preferences.gowallEnabled = checked
            Layout.alignment: Qt.AlignLeft
        }

        BaseText {
            text: "Wallpaper Gallery:"
            pixelSize: Theme.typography.size.medium
            Layout.fillWidth: true
        }

        BaseButton {
            text: "Open Gallery"
            implicitHeight: 42
            onClicked: PopoutService.toggleWallpaper()
            Layout.alignment: Qt.AlignLeft
        }

        BaseSeparator {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            Layout.topMargin: Theme.geometry.spacing.medium
            Layout.bottomMargin: Theme.geometry.spacing.medium
        }

        // --- Storage ---
        BaseText {
            text: "Storage"
            weight: Theme.typography.weights.bold
            color: Theme.colors.primary
            pixelSize: Theme.typography.size.large
            Layout.columnSpan: 2
            Layout.topMargin: Theme.geometry.spacing.medium
        }

        BaseText {
            text: "Specify the folder where your background images are stored."
            color: Theme.colors.text
            pixelSize: Theme.typography.size.medium
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.columnSpan: 2
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            spacing: Theme.geometry.spacing.small

            BaseInput {
                id: dirInput
                Layout.fillWidth: true
                implicitHeight: 42
                inputPadding: 10
                text: Preferences.wallpaperDirectory
                placeholderText: "e.g. /home/user/Pictures/Wallpapers"
                onEditingFinished: Preferences.wallpaperDirectory = text
            }

            BaseButton {
                id: browseBtn
                icon: "folder"
                Layout.preferredHeight: dirInput.height
                Layout.preferredWidth: dirInput.height
                onClicked: PopoutService.openFileDialog(Preferences.wallpaperDirectory, (path) => {
                    if (path) {
                        var p = path.toString();
                        if (p.indexOf("file://") === 0) p = p.substring(7);
                        
                        // Always update preferences
                        Preferences.wallpaperDirectory = p;
                        
                        // Only update UI if it's still alive
                        if (typeof dirInput !== 'undefined' && dirInput !== null) {
                            dirInput.text = p;
                        }
                    }
                })
            }
        }

        // Warning when no directory is set
        BaseBlock {
            visible: Preferences.wallpaperDirectory === ""
            backgroundColor: Theme.alpha(Theme.colors.warning, 0.1)
            borderColor: Theme.colors.warning
            Layout.fillWidth: true
            Layout.columnSpan: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.geometry.spacing.medium
                
                BaseIcon {
                    icon: "warning"
                    color: Theme.colors.warning
                    size: Theme.dimensions.iconMedium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    BaseText {
                        text: "No Wallpaper Directory Set"
                        font.bold: true
                        color: Theme.colors.warning
                    }
                    BaseText {
                        text: "The wallpaper gallery is disabled until you select a folder containing images."
                        pixelSize: Theme.typography.size.base
                        color: Theme.colors.text
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }

        // --- Spacer to push everything to the top ---
        Item {
            Layout.fillHeight: true
            Layout.columnSpan: 2
        }
    }
}
