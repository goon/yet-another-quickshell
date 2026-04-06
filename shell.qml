import QtQuick
//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs
import qs.services

ShellRoot {
    // Instantiate Stats service for background tracking
    property var _stats: Stats
    property var _gowall: Gowall

    objectName: "shellRoot"
    Component.onCompleted: {
        PopoutService.launcherLoader = launcherLoader;
        PopoutService.settingsLoader = settingsLoader;
        PopoutService.mediaPopoutLoader = mediaPopoutLoader;
        PopoutService.notificationPopoutLoader = notificationPopoutLoader;
        PopoutService.notificationManager = Notifications;
        PopoutService.systemPopoutLoader = systemPopoutLoader;
        PopoutService.audioPopoutLoader = audioPopoutLoader;
        PopoutService.calendarPopoutLoader = calendarPopoutLoader;
        PopoutService.systemControlPopoutLoader = systemControlPopoutLoader;
        PopoutService.fileDialogLoader = fileDialogLoader;
    }

    Commander {
        id: commander
    }

    NotificationOverlay {
        id: notificationOverlay
    }

    // Windows / Overlays
    BaseLazyLoader {
        id: launcherLoader
        source: Qt.resolvedUrl("modules/panels/launcher/Launcher.qml")
    }

    BaseLazyLoader {
        id: settingsLoader
        source: Qt.resolvedUrl("modules/panels/settings/Settings.qml")
    }

    BaseLazyLoader {
        id: mediaPopoutLoader
        source: Qt.resolvedUrl("modules/panels/MediaPopout.qml")
    }

    BaseLazyLoader {
        id: systemControlPopoutLoader
        source: Qt.resolvedUrl("modules/panels/system/SystemControlPopout.qml")
    }

    BaseLazyLoader {
        id: notificationPopoutLoader
        source: Qt.resolvedUrl("modules/panels/NotificationPopout.qml")
        onLoaded: {
            if (item) item.notificationManager = Notifications;
        }
    }

    BaseLazyLoader {
        id: systemPopoutLoader
        source: Qt.resolvedUrl("modules/panels/SystemPopout.qml")
    }

    BaseLazyLoader {
        id: audioPopoutLoader
        source: Qt.resolvedUrl("modules/panels/AudioPopout.qml")
    }

    BaseLazyLoader {
        id: calendarPopoutLoader
        source: Qt.resolvedUrl("modules/panels/CalendarPopout.qml")
    }

    BaseLazyLoader {
        id: fileDialogLoader
        source: Qt.resolvedUrl("modules/filedialog/FileDialogWindow.qml")
    }


    Instantiator {
        model: Quickshell.screens

        WallpaperBackground {
            screen: modelData
        }

    }

    Instantiator {
        model: Quickshell.screens

        Bar {
            screen: modelData
        }
    }

}
