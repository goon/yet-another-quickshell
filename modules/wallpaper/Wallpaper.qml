import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.services
import qs

FocusScope {
    id: root

    property string panelState: "Closed"

    implicitWidth: 1600
    implicitHeight: 600

    property Item initialFocusItem: carousel

    readonly property int gap: Globals.geometry.spacing.large
    readonly property int centerWidthFloor: 320
    readonly property int sideWidthFloor: 160
    readonly property real availableWidth: width - (3 * gap)
    readonly property int computedCenterWidth: Math.max(centerWidthFloor, Math.floor(availableWidth * 0.5))
    readonly property int computedSideWidth: Math.max(sideWidthFloor, Math.floor((availableWidth - computedCenterWidth) / 2))

    readonly property bool hasWallpapers: carousel.model && carousel.model.length > 0

    function activateCurrentItem() {
        if (carousel && carousel.model && carousel.model.length > 0 && carousel.currentIndex >= 0) {
            var path = carousel.model[carousel.currentIndex];
            if (path) {
                Wallpaper.setWallpaper(path);
                IslandService.closeAll();
            }
        }
    }

    onPanelStateChanged: {
        if (panelState === "Closed") {
            Wallpaper.ensureScanned();
            if (hasWallpapers) carousel.setRandomIndex();
        }
    }

    Component.onCompleted: {
        Wallpaper.ensureScanned();
        Wallpaper.shuffleWallpapers();
        if (hasWallpapers) carousel.setRandomIndex();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: Globals.geometry.spacing.medium

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Mask Source
            Rectangle {
                id: mask
                anchors.fill: parent
                radius: Globals.geometry.radius
                visible: false
                layer.enabled: true
                color: Globals.colors.text
            }

            // Masked Container
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

                    borderRadius: Globals.geometry.radius

                    gap: root.gap
                    centerWidth: root.computedCenterWidth
                    sideWidth: root.computedSideWidth

                    onCloseRequested: IslandService.closeAll()
                }
            }
        }
    }
}