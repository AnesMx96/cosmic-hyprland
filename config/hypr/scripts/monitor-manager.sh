#!/usr/bin/env bash
set -u
main=$(hyprctl monitors -j 2>/dev/null | jq -r '([.[] | select(.name | test("^(eDP|LVDS|DSI)"))][0].name) // .[0].name // "eDP-1"')
wall="$HOME/.config/hypr/scripts/wallpaper.sh"
outputs() { hyprctl monitors -j 2>/dev/null | jq -r '.[].name'; }
external_outputs() { outputs | grep -vxF "$main" || true; }
restart_bar() { pkill -x waybar 2>/dev/null || true; waybar >/dev/null 2>&1 & }
wallpaper() { "$wall" 0.4; }

extend() {
    hyprctl keyword monitor "$main,preferred,0x0,1" >/dev/null
    while IFS= read -r out; do
        [[ -n "$out" ]] && hyprctl keyword monitor "$out,preferred,auto-right,1" >/dev/null
    done < <(external_outputs)
    wallpaper; restart_bar
}

refresh() {
    if [[ -z "$(external_outputs)" ]]; then
        hyprctl keyword monitor "$main,preferred,auto,1" >/dev/null
        wallpaper; restart_bar
    else
        extend
    fi
}

choose() {
    local choice
    [[ -z "$(external_outputs)" ]] && { notify-send 'Pantallas' 'No hay monitor externo conectado'; return; }
    choice=$(printf 'Extendido\nDuplicar\nSolo monitor externo\nSolo portátil' | rofi -dmenu -i -no-custom -p '󰍹  Modo de pantalla' -theme "$HOME/.config/rofi/monitor.rasi") || return
    case "$choice" in
        Extendido) extend ;;
        Duplicar)
            while IFS= read -r out; do
                [[ -n "$out" ]] && hyprctl keyword monitor "$out,preferred,auto,1,mirror,$main" >/dev/null
            done < <(external_outputs)
            wallpaper; restart_bar ;;
        'Solo monitor externo')
            hyprctl keyword monitor "$main,disable" >/dev/null
            while IFS= read -r out; do
                [[ -n "$out" ]] && hyprctl keyword monitor "$out,preferred,auto,1" >/dev/null
            done < <(external_outputs)
            wallpaper; restart_bar ;;
        'Solo portátil')
            while IFS= read -r out; do
                [[ -n "$out" ]] && hyprctl keyword monitor "$out,disable" >/dev/null
            done < <(external_outputs)
            hyprctl keyword monitor "$main,preferred,auto,1" >/dev/null
            wallpaper; restart_bar ;;
    esac
}

if [[ "${1:-watch}" == choose ]]; then choose; exit; fi
refresh
socket="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
exec socat -u "UNIX-CONNECT:$socket" - | while IFS= read -r event; do
    case "$event" in
        monitoradded\>*|monitorremoved\>*) sleep 1; refresh ;;
    esac
done
