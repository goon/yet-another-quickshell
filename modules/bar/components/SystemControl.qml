import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services

Item {
    id: root

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false
    implicitWidth: background.implicitWidth
    implicitHeight: Theme.dimensions.barItemHeight

    Component.onCompleted: PopoutService.systemControlItem = root
    Component.onDestruction: PopoutService.systemControlItem = null

    BaseBlock {
        id: background

        anchors.fill: parent
        paddingVertical: 0
        implicitHeight: Theme.dimensions.barItemHeight
        clickable: true
        hoverEnabled: false
        onClicked: {
            PopoutService.toggleSystemControl();
        }
        popoutOnHover: true
        onHoverAction: PopoutService.openPowerPopout

        BaseIcon {
            Layout.alignment: Qt.AlignCenter
            icon: "tune"
            size: Theme.dimensions.iconBase
            color: background.containsMouse ? Theme.colors.primary : Theme.colors.text
        }

    }

}
