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
    name = "LOCA"; 
    theme = "catppuccin";

    desktop = {
      displayManager = "gdm";

      #enable = "hyprland";
      enable = "gnome";

      #hyprland = {
      #  monitors = [
      #    "HDMI-A-1, 1920x1080@60, 1920x0, 1"
      #    "DP-1, 1920x1080@60, 3840x0, 1"
      #    "DP-2, 1920x1080@60, 0x0, 1"
      #  ];

        #workspaces = [
        #  ### MAIN MONITOR ###
        #  "1,monitor:DP-3,persistent:true,default:true"
        #  "2,monitor:DP-3,persistent:true" 
        #  "3,monitor:DP-3,persistent:true" 
        #  "4,monitor:DP-3,persistent:true" 
        #  "5,monitor:DP-3,persistent:true" 
        #  "6,monitor:DP-3,persistent:true" 

        #  ### RIGHT MONITOR ###
        #  "7,monitor:DP-1,persistent:true,default:true"
        #  "8,monitor:DP-1,persistent:true"

        #  ### LEFT MONITOR ###
        #  "9,monitor:DVI-D-1,persistent:true,default:true"
        #  "10,monitor:DVI-D-1,persistent:true"
        #];
      #};
    };

    hardware = {
      openrgb.enable = true;
      cpu.vendor = "amd";
      gpu.vendor = "nvidia";

      gpu.nvidia.power-management.enable = true;
    };
  };

  userSettings = {
    name = "Esaias Westberg";
    username = "esaiaswestberg";
    email = "esaias@westbergs.se";
  };

  profiles = {
    dev.enable = true;
  };
  
  environment.systemPackages = with pkgs; (import ./packages.nix pkgs) ++ [
    # Add more packages directly here if needed
  ];

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
