#!/usr/bin/env bash
# Fondo animado o estático con mpvpaper en todas las pantallas.
# Orden de búsqueda: $COSMIC_WALLPAPER · ~/.config/hypr/wallpaper.* · ~/Videos/Wallpapers/dark-black-hole.mp4 · fondo incluido
set -u
# las copias pueden estar congeladas (SIGSTOP) por wallpaper-pause.py: despertarlas y cerrarlas
pkill -CONT -x mpvpaper 2>/dev/null; pkill -x mpvpaper 2>/dev/null
for _ in 1 2 3 4 5; do pgrep -x mpvpaper >/dev/null || break; sleep 0.2; done
pkill -KILL -x mpvpaper 2>/dev/null || true
sleep "${1:-0.5}"
wall="${COSMIC_WALLPAPER:-}"
if [ -z "$wall" ]; then
    for f in "$HOME"/.config/hypr/wallpaper.{mp4,webm,mkv,png,jpg,jpeg} \
             "$HOME/Videos/Wallpapers/dark-black-hole.mp4" \
             "$HOME/.config/hypr/assets/cosmic-wallpaper.jpg"; do
        [ -f "$f" ] && { wall="$f"; break; }
    done
fi
[ -n "$wall" ] || exit 0
case "$wall" in
    *.png|*.jpg|*.jpeg) opts="no-audio image-display-duration=inf loop" ;;
    *) opts="no-audio loop hwdec=auto video-zoom=0.111" ;;
esac
mapfile -t outputs < <(hyprctl monitors -j 2>/dev/null | jq -r '.[].name')
for output in "${outputs[@]}"; do
    mpvpaper -p -o "$opts" "$output" "$wall" >/dev/null 2>&1 &
done
