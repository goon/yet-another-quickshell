import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs

Item {
    id: islandRoot

    required property var barWindow
    property bool _ready: false
    Component.onCompleted: Qt.callLater(() => { _ready = true; })
    
    // ── DYNAMIC ISLAND STATE ──────────────────────────────────────────
    readonly property bool shouldBeMorphed: IslandService.activePanelName !== "" && 
        (IslandService.activeScreen === barWindow.screen || (!IslandService.activeScreen && barWindow.screen === Quickshell.screens[0]))

    property bool isMorphed: false
    property string activePanelName: ""
    property string loadedPanelName: ""

    // ── HOVER EXPAND STATE ────────────────────────────────────────────
    property bool isHovered: false
    onIsHoveredChanged: IslandService.isIslandHovered = isHovered;

    readonly property bool isMouseOverCapsule: typeof capsuleHoverHandler !== "undefined" ? capsuleHoverHandler.hovered : false

    onIsMouseOverCapsuleChanged: {
        if (isMouseOverCapsule) {
            hoverDelayTimer.stop();
            islandRoot.isHovered = true;
        } else {
            hoverDelayTimer.start();
        }
    }

    Timer {
        id: hoverDelayTimer
        interval: 250
        repeat: false
        onTriggered: {
            islandRoot.isHovered = false;
        }
    }

    // Gated only on capsule.height — not timers — so the bar never resizes mid-animation.
    readonly property bool isIslandMorphed: shouldBeMorphed || capsule.height > normalCapsuleHeight + 1

    // Identify toast-like panels that should not capture full screen mouse inputs
    readonly property bool isFullBar: loadedPanelName === "fullbar" || activePanelName === "fullbar"
    readonly property bool isToast: loadedPanelName === "volumetoast" || loadedPanelName === "notificationtoast" ||
                                    activePanelName === "volumetoast" || activePanelName === "notificationtoast" ||
                                    isFullBar

    // Determine whether the island should grab keyboard focus (toasts shouldn't)
    readonly property bool grabsFocus: isIslandMorphed &&
        loadedPanelName !== "volumetoast" &&
        loadedPanelName !== "notificationtoast" &&
        loadedPanelName !== "fullbar" &&
        loadedPanelName !== ""

    // Helper functions to safely call lifecycle methods and set properties on loaded views
    function notifyPanel(funcName) {
        if (panelLoader.item && typeof panelLoader.item[funcName] === "function") {
            panelLoader.item[funcName]();
        }
    }

    function setPanelState(state) {
        if (panelLoader.item) {
            if (panelLoader.item.hasOwnProperty("panelState")) {
                panelLoader.item.panelState = state;
            }
            if (panelLoader.item.hasOwnProperty("interactive")) {
                panelLoader.item.interactive = (state === "Open");
            }
        }
    }

    function updateMorphedState() {
        if (islandRoot.shouldBeMorphed) {
            var newName = IslandService.activePanelName;
            var wasAlreadyLoaded = (islandRoot.loadedPanelName !== "" && islandRoot.loadedPanelName === newName);
            
            if (islandRoot.loadedPanelName !== "" && !wasAlreadyLoaded) {
                // Transitioning directly between two panels
                if (panelLoader.item) {
                    islandRoot.setPanelState("Closing");
                    islandRoot.notifyPanel("closing");
                    islandRoot.setPanelState("Closed");
                    islandRoot.notifyPanel("closed");
                }
            }
            islandRoot.activePanelName = newName;
            islandRoot.loadedPanelName = newName;
            islandRoot.isMorphed = true;
            collapseTimer.stop();
            
            if (wasAlreadyLoaded && panelLoader.item) {
                islandRoot.setPanelState("Opening");
                islandRoot.notifyPanel("opening");
                openTimer.start();
            }
        } else {
            if (islandRoot.isMorphed) {
                islandRoot.isMorphed = false;
                if (panelLoader.item) {
                    islandRoot.setPanelState("Closing");
                    islandRoot.notifyPanel("closing");
                }
                collapseTimer.start();
            }
        }
    }

    Connections {
        target: IslandService
        function onActivePanelNameChanged() { islandRoot.updateMorphedState(); }
        function onActiveScreenChanged() { islandRoot.updateMorphedState(); }
    }

    Timer {
        id: collapseTimer
        interval: Globals.animations.normal
        repeat: false
        onTriggered: {
            if (!islandRoot.isMorphed) {
                if (panelLoader.item) {
                    islandRoot.setPanelState("Closed");
                    islandRoot.notifyPanel("closed");
                }
                loadedPanelName = "";
                activePanelName = "";
            }
        }
    }

    // Active panel element reference shortcut
    readonly property alias activePanelItem: panelLoader.item

    // Expose the mask element to Bar.qml for input region
    readonly property alias maskItem: maskItem

    readonly property real normalSideMargin: Math.max(0, (Preferences.bar.height - (Globals.dimensions.barItemHeight)) / 2)
    readonly property real normalCapsuleWidth: staticFull.implicitWidth
    readonly property real normalCapsuleHeight: Preferences.bar.height
    readonly property real normalCapsuleX: (barWindow.width - normalCapsuleWidth) / 2
    readonly property real normalCapsuleY: Preferences.bar.position === "top"
        ? Preferences.bar.marginTop
        : (barWindow.height - normalCapsuleHeight - Preferences.bar.marginTop)


    // Expected fallback dimensions during transition before component load completes
    function getExpectedPanelWidth(name) {
        var panel = IslandService.panelRegistry[name];
        return (panel && panel.width) ? panel.width : 420;
    }

    function getExpectedPanelHeight(name) {
        var panel = IslandService.panelRegistry[name];
        return (panel && panel.height) ? panel.height : 500;
    }

    readonly property real totalWidthPadding: (Globals.geometry.padding.island * 2)
    readonly property real totalHeightPadding: (Globals.geometry.padding.island * 2)

    // Target Dimensions when morphed
    property real activePanelWidth: activePanelItem ? (activePanelItem.implicitWidth || 0) + totalWidthPadding : getExpectedPanelWidth(activePanelName)
    property real activePanelHeight: activePanelItem ? (activePanelItem.implicitHeight || 0) + totalHeightPadding : getExpectedPanelHeight(activePanelName)

    readonly property real targetCapsuleWidth: {
        if (isMorphed) {
            if (activePanelName === "fullbar") {
                return (activePanelItem ? activePanelItem.implicitWidth : barWindow.width);
            }
            return activePanelWidth;
        }
        return normalCapsuleWidth;
    }

    readonly property real targetCapsuleHeight: {
        if (isMorphed) {
            if (activePanelName === "fullbar") {
                return normalCapsuleHeight;
            }
            return activePanelHeight;
        }
        return normalCapsuleHeight;
    }

    readonly property real targetCapsuleX: {
        if (!isMorphed) return normalCapsuleX;
        let actualPanelWidth = (activePanelName === "fullbar") ? targetCapsuleWidth : activePanelWidth;
        if (IslandService.anchorX < 0) return (barWindow.width - actualPanelWidth) / 2;
        
        var x = IslandService.anchorX - (actualPanelWidth / 2);
        var radiusInset = Globals.geometry.radius;
        var minX = (IslandService.anchorMinX >= 0) ? (IslandService.anchorMinX + radiusInset) : 0;
        var maxX = (IslandService.anchorMaxX >= 0) ? (IslandService.anchorMaxX - actualPanelWidth - radiusInset) : (barWindow.width - actualPanelWidth);
        return Math.max(minX, Math.min(x, maxX));
    }

    readonly property real targetCapsuleY: isMorphed 
        ? (Preferences.bar.position === "top" ? Preferences.bar.marginTop : barWindow.height - (activePanelName === "fullbar" ? targetCapsuleHeight : activePanelHeight) - Preferences.bar.marginTop)
        : normalCapsuleY

    // ── CLICK OUTSIDE SHIELD ──────────────────────────────────────────
    MouseArea {
        id: clickOutsideShield
        anchors.fill: parent
        enabled: islandRoot.isMorphed && !islandRoot.isToast
        z: 1
        onClicked: {
            IslandService.closeAll();
        }
    }

    // ── MASK ITEM (INPUT REGION) ──────────────────────────────────────
    Item {
        id: maskItem
        x: targetCapsuleX
        y: targetCapsuleY
        width: targetCapsuleWidth
        height: targetCapsuleHeight
        z: 2

        // Prevent click-throughs to clickOutsideShield inside the capsule bounds
        MouseArea {
            id: capsuleHoverArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {}
        }
    }

    // ── MORPHING CAPSULE ──────────────────────────────────────────────
    BaseBackground {
        id: capsule
        
        HoverHandler {
            id: capsuleHoverHandler
        }
        
        x: targetCapsuleX
        y: targetCapsuleY
        width: targetCapsuleWidth
        height: targetCapsuleHeight
        z: 2
        

        borderColor: Preferences.globals.islandOutline ? Globals.alpha(Globals.colors.border, 0.4) : Globals.colors.transparent
        borderWidth: Preferences.globals.islandOutline ? 1 : 0
        radius: Preferences.globals.cornerRadius || Globals.geometry.radius
        clip: true

        Behavior on x      { enabled: islandRoot._ready; PropertyAnimation { duration: Math.max(0, Math.round(Globals.animations.normal / Preferences.animations.speedMultiplier)); easing.type: Globals.animations.easingType; easing.bezierCurve: Globals.animations.bezierCurve } }
        Behavior on y      { enabled: islandRoot._ready; PropertyAnimation { duration: Math.max(0, Math.round(Globals.animations.normal / Preferences.animations.speedMultiplier)); easing.type: Globals.animations.easingType; easing.bezierCurve: Globals.animations.bezierCurve } }
        Behavior on width  { enabled: islandRoot._ready; PropertyAnimation { duration: Math.max(0, Math.round(Globals.animations.normal / Preferences.animations.speedMultiplier)); easing.type: Globals.animations.easingType; easing.bezierCurve: Globals.animations.bezierCurve } }
        Behavior on height { enabled: islandRoot._ready; PropertyAnimation { duration: Math.max(0, Math.round(Globals.animations.normal / Preferences.animations.speedMultiplier)); easing.type: Globals.animations.easingType; easing.bezierCurve: Globals.animations.bezierCurve } }



        MouseArea {
            id: capsuleInnerHoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton

            // ── NORMAL BAR LAYOUT ──────────────────────────────────────
            RowLayout {
                id: contentLayout

                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height: implicitHeight
                width: normalCapsuleWidth
                spacing: normalSideMargin
                
                opacity: islandRoot.isIslandMorphed ? 0.0 : 1.0
                enabled: opacity > 0.01

                Behavior on opacity { BaseAnimation { duration: Globals.animations.fast } }

                Full {
                    id: staticFull
                    barWindow: islandRoot.barWindow
                    Layout.alignment: Qt.AlignCenter
                }
            }

            // ── PANEL CONTENT LOADER ───────────────────────────────────
            Loader {
                id: panelLoader
                anchors.fill: parent
                anchors.margins: islandRoot.loadedPanelName === "fullbar" ? 0 : Globals.geometry.padding.island
                
                active: islandRoot.loadedPanelName !== ""
                focus: true

                Binding {
                    target: panelLoader.item
                    property: "width"
                    value: panelLoader.width
                    when: panelLoader.item !== null
                }

                Binding {
                    target: panelLoader.item
                    property: "height"
                    value: panelLoader.height
                    when: panelLoader.item !== null
                }

                Binding {
                    target: panelLoader.item
                    property: "barWindow"
                    value: islandRoot.barWindow
                    when: panelLoader.item !== null && typeof panelLoader.item.barWindow !== "undefined"
                }

                opacity: islandRoot.isMorphed && status === Loader.Ready ? 1.0 : 0.0
                visible: opacity > 0.0
                Behavior on opacity { BaseAnimation { duration: Globals.animations.fast } }

                source: {
                    var panel = IslandService.panelRegistry[islandRoot.loadedPanelName];
                    return panel ? Qt.resolvedUrl(panel.source) : "";
                }

                onLoaded: {
                    if (item) {
                        IslandService.activePanelItem = item;
                        if (islandRoot.isMorphed) {
                            islandRoot.setPanelState("Opening");
                            islandRoot.notifyPanel("opening");
                            openTimer.start();
                        }
                        if (item.forceActiveFocus && item !== islandRoot) {
                            item.forceActiveFocus();
                        }
                    }
                }
            }

            Timer {
                id: openTimer
                interval: Globals.animations.normal
                repeat: false
                onTriggered: {
                    if (islandRoot.isMorphed && panelLoader.item) {
                        islandRoot.setPanelState("Open");
                        islandRoot.notifyPanel("opened");

                        // Handle initial focus delegation
                        if (panelLoader.item.hasOwnProperty("initialFocusItem") && panelLoader.item.initialFocusItem) {
                            var focusTarget = panelLoader.item.initialFocusItem;
                            if (typeof focusTarget.focusInput === "function") {
                                focusTarget.focusInput();
                            } else {
                                focusTarget.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }
    }
}
