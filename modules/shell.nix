{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableBashCompletion = true;
    enableLsColors = true;
    vteIntegration = true;
    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    ohMyZsh = {
      enable = true;
      plugins = [
        "docker"
        "direnv"
        "fzf"
        "git"
        "sudo"
      ];
    };
    shellAliases = {
      c = "clear";
      cat = "bat";
      cb = "cliphist list | fzf | cliphist decode | wl-copy";
      d = "docker";
      dc = "docker compose";
      dps = "docker ps";
      g = "git";
      ga = "git add";
      gc = "git commit";
      gl = "git log --oneline --graph --decorate --all";
      gs = "git status -sb";
      nrb = "sudo nixos-rebuild build --flake .#loca";
      nrs = "sudo nixos-rebuild switch --flake .#loca";
      la = "eza -a --group-directories-first";
      ll = "eza -lah --group-directories-first";
      ls = "eza --group-directories-first";
      t = "tmux new -A -s main";
      shot = "grim -g \"$(slurp)\" - | swappy -f -";
    };
    interactiveShellInit = ''
      export EDITOR=vim
      export VISUAL=vim
      export PAGER=less
      export LESS='-R'
      export FZF_DEFAULT_COMMAND='fd --hidden --follow --exclude .git'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
      export FZF_ALT_C_COMMAND='fd --hidden --follow --exclude .git --type d'
      setopt AUTO_CD
      setopt HIST_IGNORE_ALL_DUPS
      setopt SHARE_HISTORY
      setopt INTERACTIVE_COMMENTS
    '';
  };

  programs.fzf = {
    keybindings = true;
    fuzzyCompletion = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    flags = [ "--cmd" "cd" ];
  };

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    baseIndex = 1;
    clock24 = true;
    escapeTime = 0;
    terminal = "tmux-256color";
    extraConfig = ''
      set -g mouse on
      set -g history-limit 100000
      set -g focus-events on
      set -g renumber-windows on
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  environment.systemPackages = with pkgs; [
    zsh-powerlevel10k
  ];
}
