import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs

BaseContainer {
    id: root

    property var notification: null
    property real progress: 0
    property bool showCloseButton: true
    property bool showTime: true
    property var time: new Date()
    property string timeString: "just now"

    signal closeClicked()

    function updateTime() {
        if (!time) return;

        const now = new Date();
        const diffMs = Math.max(0, now.getTime() - time.getTime());
        const diffSecs = Math.floor(diffMs / 1000);
        const diffMins = Math.floor(diffSecs / 60);
        const diffHours = Math.floor(diffMins / 60);
        const diffDays = Math.floor(diffHours / 24);

        if (diffDays > 0) {
            timeString = diffDays + "d ago";
        } else if (diffHours > 0) {
            timeString = diffHours + "h ago";
        } else if (diffMins > 0) {
            timeString = diffMins + "m ago";
        } else {
            timeString = "just now";
        }
    }

    Timer {
        interval: 60000 // Refresh every minute
        running: root.visible
        repeat: true
        onTriggered: root.updateTime()
    }

    readonly property bool isScreenshot: {
        if (!root.notification) return false;
        const sum = (root.notification.summary || "").toLowerCase();
        return sum.indexOf("screenshot") !== -1;
    }

    readonly property bool isRecording: {
        if (!root.notification) return false;
        const sum = (root.notification.summary || "").toLowerCase();
        return sum.indexOf("recording") !== -1;
    }

    clickable: true
    onTimeChanged: root.updateTime()

    Component.onCompleted: root.updateTime()
    Layout.fillWidth: true
    implicitWidth: 350

    // Top section: Icon, Info, Close
    RowLayout {
        Layout.fillWidth: true
        spacing: Globals.geometry.spacing.large
        Layout.alignment: Qt.AlignTop


                // App icon
                Rectangle {
                    Layout.preferredWidth: Globals.dimensions.iconLarge
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.alignment: Qt.AlignTop

                    color: Globals.colors.transparent
                    radius: 0

                    function resolveSource(src) {
                        return LauncherService.resolveIcon(src);
                    }

                    // 1. Specific Image (Highest Priority)
                    // e.g. User Avatar, Album Art
                    Image {
                        id: specificImage
                        anchors.centerIn: parent
                        width: Math.min(Globals.dimensions.iconLarge, parent.width - 4)
                        height: width

                        source: parent.resolveSource(root.notification ? root.notification.image : "")
                        sourceSize.width: width
                        sourceSize.height: height
                        visible: !root.isScreenshot && !root.isRecording && status === Image.Ready && source.toString() !== ""
                    }

                    // 2. App Icon (Middle Priority)
                    // e.g. Discord Logo, Spotify Logo
                    // Visible if Specific Image is missing or failed to load
                    Image {
                        id: appIconImage
                        anchors.centerIn: parent
                        width: Math.min(Globals.dimensions.iconLarge, parent.width - 4)
                        height: width

                        source: parent.resolveSource(root.notification ? root.notification.appIcon : "")
                        sourceSize.width: width
                        sourceSize.height: height
                        visible: !root.isScreenshot && !root.isRecording && !specificImage.visible && status === Image.Ready && source.toString() !== ""
                    }

                    // 3. Material Symbol (Custom Fallback)
                    // Visible if appIcon or image starts with 'symbol:'
                    Rectangle {
                        id: symbolIconContainer
                        anchors.centerIn: parent
                        width: 36
                        height: 36
                        radius: Globals.geometry.radius
                        color: Globals.alpha(Globals.colors.primary, 0.15)
                        visible: symbolIcon.icon !== ""
                        z: 10

                        BaseIcon {
                            id: symbolIcon
                            anchors.centerIn: parent
                            size: Globals.dimensions.iconBase
                            icon: {
                                if (!root.notification) return "";
                                if (root.isScreenshot) return "image";
                                if (root.isRecording) return "screen_record";
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
                            color: Globals.colors.primary
                        }
                    }

                    // 4. Icon Fallback (Lowest Priority)
                    // Visible if NO images or symbols are loaded
                    BaseIcon {
                        anchors.centerIn: parent
                        visible: !specificImage.visible && !appIconImage.visible && !symbolIcon.visible
                        icon: "notifications_unread"
                        width: size
                        height: size
                        color: Globals.colors.primary
                    }
                }

                // Header info: Summary (Title) | App Name (Single Line)
                RowLayout {
                    id: headerRow
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Globals.geometry.spacing.small

                    // Summary (Title)
                    BaseText {
                        id: summaryText
                        Layout.fillWidth: false
                        pixelSize: Globals.typography.size.medium
                        weight: Globals.typography.weights.bold
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
                        muted: true
                        visible: root.showTime
                    }

                    // Time
                    BaseText {
                        id: timeText
                        muted: true
                        visible: root.showTime
                        text: root.timeString
                        pixelSize: Globals.typography.size.base
                        font.italic: true
                        elide: Text.ElideRight
                    }

                    // Spacer to push everything to the left
                    Item {
                        Layout.fillWidth: true
                    }
                }

                BaseButton {
                    Layout.preferredWidth: Globals.dimensions.iconMedium
                    Layout.preferredHeight: Globals.dimensions.iconMedium
                    Layout.alignment: Qt.AlignTop
                    visible: root.showCloseButton
                    icon: "clear_all"
                    iconColor: containsMouse ? Globals.colors.surface : Globals.colors.error
                    hoverColor: Globals.colors.error
                    size: Globals.typography.size.large
                    onClicked: root.closeClicked()
                }

            }

            // Body section: Spans full width
            BaseText {
                Layout.fillWidth: true
                Layout.preferredWidth: 200 // Hint to help Layout
                bold: false
                text: root.notification ? (root.notification.body || "") : ""
                wrapMode: Text.Wrap
                maximumLineCount: 8
                elide: Text.ElideRight
                visible: text !== ""
            }
}
