#!/bin/sh

LC_ALL=C
export LC_ALL

THEME="$HOME/.config/rofi/wifi.rasi"
[ -f "$THEME" ] || THEME=""

B=""
for battery in /sys/class/power_supply/BAT*; do
  if [ -d "$battery" ]; then B=$battery; break; fi
done
[ -n "$B" ] || exit 0

rd() { cat "$B/$1" 2>/dev/null; }
is_uint() { case "$1" in ''|*[!0-9]*) return 1;; *) return 0;; esac; }

cap=$(rd capacity)
status=$(rd status)
energy_now=$(rd energy_now)
energy_full=$(rd energy_full)
energy_design=$(rd energy_full_design)
voltage=$(rd voltage_now)
power=$(rd power_now)
current=$(rd current_now)
cycles=$(rd cycle_count)
manufacturer=$(rd manufacturer)
model=$(rd model_name)

# Algunas baterías solo publican carga en µAh; conviértela a energía con el voltaje.
if ! is_uint "$energy_now" || ! is_uint "$energy_full"; then
  charge_now=$(rd charge_now)
  charge_full=$(rd charge_full)
  charge_design=$(rd charge_full_design)
  if is_uint "$voltage"; then
    is_uint "$energy_now" || { is_uint "$charge_now" && energy_now=$(awk -v c="$charge_now" -v v="$voltage" 'BEGIN { printf "%.0f", c*v/1000000 }'); }
    is_uint "$energy_full" || { is_uint "$charge_full" && energy_full=$(awk -v c="$charge_full" -v v="$voltage" 'BEGIN { printf "%.0f", c*v/1000000 }'); }
    is_uint "$energy_design" || { is_uint "$charge_design" && energy_design=$(awk -v c="$charge_design" -v v="$voltage" 'BEGIN { printf "%.0f", c*v/1000000 }'); }
  fi
fi

# Deriva potencia de corriente y voltaje si el kernel no expone power_now.
if ! is_uint "$power" || [ "$power" -eq 0 ] 2>/dev/null; then
  if is_uint "$current" && is_uint "$voltage"; then
    power=$(awk -v c="$current" -v v="$voltage" 'BEGIN { printf "%.0f", c*v/1000000 }')
  else
    power=""
  fi
fi

if ! is_uint "$cap" && is_uint "$energy_now" && is_uint "$energy_full" && [ "$energy_full" -gt 0 ]; then
  cap=$(awk -v n="$energy_now" -v f="$energy_full" 'BEGIN { printf "%d", n*100/f }')
fi
is_uint "$cap" || cap="?"

case "$status" in
  Charging) state="Cargando";;
  Discharging) state="En batería";;
  Full) state="Completa";;
  "Not charging") state="Conectada · sin cargar";;
  *) state="Conectada";;
esac

U=""
if command -v upower >/dev/null 2>&1; then
  device=$(upower -e 2>/dev/null | grep -i 'battery\|bat' | head -1)
  [ -n "$device" ] && U=$(upower -i "$device" 2>/dev/null)
fi
uv() { printf '%s\n' "$U" | sed -n "s/^[[:space:]]*$1:[[:space:]]*//p" | head -1; }

fmt_time() {
  awk -v s="$1" 'BEGIN {
    split(s, a, " "); value=a[1]+0; unit=a[2];
    if (unit ~ /^hour/) minutes=value*60;
    else if (unit ~ /^min/) minutes=value;
    else if (unit ~ /^day/) minutes=value*1440;
    else if (unit ~ /^sec/) minutes=value/60;
    else { print s; exit }
    minutes=int(minutes+0.5);
    printf "%dh %02dmin", int(minutes/60), minutes%60
  }'
}

eta=""
case "$status" in
  Discharging) eta=$(uv "time to empty");;
  Charging) eta=$(uv "time to full");;
esac
if [ -n "$eta" ]; then
  eta=$(fmt_time "$eta")
elif is_uint "$power" && [ "$power" -gt 0 ] 2>/dev/null; then
  case "$status" in
    Discharging)
      is_uint "$energy_now" && eta=$(awk -v e="$energy_now" -v p="$power" 'BEGIN { m=int(e/p*60+0.5); printf "%dh %02dmin", int(m/60), m%60 }')
      ;;
    Charging)
      if is_uint "$energy_now" && is_uint "$energy_full"; then
        remaining=$((energy_full - energy_now))
        [ "$remaining" -lt 0 ] && remaining=0
        eta=$(awk -v e="$remaining" -v p="$power" 'BEGIN { m=int(e/p*60+0.5); printf "%dh %02dmin", int(m/60), m%60 }')
      fi
      ;;
  esac
