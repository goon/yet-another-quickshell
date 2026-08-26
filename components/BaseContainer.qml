import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

FocusScope {
    id: root

    // Panel state
    property string panelState: "Closed"

    // Layout
    property real padding: 0
    property real paddingHorizontal: padding
    property real paddingVertical: padding
    property real spacing: Globals.geometry.spacing.medium

    // Interactivity
    property bool clickable: false
    property bool hoverEnabled: true
    property bool autoFillWidth: true

    Keys.onPressed: (event) => Binds.handleKey(event)
    
    HoverHandler {
        id: hoverHandler
        enabled: root.hoverEnabled || root.clickable
        cursorShape: (root.clickable && enabled) ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    readonly property bool containsMouse: hoverHandler.hovered
    readonly property alias pressed: mouseArea.pressed

    // Internal layout control
    default property alias contentData: contentContainer.data

    signal clicked()
    signal rightClicked()
    signal middleClicked()
    signal pressedSignal()
    signal releasedSignal()

    Layout.fillWidth: autoFillWidth
    implicitWidth: contentContainer.implicitWidth + (paddingHorizontal * 2)
    implicitHeight: contentContainer.implicitHeight + (paddingVertical * 2)

    scale: (root.clickable && pressed) ? 0.98 : 1.0

    Behavior on scale { BaseAnimation { duration: Globals.animations.fast } }



    MouseArea {
        id: mouseArea

        anchors.fill: parent
        enabled: root.clickable || root.hoverEnabled
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else if (mouse.button === Qt.MiddleButton)
                root.middleClicked();
            else
                root.clicked();
        }
        onPressed: (mouse) => {
            root.pressedSignal();
        }
        onReleased: root.releasedSignal()
    }

    ColumnLayout {
        id: contentContainer

        anchors.fill: parent
        anchors.leftMargin: root.paddingHorizontal
        anchors.rightMargin: root.paddingHorizontal
        anchors.topMargin: root.paddingVertical
        anchors.bottomMargin: root.paddingVertical
        spacing: root.spacing
    }
}
