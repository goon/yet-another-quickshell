import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs
import qs.services

FocusScope {
    id: root

    property string panelState: "Closed"
    property string searchText: ""

    implicitWidth: 760

    readonly property int maxVisibleItems: 8
    readonly property int listItemHeight: Globals.dimensions.listItemHeight
    readonly property int listGap: 0
    readonly property int headerHeight: 52
    readonly property int searchHeight: Globals.dimensions.launcherSearchHeight
    readonly property int containerSpacing: Globals.geometry.spacing.small
    readonly property int paneSpacing: Globals.geometry.spacing.medium
    readonly property int listAreaHeight: maxVisibleItems * listItemHeight
    readonly property int preferredHeight: headerHeight + containerSpacing + searchHeight + paneSpacing + listAreaHeight

    implicitHeight: preferredHeight

    readonly property var currentItem: (listView.currentIndex >= 0 && filteredModel.count > 0) ? filteredModel.get(listView.currentIndex) : null

    function opening() {
        if (root.searchText !== "") {
            root.searchText = "";
        } else {
            rebuildFilteredModel();
        }
        if (filteredModel.count > 0) {
            listView.currentIndex = 0;
        }
        searchInput.forceActiveFocus();
    }

    function closing() {
        root.searchText = "";
    }

    Keys.onPressed: (event) => root.handleKey(event)

    function handleKey(event) {
        if (event.key === Qt.Key_Down) {
            if (listView.count > 0) {
                if (listView.currentIndex < 0) listView.currentIndex = 0;
                else if (listView.currentIndex < listView.count - 1) listView.currentIndex++;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Up) {
            if (listView.count > 0) {
                if (listView.currentIndex > 0) listView.currentIndex--;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.currentItem) {
                Clipboard.pasteCliphistItem(root.currentItem.rawLine);
                if (Preferences.clipboard.autoClose) {
                    IslandService.closeAll();
                }
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Delete) {
            if (root.currentItem) {
                Clipboard.deleteCliphistItem(root.currentItem.rawLine);
                if (listView.currentIndex >= listView.count - 1) {
                    listView.currentIndex = Math.max(0, listView.count - 2);
                }
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            IslandService.closeAll();
            event.accepted = true;
        }
    }

    ListModel {
        id: filteredModel
    }

    Timer {
        id: filteredModelRebuildTimer
        interval: 0
        repeat: false
        onTriggered: root.rebuildFilteredModel()
    }

    function rebuildFilteredModel() {
        var prev = listView.currentIndex;
        filteredModel.clear();
        var query = (root.searchText || "").toLowerCase();
        for (var i = 0; i < Clipboard.history.count; i++) {
            var item = Clipboard.history.get(i);
            var haystack = (item.text || "").toLowerCase();
            if (!query || haystack.indexOf(query) !== -1) {
                filteredModel.append({
                    "id": item.id,
                    "text": item.text,
                    "isImage": item.isImage,
                    "rawLine": item.rawLine
                });
            }
        }
        if (filteredModel.count > 0) {
            listView.currentIndex = Math.min(prev < 0 ? 0 : prev, filteredModel.count - 1);
        } else {
            listView.currentIndex = -1;
        }
    }

    onSearchTextChanged: filteredModelRebuildTimer.restart()

    Connections {
        target: Clipboard.history
        function onCountChanged() { root.rebuildFilteredModel(); }
        function onDataChanged() { root.rebuildFilteredModel(); }
    }

    Component.onCompleted: {
        rebuildFilteredModel();
        searchInput.forceActiveFocus();
    }

    BaseContainer {
        anchors.fill: parent
        spacing: Globals.geometry.spacing.small

        // ── HEADER ──────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: Globals.geometry.spacing.large
                spacing: Globals.geometry.spacing.small

                BaseHeader {
                    text: "CLIPBOARD"
                }

                Item { Layout.fillWidth: true }

                BaseButton {
                    icon: "delete_sweep"
                    size: Globals.dimensions.iconMedium * 1.1
                    Layout.alignment: Qt.AlignVCenter
                    enabled: Clipboard.history.count > 0
                    onClicked: Clipboard.clearHistory()
                }
            }

            BaseSeparator {
                Layout.fillWidth: true
                Layout.bottomMargin: Globals.geometry.spacing.large
            }
        }

        // ── CONTENT ─────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Globals.geometry.spacing.large

            // Left pane ──────────────────────────────────────────────
            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: 450
                Layout.minimumWidth: 0
                spacing: Globals.geometry.spacing.medium

                BaseContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Globals.dimensions.launcherSearchHeight
                    paddingHorizontal: Globals.geometry.spacing.large

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Globals.geometry.spacing.large

                        BaseIcon {
                            icon: "search"
                            color: searchInput.text.length > 0 ? Globals.colors.primary : Globals.colors.muted
                            Behavior on color { BaseAnimation { } }
                            scale: searchInput.text.length > 0 ? 1.1 : 1.0
                            Behavior on scale { BaseAnimation { } }
                        }

                        BaseInput {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            placeholderText: "Search clipboard..."
                            text: root.searchText
                            onTextChanged: root.searchText = text
                            leftPadding: 8
                            rightPadding: 8
                            Keys.onPressed: (event) => root.handleKey(event)
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ListView {
                        id: listView
                        anchors.fill: parent
                        model: filteredModel
                        clip: true
                        interactive: true
                        focus: true
                        activeFocusOnTab: true
                        keyNavigationEnabled: false
                        highlightFollowsCurrentItem: false
                        currentIndex: -1
                        boundsBehavior: Flickable.StopAtBounds

                        // Sliding hover indicator — delegates feed activeHover,
                        // the indicator derives its target from it via gap debounce.
                        property Item activeHover: null

                        BaseIndicator {
                            z: 100
                            hoverPredicate: function() { return listView.activeHover; }
                        }

                        delegate: ClipboardListItem {
                            width: ListView.view ? ListView.view.width - Globals.geometry.spacing.small : 0
                            itemData: model
                            selected: ListView.isCurrentItem
                            onClicked: listView.currentIndex = index
                            onHoveredChanged: {
                                if (hovered) {
                                    listView.activeHover = this;
                                } else if (listView.activeHover === this) {
                                    listView.activeHover = null;
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: listView.count === 0
                        spacing: Globals.geometry.spacing.medium
                        BaseIcon {
                            Layout.alignment: Qt.AlignHCenter
                            icon: "content_paste_off"
                            size: Globals.dimensions.iconExtraLarge
                            color: Globals.colors.muted
                        }
                    }
                }
            }

            // Vertical separator
            BaseSeparator {
                Layout.fillHeight: true
                orientation: BaseSeparator.Vertical
            }

            // Right pane ─────────────────────────────────────────────
            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: 550
                Layout.minimumWidth: 0
                spacing: Globals.geometry.spacing.medium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Globals.geometry.spacing.small
                    Layout.alignment: Qt.AlignRight

                    Item { Layout.fillWidth: true }

                    BaseButton {
                        icon: "content_paste"
                        Layout.alignment: Qt.AlignVCenter
                        enabled: root.currentItem !== null
                        onClicked: {
                            if (root.currentItem) {
                                Clipboard.pasteCliphistItem(root.currentItem.rawLine);
                                if (Preferences.clipboard.autoClose) {
                                    IslandService.closeAll();
                                }
                            }
                        }
                    }

                    BaseButton {
                        icon: "delete"
                        Layout.alignment: Qt.AlignVCenter
                        enabled: root.currentItem !== null
                        onClicked: {
                            if (root.currentItem) {
                                Clipboard.deleteCliphistItem(root.currentItem.rawLine);
                                if (listView.currentIndex >= listView.count - 1) {
                                    listView.currentIndex = Math.max(0, listView.count - 2);
                                }
                            }
                        }
                    }
                }

                ClipboardPreview {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    item: root.currentItem
                }
            }
        }
    }
}