fi

rate=$(uv energy-rate | awk 'NF && $1 ~ /^[0-9]+([.][0-9]+)?$/ { printf "%.1f", $1; exit }')
if [ -z "$rate" ] && is_uint "$power"; then
  rate=$(awk -v p="$power" 'BEGIN { printf "%.1f", p/1000000 }')
fi
health=""
if is_uint "$energy_full" && is_uint "$energy_design" && [ "$energy_design" -gt 0 ]; then
  health=$(awk -v f="$energy_full" -v d="$energy_design" 'BEGIN { printf "%d%%", f*100/d }')
fi

msg="󰂎  BATERÍA  ${cap}%  ·  ${state}"
[ -n "$eta" ] && msg="$msg
󰥔  Tiempo estimado: $eta"
[ -n "$rate" ] && msg="$msg
󰓅  Potencia: ${rate} W"
if is_uint "$energy_now" && is_uint "$energy_full"; then
  energy_line=$(awk -v n="$energy_now" -v f="$energy_full" 'BEGIN { printf "󰋊  Energía: %.1f / %.1f Wh", n/1000000, f/1000000 }')
  msg="$msg
$energy_line"
fi
if [ -n "$health" ] || is_uint "$cycles"; then
  details="󰓢  Salud: ${health:-?}"
  is_uint "$cycles" && details="$details  ·  ${cycles} ciclos"
  msg="$msg
$details"
fi
if [ -n "$manufacturer$model" ]; then
  msg="$msg
󰍹  ${manufacturer:+$manufacturer }$model"
fi

current_profile=""
profiles=""
if command -v powerprofilesctl >/dev/null 2>&1; then
  current_profile=$(powerprofilesctl get 2>/dev/null) || current_profile=""
  profiles=$(powerprofilesctl list 2>/dev/null | sed -nE 's/^[[:space:]*]*([[:alnum:]_-]+):.*/\1/p')
fi

profile_label() {
  case "$1" in
    performance) printf 'Rendimiento';;
    balanced) printf 'Equilibrado';;
    power-saver) printf 'Ahorro de energía';;
    *) printf '%s' "$1";;
  esac
}
profile_hint() {
  case "$1" in
    performance) printf 'máxima respuesta';;
    balanced) printf 'uso diario';;
    power-saver) printf 'más autonomía';;
    *) printf 'perfil del sistema';;
  esac
}

menu=""
profile_ids=""
while IFS= read -r profile; do
  [ -n "$profile" ] || continue
  if [ "$profile" = "$current_profile" ]; then mark="●"; else mark="○"; fi
  row="$mark  $(profile_label "$profile")  ·  $(profile_hint "$profile")"
  if [ -n "$menu" ]; then menu="$menu
$row"; else menu=$row; fi
  if [ -n "$profile_ids" ]; then profile_ids="$profile_ids
$profile"; else profile_ids=$profile; fi
done <<EOF
$profiles
EOF

if [ -z "$menu" ]; then
  menu="󰅙  Perfiles de energía no disponibles"
  msg="$msg
No se pudo consultar power-profiles-daemon."
fi

if ! command -v rofi >/dev/null 2>&1; then
  command -v notify-send >/dev/null 2>&1 && notify-send -t 4000 "Batería" "$msg"
  exit 0
fi

set -- -dmenu -i -format i -no-custom -p "Energía" -mesg "$msg"
[ -n "$THEME" ] && set -- "$@" -theme "$THEME"
selected=$(printf '%s\n' "$menu" | rofi "$@" -theme-str "inputbar { enabled: false; }") || exit 0
[ -n "$selected" ] || exit 0
case "$selected" in *[!0-9]*) exit 0;; esac
[ -n "$profile_ids" ] || exit 0

profile=$(printf '%s\n' "$profile_ids" | sed -n "$((selected + 1))p")
[ -n "$profile" ] || exit 0
[ "$profile" != "$current_profile" ] || exit 0

if powerprofilesctl set "$profile"; then
  command -v notify-send >/dev/null 2>&1 && notify-send -t 2500 "Perfil de energía" "$(profile_label "$profile") · $(profile_hint "$profile")"
else
  command -v notify-send >/dev/null 2>&1 && notify-send -u critical -t 5000 "Perfil de energía" "No se pudo aplicar $(profile_label "$profile")."
fi
