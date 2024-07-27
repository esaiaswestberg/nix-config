{ config, pkgs, lib, ...}:

{
  imports = [
    # Themes
    ../../themes

    # System
    ./essential
    ./services
    ./desktop
    ./fonts.nix
    ./programs.nix
    ./user.nix
  ];

  options = {
    # Profiles
    profiles.work.enable = lib.mkEnableOption "Enable work additions";
    profiles.dev.enable = lib.mkEnableOption "Enable dev additions";

    # System/host settings (using host to avoid conflicts with builtin system options)
    systemSettings.name = lib.mkOption {
      type = lib.types.str;
      default = "NixOS";
      description = "The name of the machine as it will appear in the network, and identified by flakes.";
    };

    systemSettings.configDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/${config.userSettings.username}/.nix-config";
      description = "The directory where the flake configuration is stored.";
    };
  };

  config = {
    # Enable CUPS to print documents.
    services.printing.enable = true;
  };
}