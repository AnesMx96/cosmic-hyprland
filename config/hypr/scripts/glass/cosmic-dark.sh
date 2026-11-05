#!/bin/sh
# Modo oscuro en todo el sistema. Se puede lanzar las veces que haga falta.
# GTK y Electron leen gsettings y el portal; las apps de KDE, qt6ct y kdeglobals.
gtk=Breeze-Dark
[ -d /usr/share/themes/Breeze-Dark ] || gtk=Adwaita-dark
icons=breeze-dark

if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme "$gtk"
    gsettings set org.gnome.desktop.interface icon-theme "$icons"
    gsettings set org.gnome.desktop.interface cursor-theme breeze_cursors
fi

for f in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
    [ -f "$f" ] || { mkdir -p "$(dirname "$f")"; printf '[Settings]\n' > "$f"; }
    for pair in "gtk-application-prefer-dark-theme=true" "gtk-theme-name=$gtk" "gtk-icon-theme-name=$icons" "gtk-cursor-theme-name=breeze_cursors"; do
        k=${pair%%=*}
        if grep -q "^$k=" "$f"; then sed -i "s|^$k=.*|$pair|" "$(readlink -f "$f")"; else printf '%s\n' "$pair" >> "$f"; fi
    done
done

# Paleta oscura de Qt
c="$HOME/.config/qt6ct/qt6ct.conf"
if [ ! -f "$c" ]; then
    mkdir -p "$(dirname "$c")"
    printf '[Appearance]\ncolor_scheme_path=/usr/share/qt6ct/colors/darker.conf\ncustom_palette=true\nicon_theme=%s\nstyle=Breeze\n' "$icons" > "$c"
fi

# Apps de KDE: Kate, Okular, KCalc…
if command -v kwriteconfig6 >/dev/null && [ -f /usr/share/color-schemes/BreezeDark.colors ]; then
    kwriteconfig6 --file kdeglobals --group General --key ColorScheme BreezeDark
    kwriteconfig6 --file kdeglobals --group Icons --key Theme "$icons"
fi

# Chromium: interfaz oscura también en sus menús
f="$HOME/.config/chromium-flags.conf"
grep -q '^--force-dark-mode' "$f" 2>/dev/null || printf '%s\n' --force-dark-mode >> "$f"
