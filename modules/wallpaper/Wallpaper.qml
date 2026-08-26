import QtQuick
import QtQuick.Effects
import qs.services
import qs

FocusScope {
    id: root

    property string panelState: "Closed"

    implicitWidth: 900
    implicitHeight: 165

    property Item initialFocusItem: carousel

    readonly property bool hasWallpapers: carousel.model && carousel.model.length > 0

    onPanelStateChanged: {
        if (panelState === "Opening") {
            Wallpaper.ensureScanned();
            carousel.focusFirst();
        }
    }

    Component.onCompleted: {
        Wallpaper.ensureScanned();
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: mask
            anchors.fill: parent
            radius: Globals.geometry.radius
            visible: false
            layer.enabled: true
            color: Globals.colors.text
        }

        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: mask
            }

            WallpaperCarousel {
                id: carousel
                anchors.fill: parent

                onCloseRequested: IslandService.closeAll()
            }
        }
    }
}
