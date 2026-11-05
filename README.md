<div align="center">

# ✦ Cosmic

**Dotfiles de Hyprland con estética cósmica seria**
azul noche · blanco · acento cian · barra de cristal · todo lo demás sólido

Hyprland 0.57 (config en **Lua**) · Shell propia en **Quickshell** · Arch Linux y NixOS

> 🚧 **En desarrollo activo.** Funciona y lo uso a diario, pero voy añadiendo piezas.
> Mira el [estado](#estado) para ver qué está hecho y qué falta.

![Escritorio](screenshots/desktop.jpg)

</div>

## Capturas

| Centro de control | Lanzador |
|---|---|
| ![Centro de control](screenshots/control-center.jpg) | ![Lanzador](screenshots/launcher.jpg) |

| Pantalla de bloqueo |
|---|
| ![Bloqueo](screenshots/lockscreen.jpg) |

## Qué incluye

- **Barra (waybar) de cristal**: lanzador, escritorios, reloj con calendario del mes, volumen, brillo, Wi-Fi, Bluetooth, USB, batería con tooltip completo y campana de notificaciones.
- **Cosmic Shell (Quickshell)**: centro de control al estilo Material You, con toggles (Wi-Fi, Bluetooth, No molestar, luz nocturna, cafeína, modo juego), páginas de Wi-Fi y Bluetooth para conectarte desde ahí, sliders de volumen, micro y brillo, tarjeta de música con carátula y servidor de notificaciones propio con toasts animados.
- **Pantalla de bloqueo (hyprlock)**: diseño editorial con reloj grande, saludo, avatar, música y barra de estado (red, batería, clima).
- **Agujero negro en la GPU**: shader con lente gravitatoria real en el panel, el lanzador y el menú de apagado.
- **Lanzador (Quickshell)**: las apps salen en espiral del agujero negro.
- **Menú de apagado a pantalla completa**, visualizador de audio y anillos de CPU, memoria y temperatura.
- **Modo oscuro en todo el sistema**: GTK, Qt, KDE y Chromium.
- **Menús (rofi)**: Wi-Fi, emojis y chuleta de atajos generada a partir de tu config.
- **OSD (swayosd)** de volumen y brillo.
- **Gestos**: pellizco con 3 dedos = pantalla completa, 3 dedos a los lados = escritorios, 4 dedos = cambiar de ventana.
- **Detalles**: fondo de vídeo que se pausa cuando hay ventanas, luz nocturna, cuentagotas, modo juego, portapapeles, barra que se oculta sola.

## Instalación

### Arch Linux (y derivadas: EndeavourOS, CachyOS…)

```bash
git clone https://github.com/AnesMx96/cosmic-hyprland.git ~/cosmic
cd ~/cosmic
./install.sh
```

El instalador:
1. Instala las dependencias con `pacman` ([lista](packages/arch.txt)) y `mpvpaper` de AUR si tienes `paru` o `yay`.
2. **Guarda tu config actual** en `~/.config/cosmic-backup-FECHA/` antes de tocar nada.
3. Copia la config a `~/.config` y genera tu avatar, el fondo de bloqueo y `cfg/local.lua`, con tu distribución de teclado si no es `es`.
4. Ofrece activar NetworkManager, Bluetooth y power-profiles-daemon.

Opciones: `--link` (enlaza al repo en vez de copiar, así un `git pull` lo actualiza todo), `--no-deps`, `--no-aur`, `--yes` y `--dry-run` (muestra lo que haría sin tocar nada).

### NixOS (flake + home-manager) · *experimental*

> Los módulos están escritos con los nombres de paquete comprobados en nixpkgs, pero **aún no los he probado en un NixOS real**. Si algo falla, abre un issue.

```nix
# flake.nix de tu sistema
{
  inputs.cosmic.url = "github:AnesMx96/cosmic-hyprland";

  outputs = { nixpkgs, home-manager, cosmic, ... }: {
    nixosConfigurations.mipc = nixpkgs.lib.nixosSystem {
      modules = [
        cosmic.nixosModules.default
        { cosmic.enable = true; }

        home-manager.nixosModules.home-manager
        {
          home-manager.users.tu-usuario = {
            imports = [ cosmic.homeManagerModules.default ];
            cosmic.enable = true;
            # Tus monitores y teclado (opcional):
            cosmic.localConfig = ''
              hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
              hl.config({ input = { kb_layout = "us" } })
            '';
          };
        }
      ];
    };
  };
}
```

Necesita nixpkgs con **Hyprland ≥ 0.57**, porque la config está en Lua (`nixos-unstable`).

### Después de instalar

- **Monitores y teclado** → `~/.config/hypr/cfg/local.lua` (mira `cfg/local.example.lua`). Este archivo no se sube al repo.
- **Fondo animado propio** → copia un vídeo o una imagen a `~/.config/hypr/wallpaper.mp4` (o `.png`/`.jpg`). Si no hay ninguno, se usa el fondo incluido.
- **Avatar y fondo de bloqueo** → `~/.config/hypr/lock-avatar.png` y `~/.config/hypr/lock-bg.png`.

## Atajos principales

`SUPER+F1` muestra todos los atajos.

| Atajo | Acción |
|---|---|
| `SUPER+Enter` | Terminal (kitty) |
| `SUPER+Espacio` / `SUPER+R` | Lanzador en cuadrícula / todas las apps |
| `SUPER+E` | Archivos |
| `SUPER+N` | Centro de control |
| `SUPER+X` | Menú de apagado |
| `SUPER+L` | Bloquear |
| `SUPER+Q` | Cerrar ventana |
| `SUPER+F` / `SUPER+T` | Pantalla completa / flotante |
| `SUPER+1…0` | Escritorios |
| `SUPER+Z` | Scratchpad |
| `ALT+Tab` / `ALT+Shift+Tab` | Ventana siguiente / anterior |
| `SUPER+Shift+S` / `Impr` | Captura de zona |
| `SUPER+Shift+V` | Portapapeles |
| `SUPER+.` | Emojis |
| `SUPER+Shift+N` | Luz nocturna |
| `SUPER+G` | Modo juego |
| `SUPER+Shift+M` | Modo de pantalla (extendido, duplicado…) |

## Estructura

```
config/
  hypr/            Hyprland (hyprland.lua + cfg/*.lua), hyprlock, hypridle, scripts
  cosmic-shell/    Quickshell: centro de control y notificaciones
  waybar/  rofi/  swayosd/  kitty/
packages/          dependencias para Arch
nix/  flake.nix    módulos de NixOS y home-manager
install.sh         instalador
```

## Estado

- [x] Barra de cristal, centro de control, notificaciones, bloqueo, OSD, gestos
- [x] Instalador para Arch y flake para NixOS
- [x] Lanzador de apps en Quickshell
- [ ] Barra nueva en Quickshell
- [x] Menú de apagado en Quickshell
- [ ] OSD en Quickshell
- [ ] Probar el flake en un NixOS real

## Créditos

Inspirado en [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland), [caelestia](https://github.com/caelestia-dots/shell) y [HyDE](https://github.com/HyDE-Project/HyDE). No hay código copiado de ellos; la idea fue suya.
El fondo incluido (`config/hypr/assets/cosmic-wallpaper.jpg`) es original y se genera con ImageMagick.

## Licencia

[MIT](LICENSE)
