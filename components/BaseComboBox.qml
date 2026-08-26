import qs
import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ComboBox {
    id: root

    // Colors can be overridden
    property color textColor: Globals.colors.text
    property color backgroundColor: Globals.alpha(Globals.colors.surface, Globals.opacity.background)
    property color borderColor: Globals.colors.border
    property color borderActiveColor: Globals.colors.primary
    // List limiting
    property int maxVisibleItems: 10

    // Search and Preview
    property bool searchable: false
    property bool filterLocally: true
    property bool previewFonts: false
    property string searchText: ""

    Layout.fillWidth: true
    implicitHeight: 36
    implicitWidth: 200

    font.family: Globals.typography.family
    font.pixelSize: Globals.typography.size.base
    font.weight: Globals.typography.weights.normal
    
    enabled: count > 0 || searchable
    opacity: enabled ? 1.0 : 0.5

    // Delegate (Dropdown items)
    delegate: ItemDelegate {
        id: delegateRoot
        width: ListView.view ? ListView.view.width : root.width
        height: isItemVisible ? 36 : 0

        property bool isItemVisible: {
            // FIX: Removed the index === root.currentIndex check which was hiding the active item!
            if (!root.searchable || !root.filterLocally || root.searchText === "") return true;
            let t = (root.textRole && typeof modelData === "object") ? modelData[root.textRole] : modelData;
            return (t || "").toLowerCase().includes(root.searchText.toLowerCase());
        }

        visible: isItemVisible

        contentItem: BaseText {
            id: delegateText
            text: (root.textRole && typeof modelData === "object") ? modelData[root.textRole] : modelData
            color: delegateRoot.highlighted || delegateRoot.hovered ? Globals.colors.text : root.textColor
            weight: delegateRoot.highlighted || delegateRoot.hovered ? Globals.typography.weights.bold : Globals.typography.weights.normal
            
            // Lazy Font Loading
            property bool loadFont: !root.previewFonts
            
            Timer {
                id: lazyLoadTimer
                interval: 80
                running: root.previewFonts && delegateRoot.visible && !delegateText.loadFont && !listView.moving
                onTriggered: delegateText.loadFont = true
            }

            // Only preview if not moving to save CPU during scroll
            font.family: loadFont && root.previewFonts ? ((root.textRole && typeof modelData === "object") ? modelData[root.textRole] : modelData) : Globals.typography.family
            font.pixelSize: Globals.typography.size.base
            font.weight: Globals.typography.weights.normal
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            leftPadding: Globals.geometry.padding.small
            rightPadding: Globals.geometry.padding.small
        }

        background: Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: Globals.geometry.innerRadius.medium
            
            visible: parent.highlighted || parent.hovered
            
            color: Globals.alpha(Globals.colors.surface, 0.5)

            // Hover Notch
            Rectangle {
                width: 3
                height: 20
                radius: 1.5
                anchors.left: parent.left
                anchors.leftMargin: Globals.geometry.spacing.small
                anchors.verticalCenter: parent.verticalCenter
                
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Globals.colors.primary }
                    GradientStop { position: 1.0; color: Globals.colors.secondary }
                }
            }
        }

        // Unified staggered opacity-only reveal
        opacity: comboPopup.opened ? 1.0 : 0.0
        Behavior on opacity {
            enabled: !listView.moving
            SequentialAnimation {
                PauseAnimation { duration: Math.min(delegateRoot.index * 12, 100) }
                BaseAnimation { duration: Globals.animations.fast }
            }
        }
    }

    // Main Content Item (Selected text)
    contentItem: BaseText {
        text: root.displayText
        color: root.textColor
        font.family: Globals.typography.family
        font.pixelSize: Globals.typography.size.base
        font.weight: Globals.typography.weights.normal
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        leftPadding: Globals.geometry.padding.small
        rightPadding: root.indicator.width + Globals.geometry.spacing.small
        visible: !comboPopup.visible
        opacity: visible ? 1.0 : 0.0
    }

    // Custom Chevron Indicator
    indicator: BaseIcon {
        x: root.width - width - Globals.geometry.spacing.medium
        y: (root.availableHeight - height) / 2
        icon: "expand_more"
        color: root.textColor
        visible: (root.count > 0 || root.searchable) && !comboPopup.visible
        opacity: visible ? 1.0 : 0.0
    }

    // Background (Closed state - floating)
    background: Rectangle {
        color: root.backgroundColor
        radius: Globals.geometry.innerRadius.medium
        border.color: root.activeFocus ? root.borderActiveColor : root.borderColor
        border.width: 1
        antialiasing: true
    }

    popup: Popup {
        id: comboPopup
        y: 0
        width: root.width
        implicitHeight: contentLayout.implicitHeight + padding * 2
        padding: Globals.geometry.spacing.medium

        // Seamless on-site transitions
        enter: Transition {
            ParallelAnimation {
                BaseAnimation { property: "scale"; from: 0.95; to: 1.0; duration: Globals.animations.fast }
                BaseAnimation { property: "opacity"; from: 0; to: 1; duration: Globals.animations.fast }
            }
        }

        exit: Transition {
            ParallelAnimation {
                BaseAnimation { property: "scale"; to: 0.95; duration: Globals.animations.fast; easing.type: Easing.InQuint }
                BaseAnimation { property: "opacity"; to: 0; duration: Globals.animations.fast }
            }
        }

        onOpened: {
            if (root.searchable) {
                searchInput.forceActiveFocus();
            }
        }

        onClosed: {
            root.searchText = "";
        }

        contentItem: ColumnLayout {
            id: contentLayout

            BaseInput {
                id: searchInput
                Layout.fillWidth: true
                Layout.margins: Globals.geometry.spacing.small
                Layout.preferredHeight: 36
                placeholderText: "Search..."
                visible: root.searchable
                onTextChanged: root.searchText = text
                
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        comboPopup.close();
                    } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        // Select highlighted item
                        if (listView.count > 0) {
                            root.currentIndex = listView.currentIndex;
                            comboPopup.close();
                        }
                    }
                }
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 36 * root.maxVisibleItems)
                clip: true
                model: root.delegateModel
                currentIndex: root.highlightedIndex
                
                // Optimization for large font lists
                cacheBuffer: 100
                reuseItems: true

            }
        }

        background: Rectangle {
            color: root.backgroundColor
            border.color: root.activeFocus ? root.borderActiveColor : root.borderColor
            border.width: 1
            antialiasing: true
            radius: Globals.geometry.innerRadius.medium
        }
    }
}
