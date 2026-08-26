import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

Item {
    id: root

    implicitHeight: mainLayout.implicitHeight
    implicitWidth: mainLayout.implicitWidth
    Layout.fillWidth: true

    // Core Properties
    property string deviceType: "bluetooth" // "bluetooth" | "wifi"
    
    // Display Properties
    property string title: ""
    property string subtitle: ""
    property string iconName: "bluetooth"
    property real iconOpacity: 1.0
    property bool isConnected: false
    property bool isSecured: false
    property bool isKnown: false // For Wi-Fi or Bluetooth (paired/bonded/trusted)
    
    // Internal State
    property bool expanded: false
    readonly property bool isHovered: mainMouseArea.containsMouse
    
    // Signals
    signal connectClicked(string password)
    signal disconnectClicked()
    signal forgetClicked()
    signal actionClicked()

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right

        // Main Row Container
        Item {
            id: rowContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            implicitWidth: innerRowLayout.implicitWidth

            MouseArea {
                id: mainMouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        if (root.isKnown || root.isConnected) {
                            root.forgetClicked();
                        }
                        return;
                    }

                    if (deviceType === "wifi") {
                        if (root.isSecured && !root.isConnected && !root.isKnown) {
                            root.expanded = !root.expanded;
                            if (root.expanded) {
                                passwordInput.forceActiveFocus();
                            }
                        } else {
                            if (root.isConnected) {
                                root.disconnectClicked();
                            } else {
                                root.actionClicked();
                            }
                        }
                    } else {
                        // Bluetooth
                        if (root.isConnected) {
                            root.disconnectClicked();
                        } else {
                            root.actionClicked(); // connect
                        }
                    }
                }
            }

            RowLayout {
                id: innerRowLayout
                anchors.fill: parent
                spacing: Globals.geometry.spacing.medium

                // Icon Slot
                Item {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignVCenter
                    
                    BaseIcon {
                        anchors.centerIn: parent
                        icon: root.iconName
                        color: root.isConnected ? Globals.colors.success : (root.deviceType === "bluetooth" && root.isKnown ? Globals.colors.warning : (root.isHovered ? Globals.colors.primary : Globals.colors.text))
                        opacity: root.iconOpacity
                        Behavior on color { BaseAnimation { } }
                    }
                }

                // Title and Subtitle
                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.fillWidth: true

                    BaseText {
                        text: root.title
                        weight: root.isConnected ? Globals.typography.weights.bold : Globals.typography.weights.medium
                        color: root.isConnected ? Globals.colors.primary : (root.isHovered ? Globals.colors.primary : Globals.colors.text)
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        Layout.fillWidth: true
                        Behavior on color { BaseAnimation { } }
                    }

                    BaseText {
                        text: root.subtitle
                        visible: root.subtitle !== ""
                        pixelSize: Globals.typography.size.small
                        muted: true
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        Layout.fillWidth: true
                    }
                }

                // Wi-Fi Status Badge (Fixed Width Pill)
                Rectangle {
                    visible: deviceType === "wifi" && (root.isSecured || root.isKnown)
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: 48
                    radius: Globals.geometry.innerRadius.medium
                    color: Globals.alpha(Globals.colors.text, 0.05)
                    border.width: 1
                    border.color: Globals.alpha(Globals.colors.text, 0.1)

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        BaseIcon {
                            icon: "lock"
                            size: 12
                            visible: root.isSecured
                        }

                        BaseIcon {
                            icon: "heart_check"
                            size: 14
                            visible: root.isKnown
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.expanded ? drawerBox.implicitHeight + Globals.geometry.padding.medium : 0
            clip: true
            visible: deviceType === "wifi" && root.isSecured && !root.isConnected && !root.isKnown

            Rectangle {
                id: drawerBox
                anchors.top: parent.top
                anchors.topMargin: Globals.geometry.padding.medium
                anchors.left: parent.left
                anchors.right: parent.right
                color: Globals.colors.background
                border.width: 1
                border.color: Globals.alpha(Globals.colors.border, 0.5)
                radius: Globals.geometry.innerRadius.medium
                implicitHeight: innerLayout.implicitHeight + (Globals.geometry.spacing.large * 2)

                RowLayout {
                    id: innerLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Globals.geometry.spacing.large
                    spacing: Globals.geometry.spacing.medium

                    // Password Input
                    BaseInput {
                        id: passwordInput
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        placeholderText: "Network password..."
                        echoMode: TextInput.Password
                        onAccepted: {
                            if (text.length > 0) {
                                root.connectClicked(text);
                                text = "";
                                root.expanded = false;
                            }
                        }
                    }
                }
            }

            Behavior on Layout.preferredHeight { BaseAnimation { duration: 200 } }
        }
    }
}
