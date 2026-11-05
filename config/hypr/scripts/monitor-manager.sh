#!/usr/bin/env bash
# Conexión de pantallas y selector de modo (SUPER+SHIFT+M).
# La disposición normal sale de hyprland.lua y cfg/local.lua: aquí solo se pisa
# al elegir un modo, y "hyprctl reload" la devuelve a su estado.
set -u
wall="$HOME/.config/hypr/scripts/wallpaper.sh"

monitors() { hyprctl monitors all -j 2>/dev/null; }
main_output() { monitors | jq -r '([.[] | select(.name | test("^(eDP|LVDS|DSI)"))][0].name) // .[0].name // "eDP-1"'; }
external_outputs() { monitors | jq -r --arg main "$(main_output)" '.[] | select(.name != $main) | .name'; }
main_disabled() { monitors | jq -e --arg main "$(main_output)" 'any(.[]; .name == $main and .disabled)' >/dev/null; }

enable_output() { hyprctl eval "hl.monitor({ output = \"$1\", mode = \"preferred\", position = \"auto\", scale = 1${2:-} })" >/dev/null; }
disable_output() { hyprctl eval "hl.monitor({ output = \"$1\", disabled = true })" >/dev/null; }
restore_layout() { hyprctl reload >/dev/null; }

wallpaper() { "$wall" 0.4; }
restart_bar() {
    pgrep -x waybar >/dev/null || return 0   # si bar-auto la tiene oculta, sigue oculta
    pkill -x waybar; sleep 0.2
    waybar >/dev/null 2>&1 &
}

refresh() {
    # sin esto, desenchufar el monitor en "Solo monitor externo" deja la sesión sin pantalla
    if [[ -z "$(external_outputs)" ]] && main_disabled; then restore_layout; fi
    wallpaper; restart_bar
}

choose() {
    local choice main out
    main=$(main_output)
    [[ -z "$(external_outputs)" ]] && { notify-send 'Pantallas' 'No hay monitor externo conectado'; return; }
    choice=$(printf 'Extendido\nDuplicar\nSolo monitor externo\nSolo portátil' | rofi -dmenu -i -no-custom -p '󰍹  Modo de pantalla' -theme "$HOME/.config/rofi/monitor.rasi") || return
    case "$choice" in
        Extendido) restore_layout ;;
        Duplicar)
            restore_layout
            while IFS= read -r out; do
                [[ -n "$out" ]] && enable_output "$out" ", mirror = \"$main\""
            done < <(external_outputs) ;;
        'Solo monitor externo')
            # primero encender y luego apagar: nunca debe quedar la sesión sin salidas
            while IFS= read -r out; do
                [[ -n "$out" ]] && enable_output "$out"
            done < <(external_outputs)
            disable_output "$main" ;;
        'Solo portátil')
            enable_output "$main"
            while IFS= read -r out; do
                [[ -n "$out" ]] && disable_output "$out"
            done < <(external_outputs) ;;
        *) return ;;
    esac
    wallpaper; restart_bar
}

if [[ "${1:-watch}" == choose ]]; then choose; exit; fi

wallpaper
socket="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
socat -u "UNIX-CONNECT:$socket" - | while IFS= read -r event; do
    case "$event" in
        monitoradded\>*|monitorremoved\>*) sleep 1; refresh ;;
    esac
done
