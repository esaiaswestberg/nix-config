# This is the default configuration for the system
# It can be used as a template for other configurations
# The setup script will remove the  comments and replace the variables
# with the actual values

# It can be used as it is right now, but it's recommended to use the setup script
{ config, lib, pkgs, inputs, ...}:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/system
    ];

  systemSettings = {
    name = "SuperNix1337"; 
    theme = "catppuccin";

    desktop = {
      displayManager = "gdm";
    };

    dualBoot.enable = true;

    hardware = {
      openrgb.enable = true;
      cpu.vendor = "amd";
      gpu.vendor = "nvidia";

      gpu.nvidia.power-management.enable = true;
    };
  };

  userSettings = {
    name = "Felix Bjerhem Aronsson";
    username = "supergamer1337";
    email = "felix.b.aronsson@gmail.com";
  };

  profiles = {
    work.enable = true;
    dev.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  # Home manager state version
  home.initialStateVersion = "24.05";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
