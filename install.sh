#!/usr/bin/env bash
# ==================================================================
#  COSMIC · instalador
#  Arch Linux (y derivadas): instala dependencias y copia la config.
#  NixOS: usa el flake (ver README); este script solo copia la config.
#
#  Uso:  ./install.sh [opciones]
#    --link      enlaza (symlink) en vez de copiar: los cambios en el repo se aplican al momento
#    --no-deps   no instala paquetes, solo la config
#    --no-aur    no instala paquetes de AUR (mpvpaper)
#    --yes       no pregunta nada
#    --dry-run   enseña lo que haría sin tocar nada
# ==================================================================
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
DIRS=(hypr waybar rofi swayosd kitty cosmic-shell)
LINK=0 DEPS=1 AUR=1 YES=0 DRY=0

for a in "$@"; do
    case "$a" in
        --link) LINK=1 ;; --no-deps) DEPS=0 ;; --no-aur) AUR=0 ;;
        --yes|-y) YES=1 ;; --dry-run) DRY=1 ;;
        -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
        *) echo "Opción desconocida: $a" >&2; exit 1 ;;
    esac
done

c_info=$'\e[38;5;117m'; c_ok=$'\e[38;5;150m'; c_warn=$'\e[38;5;221m'; c_err=$'\e[38;5;210m'; c_off=$'\e[0m'
info() { printf '%s::%s %s\n' "$c_info" "$c_off" "$*"; }
ok()   { printf '%s ✓%s %s\n' "$c_ok" "$c_off" "$*"; }
warn() { printf '%s !%s %s\n' "$c_warn" "$c_off" "$*"; }
die()  { printf '%s ✗%s %s\n' "$c_err" "$c_off" "$*" >&2; exit 1; }
run()  { if [ "$DRY" = 1 ]; then printf '   [dry-run] %s\n' "$*"; else "$@"; fi; }
ask()  { [ "$YES" = 1 ] && return 0; read -r -p "$1 [S/n] " r; [[ -z "$r" || "$r" =~ ^[sSyY] ]]; }
pkgs() { grep -vE '^\s*(#|$)' "$1"; }

cat <<'EOF'

   ·  ✦      COSMIC  ·  Hyprland dotfiles      ✦  ·
      azul noche · cristal · Quickshell · Lua

EOF

[ "$(id -u)" -ne 0 ] || die "No lo ejecutes como root; usa tu usuario (pedirá sudo cuando haga falta)."

NC=(); [ "$YES" = 1 ] && NC=(--noconfirm)

# ------------------------------------------------------------ distro
distro="other"
if [ -f /etc/NIXOS ] || grep -qi '^ID=nixos' /etc/os-release 2>/dev/null; then distro="nixos"
elif command -v pacman >/dev/null 2>&1; then distro="arch"; fi
info "Sistema detectado: $distro"

# ------------------------------------------------------------ dependencias
if [ "$DEPS" = 1 ]; then
    case "$distro" in
        arch)
            mapfile -t repo_pkgs < <(pkgs "$REPO/packages/arch.txt")
            info "Paquetes oficiales: ${#repo_pkgs[@]}"
            if ask "¿Instalar/actualizar dependencias con pacman?"; then
                run sudo pacman -S --needed "${NC[@]}" "${repo_pkgs[@]}"
            fi
            if [ "$AUR" = 1 ]; then
                mapfile -t aur_pkgs < <(pkgs "$REPO/packages/aur.txt")
                helper=""; for h in paru yay; do command -v "$h" >/dev/null && { helper=$h; break; }; done
                if [ -n "$helper" ]; then
                    if ask "¿Instalar de AUR con $helper: ${aur_pkgs[*]}?"; then
                        run "$helper" -S --needed "${NC[@]}" "${aur_pkgs[@]}"
                    fi
                else
                    warn "No hay paru ni yay: instala a mano desde AUR: ${aur_pkgs[*]} (el fondo animado lo necesita)"
                fi
            fi ;;
        nixos)
            warn "En NixOS las dependencias van en el flake (README → NixOS). Sigo solo con la config." ;;
        *)
            warn "Distro no soportada para dependencias. Instala a mano lo de packages/arch.txt. Sigo con la config." ;;
    esac
fi

