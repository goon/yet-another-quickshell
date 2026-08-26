import QtQuick
//@ pragma UseQApplication
import Quickshell
import qs
import qs.services

ShellRoot {
    // Instantiate background services for tracking
    property var _stats: Stats
    property var _gowall: Gowall
    property var _display: Display
    property var _cava: Cava

    objectName: "shellRoot"

    Commander {
        id: commander
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
