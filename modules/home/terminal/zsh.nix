{ config, osConfig, pkgs, lib, ... }:

{
  options = {};

  config = {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
          ll = "ls -l";
          la = "ls -a";
          cd = "z";
          rebuild = "sudo nixos-rebuild switch --flake /home/esaiaswestberg/nix-config#LOCA";
	  dev = "nix develop -c $SHELL";
      };

      history = {
        size = 10000;
        path = "${config.xdg.dataHome}/zsh/history";
      };

      oh-my-zsh = {
        enable = true;
        plugins = [ "git" "direnv" ];
      };
      
      plugins = [
      	{
	  name = "zsh-nix-shell";
	  file = "nix-shell.plugin.zsh";
	  src = pkgs.fetchFromGitHub {
	    owner = "chisui";
	    repo = "zsh-nix-shell";
	    rev = "v0.8.0";
	    sha256 = "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7";
	  };
	}
      ];
    };

    programs.oh-my-posh = {
      enable = true;
      enableZshIntegration = true;
      useTheme = "catppuccin";
    };
  };
}
