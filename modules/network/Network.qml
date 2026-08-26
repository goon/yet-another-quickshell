import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs
import ".."

BaseContainer {
    id: root
    implicitWidth: 400

    property string panelState: "Closed"
    property alias pageStack: stackView

    function pushPage(pageName) {
        var file = "";
        if (pageName === "wifi" || pageName === "network") file = "NetworkWifi.qml";
        if (pageName === "bluetooth") file = "NetworkBluetooth.qml";
        
        if (file !== "") {
            if (stackView.currentItem && stackView.currentItem.objectName === file) return;
            stackView.push(file, { objectName: file });
        }
    }

    // Reset stackview when closed
    onPanelStateChanged: {
        if (panelState === "Closed") {
            stackView.pop(null); // pop to root
        }
    }

    BaseStackView {
        id: stackView
        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitHeight: currentItem ? currentItem.implicitHeight : 0
        initialItem: mainPage
    }

        Component {
        id: mainPage
        Item {
            implicitHeight: mainCol.implicitHeight
            implicitWidth: parent.width

            ColumnLayout {
                id: mainCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                BaseHeader {
                    text: "NETWORKING"
                    isActive: wifiItem.hovered || btItem.hovered
                    Layout.bottomMargin: Globals.geometry.spacing.small
                }


                // ── WI-FI ──────────────────────────────────────────────
                BaseListItem {
                    id: wifiItem
                    Layout.fillWidth: true

                    title: Network.connected ? "Wi-Fi" : (Network.ethernetConnected ? "Network" : "Wi-Fi")
                    subtitle: {
                        if (Network.connected) {
                            return "Wireless · " + Network.ssid + " · " + Network.signalStrength + "%";
                        }
                        if (Network.ethernetConnected) {
                            var speed = (Network.wiredDevice && Network.wiredDevice.linkSpeed > 0) ? Network.wiredDevice.linkSpeed : 1000;
                            var speedStr = speed >= 1000 ? (speed / 1000).toFixed(1).replace(".0", "") + " Gb/s" : speed + " Mbps";
                            return "Wired · " + speedStr;
                        }
                        return "Disconnected";
                    }
                    leftIcon: Network.connected ? "wifi" : (Network.ethernetConnected ? "desktop_windows" : "wifi_off")
                    leftIconActive: Network.connected || Network.ethernetConnected
                    leftIconInteractive: !Network.ethernetConnected
                    showVerticalSeparator: true
                    onClicked: root.pushPage("wifi")
                    onLeftIconClicked: {
                        if (!Network.ethernetConnected) {
                            Network.toggleWifi();
                        }
                    }
                }

                // ── BLUETOOTH ──────────────────────────────────────────
                BaseListItem {
                    id: btItem
                    Layout.fillWidth: true

                    title: "Bluetooth"
                    subtitle: Bluetooth.powered ? (Bluetooth.connectedCount > 0 ? Bluetooth.connectedCount + " devices" : "On") : "Off"
                    leftIcon: Bluetooth.powered ? "bluetooth" : "bluetooth_disabled"
                    leftIconActive: Bluetooth.powered
                    leftIconScale: 1.25
                    leftIconInteractive: false
                    showVerticalSeparator: true
                    onClicked: root.pushPage("bluetooth")
                }
            }

            // Sliding Hover Indicator
            BaseIndicator {
                id: slidingPill
                targetItem: {
                    if (wifiItem.hovered) return wifiItem;
                    if (btItem.hovered) return btItem;
                    return null;
                }
            }
        }
    }
}
