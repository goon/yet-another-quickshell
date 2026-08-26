import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

Item {
    id: root
    implicitHeight: mainCol.implicitHeight
    Layout.fillWidth: true

    property string title: "Settings"

    function pushPage(name) {
        StackView.view.push(name);
    }

    // ── SINGLE SOURCE OF TRUTH ──────────────────────────────────────────

    readonly property var _menuModel: [
        { page: "Style.qml",         title: "Style",         subtitle: "Look, feel, and typography.",            icon: "brush" },
        { page: "Bar.qml",           title: "Bar",           subtitle: "Position, size, and layout of the bar.", icon: "border_top" },
        { page: "Notifications.qml", title: "Notifications", subtitle: "Behaviour, sounds, and display.",        icon: "notifications" },
        { page: "Clipboard.qml",     title: "Clipboard",     subtitle: "History, sync, and behaviour.",          icon: "content_paste" },
        { page: "Launcher.qml",      title: "Launcher",      subtitle: "Launcher look, feel and behaviour.",     icon: "rocket_launch" },
        { page: "Animations.qml",    title: "Animations",    subtitle: "Speed, transitions, and motion.",        icon: "animation" },
        { page: "TimeDate.qml",      title: "Time & Date",   subtitle: "Time formatting and location settings.", icon: "schedule" },
        { page: "Wallpaper.qml",     title: "Wallpaper",     subtitle: "Wallpaper and dynamic themeing.",        icon: "image" },
        { page: "Applications.qml",  title: "Applications",  subtitle: "External application themeing.",         icon: "apps" },
    ]

    readonly property Item activeHover: {
        for (var i = 0; i < menuRepeater.count; i++) {
            var item = menuRepeater.itemAt(i);
            if (item && item.hovered) return item;
        }
        return null;
    }

    function _hoverPredicate() {
        return root.activeHover;
    }

    ColumnLayout {
        id: mainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        BaseHeader {
            text: "SETTINGS"
            isActive: root.activeHover !== null
            Layout.bottomMargin: Globals.geometry.spacing.large
        }

        BaseSeparator {
            Layout.fillWidth: true
            Layout.bottomMargin: Globals.geometry.spacing.large
        }

        Repeater {
            id: menuRepeater
            model: root._menuModel

            delegate: BaseListItem {
                required property int index
                required property var modelData

                Layout.fillWidth: true
                title: modelData.title
                subtitle: modelData.subtitle
                showSubtitleOnHover: true
                leftIcon: modelData.icon
                onClicked: root.pushPage(modelData.page)
            }
        }
    }

    // Sliding Hover Indicator
    BaseIndicator {
        hoverPredicate: root._hoverPredicate
    }
}
