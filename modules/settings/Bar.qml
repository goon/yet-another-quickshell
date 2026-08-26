import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Bar"
    description: "Configure the position, size, and layout of the system bar."

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Globals.geometry.spacing.large

        SettingsGroup {
            Layout.fillWidth: true

            SettingsRow {
                icon: "border_top"
                label: "Position"

                BaseSegmentedControl {
                    Layout.fillWidth: true
                    model: [{ "label": "Top", "value": "top" }, { "label": "Bottom", "value": "bottom" }]
                    currentValue: Preferences.bar.position
                    onActivated: (index, value) => {
                        Preferences.bar.position = value;
                    }
                }
            }


            SettingsRow {
                icon: "space_bar"
                label: "Margin"

                BaseSpinBox {
                    from: 0
                    to: 50
                    stepSize: 1
                    value: Preferences.bar.marginTop
                    suffix: "px"
                    onValueChanged: Preferences.bar.marginTop = value
                }
            }

            SettingsRow {
                icon: "view_module"
                label: "Workspace Count"
                showSeparator: true

                BaseSpinBox {
                    from: 1
                    to: 20
                    value: Preferences.bar.workspaceCount
                    onValueChanged: Preferences.bar.workspaceCount = value
                }
            }



            SettingsRow {
                id: activeComponentsTitle
                icon: "drag_indicator"
                label: "Components"
                showSeparator: false
                Layout.fillWidth: true
            }

            BarConfiguration {
                Layout.fillWidth: true
                property var indicatorTarget: activeComponentsTitle
            }
        }
    }

    // ── BarConfiguration component ────────────────────────────────────────
    component BarConfiguration: ColumnLayout {
        id: barRoot

        readonly property var componentMetadata: ({
            "workspaces": { name: "Workspaces", icon: "view_week" },
            "clock":      { name: "Clock",      icon: "schedule"  },
            "dock":       { name: "Dock",        icon: "vertical_split" },
            "indicators": { name: "Indicators",  icon: "stacks"   },
        })


        function getList(listName) {
            if (listName === "barComponents") return Array.from(Preferences.bar.components);
            return [];
        }

        function updateList(listName, list) {
            if (listName === "barComponents") Preferences.bar.components = list;
        }

        function moveComponent(componentId, sourceSection, targetSection, targetIndex) {
            if (sourceSection !== targetSection) return;

            var targetList = getList(targetSection);
            var sourceIndex = targetList.indexOf(componentId);
            
            if (sourceIndex > -1) {
                targetList.splice(sourceIndex, 1);
                if (targetIndex === -1 || targetIndex >= targetList.length) {
                    targetList.push(componentId);
                } else {
                    targetList.splice(targetIndex, 0, componentId);
                }
                updateList(targetSection, targetList);
            }
        }

        Layout.fillWidth: true

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Globals.geometry.spacing.medium

            ComponentList {
                id: componentList
                property var indicatorTarget: activeComponentsTitle
                Layout.fillWidth: true
                Layout.margins: Globals.geometry.spacing.medium
                Layout.topMargin: Globals.geometry.spacing.large
                sectionName: "barComponents"
                components: Preferences.bar.components
            }
        }
    }

    // ── BarComponentItem ─────────────────────────────────────────────────
    component BarComponentItem: Item {
        id: itemRoot

        property string componentId
        property string sourceSection
        property string label
        property var dragData: ({ componentId: componentId, sourceSection: sourceSection })

        width:  parent ? parent.width : 200
        height: rect.height
        opacity: dragHandler.drag.active ? 0.3 : 1.0

        Rectangle {
            id: rect
            property var  dragData: itemRoot.dragData
            readonly property bool isActive: dragHandler.containsMouse || dragHandler.drag.active
            readonly property bool isEnabled: Preferences.bar.componentsEnabled[itemRoot.componentId] === true

            width:  parent.width
            height: 48

            radius: Globals.geometry.innerRadius.medium

            // Flat well-style container pills
            color:        rect.isEnabled ? Globals.alpha(Globals.colors.primary, 0.15) : Globals.alpha(Globals.colors.surface, 0.5)
            border.width: rect.isEnabled ? 1 : 0
            border.color: rect.isEnabled ? Globals.colors.primary : Globals.colors.transparent

            // Drag handler covering the entire background of the pill
            MouseArea {
                id: dragHandler
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                drag.target: rect
                drag.axis:   Drag.XAndYAxis
                cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                onReleased: { rect.Drag.drop(); rect.x = 0; rect.y = 0; }

                onClicked: (mouse) => {
                    let map = JSON.parse(JSON.stringify(Preferences.bar.componentsEnabled));
                    map[componentId] = !rect.isEnabled;
                    Preferences.bar.componentsEnabled = map;
                }
            }

            RowLayout {
                id: innerLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Globals.geometry.spacing.medium
                anchors.rightMargin: Globals.geometry.spacing.medium
                spacing: Globals.geometry.spacing.medium

                BaseIcon {
                    icon:  barRoot.componentMetadata[itemRoot.componentId]?.icon || "extension"
                    size:  Globals.dimensions.iconBase
                    color: rect.isEnabled ? Globals.colors.primary : Globals.colors.text
                }

                BaseText {
                    text:  itemRoot.label
                    color: rect.isEnabled ? Globals.colors.textLighter : Globals.colors.text
                    Layout.fillWidth: true
                }

                BaseIcon {
                    icon: "reorder"
                    size: Globals.dimensions.iconBase
                    color: Globals.alpha(Globals.colors.text, 0.5)
                }
            }

            Drag.active:    dragHandler.drag.active
            Drag.keys:      ["bar-component"]
            Drag.hotSpot.x: width  / 2
            Drag.hotSpot.y: height / 2

            states: [
                State {
                    when: dragHandler.drag.active
                    ParentChange { target: rect; parent: root }
                    AnchorChanges {
                        target: rect
                        anchors.horizontalCenter: undefined
                        anchors.verticalCenter:   undefined
                    }
                }
            ]
        }
    }

    // ── ComponentList ────────────────────────────────────────────────────
    component ComponentList: ColumnLayout {
        id: section

        required property string sectionName
        required property var    components

        spacing: Globals.geometry.spacing.small

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(flow.height + Globals.geometry.spacing.medium * 2, 50)
            color:        Globals.colors.transparent
            radius:       Globals.geometry.innerRadius.medium
            border.width: 0

            DropArea {
                id: dropArea
                anchors.fill: parent
                keys: ["bar-component"]
                onDropped: (drop) => {
                    var data = drop.source && drop.source.dragData;
                    if (!data) return;
                    barRoot.moveComponent(data.componentId, data.sourceSection, section.sectionName, -1);
                    drop.accept();
                }
            }



            ColumnLayout {
                id: flow
                anchors.top:   parent.top
                anchors.left:  parent.left
                anchors.right: parent.right
                anchors.margins: Globals.geometry.spacing.small
                spacing: Globals.geometry.spacing.small

                Repeater {
                    model: components
                    Item {
                        Layout.fillWidth: true
                        height: itemInstance.height

                        BarComponentItem {
                            id: itemInstance
                            anchors.left: parent.left
                            anchors.right: parent.right
                            componentId:   modelData
                            sourceSection: section.sectionName
                            label:         barRoot.componentMetadata[modelData]?.name || modelData
                        }

                        DropArea {
                            anchors.fill: parent
                            keys: ["bar-component"]
                            onDropped: (drop) => {
                                var data = drop.source && drop.source.dragData;
                                if (!data) return;
                                barRoot.moveComponent(data.componentId, data.sourceSection, section.sectionName, index);
                                drop.accept();
                            }
                        }
                    }
                }
            }
        }
    }
}
