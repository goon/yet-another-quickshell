import QtQuick.Effects
import QtQuick
import Quickshell
import qs

Text {
    id: root

    // Convenience properties for common overrides
    property alias pixelSize: root.font.pixelSize
    property alias bold: root.font.bold
    property alias italic: root.font.italic
    property alias family: root.font.family
    // Centralized defaults from Theme
    property color normalColor: Theme.colors.text
    property color hoverColor: Theme.colors.muted
    // Hover support
    property bool hoverEnabled: false
    Loader {
        id: mouseAreaLoader
        anchors.fill: parent
        active: root.hoverEnabled
        sourceComponent: Component {
            MouseArea {
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: (mouse) => root.clicked()
                onPressed: root.pressedSignal()
                onReleased: root.released()
            }
        }
    }

    readonly property bool containsMouse: mouseAreaLoader.item ? mouseAreaLoader.item.containsMouse : false
    readonly property Item mouseArea: mouseAreaLoader.item
    // Shadow support
    property bool shadow: false
    property color shadowColor: Theme.effects.shadow.color
    property int shadowRadius: Theme.effects.shadow.radius
    property int shadowSamples: Theme.effects.shadow.samples
    property int shadowOffsetX: Theme.effects.shadow.offsetX
    property int shadowOffsetY: Theme.effects.shadow.offsetY
    property int weight: Theme.typography.weights.normal

    signal clicked()
    signal pressedSignal()
    signal released()

    color: (hoverEnabled && root.containsMouse) ? hoverColor : normalColor
    family: Theme.typography.family
    pixelSize: Theme.typography.size.base
    font.weight: root.weight
    wrapMode: Text.WordWrap
    layer.enabled: shadow

    Behavior on color {
        BaseAnimation {
            duration: Theme.animations.fast
        }
    }

    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: root.shadowColor
        shadowBlur: root.shadowRadius / 20.0
        shadowHorizontalOffset: root.shadowOffsetX
        shadowVerticalOffset: root.shadowOffsetY
    }

}
