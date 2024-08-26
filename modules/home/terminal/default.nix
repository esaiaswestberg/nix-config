{ config, osConfig, pkgs, lib, ... }:

{
  imports = [
    ./alacritty.nix
    ./zsh.nix
    ./tmux.nix
  ];

  options = {};

  config = {
    programs.zoxide.enable = true;
  };
}
