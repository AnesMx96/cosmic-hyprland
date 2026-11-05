#!/usr/bin/env bash
# ==================================================================
#  HYPRGRAVITY · instalador
#  EndeavourOS, Arch y derivadas: lo instala todo con una sola pregunta.
#  NixOS: usa el flake (ver README); este script solo copia la config.
#
#  Uso:  ./install.sh [opciones]
#    --yes       no pregunta nada
#    --dry-run   enseña lo que haría sin tocar nada
#    --link      enlaza en vez de copiar: un git pull lo actualiza todo
#    --no-deps   no instala paquetes, solo la config
#    --no-aur    no instala paquetes de AUR (mpvpaper, el fondo de pantalla)
# ==================================================================
set -eEuo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
DIRS=(hypr waybar rofi swayosd kitty cosmic-shell)
MIN_HYPR=0.57
LOG="$HOME/hyprgravity-install.log"
LINK=0 DEPS=1 AUR=1 YES=0 DRY=0

for a in "$@"; do
    case "$a" in
        --link) LINK=1 ;; --no-deps) DEPS=0 ;; --no-aur) AUR=0 ;;
        --yes|-y) YES=1 ;; --dry-run) DRY=1 ;;
        -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
        *) echo "Opción desconocida: $a" >&2; exit 1 ;;
    esac
done

c_info=$'\e[38;5;117m'; c_ok=$'\e[38;5;150m'; c_warn=$'\e[38;5;221m'; c_err=$'\e[38;5;210m'; c_bold=$'\e[1m'; c_off=$'\e[0m'
info() { printf '%s::%s %s\n' "$c_info" "$c_off" "$*"; }
ok()   { printf '%s ✓%s %s\n' "$c_ok" "$c_off" "$*"; }
warn() { printf '%s !%s %s\n' "$c_warn" "$c_off" "$*"; }
die()  { printf '%s ✗%s %s\n' "$c_err" "$c_off" "$*" >&2; exit 1; }
run()  { if [ "$DRY" = 1 ]; then printf '   [dry-run] %s\n' "$*"; else "$@"; fi; }
pkgs() { grep -vE '^\s*(#|$)' "$1"; }

cat <<EOF2

   ${c_info}·  ✦   ${c_off}${c_bold}H Y P R G R A V I T Y${c_off}${c_info}   ✦  ·${c_off}
      un agujero negro de verdad en tu Hyprland

EOF2

[ "$(id -u)" -ne 0 ] || die "No lo ejecutes como root ni con sudo: ejecútalo con tu usuario. La contraseña se pide cuando hace falta."

distro="other"
if [ -f /etc/NIXOS ] || grep -qi '^ID=nixos' /etc/os-release 2>/dev/null; then distro="nixos"
elif command -v pacman >/dev/null 2>&1; then distro="arch"; fi
info "Sistema detectado: $distro"

# ------------------------------------------------------------ la única pregunta
if [ "$YES" = 0 ] && [ "$DRY" = 0 ]; then
    cat <<EOF2

  Esto va a:
    1. Actualizar el sistema e instalar lo necesario (unos minutos, depende de tu conexión).
    2. Guardar tu config actual en una copia de seguridad.
    3. Instalar Hyprgravity y poner el modo oscuro.

  Tu escritorio actual no se borra: podrás elegirlo igual al iniciar sesión.

EOF2
    read -r -p "¿Empezamos? [S/n] " r
    [[ -z "$r" || "$r" =~ ^[sSyY] ]] || { info "Cancelado. No he tocado nada."; exit 0; }
fi

if [ "$DRY" = 0 ]; then
    exec > >(tee "$LOG") 2>&1
    trap 'printf "\n%s ✗%s Algo ha fallado en la línea %s.\n   Lo que pasó está en %s\n   Puedes volver a lanzar ./install.sh: es seguro repetirlo.\n" "$c_err" "$c_off" "$LINENO" "$LOG"' ERR
fi

