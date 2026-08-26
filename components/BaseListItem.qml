import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root

    implicitHeight: Math.max(Globals.dimensions.listItemHeight, layout.implicitHeight)
    implicitWidth: layout.implicitWidth

    property string title: ""
    property int titleSize: Globals.typography.size.medium
    property string titleFamily: Globals.typography.family
    property string subtitle: ""
    property int subtitleSize: Globals.typography.size.base
    property bool showSubtitleOnHover: false
    
    property string leftIcon: ""
    property bool leftIconInteractive: true
    property bool leftIconActive: false
    property real leftIconScale: 1.0
    
    // Separator
    property bool showVerticalSeparator: false
    
    // Right Icon Properties
    property string rightIcon: "chevron_right"
    property bool rightIconVisible: true
    
    // Selection state
    property bool selected: false

    // Internal indicator (the gradient bar on the left edge).
    // Set to false when an external BaseIndicator is used instead (e.g. for hover-driven indicators).
    property bool showInternalIndicator: true

    // State
    readonly property bool containsMouse: mainMouseArea.containsMouse
    readonly property bool hovered: containsMouse

    // Signals
    signal clicked()
    signal leftIconClicked()

    // Main row hover/click area
    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: Globals.geometry.spacing.medium

        // Active / Hover Notch
        Rectangle {
            visible: root.showInternalIndicator && root.selected
            Layout.preferredWidth: 3
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
            radius: 1.5
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Globals.colors.primary }
                GradientStop { position: 1.0; color: Globals.colors.secondary }
            }
        }

        // Left Icon Slot
        Item {
            visible: root.leftIcon !== ""
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignVCenter
            scale: root.leftIconScale

            // Left Icon (Interactive Toggle)
            BaseButton {
                visible: root.leftIconInteractive
                anchors.centerIn: parent
                icon: root.leftIcon
                size: Globals.dimensions.iconMedium
                iconColor: root.leftIconActive ? Globals.colors.primary : Globals.colors.text
                onClicked: root.leftIconClicked()
                z: 2 // Sit above the main MouseArea
            }
            
            BaseIcon {
                visible: !root.leftIconInteractive
                anchors.centerIn: parent
                icon: root.leftIcon
                size: Globals.dimensions.iconMedium
                color: root.selected ? Globals.colors.primary : (root.containsMouse ? Globals.colors.primary : Globals.colors.text)
                Behavior on color { BaseAnimation { } }
            }
        }

        BaseSeparator {
            visible: root.showVerticalSeparator
            orientation: BaseSeparator.Vertical
            Layout.fillHeight: true
            Layout.topMargin: Globals.geometry.spacing.medium
            Layout.bottomMargin: Globals.geometry.spacing.medium
            opacity: 0.3
        }

        // Text Labels
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: root.showVerticalSeparator ? 8 : 0

            BaseText {
                visible: root.title !== ""
                text: root.title
                pixelSize: root.titleSize
                family: root.titleFamily
                weight: root.selected ? Globals.typography.weights.bold : Globals.typography.weights.medium
                color: root.selected ? Globals.colors.primary : (root.containsMouse ? Globals.colors.primary : Globals.colors.text)
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                maximumLineCount: 1
                Behavior on color { BaseAnimation { } }
            }

            Item {
                Layout.fillWidth: true
                visible: root.subtitle !== ""
                Layout.preferredHeight: (root.showSubtitleOnHover && !root.hovered) ? 0 : subtitleText.implicitHeight
                Behavior on Layout.preferredHeight { BaseAnimation { easing.type: Easing.OutQuart } }
                clip: true
                opacity: (root.showSubtitleOnHover && !root.hovered) ? 0.0 : 1.0
                Behavior on opacity { BaseAnimation { } }

                BaseText {
                    id: subtitleText
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: root.subtitle
                    pixelSize: root.subtitleSize
                    muted: true
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        BaseIcon {
            visible: root.rightIconVisible && root.rightIcon !== ""
            icon: root.rightIcon
            color: root.selected ? Globals.colors.primary : (root.containsMouse ? Globals.colors.text : Globals.colors.muted)
            Behavior on color { BaseAnimation { } }
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
