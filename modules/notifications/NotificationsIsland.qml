import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs

BaseContainer {
    id: root

    property string panelState: "Closed"
    implicitWidth: 460

    property var notificationManager: Notifications
    property int notifCount: notificationManager ? notificationManager.notificationHistory.count : 0

    spacing: Globals.geometry.spacing.large

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.notifCount > 0

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Globals.geometry.spacing.large
            spacing: Globals.geometry.spacing.small

            BaseHeader {
                text: "NOTIFICATIONS (" + root.notifCount + ")"
            }

            Item { Layout.fillWidth: true }

            BaseButton {
                icon: "clear_all"
                hoverColor: "transparent"
                onClicked: {
                    if (root.notificationManager) {
                        const model = root.notificationManager.notificationHistory;
                        for (let i = model.count - 1; i >= 0; i--) {
                            let notif = model.get(i).modelData;
                            if (notif)
                                notif.dismiss();
                        }
                    }
                }
                enabled: root.notificationManager && root.notificationManager.notificationHistory.count > 0
                opacity: enabled ? 1 : 0.3
            }
        }

        BaseSeparator {
            Layout.fillWidth: true
        }
    }

    ListView {
        id: list

        Layout.fillWidth: true
        implicitHeight: contentHeight
        model: root.notificationManager ? root.notificationManager.notificationHistory : null
        spacing: Globals.geometry.spacing.large
        interactive: false
        visible: root.notifCount > 0

        delegate: Column {
            width: ListView.view.width
            spacing: Globals.geometry.spacing.large

            NotificationCard {
                width: parent.width
                notification: modelData
                time: receivedAt
                showCloseButton: false
                onRightClicked: {
                    if (modelData)
                        modelData.dismiss();
                }
            }

            BaseSeparator {
                width: parent.width
                visible: index < list.count - 1
            }
        }
    }

    // ── EMPTY STATE PLACEHOLDERS ─────────────────────────────────────
    Item {
        id: emptyPlaceholder
        Layout.fillWidth: true
        Layout.preferredHeight: root.notifCount === 0 ? 250 : 0
        visible: root.notifCount === 0
        opacity: visible ? 1 : 0
        Behavior on opacity { BaseAnimation { } }
        Behavior on height { BaseAnimation { } }
        clip: true

        // ── STYLE 0: BOUNCING "DVD LOGO" BELL ────────────────────────────
        Item {
            anchors.fill: parent
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: -8 // Tight vertical spacing for editorial look
                
                BaseText {
                    text: "you're"
                    muted: true
                    pixelSize: Globals.typography.size.large
                    font.italic: true
                    Layout.alignment: Qt.AlignLeft
                    Layout.leftMargin: 8
                }
                
                Item {
                    width: 320
                    height: 64
                    Layout.alignment: Qt.AlignHCenter
                    
                    BaseText {
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "ALL CAUGHT"
                        opacity: 0.4
                        pixelSize: 48
                        weight: Globals.typography.weights.bold
                        font.letterSpacing: -1
                    }
                    
                    BaseText {
                        id: pulseText
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "ALL CAUGHT"
                        color: Globals.colors.primary
                        opacity: 0.0
                        pixelSize: 48
                        weight: Globals.typography.weights.bold
                        font.letterSpacing: -1
                        
                        SequentialAnimation {
                            loops: Animation.Infinite
                            running: emptyPlaceholder.visible
                            
                            NumberAnimation { target: pulseText; property: "opacity"; to: 1.0; duration: 2000; easing.type: Easing.InOutQuad }
                            ColorAnimation { target: pulseText; property: "color"; to: Globals.colors.secondary; duration: 2000; easing.type: Easing.InOutQuad }
                            ColorAnimation { target: pulseText; property: "color"; to: Globals.colors.primary; duration: 2000; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: pulseText; property: "opacity"; to: 0.0; duration: 2000; easing.type: Easing.InOutQuad }
                            PauseAnimation { duration: 1000 }
                        }
                    }
                }
                
                BaseText {
                    text: "up."
                    color: Globals.colors.primary
                    pixelSize: Globals.typography.size.large
                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: 8
                }
            }

            Canvas {
                id: bounceContainer
                z: -1 // CRITICAL: Explicitly layer the bell behind the text ColumnLayout
                width: Globals.dimensions.iconExtraLarge
                height: Globals.dimensions.iconExtraLarge
                
                property real vx: 1.5
                property real vy: 1.2
                
                x: parent.width / 2
                y: parent.height / 2
                
                property real offset: 0
                
                NumberAnimation on offset {
                    loops: Animation.Infinite
                    from: 0
                    to: 1
                    duration: 2000
                    running: emptyPlaceholder.visible
                }
                
                onOffsetChanged: requestPaint()
                
                RotationAnimation on rotation {
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 4000
                    running: emptyPlaceholder.visible
                }
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    
                    // Oscillating gradient vector to create a smooth, continuous flow
                    var gradOffset = Math.sin(offset * Math.PI * 2);
                    var gradX1 = (width / 2) + (width / 2) * gradOffset;
                    var gradX2 = (width / 2) - (width / 2) * gradOffset;
                    
                    var grad = ctx.createLinearGradient(gradX1, 0, gradX2, height);
                    grad.addColorStop(0.0, Globals.colors.primary);
                    grad.addColorStop(1.0, Globals.colors.secondary);
                    
                    ctx.fillStyle = grad;
                    // Note: Globals.typography.iconFamily provides the Material font
                    ctx.font = Globals.dimensions.iconExtraLarge + "px \"" + Globals.typography.iconFamily + "\"";
                    ctx.textAlign = "center";
                    ctx.textBaseline = "middle";
                    ctx.globalAlpha = 0.7; // Dim slightly per request
                    ctx.fillText("notifications", width/2, height/2);
                }
                
                Timer {
                    interval: 16
                    running: emptyPlaceholder.visible
                    repeat: true
                    onTriggered: {
                        var nx = bounceContainer.x + bounceContainer.vx;
                        var ny = bounceContainer.y + bounceContainer.vy;
                        
                        if (nx <= 0 || nx + bounceContainer.width >= bounceContainer.parent.width) {
                            bounceContainer.vx *= -1;
                            nx = Math.max(0, Math.min(nx, bounceContainer.parent.width - bounceContainer.width));
                        }
                        if (ny <= 0 || ny + bounceContainer.height >= bounceContainer.parent.height) {
                            bounceContainer.vy *= -1;
                            ny = Math.max(0, Math.min(ny, bounceContainer.parent.height - bounceContainer.height));
                        }
                        
                        bounceContainer.x = nx;
                        bounceContainer.y = ny;
                    }
                }
            }
        }

    }
}
