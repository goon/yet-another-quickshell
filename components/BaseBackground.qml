import QtQuick
import QtQuick.Shapes
import Quickshell
import qs

/**
 * BaseBackground - Standardized background component for top-level windows.
 * Used by Bar and BasePopoutWindow to provide consistent styling and support
 * for complex shapes and future effects like blur and opacity.
 */
Rectangle {
    id: root

    property color borderColor: Globals.colors.transparent
    property real borderWidth: 1

    color: Globals.alpha(Globals.colors.background, Globals.opacity.background)
    radius: Globals.geometry.radius
}
