{ config, osConfig, pkgs, lib, ... }:

{
  imports = [
    ./desktop
    ./terminal
    ./essential
    ../../themes/home.nix
  ];

  options = {};

  config = {
    home.packages = with pkgs; lib.mkMerge [ 
      [
        # Essentials
        neovim
        microsoft-edge
        fastfetch
        zip
        unzip
        bat
        btop

        # Communication
        vesktop # Discord, modded.

        # Media
        plex-desktop

        # Development
        vscode-fhs
        nil # Nix LSP
        nixd # Alternative LSP

        # Utils
        bitwarden-desktop
      ]

      # Dev profile
      (lib.mkIf (osConfig.profiles.dev.enable) [
        jetbrains.webstorm
        jetbrains.goland
        dbeaver-bin
      ])
    ];
  };
}
