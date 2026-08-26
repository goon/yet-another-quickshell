import QtQuick
import QtQuick.Controls
import qs

ListView {
    id: root

    // Common Configuration
    spacing: Globals.geometry.spacing.large
    activeFocusOnTab: false
    
    // Disable highlight animations for snappier feel
    highlightMoveDuration: 0
    highlightResizeDuration: 0


    // Helper functions often used in tabs
    function safeIncrement() {
        if (currentIndex < count - 1) {
            incrementCurrentIndex();
        }
    }

    function safeDecrement() {
        if (currentIndex > 0) {
            decrementCurrentIndex();
        }
    }
}
