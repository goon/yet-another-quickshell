import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs

Item {
    id: fullRoot
    
    property var barWindow: null
    
    // Explicitly define height matching the pill clock capsule height
    implicitHeight: Preferences.bar.height
    implicitWidth: (contentLayout.implicitWidth || 0) + (dynamicEndMargin * 2)
    
    readonly property real normalSideMargin: 0
    readonly property real dynamicEndMargin: Globals.geometry.padding.island
    readonly property real horizontalSpacing: 20

    RowLayout {
        id: contentLayout
        
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        height: implicitHeight
        width: mainContent.implicitWidth
        spacing: horizontalSpacing
        
        RowLayout {
            id: mainContent
            Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
            spacing: horizontalSpacing
            
            Repeater {
                model: barWindow ? barWindow.components : []
                
                RowLayout {
                    id: componentLayout
                    Layout.alignment: Qt.AlignVCenter
                    
                    readonly property bool isComponentVisible: (Preferences.bar.componentsEnabled[modelData] === true) && (modelData === "dock" ? Compositor.hasDockWindows : (barWindow && barWindow.resolveComponentSource(modelData) !== ""))
                    visible: isComponentVisible
                    spacing: horizontalSpacing
                    
                    BaseSeparator {
                        visible: {
                            if (!componentLayout.isComponentVisible) return false;
                            
                            for (let i = 0; i < index; i++) {
                                let otherData = barWindow.components[i];
                                let otherVisible = (Preferences.bar.componentsEnabled[otherData] === true) && 
                                                   (otherData === "dock" ? Compositor.hasDockWindows : (barWindow && barWindow.resolveComponentSource(otherData) !== ""));
                                if (otherVisible) return true;
                            }
                            return false;
                        }
                        orientation: BaseSeparator.Vertical
                        Layout.fillHeight: false
                        Layout.preferredHeight: 30
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Loader {
                        id: componentLoader
                        Layout.alignment: Qt.AlignVCenter
                        source: barWindow ? barWindow.resolveComponentSource(modelData) : ""
                        Binding {
                            target: componentLoader.item
                            property: "barWindow"
                            value: barWindow
                            when: componentLoader.item !== null && (modelData === "indicators" || modelData === "tray")
                        }
                    }
                }
            }
        }
    }
}