# ------------------------------------------------------------ copia de seguridad + instalación
stamp="$(date +%Y%m%d-%H%M%S)"
backup="$CONFIG/cosmic-backup-$stamp"
run mkdir -p "$CONFIG"
info "Instalando config en $CONFIG ($([ "$LINK" = 1 ] && echo enlaces || echo copia))"
for d in "${DIRS[@]}"; do
    src="$REPO/config/$d" dst="$CONFIG/$d"
    [ -d "$src" ] || continue
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$src" ]; then ok "$d ya enlazado"; continue; fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        run mkdir -p "$backup"
        run mv "$dst" "$backup/$d"
        warn "$d existente → $backup/$d"
    fi
    if [ "$LINK" = 1 ]; then run ln -s "$src" "$dst"; else run cp -a "$src" "$dst"; fi
    ok "$d"
done
# Conserva tus ajustes locales si los tenías
if [ -f "$backup/hypr/cfg/local.lua" ]; then run cp "$backup/hypr/cfg/local.lua" "$CONFIG/hypr/cfg/local.lua"; ok "Restaurado tu cfg/local.lua"; fi
for f in lock-bg.png lock-avatar.png; do
    [ -f "$backup/hypr/$f" ] && run cp "$backup/hypr/$f" "$CONFIG/hypr/$f"
done

# ------------------------------------------------------------ archivos personales
H="$CONFIG/hypr"
if [ ! -f "$H/cfg/local.lua" ]; then
    run cp "$H/cfg/local.example.lua" "$H/cfg/local.lua"
    layout="$(localectl status 2>/dev/null | awk -F': ' '/X11 Layout/{print $2}' | cut -d, -f1 | tr -d ' ')"
    if [ -n "$layout" ] && [ "$layout" != "es" ] && [ "$DRY" = 0 ]; then
        printf '\nhl.config({ input = { kb_layout = "%s" } })\n' "$layout" >> "$H/cfg/local.lua"
        ok "Teclado: $layout (en cfg/local.lua)"
    fi
    ok "Creado cfg/local.lua (edítalo para tus monitores)"
fi
if command -v magick >/dev/null 2>&1 && [ "$DRY" = 0 ]; then
    [ -f "$H/lock-bg.png" ] || { magick "$H/assets/cosmic-wallpaper.jpg" "$H/lock-bg.png"; ok "Fondo de bloqueo generado"; }
    if [ ! -f "$H/lock-avatar.png" ]; then
        initial="$(printf '%s' "${USER:-c}" | cut -c1 | tr '[:lower:]' '[:upper:]')"
        magick -size 512x512 radial-gradient:'#9ccfff-#4a5be8' \
            \( -size 512x512 xc:none -fill white -draw "circle 256,256 256,0" \) -compose DstIn -composite \
            \( -size 512x512 xc:none -font Inter-Bold -pointsize 230 -fill '#06101f' -gravity center -annotate +0+8 "$initial" \) \
            -compose Over -composite "$H/lock-avatar.png" 2>/dev/null && ok "Avatar generado ($initial)"
    fi
else
    [ -f "$H/lock-bg.png" ] || run cp "$H/assets/cosmic-wallpaper.jpg" "$H/lock-bg.png"
fi
run chmod +x "$H"/scripts/*.sh "$H"/scripts/*/*.sh "$CONFIG"/waybar/scripts/* 2>/dev/null || true
run "$H/scripts/glass/cosmic-dark.sh" && ok "Modo oscuro aplicado (GTK, Qt, KDE y Chromium)"

# ------------------------------------------------------------ servicios
if [ "$distro" = arch ] && [ "$DEPS" = 1 ]; then
    for s in NetworkManager bluetooth power-profiles-daemon; do
        if systemctl list-unit-files "$s.service" >/dev/null 2>&1 && ! systemctl is-enabled -q "$s" 2>/dev/null; then
            ask "¿Activar el servicio $s?" && run sudo systemctl enable --now "$s"
        fi
    done
fi
# swaync robaría las notificaciones a la shell
if systemctl --user list-unit-files swaync.service >/dev/null 2>&1 && [ "$(systemctl --user is-enabled swaync 2>/dev/null)" != masked ]; then
    info "Desactivando swaync (Cosmic Shell gestiona las notificaciones)"
    run systemctl --user mask swaync
fi

cat <<EOF

${c_ok}Listo.${c_off}
  · Entra en Hyprland (o recarga con SUPER+SHIFT+R).
  · Tus monitores y teclado: ${H}/cfg/local.lua
  · Fondo animado propio: copia un vídeo a ${H}/wallpaper.mp4
  · Chuleta de atajos: SUPER+F1
$( [ -d "$backup" ] && echo "  · Tu config anterior está en $backup" )

EOF
