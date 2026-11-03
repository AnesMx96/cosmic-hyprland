#!/bin/sh
# Modo juego: quita animaciones, blur, sombras y huecos. Volver a pulsar restaura.
if hyprctl getoption animations.enabled | grep -q 'bool: true'; then
    hyprctl eval 'hl.config({ animations = { enabled = false }, general = { gaps_in = 0, gaps_out = 0, border_size = 1 }, decoration = { rounding = 0, active_opacity = 1.0, inactive_opacity = 1.0, shadow = { enabled = false }, blur = { enabled = false } } })' >/dev/null
    notify-send -a "Modo juego" -i input-gaming "Modo juego" "Activado · máximo rendimiento"
else
    hyprctl reload >/dev/null
    notify-send -a "Modo juego" -i input-gaming "Modo juego" "Desactivado"
fi
