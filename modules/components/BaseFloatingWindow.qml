import QtQuick
import Quickshell
import qs

FloatingWindow {
    id: root

    property Component body: null
    property alias color: bg.color
    property real radius: Theme.geometry.radius
    property int layoutMargin: Theme.geometry.spacing.large

    visible: false
    implicitWidth: 800
    implicitHeight: 600
    color: Theme.colors.background // Solid background, compositor handles rounding
    
    // Background surface (Square for the root window)
    BaseBackground {
        id: bg
        anchors.fill: parent
        radius: 0 // Compositor handles outer corners
        color: Theme.colors.background
        opacity: 0
    }

    property bool wasEverVisible: false
    onVisibleChanged: if (visible) wasEverVisible = true

    Loader {
        id: contentLoader
        active: root.wasEverVisible
        anchors.fill: parent
        sourceComponent: root.body
        opacity: 0
        
        onLoaded: {
            if (item) {
                // Manually ensure it fills the loader if anchors are ignored
                item.width = contentLoader.width;
                item.height = contentLoader.height;
            }
        }
    }

    // Basic animations for entry
    NumberAnimation {
        target: bg
        property: "opacity"
        from: 0
        to: root.visible ? 1.0 : 0
        duration: Theme.animations.normal
        running: root.visible
    }

    NumberAnimation {
        target: contentLoader
        property: "opacity"
        from: 0
        to: 1
        duration: Theme.animations.normal
        running: root.visible
    }


    // Escape to close
    Item {
        focus: true
        Keys.onEscapePressed: root.visible = false
    }
}
