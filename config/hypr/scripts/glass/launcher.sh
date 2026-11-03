#!/bin/sh
# Lanzador en cuadrícula de cristal (botón izquierdo de waybar)
pkill -x rofi && exit 0
THEME="$HOME/.config/rofi/launcher-grid.rasi"
entries='Archivos|system-file-manager|dolphin
Terminal|utilities-terminal|kitty
Firefox|firefox|firefox
WhatsApp|/usr/share/icons/Qogir/scalable/apps/whatsapp.svg|$HOME/.config/hypr/scripts/glass/whatsapp.sh
Telegram|org.telegram.desktop|Telegram
VS Code|vscode|code
Nautilus|org.gnome.Nautilus|nautilus
Kate|kate|kate
Calculadora|accessories-calculator|kcalc
Monitor|utilities-system-monitor|kitty --class btop -e btop
LibreOffice|libreoffice-startcenter|libreoffice
Máquinas|virt-manager|virt-manager
Ajustes|preferences-system|systemsettings
Todas|view-app-grid-symbolic|ALL'
sel=$(printf '%s\n' "$entries" | while IFS='|' read -r n i c; do printf '%s\0icon\x1f%s\n' "$n" "$i"; done |
      rofi -dmenu -i -p "󰣇" -theme "$THEME" -format i) || exit 0
cmd=$(printf '%s\n' "$entries" | sed -n "$((sel+1))p" | cut -d'|' -f3)
if [ "$cmd" = ALL ]; then
    exec rofi -show drun -theme "$THEME" -theme-str 'listview { lines: 4; }'
fi
setsid -f sh -c "$cmd" >/dev/null 2>&1
