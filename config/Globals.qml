import QtQuick
import Quickshell
import qs.services
pragma Singleton

QtObject {
    id: root

    // ── PATHS & EXTERNAL RESOURCES ───────────────────────────────────────
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string rootDir: homeDir + "/.config/yaks"
    readonly property string assetsDir: rootDir + "/assets"
    readonly property string dataDir: homeDir + "/.local/share/yaks"
    readonly property string cacheDir: homeDir + "/.cache/yaks"

    readonly property var activePalette: Theme.currentColors

    readonly property real shellScale: {
        if (Preferences.globals.scale === 0)
            return 0.9;
        if (Preferences.globals.scale === 1)
            return 1;
        if (Preferences.globals.scale === 2)
            return 1.1;
        return 1;
    }
    /*
     * =========================================================================
     *   🌈 SEMANTIC COLORS (UI Roles)
     *   Mirrors the flat semantic structure used in theme assets
     * =========================================================================
     */
    readonly property QtObject base16: QtObject {
        // ── BACKGROUNDS & SURFACES ────────────────────────────────────────
        readonly property color base00: root.activePalette.base00 || "#1e1e2d" // Default App Background
        readonly property color base01: root.activePalette.base01 || "#181824" // Lighter Background (Panels, Status Bars)
        readonly property color base02: root.activePalette.base02 || "#29293b" // Selection Background / Hover States
        readonly property color base03: root.activePalette.base03 || "#3d3d51" // Inactive Elements / Borders / Comments
        
        // ── FOREGROUNDS & TEXT ────────────────────────────────────────────
        readonly property color base04: root.activePalette.base04 || "#4f4f65" // Muted Text / Dark Foreground
        readonly property color base05: root.activePalette.base05 || "#CDD6F4" // Default Foreground / Standard Text
        readonly property color base06: root.activePalette.base06 || "#F5E0DC" // Light Foreground / Emphasized Text
        readonly property color base07: root.activePalette.base07 || "#B4BEFE" // Brightest Foreground / Active Text

        // ── BRAND & FEEDBACK COLORS ───────────────────────────────────────
        readonly property color base08: root.activePalette.base08 || "#F38BA8" // Red: Error, Destructive Actions
        readonly property color base09: root.activePalette.base09 || "#FAB387" // Orange: Warning, Alerts
        readonly property color base0A: root.activePalette.base0A || "#F9E2AF" // Yellow: Accent, Highlights
        readonly property color base0B: root.activePalette.base0B || "#A6E3A1" // Green: Success, Positive States
        readonly property color base0C: root.activePalette.base0C || "#94E2D5" // Cyan: Info, Active Indicators
        readonly property color base0D: root.activePalette.base0D || "#9d99e5" // Blue: Primary Brand Color, Links
        readonly property color base0E: root.activePalette.base0E || "#c199e5" // Purple/Magenta: Secondary Brand Color
        readonly property color base0F: root.activePalette.base0F || "#F2CDCD" // Brown: Tertiary Colors, Misc
    }

    readonly property QtObject
    colors: QtObject {
        // ── BRANDING & GRADIENTS ──────────────────────────────────────────
        readonly property color primary: root.activePalette.primaryIdx ? base16[root.activePalette.primaryIdx] : base16.base0D
        readonly property color secondary: root.activePalette.secondaryIdx ? base16[root.activePalette.secondaryIdx] : base16.base0E
        readonly property color accent: base16.base0A

        // ── FEEDBACK & ALERTS ─────────────────────────────────────────────
        readonly property color success: base16.base0B
        readonly property color warning: base16.base09
        readonly property color error: base16.base08
        readonly property color info: base16.base0C

        // ── BACKWARD COMPATIBILITY ALIASES ────────────────────────────────
        readonly property color base: base16.base00
        readonly property color background: base16.base01
        readonly property color surface: base16.base02
        readonly property color border: base16.base03
        readonly property color muted: base16.base04
        readonly property color text: base16.base05
        readonly property color textLighter: base16.base07

        // ── HELPERS ───────────────────────────────────────────────────────
        readonly property color transparent: "transparent"
    }

    readonly property QtObject opacity: QtObject {
        readonly property real background: Math.max(0.3, Preferences.globals.backgroundOpacity)
    }

    /*
     * =========================================================================
     *   📐 GEOMETRY (Style Tokens)
     * =========================================================================
     */
    readonly property QtObject geometry: QtObject {
        readonly property int radius: Preferences.globals.cornerRadius * root.shellScale
        readonly property QtObject spacing: QtObject {
            readonly property int small: 6 * root.shellScale
            readonly property int medium: 8 * root.shellScale
            readonly property int large: 12 * root.shellScale
            readonly property int xlarge: 18 * root.shellScale
        }

        readonly property QtObject padding: QtObject {
            readonly property int small: 8 * root.shellScale
            readonly property int medium: 14 * root.shellScale
            readonly property int large: 18 * root.shellScale
            readonly property int island: Math.max(22 * root.shellScale, Math.ceil(root.geometry.radius * 0.5))
        }

        readonly property QtObject innerRadius: QtObject {
            readonly property int small: root.geometry.radius === 0 ? 0 : Math.max(4 * root.shellScale, root.geometry.radius - root.geometry.spacing.small)
            readonly property int medium: root.geometry.radius === 0 ? 0 : Math.max(4 * root.shellScale, root.geometry.radius - root.geometry.spacing.medium)
            readonly property int large: root.geometry.radius === 0 ? 0 : Math.max(4 * root.shellScale, root.geometry.radius - root.geometry.spacing.large)
            readonly property int island: root.geometry.radius === 0 ? 0 : Math.max(4 * root.shellScale, root.geometry.radius - root.geometry.padding.island)
        }
    }

    /*
     * =========================================================================
     *   📏 DIMENSIONS (Component Sizing)
     * =========================================================================
     */
    readonly property QtObject
    dimensions: QtObject {
        readonly property int barItemHeight: 32 * root.shellScale
        readonly property int listItemHeight: 44 * root.shellScale
        readonly property int iconSmall: 16 * root.shellScale
        readonly property int iconBase: 18 * root.shellScale
        readonly property int iconMedium: 20 * root.shellScale
        readonly property int iconLarge: 32 * root.shellScale
        readonly property int iconExtraLarge: 48 * root.shellScale
        readonly property int calendarCellSize: 40 * root.shellScale
        readonly property int calendarBlockWidth: 320 * root.shellScale
        readonly property int launcherItemHeight: 54 * root.shellScale
        readonly property int launcherSearchHeight: 50 * root.shellScale
    }

    /*
     * =========================================================================
     *   🔡 TYPOGRAPHY
     * =========================================================================
     */
    readonly property QtObject
    typography: QtObject {
        readonly property string family: Preferences.globals.shellFont
        readonly property string iconFamily: "Material Symbols Rounded"
        readonly property QtObject
        weights: QtObject {
            readonly property int normal: 400
            readonly property int medium: 500
            readonly property int bold: 700
        }

        readonly property QtObject
        size: QtObject {
            readonly property int small: 12 * root.shellScale
            readonly property int base: 14 * root.shellScale
            readonly property int medium: 16 * root.shellScale
            readonly property int large: 18 * root.shellScale
            readonly property int display: 48 * root.shellScale
        }

    }

    /*
     * =========================================================================
     *   🎬 ANIMATIONS & EFFECTS
     * =========================================================================
     */
    readonly property QtObject
    animations: QtObject {
        readonly property int fast: 250
        readonly property int normal: 450
        readonly property int slow: 700
        readonly property int easingType: Easing.OutQuint
        readonly property var bezierCurve: [0.15, 0, 0, 1]
    }

    readonly property QtObject
    effects: QtObject {
        readonly property QtObject
        shadow: QtObject {
            readonly property color color: colors.base
            readonly property int radius: 20
            readonly property int samples: 20
            readonly property int offsetX: 0
            readonly property int offsetY: 0
        }
    }

    function alpha(c, a) {
        if (!c)
            return "transparent";

        return Qt.rgba(c.r, c.g, c.b, a);
    }

}
