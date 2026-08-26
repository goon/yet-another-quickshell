.pragma library

function generate(colors, opacity, mode, context) {
    const bg = colors.base00 || "#000000";
    const surface = colors.base01 || bg;
    const text = colors.base05 || "#ffffff";
    const textDim = colors.base04 || "#6a6a7a";
    const primary = colors[colors.primaryIdx] || colors.base0D;
    const accent = colors.base0A || primary;
    const cyan = colors.base0C || "#00ffff";

    const content = `{
  "wallpaper": "",
  "alpha": "100",
  "colors": {
    "color0": "${bg}",
    "color1": "${bg}",
    "color2": "${bg}",
    "color3": "${primary}",
    "color4": "${primary}",
    "color5": "${primary}",
    "color6": "${cyan}",
    "color7": "${surface}",
    "color8": "${bg}",
    "color9": "${bg}",
    "color10": "${primary}",
    "color11": "${primary}",
    "color12": "${primary}",
    "color13": "${accent}",
    "color14": "${cyan}",
    "color15": "${text}",
    "color16": "${text}",
    "color17": "${surface}",
    "color18": "${surface}",
    "color19": "${bg}"
  }
}`;

    return {
        destination: "~/.cache/yaks/themes/pywalfox.json",
        content: content,
        reloadCommand: "mkdir -p ~/.cache/wal && ln -sf ~/.cache/yaks/themes/pywalfox.json ~/.cache/wal/colors.json && (command -v pywalfox >/dev/null 2>&1 && pywalfox update || true)"
    };
}
