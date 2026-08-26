import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs

BaseContainer {
    id: root

    readonly property real _spacing: Globals.geometry.spacing.small
    readonly property real _itemSize: Globals.dimensions.barItemHeight

    visible: Compositor.hasDockWindows
    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false
    paddingHorizontal: 0
    implicitHeight: _itemSize
    ListView {
        id: listView

        Layout.alignment: Qt.AlignCenter
        orientation: ListView.Horizontal
        interactive: false
        model: Hyprland.toplevels
        implicitWidth: contentWidth
        implicitHeight: _itemSize

        delegate: Item {
            id: windowItem

            required property HyprlandToplevel modelData

            readonly property bool isValid: {
                if (!modelData) return false;
                var addr = modelData.address;
                if (!addr) return false;
                if (!addr.startsWith("0x")) addr = "0x" + addr;
                return !!Compositor.windowByAddress[addr];
            }
            readonly property string windowAppId: !modelData ? "" : (modelData.wayland?.appId ?? modelData.lastIpcObject?.class ?? "")
            readonly property bool isHovered: mouseArea.containsMouse
            readonly property bool isFocused: modelData ? modelData.activated : false

            implicitHeight: _itemSize
            implicitWidth: isValid ? _itemSize : 0

            Behavior on implicitWidth {
                NumberAnimation { duration: Globals.animations.fast; easing.type: Easing.OutQuad }
            }

            Image {
                id: icon

                visible: isValid
                anchors.centerIn: parent
                source: LauncherService.resolveIcon(windowItem.windowAppId) || "image://icon/application-x-executable"
                sourceSize: Qt.size(64, 64)
                width: Globals.dimensions.iconBase
                height: Globals.dimensions.iconBase
                fillMode: Image.PreserveAspectFit
                mipmap: true
                scale: (isFocused || isHovered) ? 1.2 : 1
                opacity: (isFocused || isHovered) ? 1 : 0.6

                Behavior on scale {
                    BaseAnimation {
                    }

                }

                Behavior on opacity {
                    BaseAnimation {
                    }

                }

            }

            MouseArea {
                id: mouseArea

                visible: isValid
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (modelData && modelData.address) Compositor.focusWindow(modelData.address); }
            }

        }

        move: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: Globals.animations.normal
                easing.type: Easing.OutQuad
            }

        }

        add: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Globals.animations.fast
            }

            NumberAnimation {
                property: "scale"
                from: 0
                to: 1
                duration: Globals.animations.fast
                easing.type: Easing.OutBack
            }

        }

        remove: Transition {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: Globals.animations.fast
            }

            NumberAnimation {
                property: "scale"
                to: 0
                duration: Globals.animations.fast
            }

        }

        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: Globals.animations.normal
                easing.type: Easing.OutQuad
            }

        }

    }

}
