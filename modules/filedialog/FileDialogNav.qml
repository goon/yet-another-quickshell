import QtQuick
import QtQuick.Layouts
import qs

BaseBlock {
    id: root

    property string currentPath: "/"
    property bool showHidden: false
    signal navigateUp()
    signal navigateTo(string path)
    signal selectCurrent()
    signal toggleHiddenClicked()

    blockRadius: Theme.geometry.radius
    backgroundColor: Theme.colors.surface // Use solid surface color
    implicitHeight: 54
    Layout.fillWidth: true
    padding: 0
    spacing: 0

    RowLayout {
        id: mainRow
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: Theme.geometry.spacing.dynamicPadding
        Layout.rightMargin: Theme.geometry.spacing.dynamicPadding
        spacing: Theme.geometry.spacing.medium

        // 1. Navigation Controls (Up button only)
        BaseButton {
            icon: "arrow_upward"
            size: 24
            implicitWidth: 40; implicitHeight: 40; paddingHorizontal: 0; paddingVertical: 0
            Layout.alignment: Qt.AlignVCenter
            onClicked: root.navigateUp()
            enabled: root.currentPath !== "/"
            opacity: enabled ? 1 : 0.5
            hoverEnabled: false
        }

        // Refined Separator - explicitly 1px wide to avoid "grey box" look
        Rectangle {
            width: 1
            Layout.preferredWidth: 1
            Layout.preferredHeight: 28
            Layout.alignment: Qt.AlignVCenter
            color: Theme.alpha(Theme.colors.border, 0.3)
        }

        // 2. Breadcrumbs (Does not fill width, allowing spacer to work)
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 0
            clip: true

            BaseButton {
                icon: "computer"
                text: "/"
                size: 24
                textSize: Theme.typography.size.medium
                Layout.alignment: Qt.AlignVCenter
                hoverEnabled: false
                paddingHorizontal: Theme.geometry.spacing.small
                onClicked: root.navigateTo("/")
            }

            Repeater {
                id: breadcrumbRepeater
                model: root.currentPath.split("/").filter(s => s !== "")
                
                delegate: RowLayout {
                    spacing: 0
                    BaseText { 
                        text: "chevron_right"
                        font.family: Theme.typography.iconFamily
                        color: Theme.colors.muted
                        pixelSize: 18
                        Layout.alignment: Qt.AlignVCenter
                    }
                    BaseButton {
                        text: modelData
                        textSize: Theme.typography.size.medium
                        hoverEnabled: false
                        paddingHorizontal: Theme.geometry.spacing.small
                        onClicked: {
                            var components = root.currentPath.split("/").filter(s => s !== "");
                            var newPath = "/" + components.slice(0, index + 1).join("/");
                            root.navigateTo(newPath);
                        }
                    }
                }
            }
        }

        // 3. Spacer to force absolute right alignment
        Item {
            Layout.fillWidth: true
        }

        // 4. Right-aligned controls
        BaseButton {
            icon: root.showHidden ? "visibility_off" : "visibility"
            size: 24
            implicitWidth: 40; implicitHeight: 40; paddingHorizontal: 0; paddingVertical: 0
            Layout.alignment: Qt.AlignVCenter
            onClicked: root.toggleHiddenClicked()
            hoverEnabled: false
        }
    }
}
