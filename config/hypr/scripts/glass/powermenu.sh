#!/bin/sh
pkill -x rofi && exit 0
# Menú de Cosmic Shell; si la shell no está en marcha, el de rofi
qs -p "$HOME/.config/cosmic-shell" ipc call power toggle 2>/dev/null && exit 0
up=$(uptime -p | sed 's/up /Encendido: /;s/hours\?/h/;s/minutes\?/min/;s/days\?/d/')
sel=$(printf '%s|' "<span size='22pt'>󰌾</span>
Bloquear" "<span size='22pt'>󰤄</span>
Suspender" "<span size='22pt'>󰍃</span>
Salir" "<span size='22pt'>󰜉</span>
Reiniciar" "<span size='22pt'>󰐥</span>
Apagar" |
      rofi -dmenu -sep '|' -eh 3 -markup-rows -p "" -mesg "$up" -theme "$HOME/.config/rofi/power.rasi" -u 4 -format i) || exit 0
case "$sel" in
  0) hyprlock ;;
  1) systemctl suspend ;;
  2) hyprctl dispatch 'hl.dsp.exit()' ;;
  3) systemctl reboot ;;
  4) systemctl poweroff ;;
esac
