#!/usr/bin/env bash
# scripts/gtk4.sh
# This script is triggered by Quickshell's ThemeService.
# Args: $1 = theme_id, $2 = theme_path

THEME_ID="$1"
THEME_PATH="$2"
CONTEXT="$3"
OPACITY="${4:-1.0}"
MODE="${5:-dark}"
COLORS_JSON="$THEME_PATH/colors.json"

if [ ! -f "$COLORS_JSON" ]; then
    echo "Colors file not found: $COLORS_JSON"
    exit 1
fi

get_color_raw() {
    grep "\"$1\":" "$COLORS_JSON" | sed -E 's/.*:[[:space:]]*"([^"]*)".*/\1/' | head -n 1
}

get_color() {
    local key="$1"
    case "$key" in
        "background"|"base") key="base00" ;;
        "surface"|"surfaceAlt") key="base01" ;;
        "border"|"divider") key="base03" ;;
        "textDim"|"muted") key="base04" ;;
        "text") key="base05" ;;
        "error") key="base08" ;;
        "warning") key="base09" ;;
        "accent") key="base0A" ;;
        "success") key="base0B" ;;
        "info") key="base0C" ;;
        "primary") key="primaryIdx" ;;
        "secondary") key="secondaryIdx" ;;
    esac
    
    local val=$(get_color_raw "$key")
    if [[ "$val" == base* ]]; then
        get_color_raw "$val"
    else
        echo "$val"
    fi
}

hex_to_rgba() {
    local hex="$1"
    local alpha="$2"
    # Remove # if present
    hex=${hex#\#}
    # Ensure it's a 6-digit hex
    if [ ${#hex} -ne 6 ]; then
        echo "$1"
        return
    fi
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "rgba($r, $g, $b, $alpha)"
}

BG=$(get_color "background")
SURFACE=$(get_color "surface")
TEXT=$(get_color "text")
PRIMARY=$(get_color "primary")
ACCENT=$(get_color "accent")

ERROR=$(get_color "error")
WARNING=$(get_color "warning")
SUCCESS=$(get_color "success")

# Fallbacks if colors are missing
[ -z "$BG" ] && BG=$(get_color "base")
[ -z "$ACCENT" ] && ACCENT="$PRIMARY"
[ -z "$ERROR" ] && ERROR="#ff5555"
[ -z "$WARNING" ] && WARNING="#ffcc00"
[ -z "$SUCCESS" ] && SUCCESS="#55ff55"

# RGBA variants for background elements
BG_RGBA=$(hex_to_rgba "$BG" "$OPACITY")
SURFACE_RGBA=$(hex_to_rgba "$SURFACE" "$OPACITY")

# --- 1. Template & CSS Generation ---

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TEMPLATE_DIR="$SCRIPT_DIR/../assets/themes"

apply_template() {
    local template_file="$1"
    local output_file="$2"
    
    if [ ! -f "$template_file" ]; then
        echo "Template not found: $template_file"
        return 1
    fi
    
    local content=$(cat "$template_file")
    
    # Replace placeholders using bash string replacement
    content="${content//\{\{ACCENT\}\}/$ACCENT}"
    content="${content//\{\{BG\}\}/$BG}"
    content="${content//\{\{ERROR\}\}/$ERROR}"
    content="${content//\{\{WARNING\}\}/$WARNING}"
    content="${content//\{\{SUCCESS\}\}/$SUCCESS}"
    content="${content//\{\{BG_RGBA\}\}/$BG_RGBA}"
    content="${content//\{\{SURFACE_RGBA\}\}/$SURFACE_RGBA}"
    content="${content//\{\{TEXT\}\}/$TEXT}"
    content="${content//\{\{OPACITY\}\}/$OPACITY}"
    
    echo "$content" > "$output_file"
    chmod 644 "$output_file"
}

# Apply to GTK 4.0 (Libadwaita)
GTK4_DIR="$HOME/.config/gtk-4.0"
GTK4_THEME_CSS="$GTK4_DIR/quickshell.css"
GTK4_MAIN_CSS="$GTK4_DIR/gtk.css"
GTK4_DARK_CSS="$GTK4_DIR/gtk-dark.css"

mkdir -p "$GTK4_DIR"
apply_template "$TEMPLATE_DIR/gtk4.css" "$GTK4_THEME_CSS"

IMPORT_LINE='@import url("quickshell.css");'
safe_write_import "$GTK4_MAIN_CSS" "$IMPORT_LINE"
safe_write_import "$GTK4_DARK_CSS" "$IMPORT_LINE"

# Apply to GTK 3.0
GTK3_DIR="$HOME/.config/gtk-3.0"
GTK3_THEME_CSS="$GTK3_DIR/quickshell.css"
GTK3_MAIN_CSS="$GTK3_DIR/gtk.css"

mkdir -p "$GTK3_DIR"
apply_template "$TEMPLATE_DIR/gtk3.css" "$GTK3_THEME_CSS"
safe_write_import "$GTK3_MAIN_CSS" "$IMPORT_LINE"


# --- 3. Update gsettings ---
# MODE is $5 (captured above)
TARGET_GTK_THEME="adw-gtk3-dark"
COLOR_SCHEME="prefer-dark"

if [ "$MODE" = "light" ]; then
    TARGET_GTK_THEME="adw-gtk3"
    COLOR_SCHEME="prefer-light"
fi

# Apply the theme if it exists
if ls /usr/share/themes | grep -q "$TARGET_GTK_THEME"; then
    dconf write /org/gnome/desktop/interface/gtk-theme "'$TARGET_GTK_THEME'"
fi

dconf write /org/gnome/desktop/interface/color-scheme "'$COLOR_SCHEME'"

# --- 4. Force Reload (Contrast Trick) ---
if [ "$CONTEXT" != "startup" ]; then
    dconf write /org/gnome/desktop/a11y/interface/high-contrast true
    sleep 0.1
    dconf write /org/gnome/desktop/a11y/interface/high-contrast false
fi

echo "GTK Theme sync completed for $THEME_ID (Mode: $MODE)"

