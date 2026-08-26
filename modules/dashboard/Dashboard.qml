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

    implicitWidth: 1060
    
    readonly property real maxHeight: (root.popupWindow && root.popupWindow.screen) 
        ? Math.min(860, root.popupWindow.screen.height * 0.9 - 40)
        : 760

    implicitHeight: Math.min(maxHeight, mainRow.implicitHeight)

    // CONTENT AREA
    Item {
        anchors.fill: parent

        // Scroller container
        Item {
            anchors.fill: parent

            BaseScrolling {
                id: contentScroller
                anchors.fill: parent
                clip: true

                ColumnLayout {
                    id: centeredContainer
                    width: parent.width

                    ColumnLayout {
                        id: mainRow
                        Layout.fillWidth: true
                        spacing: Globals.geometry.spacing.large

                        // Top Row: Weather
                        DashboardWeather {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 190
                        }

                        // Bottom Row: Clock & Calendar & Resource Bars & Media
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 320
                            spacing: Globals.geometry.spacing.large

                            DashboardClock {
                                Layout.fillHeight: true
                            }

                            DashboardCalendar {
                                Layout.fillHeight: true
                            }

                            DashboardResourceBars {
                                Layout.fillHeight: true
                            }

                            DashboardMedia {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }
                }
            }
        }
    }
}
