#!/bin/sh
# Toggles del centro de control. Uso: cc-toggle.sh <wifi|bt|night> [state]
q() { "$@" >/dev/null 2>&1; }
case "$1" in
  wifi)
    if [ "$2" = state ]; then [ "$(nmcli radio wifi)" = enabled ] && echo true || echo false; exit 0; fi
    if [ "$SWAYNC_TOGGLE_STATE" = true ]; then q nmcli radio wifi on; else q nmcli radio wifi off; fi ;;
  bt)
    if [ "$2" = state ]; then bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo true || echo false; exit 0; fi
    if [ "$SWAYNC_TOGGLE_STATE" = true ]; then q bluetoothctl power on; else q bluetoothctl power off; fi ;;
  night)
    if [ "$2" = state ]; then pgrep -x hyprsunset >/dev/null && echo true || echo false; exit 0; fi
    if [ "$SWAYNC_TOGGLE_STATE" = true ]; then setsid -f hyprsunset -t 4500 >/dev/null 2>&1; else q pkill -x hyprsunset; fi ;;
esac
