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
	  lla = "ls -la";
          cd = "z";
	  update-channel = "sudo nix-channel --update";
          rebuild = "sudo nixos-rebuild switch --flake /home/esaiaswestberg/nix-config#LOCA";
	  dev = "nix develop -c $SHELL";
	  htop = "btop";

	  ssh-david = "ssh -i /home/esaiaswestberg/.ssh/id_david -o IdentitiesOnly=yes ubuntu@129.151.192.63";
	  ssh-lola = "ssh -i /home/esaiaswestberg/.ssh/id_lola -o IdentitiesOnly=yes ubuntu@158.179.203.194";
          ssh-linode = "ssh -i /home/esaiaswestberg/.ssh/id_linode -o IdentitiesOnly=yes root@172.232.134.132";
          ssh-intradisp = "ssh -i /home/esaiaswestberg/.ssh/intradisp -o IdentitiesOnly=yes intradisp@10.0.1.230";
          ssh-eloquentiastudios = "ssh -i /home/esaiaswestberg/.ssh/eloquentiastudios -o IdentitiesOnly=yes opc@129.151.220.30";
          ssh-eloquentia = "ssh-eloquentiastudios";
          ssh-jake = "ssh -i /home/esaiaswestberg/.ssh/id_github -o IdentitiesOnly=yes jake@10.0.0.100";
      };

      history = {
        size = 10000;
        path = "${config.xdg.dataHome}/zsh/history";
      };

      oh-my-zsh = {
        enable = true;
        plugins = [ "git" "direnv" ];
      };

      initExtra = ''
      	export ANDROID_HOME=$(dirname $(dirname $(readlink -f $(which adb))))
	export ANDROID_SDK_ROOT=$ANDROID_HOME
	export PATH=$PATH:/home/esaiaswestberg/go/bin
      '';
      
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
