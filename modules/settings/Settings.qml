import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs

FocusScope {
    id: root

    property string panelState: "Closed"

    readonly property var popupWindow: Window.window

    implicitWidth: 460
    
    readonly property real maxHeight: (root.popupWindow && root.popupWindow.screen) 
        ? Math.min(860, root.popupWindow.screen.height * 0.9 - 40)
        : 760

    implicitHeight: Math.min(maxHeight, mainCol.implicitHeight)

    property alias pageStack: pageStack

    function changePage(pageName) {
        pageStack.push(pageName + ".qml");
    }

    function closed() {
        pageStack.pop(null); // Return to root when closed
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            IslandService.closeAll();
            event.accepted = true;
        } else if (!event.accepted && event.key === Qt.Key_Backspace && pageStack.depth > 1) {
            pageStack.pop(null);
            event.accepted = true;
        }
    }


    BaseContainer {
        id: mainCol
        anchors.fill: parent
        spacing: Globals.geometry.spacing.large

        // ── CONTENT AREA ──────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: pageStack.implicitHeight

            // Scroller container
            Item {
                anchors.fill: parent

                BaseScrolling {
                    id: contentScroller
                    anchors.fill: parent
                    clip: true
                    implicitHeight: 0

                    BaseStackView {
                        id: pageStack
                        width: contentScroller.availableWidth
                        implicitHeight: currentItem ? currentItem.implicitHeight : 0
                        initialItem: "Menu.qml"
                    }
                }
            }
        }
    }
}
