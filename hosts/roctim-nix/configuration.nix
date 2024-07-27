{ config, lib, pkgs, inputs, ...}:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/system
    ];

  # System settings 
  systemSettings = {
    name = "roctim-nix"; 
    theme = "candyland";
  };

  # User settings
  userSettings = {
    name = "Felix Bjerhem Aronsson";
    username = "felbjar";
    email = "felix.b.aronsson@gmail.com";
  };

  # Profiles
  profiles.work.enable = true;
  profiles.dev.enable = true;

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
