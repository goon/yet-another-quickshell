import QtQuick
import qs
pragma Singleton

QtObject {
    id: root

    // ── WHEEL STATE ──────────────────────────────────────────────────
    property real _wheelAcc: 0

    // ── KEYBOARD ROUTING ─────────────────────────────────────────────

    function handleKey(event) {
        var panel = IslandService.activePanelName;
        var item = IslandService.activePanelItem;

        if (panel === "launcher") {
            handleLauncherKey(event, item);
        } else if (panel === "clipboard") {
            handleClipboardKey(event, item);
        } else if (panel === "wallpaper") {
            handleWallpaperKey(event, item);
        }

        // Escape closes any panel
        if (event.key === Qt.Key_Escape) {
            IslandService.closeAll();
            event.accepted = true;
        }
    }

    // ── LAUNCHER ─────────────────────────────────────────────────────

    function handleLauncherKey(event, launcher) {
        if (!launcher) return;

        if (event.key === Qt.Key_Down) {
            launcher.navigateDown();
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            launcher.navigateUp();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            launcher.activateCurrentItem();
            event.accepted = true;
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
            if (launcher.isWallpaperActive) {
                launcher.navigateHorizontal(event.key === Qt.Key_Left ? -1 : 1);
                event.accepted = true;
            }
        } else if (launcher.getCurrentListView && launcher.getCurrentListView()
                   && launcher.getCurrentListView().activeFocus) {
            var listView = launcher.getCurrentListView();

            if (event.key === Qt.Key_Delete) {
                event.accepted = false;
                return;
            }

            var isSpecial = (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab
                             || event.key === Qt.Key_Left || event.key === Qt.Key_Right);
            if (!isSpecial && event.text.length > 0) {
                launcher.backToSearch(event.text);
                event.accepted = true;
            } else if (event.key === Qt.Key_Backspace) {
                launcher.backToSearch("\b");
                event.accepted = true;
            }
        }
    }

    // ── CLIPBOARD ────────────────────────────────────────────────────

    function handleClipboardKey(event, clipboard) {
        if (!clipboard) return;

        if (event.key === Qt.Key_Down) {
            if (clipboard.listView.count > 0) {
                if (clipboard.listView.currentIndex < 0)
                    clipboard.listView.currentIndex = 0;
                else if (clipboard.listView.currentIndex < clipboard.listView.count - 1)
                    clipboard.listView.currentIndex++;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Up) {
            if (clipboard.listView.count > 0 && clipboard.listView.currentIndex > 0) {
                clipboard.listView.currentIndex--;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (clipboard.currentItem) {
                Clipboard.pasteCliphistItem(clipboard.currentItem.rawLine);
                if (Preferences.clipboard.autoClose) {
                    IslandService.closeAll();
                }
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Delete) {
            if (clipboard.currentItem) {
                Clipboard.deleteCliphistItem(clipboard.currentItem.rawLine);
                if (clipboard.listView.currentIndex >= clipboard.listView.count - 1) {
                    clipboard.listView.currentIndex = Math.max(0, clipboard.listView.count - 2);
                }
            }
            event.accepted = true;
        }
    }

    // ── WALLPAPER ────────────────────────────────────────────────────

    function handleWallpaperKey(event, panel) {
        if (!panel) return;
        var carousel = panel.carouselItem || panel;
        if (!carousel || !carousel.move) return;

        if (event.key === Qt.Key_Left) {
            carousel.move(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            carousel.move(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (carousel.model && carousel.currentIndex >= 0
                    && carousel.currentIndex < carousel.model.length) {
                Wallpaper.setWallpaper(carousel.model[carousel.currentIndex].path);
                carousel.closeRequested();
            }
            event.accepted = true;
        }
    }

    // ── MOUSE WHEEL ROUTING ──────────────────────────────────────────

    function handleWheel(event) {
        var panel = IslandService.activePanelName;

        if (panel === "wallpaper") {
            var panelItem = IslandService.activePanelItem;
            var carousel = (panelItem && panelItem.carouselItem) ? panelItem.carouselItem : panelItem;
            if (carousel) {
                _wheelAcc += event.angleDelta.y / 120;
                var notches = Math.trunc(_wheelAcc);
                if (notches !== 0) {
                    carousel.move(-notches);
                    _wheelAcc -= notches;
                }
            }
            event.accepted = true;
        }
        // Launcher and Clipboard: Flickable handles scrolling natively,
        // so we do nothing here. The event propagates naturally.
    }

}
