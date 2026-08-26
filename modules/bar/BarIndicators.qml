import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import qs
import qs.services

Item {
    id: root

    property var barWindow: null
    property string hoveredKey: ""

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false
    implicitWidth: background.implicitWidth
    implicitHeight: Globals.dimensions.barItemHeight

    readonly property int spacing: Globals.geometry.spacing.small
    readonly property int indicatorItemWidth: 32

    readonly property int traySectionWidth: trayRow.visible ? trayRow.width : 0

    // ── SINGLE SOURCE OF TRUTH ──────────────────────────────────────────

    readonly property var _indicatorModel: [
        { key: "wifi", icon: "wifi" },
        { key: "notifications", icon: "notifications" },
        { key: "settings", icon: "settings" },
        { key: "instantmix", icon: "instant_mix" },
        { key: "power", icon: "power_settings_new" },
        { key: "clipboard", icon: "content_paste" },
    ]

    function _modelIndex(key) {
        for (var i = 0; i < _indicatorModel.length; i++) {
            if (_indicatorModel[i].key === key) return i;
        }
        return -1;
    }

    function getItemWidth(key) {
        return indicatorItemWidth;
    }

    // Filter to get only visible draggable items in order
    readonly property var visibleKeys: {
        var keys = [];
        for (var i = 0; i < Preferences.indicators.order.length; i++) {
            var key = Preferences.indicators.order[i];
            if (_modelIndex(key) !== -1) keys.push(key);
        }
        // Fallbacks for keys that aren't in indicatorsOrder yet
        for (var j = 0; j < _indicatorModel.length; j++) {
            if (keys.indexOf(_indicatorModel[j].key) === -1)
                keys.push(_indicatorModel[j].key);
        }
        return keys;
    }

    // Total content width based on animating widths of item components
    readonly property int contentWidth: {
        var w = 0;
        var hasVisibleItem = false;
        
        if (traySectionWidth > 0) {
            w += traySectionWidth;
            hasVisibleItem = true;
        }

        for (var i = 0; i < visibleKeys.length; i++) {
            var idx = _modelIndex(visibleKeys[i]);
            var item = (idx >= 0 && idx < indicatorRepeater.count) ? indicatorRepeater.itemAt(idx) : null;
            var itemW = item ? item.width : getItemWidth(visibleKeys[i]);
            if (itemW > 0) {
                if (hasVisibleItem) w += spacing;
                w += itemW;
                hasVisibleItem = true;
            }
        }
        return w;
    }

    // Get current animating X coordinate for positioning items in flow
    function getActualX(key) {
        var idx = visibleKeys.indexOf(key);
        if (idx < 0) return 0;
        
        var x = (traySectionWidth > 0) ? traySectionWidth + spacing : 0;
        for (var i = 0; i < idx; i++) {
            var k = visibleKeys[i];
            var mi = _modelIndex(k);
            var item = (mi >= 0 && mi < indicatorRepeater.count) ? indicatorRepeater.itemAt(mi) : null;
            x += (item ? item.width : getItemWidth(k)) + spacing;
        }
        return x;
    }

    // Get static target position for drag and swap math
    function getTargetX(key) {
        var idx = visibleKeys.indexOf(key);
        if (idx < 0) return 0;
        
        var x = (traySectionWidth > 0) ? traySectionWidth + spacing : 0;
        for (var i = 0; i < idx; i++) {
            x += getItemWidth(visibleKeys[i]) + spacing;
        }
        return x;
    }

    function _openPanel(key) {
        switch (key) {
            case "wifi": IslandService.toggleNetworkPopout(); break;
            case "notifications": IslandService.toggleNotificationsPopout(); break;
            case "power": IslandService.togglePowerPopout(); break;
            case "instantmix": IslandService.toggleMixerPopout(); break;
            case "settings": IslandService.toggleSettings(); break;
            case "clipboard": IslandService.toggleClipboard(); break;
        }
    }

    function _handleRightClick(key) {
        if (key === "notifications")
            Preferences.notifications.mode = Preferences.notifications.mode === 1 ? 0 : 1;
    }

    BaseContainer {
        id: background

        anchors.fill: parent
        implicitHeight: Globals.dimensions.barItemHeight
        hoverEnabled: false

        Item {
            id: container
            implicitWidth: root.contentWidth
            implicitHeight: Globals.dimensions.barItemHeight
            height: parent.height

            Row {
                id: trayRow
                x: 0
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.spacing

                Repeater {
                    model: SystemTray.items

                    delegate: Item {
                        width: root.indicatorItemWidth
                        height: container.height

                        MouseArea {
                            id: trayMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor

                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    modelData.display(barWindow, mouse.x, mouse.y);
                                } else {
                                    modelData.activate();
                                }
                            }
                        }

                        Image {
                            anchors.centerIn: parent
                            width: Globals.dimensions.iconMedium * 1.1
                            height: Globals.dimensions.iconMedium * 1.1
                            source: modelData.icon
                            sourceSize: Qt.size(width, height)
                            fillMode: Image.PreserveAspectFit
                            
                            opacity: trayMouseArea.containsMouse ? 1.0 : 0.8
                            Behavior on opacity { BaseAnimation { duration: Globals.animations.fast } }

                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1.0
                                colorizationColor: Globals.colors.text
                            }
                        }
                    }
                }
            }
            Repeater {
                id: indicatorRepeater
                model: root._indicatorModel

                delegate: IndicatorIcon {
                    itemKey: modelData.key
                    iconName: {
                        if (modelData.key === "notifications") {
                            if (Preferences.notifications.mode === 1) return "notifications_off";
                            if (Notifications.unreadCount > 0) return "notifications_unread";
                            return "notifications";
                        }
                        return modelData.icon;
                    }
                }
            }
        }
    }

    component IndicatorIcon: Item {
        id: itemRoot

        required property int index
        required property var modelData
        required property string itemKey
        property string iconName

        readonly property bool isVisible: _modelIndex(itemKey) !== -1

        visible: isVisible
        height: parent.height
        // Define animating width centered on the item's state width
        width: isVisible ? getItemWidth(itemKey) : 0

        readonly property int targetX: getTargetX(itemKey)
        readonly property bool isDragging: dragArea.drag.active

        // Follow the actual coordinates when not dragged.
        // Uses a Binding element (not an inline binding) to avoid a self-referential
        // binding loop: `x: isDragging ? x : ...` would reference `x` itself and crash.
        Binding {
            target: itemRoot
            property: "x"
            value: getActualX(itemKey)
            when: !itemRoot.isDragging
            // Without RestoreNone, QML reverts x to 0 (the pre-binding default) when
            // the drag starts and the Binding releases, causing a visible flick to the
            // left edge before the drag system corrects it.
            restoreMode: Binding.RestoreNone
        }

        // (Removed Behavior on x to prevent sliding animation)

        onIsDraggingChanged: {
            if (isDragging) {
                // Only close other panels — do NOT close the fullbar we're dragging inside
                if (IslandService.activePanelName !== "fullbar") {
                    IslandService.closeAll();
                }
                if (root.hoveredKey === itemKey) {
                    root.hoveredKey = "";
                }
            }
        }
        BaseIcon {
            anchors.centerIn: parent
            icon: itemRoot.iconName
            opacity: dragArea.containsMouse ? 1.0 : 0.8
            Behavior on opacity { BaseAnimation { duration: Globals.animations.fast } }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: dragArea.containsMouse ? Globals.alpha(Globals.colors.text, 0.1) : "transparent"
                shadowBlur: 0.8
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
                Behavior on shadowColor { ColorAnimation { duration: Globals.animations.fast } }
            }
        }



        Connections {
            target: dragArea
            function onContainsMouseChanged() {
                if (dragArea.containsMouse && !itemRoot.isDragging) {
                    root.hoveredKey = itemKey;
                } else {
                    if (root.hoveredKey === itemKey) {
                        root.hoveredKey = "";
                    }
                }
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor

            drag.target: itemRoot
            drag.axis: Drag.XAxis
            drag.minimumX: (root.traySectionWidth > 0) ? root.traySectionWidth + root.spacing : 0
            drag.maximumX: container.width - width
            drag.threshold: 8

            onPositionChanged: {
                if (drag.active) {
                    swapDebounce.restart();
                }
            }

            onReleased: (mouse) => {
                if (!drag.active) {
                    triggerClick(mouse);
                }
                // No need to restore x — the Binding element re-engages automatically
                // when isDragging becomes false.
            }

            onCanceled: {
                // No need to restore x — the Binding element re-engages automatically.
            }

            function triggerClick(mouse) {
                if (mouse.button === Qt.RightButton) {
                    root._handleRightClick(itemKey);
                } else {
                    root._openPanel(itemKey);
                }
            }
        }

        Timer {
            id: swapDebounce
            interval: 50
            repeat: false
            onTriggered: {
                if (itemRoot.isDragging) checkAndSwap();
            }
        }

        function checkAndSwap() {
            let activeWidth = getItemWidth(itemKey);
            let centerX = itemRoot.x + activeWidth / 2;

            // Snapshot the array to avoid mutating a live binding mid-read
            let keys = visibleKeys.slice();
            let currentIdx = keys.indexOf(itemKey);
            if (currentIdx === -1) return;

            let closestIdx = currentIdx;
            let minDistance = 999999;

            for (let i = 0; i < keys.length; i++) {
                let k = keys[i];
                let centerI = getTargetX(k) + getItemWidth(k) / 2;
                let dist = Math.abs(centerX - centerI);
                if (dist < minDistance) {
                    minDistance = dist;
                    closestIdx = i;
                }
            }

            if (closestIdx !== currentIdx) {
                let activeKey = keys[currentIdx];
                let targetKey = keys[closestIdx];

                // Snapshot Preferences.indicators.order to avoid reactive mid-write
                let order = Preferences.indicators.order.slice();
                let fullIdx1 = order.indexOf(activeKey);
                let fullIdx2 = order.indexOf(targetKey);

                if (fullIdx1 !== -1 && fullIdx2 !== -1) {
                    // Move (shift) not swap: remove from current slot and insert at target slot.
                    // All icons between the two positions shift by one — no teleporting.
                    order.splice(fullIdx1, 1);
                    order.splice(fullIdx2, 0, activeKey);
                    Preferences.indicators.order = order;
                }
            }
        }
    }


}
