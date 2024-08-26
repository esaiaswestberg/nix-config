{ config, osConfig, pkgs, lib, ... }:

{
  options = {};

  config = {
    programs.tmux = {
      enable = true;
    };
  };
}