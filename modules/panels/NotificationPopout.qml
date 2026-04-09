import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs

BasePopoutWindow {
    id: root

    property var notificationManager: null
    property var expandedStates: ({
    })
    property var groupedModel: []

    fixedWidth: 550
    panelNamespace: "quickshell:notification-popout"

    body: ScrollView {
        id: mainScroll

        implicitWidth: 400
        implicitHeight: Math.min(800, mainContent.implicitHeight)
        contentWidth: availableWidth
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            id: mainContent

            property var notificationManager: root.notificationManager
            property int notifCount: notificationManager ? notificationManager.notificationHistory.count : 0

            onNotificationManagerChanged: updateGroupedModel()

            function updateGroupedModel() {
                if (!notificationManager) {
                    root.groupedModel = [];
                    return ;
                }
                const history = notificationManager.notificationHistory;
                const groups = {
                };
                const result = [];
                for (let i = 0; i < history.count; i++) {
                    const item = history.get(i);
                    const appName = item.modelData.appName || "Unknown";
                    if (!groups[appName]) {
                        groups[appName] = {
                            "appName": appName,
                            "notifications": [],
                            "latest": item.receivedAt
                        };
                        result.push(groups[appName]);
                    }
                    groups[appName].notifications.push(item);
                }
                root.groupedModel = result;
            }

            width: parent.width
            spacing: Theme.geometry.spacing.large
            Component.onCompleted: updateGroupedModel()

            Connections {
                function onCountChanged() {
                    mainContent.updateGroupedModel();
                }

                target: mainContent.notificationManager ? mainContent.notificationManager.notificationHistory : null
            }

            BaseBlock {
                Layout.fillWidth: true
                backgroundColor: Theme.alpha(Theme.colors.surface, Theme.blur.surfaceOpacity)
                spacing: Theme.geometry.spacing.large
                paddingVertical: Theme.geometry.spacing.large

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    // Left balancing item (matches width of buttons on the right)
                    Item {
                        Layout.preferredWidth: headerButtons.implicitWidth
                        Layout.fillHeight: true
                    }

                    // Styled Label
                    BaseText {
                        Layout.fillWidth: true
                        text: "NOTIFICATIONS (" + mainContent.notifCount + ")"
                        color: Theme.colors.muted
                        pixelSize: Theme.typography.size.base
                        weight: Theme.typography.weights.bold
                        horizontalAlignment: Text.AlignHCenter
                        font.letterSpacing: 2
                    }

                    // Header Actions
                    RowLayout {
                        id: headerButtons
                        spacing: Theme.geometry.spacing.small

                        BaseButton {
                            icon: Preferences.notificationMode === 1 ? "notifications_off" : "notifications"
                            iconColor: (Preferences.notificationMode === 1 && !containsMouse) ? Theme.colors.error : (containsMouse ? Theme.colors.primary : Theme.colors.text)
                            size: Theme.dimensions.iconMedium
                            hoverColor: Theme.alpha(Theme.colors.error, 0.1)
                            onClicked: Preferences.notificationMode = (Preferences.notificationMode + 1) % 2
                        }

                        BaseButton {
                            icon: "clear_all"
                            size: Theme.dimensions.iconMedium
                            hoverColor: Theme.alpha(Theme.colors.error, 0.1)
                            onClicked: {
                                if (mainContent.notificationManager) {
                                    const model = mainContent.notificationManager.notificationHistory;
                                    for (let i = model.count - 1; i >= 0; i--) {
                                        let notif = model.get(i).modelData;
                                        if (notif)
                                            notif.dismiss();
                                    }
                                }
                            }
                            enabled: mainContent.notificationManager && mainContent.notificationManager.notificationHistory.count > 0
                            opacity: enabled ? 1 : 0.3
                        }
                    }
                }

                // Notifications List
                ListView {
                    id: list

                    Layout.fillWidth: true
                    implicitHeight: contentHeight
                    model: root.groupedModel
                    spacing: Theme.geometry.spacing.medium
                    interactive: false

                    delegate: Column {
                        id: groupDelegate

                        property var groupData: modelData
                        property bool isStack: groupData.notifications.length > 1
                        property bool expanded: root.expandedStates[groupData.appName] === true

                        width: ListView.view.width
                        spacing: Theme.geometry.spacing.small // Tighter gap within a group stack

                        // Stack/Header
                        Item {
                            width: parent.width
                            height: headerCard.implicitHeight + (isStack && !expanded ? 8 : 0)

                            Behavior on height { BaseAnimation { speed: "fast" } }

                            // Stack Background (Shadow/Cards behind) - Single Layer
                            Rectangle {
                                visible: opacity > 0
                                opacity: isStack && !expanded ? 1 : 0
                                width: parent.width - 24
                                height: headerCard.implicitHeight
                                anchors.horizontalCenter: parent.horizontalCenter
                                z: -1
                                y: 8
                                color: Theme.alpha(Theme.colors.base, Theme.blur.surfaceOpacity)
                                radius: Theme.geometry.radius
                                border.color: Theme.alpha(Theme.colors.base, Theme.blur.surfaceOpacity)
                                border.width: 1

                                Behavior on opacity { BaseAnimation { speed: "fast" } }
                            }

                            NotificationCard {
                                id: headerCard
                                
                                width: parent.width
                                z: 1
                                notification: groupData.notifications[0].modelData
                                time: groupData.notifications[0].receivedAt
                                borderEnabled: false
                                padding: 0
                                showCloseButton: true
                                progress: 0
                                backgroundColor: Theme.alpha(Theme.colors.background, Theme.blur.surfaceOpacity)
                                onClicked: {
                                    if (!isStack) return;
                                    var states = root.expandedStates;
                                    states[groupData.appName] = !groupDelegate.expanded;
                                    root.expandedStates = Object.assign({}, states);
                                }
                                onCloseClicked: {
                                    const notifs = groupData.notifications;
                                    if (!expanded && isStack) {
                                        for (let i = notifs.length - 1; i >= 0; i--) {
                                            if (notifs[i].modelData)
                                                notifs[i].modelData.dismiss();
                                        }
                                    } else {
                                        if (notifs[0].modelData)
                                            notifs[0].modelData.dismiss();
                                    }
                                }
                            }
                        }

                        // Expanded Notifications
                        Column {
                            width: parent.width
                            visible: height > 0
                            clip: true
                            spacing: Theme.geometry.spacing.small
                            opacity: expanded ? 1 : 0
                            height: expanded ? implicitHeight : 0

                            Behavior on height { BaseAnimation { speed: "normal" } }
                            Behavior on opacity { BaseAnimation { speed: "normal" } }

                            Repeater {
                                model: isStack ? groupData.notifications.slice(1) : 0

                                delegate: NotificationCard {
                                    width: parent.width
                                    notification: modelData.modelData
                                    time: modelData.receivedAt
                                    borderEnabled: false
                                    padding: 0
                                    showCloseButton: true
                                    backgroundColor: Theme.alpha(Theme.colors.base, Theme.blur.surfaceOpacity)
                                    onCloseClicked: {
                                        if (modelData.modelData)
                                            modelData.modelData.dismiss();
                                    }
                                }
                            }

                            Item {
                                width: parent.width
                                height: 4
                            }
                        }
                    }
                }
            }

        }

    }

}
