import QtQuick
import QtQuick.Layouts
import qs

BaseContainer {
    id: root

    property alias text: input.text
    property alias inputItem: input
    property alias placeholderText: input.placeholderText
    property int currentIndex: 0
    property list<Item> activePageHints: []

    signal accepted()
    signal downPressed()
    signal tabClicked(int index)

    // Expose forceActiveFocus so parent can focus it
    function focusInput() {
        input.forceActiveFocus();
        input.cursorPosition = input.text.length;
    }

    Layout.fillWidth: true
    Layout.preferredHeight: Globals.dimensions.launcherSearchHeight
    paddingHorizontal: Globals.geometry.spacing.large
    clickable: true

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: 0
        Layout.rightMargin: 0
        Layout.topMargin: 0
        Layout.bottomMargin: 0
        spacing: Globals.geometry.spacing.large

        BaseIcon {
            icon: "search"
            color: input.text.length > 0 ? Globals.colors.primary : Globals.colors.muted
            
            Behavior on color { BaseAnimation { } }
            
            // Subtle pulse when typing
            scale: input.text.length > 0 ? 1.1 : 1.0
            Behavior on scale { BaseAnimation { } }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true



            BaseInput {
                id: input
                anchors.fill: parent
                clip: true
                leftPadding: 8
                rightPadding: 8
                placeholderText: "Search..."
                verticalAlignment: Text.AlignVCenter
                focus: true
                activeFocusOnTab: false

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Down) {
                        root.downPressed();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Backspace && input.text.length === 0) {
                        if (LauncherService.activeUtilityMode !== "") {
                            LauncherService.activeUtilityMode = "";
                            event.accepted = true;
                        } else if (root.currentIndex !== 0) {
                            root.tabClicked(0);
                            event.accepted = true;
                        }
                    }
                }
            }
        }

        RowLayout {
            id: hintsArea
            spacing: Globals.geometry.spacing.small
            Layout.alignment: Qt.AlignVCenter
            
            Repeater {
                model: root.activePageHints
                
                delegate: Item {
                    implicitWidth: modelData.implicitWidth
                    Layout.preferredHeight: Globals.dimensions.iconLarge
                    Layout.alignment: Qt.AlignVCenter

                    Component.onCompleted: {
                        modelData.parent = this;
                        // Use Layout properties instead of anchors inside Layout
                        // But modelData might be a generic Item. 
                        // If it's being parented to 'this' (an Item in a RowLayout), it's fine.
                        modelData.anchors.fill = this;
                    }
                }
            }
        }



    }
}

