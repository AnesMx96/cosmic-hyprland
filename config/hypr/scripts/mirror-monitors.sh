#!/usr/bin/env bash

# Duplica la pantalla principal en cualquier monitor conectado adicional.
set -u

main_monitor="eDP-1"

for _ in {1..20}; do
    monitors="$(hyprctl monitors -j 2>/dev/null || true)"
    if [[ -n "$monitors" ]] && command -v jq >/dev/null 2>&1; then
        while IFS= read -r monitor; do
            [[ -z "$monitor" || "$monitor" == "$main_monitor" ]] && continue
            hyprctl keyword monitor "$monitor,preferred,auto,1,mirror,$main_monitor" >/dev/null
        done < <(printf '%s' "$monitors" | jq -r '.[].name')
        exit 0
    fi
    sleep 1
done

exit 1
