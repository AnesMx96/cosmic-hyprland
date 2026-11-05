#!/bin/sh
# Lanzador de Cosmic Shell; si la shell no está en marcha, el de rofi
qs -p "$HOME/.config/cosmic-shell" ipc call launcher toggle 2>/dev/null ||
    exec rofi -show drun -theme "$HOME/.config/rofi/launcher-grid.rasi"
