# Módulo de home-manager: instala los programas y enlaza la config de Cosmic.
self:
{ config, lib, pkgs, ... }:
let
  cfg = config.cosmic;
  src = "${self}/config";
  dirs = [ "hypr" "waybar" "rofi" "swayosd" "kitty" "cosmic-shell" ];

  # Fondo de bloqueo y avatar (los originales del autor no van en el repo)
  lockBg = pkgs.runCommand "cosmic-lock-bg.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick ${src}/hypr/assets/cosmic-wallpaper.jpg $out
  '';
  avatar = pkgs.runCommand "cosmic-avatar.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick -size 512x512 radial-gradient:'#9ccfff-#4a5be8' \
      \( -size 512x512 xc:none -fill white -draw "circle 256,256 256,0" \) \
      -compose DstIn -composite $out
  '';
in {
  options.cosmic = {
    enable = lib.mkEnableOption "Cosmic (dotfiles de Hyprland)";

    localConfig = lib.mkOption {
      type = lib.types.lines;
      default = builtins.readFile "${src}/hypr/cfg/local.example.lua";
      description = "Contenido de ~/.config/hypr/cfg/local.lua (monitores, teclado…).";
      example = ''
        hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
        hl.config({ input = { kb_layout = "us" } })
      '';
    };

    lockBackground = lib.mkOption {
      type = lib.types.path;
      default = lockBg;
      description = "Imagen PNG para la pantalla de bloqueo.";
    };

    avatar = lib.mkOption {
      type = lib.types.path;
      default = avatar;
      description = "Imagen PNG cuadrada para el avatar de la pantalla de bloqueo.";
    };

    extraApps = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Instalar las apps que usan los atajos (Dolphin, Firefox, calendario).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Hyprland y compañía (Hyprland en sí lo activa el módulo de NixOS)
      hyprlock hypridle hyprsunset hyprpicker hyprpolkitagent
      # Shell, barra, menús
      quickshell waybar swayosd
      (rofi.override { plugins = [ rofi-emoji ]; })
      # Terminal, fondo
      kitty mpvpaper
      # Fuentes
      inter nerd-fonts.jetbrains-mono material-icons
      # Utilidades de los scripts
      brightnessctl playerctl pavucontrol networkmanagerapplet blueman
      cliphist wl-clipboard grim slurp wtype jq python3 imagemagick libnotify rsync
    ] ++ lib.optionals cfg.extraApps [ kdePackages.dolphin firefox gnome-calendar ];

    fonts.fontconfig.enable = true;

    # Cada carpeta de config/ se enlaza archivo a archivo (las carpetas siguen siendo escribibles)
    xdg.configFile = lib.mkMerge [
      (lib.genAttrs dirs (d: { source = "${src}/${d}"; recursive = true; }))
      {
        "hypr/cfg/local.lua".text = cfg.localConfig;
        "hypr/lock-bg.png".source = cfg.lockBackground;
        "hypr/lock-avatar.png".source = cfg.avatar;
      }
    ];
  };
}
