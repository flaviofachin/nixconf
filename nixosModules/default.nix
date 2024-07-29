{
  pkgs,
  config,
  lib,
  inputs,
  outputs,
  myLib,
  ...
}: let
  cfg = config.myNixOS;

  # Taking all modules in the directories specified and adding enables to them
  magDirs = mylib.magicDirs ["features" "bundles" "services"];
in {
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
    ]
    ++ magDirs.features
    ++ magDirs.bundles
    ++ magDirs.services;

  options.myNixOS = {
    hyprland.enable = lib.mkEnableOption "enable hyprland";
  };

  config = {
    nix.settings.experimental-features = ["nix-command" "flakes"];
    programs.nix-ld.enable = true;
    nixpkgs.config.allowUnfree = true;
  };
}
