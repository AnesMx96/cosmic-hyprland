#!/bin/sh
c=$(hyprpicker -a -f hex) || exit 0
[ -n "$c" ] && notify-send -a "Cuentagotas" -i color-picker "Color copiado" "$c"
