{
  description = "Cosmic — dotfiles de Hyprland (config en Lua + Quickshell)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    # Lo del sistema: Hyprland, audio, red, Bluetooth, PAM de hyprlock
    nixosModules.default = import ./nix/nixos.nix;

    # Lo del usuario: paquetes + ~/.config enlazado desde este repo
    homeManagerModules.default = import ./nix/home.nix self;
  };
}
