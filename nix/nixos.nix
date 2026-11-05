# Módulo de NixOS: servicios de sistema que necesita Cosmic.
{ config, lib, pkgs, ... }:
let cfg = config.cosmic;
in {
  options.cosmic.enable = lib.mkEnableOption "Cosmic (servicios de sistema para Hyprland)";

  config = lib.mkIf cfg.enable {
    programs.hyprland.enable = true;          # Hyprland >= 0.57 (config en Lua)
    security.pam.services.hyprlock = { };     # para que hyprlock pueda desbloquear

    networking.networkmanager.enable = lib.mkDefault true;
    hardware.bluetooth.enable = lib.mkDefault true;
    services.blueman.enable = lib.mkDefault true;
    services.power-profiles-daemon.enable = lib.mkDefault true;
    services.upower.enable = lib.mkDefault true;   # batería en la shell
    services.udisks2.enable = lib.mkDefault true;  # montar USB desde la barra

    services.pipewire = {
      enable = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
      wireplumber.enable = lib.mkDefault true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    fonts.packages = with pkgs; [ inter nerd-fonts.jetbrains-mono material-icons ];
  };
}
