import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import "../lib/dynagen.js" as Generator

import "../lib/firefox.js" as FirefoxHook
import "../lib/kitty.js" as KittyHook
import "../lib/obsidian.js" as ObsidianHook
import "../lib/vesktop.js" as VesktopHook
import "../lib/nvim.js" as NvimHook
import "../lib/steam.js" as SteamHook
import "../lib/vscodium.js" as VscodiumHook
import "../lib/gtk.js" as GtkHook
import "../lib/qt.js" as QtHook
pragma Singleton

Item {
    id: root

    property bool ready: false
    property var currentColors: ({})

    // ── THEME LIST (declarative — no runtime loading) ─────────────────
    readonly property var allThemes: [
        { id: "pure",        name: "Pure"       },
        { id: "tinted",      name: "Tinted"     },
        { id: "monochrome",  name: "Monochrome" },
        { id: "pastel",      name: "Pastel"     },
    ]

    // Application metadata for theming
    readonly property var applications: [
        {
            "id": "gtk",
            "name": "GTK",
            "binary": "command -v gsettings"
        },
        {
            "id": "qt",
            "name": "Qt",
            "binary": "test -d ~/.config/Kvantum"
        },
        {
            "id": "kitty",
            "name": "Kitty",
            "binary": "command -v kitty"
        },
        {
            "id": "nvim",
            "name": "Neovim",
            "binary": "command -v nvim"
        },
        {
            "id": "obsidian",
            "name": "Obsidian",
            "binary": "command -v obsidian || flatpak info md.obsidian.Obsidian"
        },
        {
            "id": "vesktop",
            "name": "Vesktop",
            "binary": "command -v vesktop || flatpak info dev.vencord.Vesktop"
        },
        {
            "id": "firefox",
            "name": "Firefox",
            "binary": "command -v pywalfox"
        },
        {
            "id": "steam",
            "name": "Steam / Millennium",
            "binary": "command -v steam && test -d ~/.config/millennium"
        },
        {
            "id": "gowall",
            "name": "Gowall",
            "binary": "command -v gowall"
        },
        {
            "id": "vscodium",
            "name": "VSCode",
            "binary": "command -v codium || command -v vscodium"
        }
    ]

    // Canonical path that all hook scripts read colours from.
    readonly property string currentThemePath: Globals.cacheDir + "/current_theme"

    // ── STATE PROPERTIES (SYSTEM THEME) ──────────────────────────────
    property string gtkTheme: ""
    property string iconTheme: ""
    property string fontName: ""
    property string colorScheme: ""
    property var availableGtkThemes: []
    property var availableIconThemes: []
    property string cursorTheme: ""
    property int cursorSize: 24
    property var availableCursorThemes: []

    property var installedApps: ({})
    readonly property int debounceInterval: 300

    // ── THEME APPLICATION ─────────────────────────────────────────────

    function setTheme(id, silent = false) {
        Preferences.currentTheme = id;
        var seed = Preferences.globals.dynamicSeedColor;
        var bgL  = Preferences.globals.dynamicBgLightness;
        var hsl  = Generator.hexToHsl(seed);
        var themeData = null;

        if      (id === "pure")       themeData = Generator.generatePure(seed, hsl, bgL);
        else if (id === "tinted")     themeData = Generator.generateTinted(seed, hsl, bgL);
        else if (id === "monochrome") themeData = Generator.generateMonochrome(seed, hsl, bgL);
        else if (id === "pastel")     themeData = Generator.generatePastel(seed, hsl, bgL);

        if (!themeData) return;

        root.applyThemeColors(themeData);

        // Write to the single canonical path so all hook scripts read from one place.
        var jsonStr = JSON.stringify(themeData, null, 2);
        var targetFile = currentThemePath + "/colors.json";
        var tempFile = targetFile + ".tmp";
        var cmd = 'mkdir -p "$1" && printf "%s" "$2" > "$3" && mv "$3" "$4"';
        
        ProcessService.run(["sh", "-c", cmd, "--", currentThemePath, jsonStr, tempFile, targetFile], function() {
            root.triggerHooks(id, currentThemePath);
        });

        if (!silent) {
            var label = id.charAt(0).toUpperCase() + id.slice(1);
            ProcessService.runDetached(["notify-send", "-a", "Theme", "-i", "symbol:palette", "Theme",
                "The <b>" + label + "</b> palette has been applied."]);
        }
    }

    function applyThemeColors(data) {
        if (!data) return;
        root.currentColors = data;
        root.ready = true;
    }

    function loadDefaultFallback() {
        var seed = Preferences.globals.dynamicSeedColor;
        var bgL  = Preferences.globals.dynamicBgLightness;
        var hsl  = Generator.hexToHsl(seed);
        var themeData = Generator.generateTinted(seed, hsl, bgL);
        
        if (themeData) {
            currentColors = themeData;
        } else {
            // Absolute failsafe
            currentColors = {
                "base00": "#1e1e2d",
                "base01": "#181824",
                "base02": "#29293b",
                "base03": "#3d3d51",
                "base04": "#4f4f65",
                "base05": "#CDD6F4",
                "base06": "#F5E0DC",
                "base07": "#B4BEFE",
                "base08": "#F38BA8",
                "base09": "#FAB387",
                "base0A": "#F9E2AF",
                "base0B": "#A6E3A1",
                "base0C": "#94E2D5",
                "base0D": "#9d99e5",
                "base0E": "#c199e5",
                "base0F": "#F2CDCD",
                "primaryIdx": "base0D",
                "secondaryIdx": "base0E"
            };
        }
        ready = true;
    }

    // ── STARTUP ───────────────────────────────────────────────────────

    property bool _startupHooksRun: false
    function runStartupHooks() {
        if (_startupHooksRun || !Preferences.loaded) return;
        _startupHooksRun = true;
        // Always regenerate from seed + bgL — no palette cache needed.
        root.setTheme(Preferences.currentTheme, true);
    }

    // ── SYSTEM THEME SCANNING ─────────────────────────────────────────

    function refreshThemeService() {
        ProcessService.run(["gsettings", "get", "org.gnome.desktop.interface", "gtk-theme"], function(out) {
            root.gtkTheme = out.trim().replace(/'/g, "");
        });
        ProcessService.run(["gsettings", "get", "org.gnome.desktop.interface", "icon-theme"], function(out) {
            root.iconTheme = out.trim().replace(/'/g, "");
        });
        ProcessService.run(["gsettings", "get", "org.gnome.desktop.interface", "cursor-theme"], function(out) {
            root.cursorTheme = out.trim().replace(/'/g, "");
        });
        ProcessService.run(["gsettings", "get", "org.gnome.desktop.interface", "cursor-size"], function(out) {
            var val = parseInt(out.trim());
            root.cursorSize = isNaN(val) ? 24 : val;
        });
        ProcessService.run(["gsettings", "get", "org.gnome.desktop.interface", "font-name"], function(out) {
            root.fontName = out.trim().replace(/'/g, "");
        });
        ProcessService.run(["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"], function(out) {
            root.colorScheme = out.trim().replace(/'/g, "");
        });
    }

    function scanThemeServices() {
        const agnosticCmd = `
            echo "$XDG_DATA_DIRS:/usr/local/share:/usr/share" | tr ':' '\\n' | while read -r dir; do
                [ -d "$dir/themes" ] && find -L "$dir/themes" -mindepth 1 -maxdepth 1 -type d -printf '%f\\n' 2>/dev/null
                [ "$dir" = "$HOME/.themes" ] && find -L "$dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\\n' 2>/dev/null
            done | sort | uniq
        `;
        ProcessService.run(["sh", "-c", agnosticCmd], function(out) {
            root.availableGtkThemes = out.split('\n').filter(l => l.length > 0 && l !== "themes" && l[0] !== '.');
        });

        const agnosticIconsCmd = `
            echo "$XDG_DATA_DIRS:/usr/local/share:/usr/share" | tr ':' '\\n' | while read -r dir; do
                SDIR="$dir"
                [ -d "$dir/icons" ] && SDIR="$dir/icons"
                [ -d "$SDIR" ] && for d in "$SDIR"/*; do
                    [ -d "$d" ] && [ -f "$d/index.theme" ] && [ ! -d "$d/cursors" ] && [ ! -f "$d/cursor.theme" ] && basename "$d"
                done
            done 2>/dev/null | sort | uniq
        `;
        ProcessService.run(["sh", "-c", agnosticIconsCmd], function(out) {
            root.availableIconThemes = out.split('\n').filter(l => l.length > 0 && l !== "icons" && l[0] !== '.');
        });

        scanCursorThemes();
    }

    function scanCursorThemes() {
        const agnosticCursorsCmd = `
            echo "$XDG_DATA_DIRS:/usr/local/share:/usr/share" | tr ':' '\\n' | while read -r dir; do
                SDIR="$dir"
                [ -d "$dir/icons" ] && SDIR="$dir/icons"
                [ -d "$SDIR" ] && for d in "$SDIR"/*; do
                    [ -d "$d" ] && { [ -d "$d/cursors" ] || [ -f "$d/cursor.theme" ]; } && basename "$d"
                done
            done 2>/dev/null | sort | uniq
        `;
        ProcessService.run(["sh", "-c", agnosticCursorsCmd], function(out) {
            root.availableCursorThemes = out.split('\n').filter(l => l.length > 0);
        });
    }

    function toggleColorScheme() {
        var newScheme = (root.colorScheme === 'prefer-dark') ? 'default' : 'prefer-dark';
        ProcessService.run(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", newScheme], function() {
            refreshThemeService();
        });
    }

    property var allFontFamilies: []
    function updateFontFamilies() {
        const blacklist = /(mtx|math|private|opensymbol|stix|tex|pfont|noto sans .* [0-9])/i;
        root.allFontFamilies = Qt.fontFamilies().filter(font => !blacklist.test(font));
    }
    function getCleanFontFamilies() {
        if (allFontFamilies.length === 0) updateFontFamilies();
        return allFontFamilies;
    }

    // ── HOOK SERVICE ──────────────────────────────────────────────────

    function checkInstalledApps() {
        let newInstalled = {};
        let apps = root.applications;
        let completed = 0;
        apps.forEach(app => {
            ProcessService.run(["sh", "-c", app.binary + " > /dev/null 2>&1"], function(out, exitCode) {
                newInstalled[app.id] = (exitCode === 0);
                completed++;
                if (completed === apps.length) root.installedApps = newInstalled;
            });
        });
    }

    function triggerHooks(themeId, themePath, context = "manual") {
        executionTimer.pendingId      = themeId;
        executionTimer.pendingPath    = themePath;
        executionTimer.pendingContext = context;
        executionTimer.restart();
    }

    function executeHooks(id, path, context = "manual") {
        if (!Preferences.loaded) {
            console.warn("[Theme] Attempted to execute hooks before Preferences were loaded. Skipping.");
            return;
        }

        const hooks = {
            "firefox": FirefoxHook,
            "kitty": KittyHook,
            "obsidian": ObsidianHook,
            "vesktop": VesktopHook,
            "nvim": NvimHook,
            "steam": SteamHook,
            "vscodium": VscodiumHook,
            "gtk": GtkHook,
            "qt": QtHook
        };

        const opacity = Preferences.applications.themedAppsOpacity;
        const mode = Preferences.globals.themeMode;
        
        const hookContext = {
            font: Preferences.globals.shellFont,
            name: id,
            triggerContext: context
        };

        for (let i = 0; i < root.applications.length; i++) {
            let app = root.applications[i];
            
            // Skip disabled apps
            if (Preferences.applications.themedApps[app.id] !== true) continue;
            
            // Skip apps without a hook (e.g. gowall is handled internally by Gowall.qml)
            let hook = hooks[app.id];
            if (!hook) continue;

            let result = hook.generate(root.currentColors, opacity, mode, hookContext);
            if (!result) continue;

            let finalCommand = "";

            if (result.destination) {
                let dest = result.destination.replace(/^~/, "$HOME");
                let writeCmd = `mkdir -p $(dirname "${dest}") && printf '%s' "$1" > "${dest}"`;
                if (result.reloadCommand) {
                    writeCmd += ` && ${result.reloadCommand}`;
                }
                finalCommand = writeCmd;
            } else if (result.customCommand) {
                finalCommand = result.customCommand;
            }

            if (finalCommand !== "") {
                ProcessService.runDetached(["sh", "-c", finalCommand, "--", result.content || ""]);
            }
        }
    }

    property Timer executionTimer: Timer {
        interval: root.debounceInterval
        repeat: false
        property string pendingId: ""
        property string pendingPath: ""
        property string pendingContext: "manual"
        onTriggered: root.executeHooks(pendingId, pendingPath, pendingContext)
    }

    // ── CONNECTIONS ───────────────────────────────────────────────────

    Connections {
        target: Preferences
        function onLoadedChanged() {
            if (Preferences.loaded) root.runStartupHooks();
        }
    }

    Connections {
        target: Preferences.applications
        function onThemedAppsOpacityChanged() {
            if (Preferences.loaded)
                root.triggerHooks(Preferences.currentTheme, root.currentThemePath, "opacity_update");
        }
        function onThemedAppsChanged() {
            if (Preferences.loaded)
                root.triggerHooks(Preferences.currentTheme, root.currentThemePath, "app_toggle");
        }
    }

    Component.onCompleted: {
        refreshThemeService();
        scanThemeServices();
        checkInstalledApps();
        updateFontFamilies();
    }
}
