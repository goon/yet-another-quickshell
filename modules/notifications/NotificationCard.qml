import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs

BaseBlock {
    id: root

    property var notification: null
    property real progress: 0
    property bool showCloseButton: true
    property bool showTime: true
    property var time: new Date()
    property string timeString: "now"

    signal closeClicked()

    function updateTime() {
        if (!time)
            return ;

        timeString = Qt.formatDateTime(time, "hh:mm");
    }

    readonly property bool isScreenshot: {
        if (!root.notification) return false;
        const app = (root.notification.appName || "").toLowerCase();
        const sum = (root.notification.summary || "").toLowerCase();
        return app === "niri" || sum.indexOf("screenshot") !== -1;
    }

    borderWidth: 1
    borderColor: Theme.colors.border
    premiumHover: true
    clickable: true
    padding: 0
    onTimeChanged: root.updateTime()

    Component.onCompleted: root.updateTime()
    Layout.fillWidth: true
    implicitWidth: 350

    // Inner Content Block
    Rectangle {
        property real innerPadding: Theme.geometry.spacing.dynamicPadding

        Layout.fillWidth: true

        Layout.preferredHeight: notifContent.implicitHeight + (innerPadding * 2)
        color: Theme.colors.transparent
        radius: Theme.geometry.radius

        ColumnLayout {
            id: notifContent

            anchors.fill: parent
            anchors.margins: parent.innerPadding
            spacing: Theme.geometry.spacing.medium


            // Top section: Icon, Info, Close
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.geometry.spacing.large
                Layout.alignment: Qt.AlignTop


                // App icon
                Rectangle {
                    Layout.preferredWidth: Theme.dimensions.iconLarge
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.alignment: Qt.AlignTop

                    color: Theme.colors.transparent
                    radius: 0

                    function resolveSource(src) {
                        return LauncherService.resolveIcon(src);
                    }

                    // 1. Specific Image (Highest Priority)
                    // e.g. User Avatar, Album Art
                    Image {
                        id: specificImage
                        anchors.centerIn: parent
                        width: Math.min(Theme.dimensions.iconLarge, parent.width - 4)
                        height: width

                        source: parent.resolveSource(root.notification ? root.notification.image : "")
                        sourceSize.width: width
                        sourceSize.height: height
                        smooth: true
                        visible: !root.isScreenshot && status === Image.Ready && source.toString() !== ""
                    }

                    // 2. App Icon (Middle Priority)
                    // e.g. Discord Logo, Spotify Logo
                    // Visible if Specific Image is missing or failed to load
                    Image {
                        id: appIconImage
                        anchors.centerIn: parent
                        width: Math.min(Theme.dimensions.iconLarge, parent.width - 4)
                        height: width

                        source: parent.resolveSource(root.notification ? root.notification.appIcon : "")
                        sourceSize.width: width
                        sourceSize.height: height
                        smooth: true
                        visible: !root.isScreenshot && !specificImage.visible && status === Image.Ready && source.toString() !== ""
                    }

                    // 3. Material Symbol (Custom Fallback)
                    // Visible if appIcon or image starts with 'symbol:'
                    Text {
                        id: symbolIcon
                        anchors.centerIn: parent
                        font.pixelSize: Theme.dimensions.iconMedium
                        font.family: Theme.typography.iconFamily
                        text: {
                            if (!root.notification) return "";
                            if (root.isScreenshot) return "image";
                            const ai = root.notification.appIcon || "";
                            const img = root.notification.image || "";
                            
                            function extract(s) {
                                if (s.startsWith("symbol:")) return s.substring(7);
                                const idx = s.indexOf("symbol:");
                                if (idx !== -1) return s.substring(idx + 7);
                                return "";
                            }
                            
                            const res = extract(ai);
                            if (res) return res;
                            return extract(img);
                        }
                        visible: text !== ""
                        color: Theme.colors.primary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        z: 10
                    }

                    // 4. Icon Fallback (Lowest Priority)
                    // Visible if NO images or symbols are loaded
                    BaseIcon {
                        anchors.centerIn: parent
                        visible: !specificImage.visible && !appIconImage.visible && !symbolIcon.visible
                        icon: "notifications_unread"
                        size: Theme.dimensions.iconMedium
                        width: size
                        height: size
                        color: Theme.colors.primary
                    }
                }

                // Header info: Summary (Title) | App Name (Single Line)
                RowLayout {
                    id: headerRow
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Theme.geometry.spacing.small

                    // Summary (Title)
                    BaseText {
                        id: summaryText
                        Layout.fillWidth: false
                        color: Theme.colors.text
                        pixelSize: Theme.typography.size.medium
                        weight: Theme.typography.weights.bold
                        text: root.notification ? (root.notification.summary || "") : ""
                        maximumLineCount: 1
                        elide: Text.ElideRight
                        // Allow the summary to shrink but avoid circular dependency on parent.width
                        Layout.maximumWidth: root.width - 120
                    }

                    // Separator
                    BaseText {
                        id: separator
                        text: "|"
                        color: Theme.colors.muted
                        visible: root.showTime
                        pixelSize: Theme.typography.size.base
                    }

                    // Time
                    BaseText {
                        id: timeText
                        color: Theme.colors.muted
                        visible: root.showTime
                        text: root.timeString.toUpperCase()
                        pixelSize: Theme.typography.size.small
                        elide: Text.ElideRight
                    }

                    // Spacer to push everything to the left
                    Item {
                        Layout.fillWidth: true
                    }
                }

                // Close button
                BaseButton {
                    Layout.preferredWidth: Theme.dimensions.iconMedium
                    Layout.preferredHeight: Theme.dimensions.iconMedium
                    Layout.alignment: Qt.AlignTop
                    visible: root.showCloseButton
                    icon: "clear_all"
                    iconColor: containsMouse ? Theme.colors.surface : Theme.colors.error
                    hoverColor: Theme.colors.error
                    size: Theme.typography.size.large
                    onClicked: root.closeClicked()
                }

            }

            // Body section: Spans full width
            BaseText {
                Layout.fillWidth: true
                Layout.preferredWidth: 200 // Hint to help Layout
                color: Theme.colors.text
                bold: false
                text: root.notification ? (root.notification.body || "") : ""
                wrapMode: Text.Wrap
                maximumLineCount: 8
                elide: Text.ElideRight
                visible: text !== ""
            }


        }

    }

}
