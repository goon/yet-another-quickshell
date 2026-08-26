import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs

FocusScope {
    id: root
    
    property string panelState: "Closed"

    implicitWidth: 500
    implicitHeight: {
        var searchHeight = Globals.dimensions.launcherSearchHeight;
        var padLarge = Globals.geometry.spacing.large;

        if (root.isWallpaperActive) {
            return 660;
        }

        var count = root.activeListCount;
        var maxItems = 8;
        var visibleItems = Math.min(count, maxItems);
        
        var itemHeight = Globals.dimensions.launcherItemHeight;

        if (visibleItems === 0) {
            return searchHeight + padLarge;
        }

        // Calculation based on ColumnLayout spacing:
        // searchHeight (50) 
        // + columnSpacing to separator (12)
        // + separator (1)
        // + columnSpacing to results (12) 
        // + listHeight
        var listHeight = (visibleItems * itemHeight) + (Math.max(0, visibleItems - 1) * padLarge);
        return searchHeight + (2 * padLarge) + 1 + listHeight;
    }

    property Item initialFocusItem: searchBar
    
    property int currentTabIndex: 0
    property int activeListCount: root.activeTabObject ? root.activeTabObject.listCount : 0
    readonly property var activeTab: root.activeTabObject

    function opening() {
        LauncherService.resetInputStates();
        LauncherService.activeUtilityMode = "";
        LauncherService.lastInputMethod = "keyboard";
        searchBar.text = "";
        
        root.currentTabIndex = 0;
        root.currentItem = null;
        
        for (var i = 0; i < root.tabModel.length; i++) {
            var tab = root.getTab(i);
            if (tab) tab.isActive = (i === 0);
            root.resetTabToTop(i);
        }
    }
    
    function closing() {
        LauncherService.resetInputStates();
        LauncherService.activeUtilityMode = "";
        searchBar.text = "";
        for (var i = 0; i < root.tabModel.length; i++) {
            var tab = root.getTab(i);
            if (tab && tab.onLauncherClosed) tab.onLauncherClosed();
            root.resetTabToTop(i);
        }
    }

    Binding {
        target: root
        property: "currentItem"
        value: root.activeTab ? root.activeTab.currentItem : null
    }

    property var currentItem: null
    
    property var tabModel: [
        { icon: "dashboard", key: "", component: "LauncherApps.qml", placeholder: "Search..." },
        { icon: "palette", key: "", component: "LauncherTheme.qml", placeholder: "Search themes..." }
    ]

    readonly property var activeTabObject: (tabRepeater && root.currentTabIndex >= 0 && root.currentTabIndex < tabRepeater.count) ? tabRepeater.itemAt(root.currentTabIndex).item : null
    readonly property bool isWallpaperActive: (root.currentTabIndex >= 0 && root.currentTabIndex < tabModel.length) ? !!tabModel[root.currentTabIndex].isWallpaper : false

        property string currentPlaceholder: {
            if (root.currentTabIndex === 0) {
                var mode = LauncherService.activeUtilityMode;
                if (mode === "web") return "Search the web...";
                if (mode === "youtube") return "Search YouTube...";
                if (mode === "calculator") return "Type math expression...";

            }
            if (root.currentTabIndex >= 0 && root.currentTabIndex < tabModel.length) {
                return tabModel[root.currentTabIndex].placeholder; 
            }
            return "Search...";
        }

        function getTab(index) {
            if (index < 0 || index >= tabRepeater.count) return null;
            return tabRepeater.itemAt(index).item;
        }

        function getTabListView(tab) {
            return (tab && tab.listView) ? tab.listView : null;
        }

        function getCurrentListView() {
            var tab = getTab(root.currentTabIndex);
            return getTabListView(tab);
        }

        function resetTabToTop(index) {
            var tab = getTab(index);
            if (!tab) return;
            
            // Bypass reset for Wallpaper tab to preserve randomized starting position
            if (root.tabModel[index].isWallpaper) return;

            var listView = getTabListView(tab);
            if (listView && listView.count > 0) {
                // Check if listView supports positionViewAtBeginning (standard ListView)
                if (listView.positionViewAtBeginning) {
                    listView.currentIndex = 0;
                    listView.positionViewAtBeginning();
                }
            }
        }

        function switchTab(newIndex) {
            if (newIndex < 0 || newIndex >= root.tabModel.length) return;

            LauncherService.resetInputStates();
            LauncherService.activeUtilityMode = "";
            searchBar.text = "";
            
            // Deactivate old tab
            var oldTab = getTab(root.currentTabIndex);
            if (oldTab) oldTab.isActive = false;

            root.currentTabIndex = newIndex;
            root.resetTabToTop(newIndex);
            
            // Activate new tab
            var newTab = getTab(newIndex);
            if (newTab) {
                newTab.isActive = true;
                root.currentItem = newTab.currentItem;
            }

            searchBar.focusInput();
        }

        function navigateHorizontal(dir) {
            var listView = getCurrentListView();
            if (listView) {
                if (dir === -1 && listView.safeDecrement)
                    listView.safeDecrement();
                else if (dir === 1 && listView.safeIncrement)
                    listView.safeIncrement();
            }
        }

        function activateCurrentItem() {
            var tab = getTab(root.currentTabIndex);
            if (tab && tab.activateCurrentItem)
                tab.activateCurrentItem();
        }

        function navigateDown() {
            var tab = getTab(root.currentTabIndex);
            var listView = getCurrentListView();
            if (tab) tab.forceActiveFocus();

            // Ensure tab is focused for key events
            if (listView && listView.count > 0) {
                LauncherService.resetInputStates();
                listView.forceActiveFocus();
                if (listView.currentIndex === -1)
                    listView.currentIndex = 0;
                else
                    listView.incrementCurrentIndex();
            }
        }

        function navigateUp() {
            var listView = getCurrentListView();
            if (listView) {
                if (listView.currentIndex > 0) {
                    LauncherService.resetInputStates();
                    listView.decrementCurrentIndex();
                } else {
                    backToSearch("");
                }
            }
        }

        function backToSearch(text) {
            LauncherService.resetInputStates();
            searchBar.focusInput();
            if (text === "\b") {
                if (searchBar.text.length > 0)
                    searchBar.text = searchBar.text.substring(0, searchBar.text.length - 1);

            } else if (text && text.length > 0) {
                searchBar.text += text;
            }
        }

        function handleListMouseMove(listView, index, mouse) {
            var globalPos = listView.mapToGlobal(mouse.x, mouse.y);
            if (LauncherService.handleMouseMove(globalPos.x, globalPos.y))
                listView.currentIndex = index;
        }

        // Centralized Keyboard Handling
        Keys.onPressed: (event) => {
            var listView = getCurrentListView();
            if (event.key === Qt.Key_Down) {
                navigateDown();
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                navigateUp();
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                activateCurrentItem();
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                IslandService.closeAll();
                event.accepted = true;
            } else if (listView && listView.activeFocus) {
                if (event.key === Qt.Key_Delete) {
                    event.accepted = false; 
                    return;
                }
                
                var isSpecial = (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab || event.key === Qt.Key_Left || event.key === Qt.Key_Right);
                if (!isSpecial && event.text.length > 0) {
                    backToSearch(event.text);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Backspace) {
                    backToSearch("\b");
                    event.accepted = true;
                }
            }
        }

        anchors.fill: parent
        focus: true



        ColumnLayout {
            anchors.fill: parent
            spacing: Globals.geometry.spacing.large // Precise 12px gap between search and results

            LauncherSearch {
                id: searchBar


                // Dynamic Placeholder Binding
                placeholderText: root.currentPlaceholder

                activePageHints: {
                    var tab = root.getTab(root.currentTabIndex);
                    return (tab && tab.pageHints) ? tab.pageHints : [];
                }
                clickable: true
                Layout.fillWidth: true
                currentIndex: root.currentTabIndex
                onTabClicked: (index) => {
                    return root.switchTab(index);
                }
                
                visible: !root.isWallpaperActive
                Layout.preferredHeight: visible ? Globals.dimensions.launcherSearchHeight : 0

                
                inputItem.Keys.onLeftPressed: (event) => {
                    if (root.isWallpaperActive) {
                        root.navigateHorizontal(-1);
                        event.accepted = true;
                    } else {
                        event.accepted = false;
                    }
                }
                inputItem.Keys.onRightPressed: (event) => {
                     if (root.isWallpaperActive) {
                        root.navigateHorizontal(1);
                        event.accepted = true;
                    } else {
                        event.accepted = false;
                    }
                }

                onDownPressed: root.navigateDown()
                onPressedSignal: {
                    LauncherService.resetInputStates();
                    searchBar.focusInput();
                }
            }

            BaseSeparator {
                Layout.fillWidth: true
                visible: !root.isWallpaperActive && root.activeListCount > 0
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.isWallpaperActive || root.activeListCount > 0
                clip: true

                // Background removed for flat design


                // Dynamic Tab Loader Container
                FocusScope {
                    anchors.fill: parent

                    
                    Repeater {
                        id: tabRepeater
                        model: root.tabModel
                        
                        Loader {
                            id: tabLoader
                            anchors.fill: parent
                            
                            // Lazy loading logic: only load if active or previously loaded
                            property bool wasEverActive: false
                            active: (root.currentTabIndex === index) || wasEverActive
                            
                            onActiveChanged: {
                                if (active) wasEverActive = true;
                            }

                            source: modelData.component
                            
                            opacity: root.currentTabIndex === index ? 1 : 0
                            scale: root.currentTabIndex === index ? 1 : 0.98
                            z: root.currentTabIndex === index ? 1 : 0
                            
                            Behavior on opacity { BaseAnimation {} }
                            Behavior on scale { BaseAnimation { easing.type: Easing.OutBack } }

                            onLoaded: {
                                if (item) {
                                    // Connect signals
                                    item.closeRequested.connect(IslandService.closeAll);
                                    item.mouseMoveRequested.connect((index, mouse) => {
                                         root.handleListMouseMove(item.listView, index, mouse);
                                    });
                                    item.tabRedirectRequested.connect((targetIndex) => {
                                         Qt.callLater(() => {
                                             searchBar.text = "";
                                             root.switchTab(targetIndex);
                                         });
                                    });
                                    if (typeof item.searchTextUpdateRequested !== 'undefined') {
                                        item.searchTextUpdateRequested.connect((newText) => {
                                            searchBar.text = newText;
                                            searchBar.focusInput();
                                        });
                                    }
                                    
                                    // Bind properties
                                    item.searchText = Qt.binding(() => searchBar.text);
                                    item.isActive = Qt.binding(() => root.currentTabIndex === index);
                                }
                            }
                            
                            Connections {
                                target: tabLoader.item || null
                                function onCurrentItemChanged() {
                                    if (root.currentTabIndex === index) {
                                        root.currentItem = tabLoader.item.currentItem;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
