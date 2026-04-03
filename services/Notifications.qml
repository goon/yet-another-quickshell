import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs

pragma Singleton

Item {
    id: root

    // The core notification server provided by Quickshell
    property NotificationServer server: NotificationServer {}
    
    // History model
    property alias notificationHistory: historyModel
    readonly property alias unreadCount: historyModel.count

    ListModel {
        id: historyModel
    }

    // Signal for the UI (Overlay) to listen to
    signal notificationReceived(var notification)

    Connections {
        target: server
        
        function onNotification(notification) {
            notification.tracked = true;
            
            // Add to history (at the top)
            historyModel.insert(0, {
                "modelData": notification,
                "receivedAt": new Date()
            });

            // Handle dismissal/closing
            notification.onClosed.connect(() => {
                for (var i = 0; i < historyModel.count; i++) {
                    if (historyModel.get(i).modelData === notification) {
                        historyModel.remove(i);
                        break;
                    }
                }
            });

            // Sound logic
            if (Preferences.notificationMode === 0) {
                if (Config.notificationSoundEnabled) {
                    ProcessService.runDetached([
                        "pw-play", 
                        "--volume", (Config.notificationSoundVolume / 100.0).toString(), 
                        Config.notificationSoundPath
                    ]);
                }
                
                // Emit signal for Toasts
                root.notificationReceived(notification);
            }
        }
    }
    
    function clearAll() {
        for (let i = historyModel.count - 1; i >= 0; i--) {
            let notif = historyModel.get(i).modelData;
            if (notif) notif.dismiss();
        }
    }
}