# ------------------------------------------------------------ dependencias
need_dm=0
if [ "$DEPS" = 1 ]; then
    case "$distro" in
        arch)
            mapfile -t repo_pkgs < <(pkgs "$REPO/packages/arch.txt")
            [ -e /etc/systemd/system/display-manager.service ] || { need_dm=1; repo_pkgs+=(sddm); }
            info "Actualizando el sistema e instalando ${#repo_pkgs[@]} paquetes"
            if [ "$DRY" = 0 ]; then
                sudo -v
                # la contraseña no debe caducar a mitad de una compilación larga
                ( while sudo -n true 2>/dev/null; do sleep 50; done ) &
                keepalive=$!
                trap 'kill "$keepalive" 2>/dev/null || true' EXIT
            fi
            # en Arch no se instala sin actualizar: mezclar versiones rompe el sistema
            run sudo pacman -Syu --needed --noconfirm "${repo_pkgs[@]}"
            ok "Paquetes instalados"
            if [ "$AUR" = 1 ]; then
                mapfile -t aur_pkgs < <(pkgs "$REPO/packages/aur.txt")
                helper=""; for h in yay paru; do command -v "$h" >/dev/null && { helper=$h; break; }; done
                if [ -z "$helper" ]; then
                    info "Instalando yay para poder usar AUR"
                    if [ "$DRY" = 1 ]; then helper=yay; else
                        tmp="$(mktemp -d)"
                        git clone -q --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay" \
                            && ( cd "$tmp/yay" && makepkg -si --noconfirm ) && helper=yay
                        rm -rf "$tmp"
                    fi
                fi
                aur_ok=0
                case "$helper" in
                    yay) run yay -S --needed --noconfirm --answerclean None --answerdiff None "${aur_pkgs[@]}" && aur_ok=1 ;;
                    paru) run paru -S --needed --noconfirm --skipreview "${aur_pkgs[@]}" && aur_ok=1 ;;
                esac
                if [ "$aur_ok" = 1 ]; then ok "AUR: ${aur_pkgs[*]}"
                else warn "No pude instalar ${aur_pkgs[*]}: todo funciona menos el fondo de pantalla. Prueba luego: yay -S ${aur_pkgs[*]}"; fi
            fi
            if [ "$DRY" = 0 ]; then
                ver="$(hyprland --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || true)"
                if [ -z "$ver" ] || [ "$(printf '%s\n%s\n' "$MIN_HYPR" "$ver" | sort -V | head -1)" != "$MIN_HYPR" ]; then
                    die "Hace falta Hyprland $MIN_HYPR o superior y aquí hay ${ver:-ninguno}."
                fi
                ok "Hyprland $ver"
            fi ;;
        nixos)
            warn "En NixOS las dependencias van en el flake (README → NixOS). Sigo solo con la config." ;;
        *)
            warn "Esta distro no está soportada: instala a mano lo de packages/arch.txt. Sigo con la config." ;;
    esac
fi

# ------------------------------------------------------------ copia de seguridad + instalación
stamp="$(date +%Y%m%d-%H%M%S)"
backup="$CONFIG/hyprgravity-backup-$stamp"
run mkdir -p "$CONFIG"
info "Instalando la config en $CONFIG ($([ "$LINK" = 1 ] && echo enlaces || echo copia))"
for d in "${DIRS[@]}"; do
    src="$REPO/config/$d" dst="$CONFIG/$d"
    [ -d "$src" ] || continue
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$src" ]; then ok "$d ya enlazado"; continue; fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        run mkdir -p "$backup"
        run mv "$dst" "$backup/$d"
        warn "$d anterior guardado en $backup/$d"
    fi
    if [ "$LINK" = 1 ]; then run ln -s "$src" "$dst"; else run cp -a "$src" "$dst"; fi
    ok "$d"
done
# Conserva tus ajustes locales si los tenías
if [ -f "$backup/hypr/cfg/local.lua" ]; then run cp "$backup/hypr/cfg/local.lua" "$CONFIG/hypr/cfg/local.lua"; ok "Restaurado tu cfg/local.lua"; fi
for f in lock-bg.png lock-avatar.png; do
    if [ -f "$backup/hypr/$f" ]; then run cp "$backup/hypr/$f" "$CONFIG/hypr/$f"; fi
