import QtQuick
import Quickshell
import qs

Item {
    id: root

    property var activePopups: []
    property var trackedNotifications: ({})
    property var popupHandlers: ({})
    property Component toastComponent: Qt.createComponent("NotificationToast.qml")

    function createPopup(notification) {
        if (toastComponent.status === Component.Ready) {
            var popup = toastComponent.createObject(root, {
                "notification": notification,
                "stackIndex": activePopups.length
            });
            if (popup) {
                activePopups.push(popup);
                root.trackedNotifications[notification.trackingId] = true;
                updateStackIndices();
                
                var handlerId = notification.trackingId;
                popupHandlers[handlerId] = {
                    "popup": popup,
                    "heightChanged": () => { return updateStackIndices(); },
                    "notificationChanged": () => {
                        if (popup.notification === null)
                            removePopup(popup);
                    }
                };
                
                popup.implicitHeightChanged.connect(popupHandlers[handlerId].heightChanged);
                popup.notificationChanged.connect(popupHandlers[handlerId].notificationChanged);
            }
        }
    }

    function removePopup(popup) {
        var index = activePopups.indexOf(popup);
        if (index > -1) {
            if (popup.notification) {
                var handlerId = popup.notification.trackingId;
                delete root.trackedNotifications[handlerId];
                if (popupHandlers[handlerId]) {
                    popup.implicitHeightChanged.disconnect(popupHandlers[handlerId].heightChanged);
                    popup.notificationChanged.disconnect(popupHandlers[handlerId].notificationChanged);
                    delete popupHandlers[handlerId];
                }
            }
            activePopups.splice(index, 1);
            updateStackIndices();
            popup.destroy(Theme.animations.fast);
        }
    }

    function updateStackIndices() {
        var currentOffset = 0;
        for (var i = 0; i < activePopups.length; i++) {
            var popup = activePopups[i];
            popup.stackIndex = i;
            popup.offset = currentOffset;
            currentOffset += popup.implicitHeight + Theme.geometry.barPanelGap;
        }
    }

    // Listen to the singleton service
    Connections {
        target: Notifications
        function onNotificationReceived(notification) {
            createPopup(notification);
        }
    }
}
