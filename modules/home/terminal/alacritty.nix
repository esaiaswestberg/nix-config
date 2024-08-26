{ config, osConfig, pkgs, lib, ... }:

{
  options = {};

  config = {
    programs.alacritty = {
      enable = true;
      settings = {
        window.startup_mode = "Maximized";

        # Set the shell to start TMUX
        shell = {
          program = "tmux";
          args = [ "new-session" "-A" "-s" "main" "zsh" ];
        };
      };
    };

    # Fix for alacritty creating weird errors when sshing
    programs.zsh.shellAliases."ssh" = "TERM=xterm-256color ssh";
  };
}