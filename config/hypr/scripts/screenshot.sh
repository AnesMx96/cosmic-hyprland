#!/usr/bin/env bash
# Captura de zona. Por defecto la guarda en Imágenes/Screenshots; con --copy, al portapapeles.
# Cancelar con Esc no hace nada: si no, grim falla y wl-copy vacía el portapapeles.
area=$(slurp) || exit 0
if [ "${1:-}" = --copy ]; then
    file=$(mktemp --suffix=.png) || exit 1
    trap 'rm -f "$file"' EXIT
    grim -g "$area" "$file" && wl-copy --type image/png < "$file"
else
    dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Screenshots"
    mkdir -p "$dir"
    grim -g "$area" "$dir/$(date +'%Y-%m-%d_%H-%M-%S').png"
fi
