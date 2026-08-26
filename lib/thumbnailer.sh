#!/usr/bin/env bash
set -euo pipefail

wpdir="${1:?usage: thumbnailer.sh <wpdir> <thumbdir>}"
thumbdir="${2:?usage: thumbnailer.sh <wpdir> <thumbdir>}"

if ! command -v magick &>/dev/null; then
    for p in /run/current-system/sw/bin /etc/profiles/per-user/*/bin /nix/var/nix/profiles/default/bin; do
        [ -x "$p/magick" ] && export PATH="$p:$PATH" && break
    done
fi
if ! command -v magick &>/dev/null; then
    _magick=$(find /nix/store -maxdepth 4 -name magick -path '*/bin/magick' -type f 2>/dev/null | tail -1)
    if [ -n "$_magick" ]; then
        export PATH="$(dirname "$_magick"):$PATH"
    fi
    unset _magick
fi

mkdir -p "$thumbdir"

for f in "$thumbdir"/*.png; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .png)"
    if ! find "$wpdir" -type f -name "$base" -print -quit | grep -q .; then
        rm -f "$f"
    fi
done

find "$wpdir" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) |
while IFS= read -r src; do
    thumb="$thumbdir/$(basename "$src").png"
    if [ ! -s "$thumb" ] || [ "$src" -nt "$thumb" ]; then
        if magick "${src}[0]" -strip -resize 512x "png:$thumb.tmp" 2>/dev/null; then
            mv "$thumb.tmp" "$thumb"
        else
            rm -f "$thumb.tmp"
        fi
    fi
done