done

# ------------------------------------------------------------ archivos personales
H="$CONFIG/hypr"
if [ ! -f "$H/cfg/local.lua" ]; then
    run cp "$H/cfg/local.example.lua" "$H/cfg/local.lua"
    layout="$(localectl status 2>/dev/null | awk -F': ' '/X11 Layout|VC Keymap/{print $2}' | grep -vE '^\(?(unset|n/a)' | head -1 | cut -d, -f1 | tr -d ' ' || true)"
    if [ -n "$layout" ] && [ "$layout" != "es" ] && [ "$DRY" = 0 ]; then
        printf '\nhl.config({ input = { kb_layout = "%s" } })\n' "$layout" >> "$H/cfg/local.lua"
        ok "Teclado: $layout"
    fi
    ok "Creado cfg/local.lua"
fi
if command -v magick >/dev/null 2>&1 && [ "$DRY" = 0 ]; then
    [ -f "$H/lock-bg.png" ] || { magick "$H/assets/cosmic-wallpaper.jpg" "$H/lock-bg.png"; ok "Fondo de bloqueo generado"; }
    if [ ! -f "$H/lock-avatar.png" ]; then
        initial="$(printf '%s' "${USER:-c}" | cut -c1 | tr '[:lower:]' '[:upper:]')"
        magick -size 512x512 radial-gradient:'#9ccfff-#4a5be8' \
            \( -size 512x512 xc:none -fill white -draw "circle 256,256 256,0" \) -compose DstIn -composite \
            \( -size 512x512 xc:none -font Inter-Bold -pointsize 230 -fill '#06101f' -gravity center -annotate +0+8 "$initial" \) \
            -compose Over -composite "$H/lock-avatar.png" 2>/dev/null && ok "Avatar generado ($initial)" || warn "No pude generar el avatar; no pasa nada"
    fi
else
    [ -f "$H/lock-bg.png" ] || run cp "$H/assets/cosmic-wallpaper.jpg" "$H/lock-bg.png"
fi
run chmod +x "$H"/scripts/*.sh "$H"/scripts/*/*.sh "$CONFIG"/waybar/scripts/* 2>/dev/null || true
run "$H/scripts/glass/cosmic-dark.sh" && ok "Modo oscuro en todo el sistema" || warn "El modo oscuro se aplicará al entrar en Hyprland"

# ------------------------------------------------------------ servicios
if [ "$distro" = arch ] && [ "$DEPS" = 1 ]; then
    for s in NetworkManager bluetooth power-profiles-daemon; do
        if systemctl list-unit-files "$s.service" >/dev/null 2>&1 && ! systemctl is-enabled -q "$s" 2>/dev/null; then
            run sudo systemctl enable --now "$s" || warn "No pude activar $s"
        fi
    done
    # sin --now: arrancarla aquí cortaría la sesión en la que estás instalando
    if [ "$need_dm" = 1 ]; then run sudo systemctl enable sddm && ok "Pantalla de inicio de sesión (SDDM) activada"; fi
fi
# swaync robaría las notificaciones a la shell
if systemctl --user list-unit-files swaync.service >/dev/null 2>&1 && [ "$(systemctl --user is-enabled swaync 2>/dev/null || true)" != masked ]; then
    info "Desactivando swaync (Hyprgravity gestiona las notificaciones)"
    run systemctl --user mask swaync
fi

cat <<EOF2

${c_ok}${c_bold}  ✦ ¡Listo! Ya estás en el horizonte de sucesos.${c_off}

  ${c_bold}Lo que te falta:${c_off}
    1. Reinicia el ordenador.
    2. Al iniciar sesión, elige ${c_bold}Hyprland${c_off} en el selector de sesión.
    3. Pulsa ${c_bold}SUPER+F1${c_off} para ver todos los atajos (SUPER es la tecla de Windows).

  SUPER+Enter terminal · SUPER+Espacio apps · SUPER+N panel · SUPER+X apagar

  Registro de la instalación: $LOG
$( [ -d "$backup" ] && echo "  Tu config anterior: $backup" )

EOF2
