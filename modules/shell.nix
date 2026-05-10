{ ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableBashCompletion = true;
    enableLsColors = true;
    vteIntegration = true;
    shellAliases = {
      c = "clear";
      cat = "bat";
      cb = "cliphist list | fzf | cliphist decode | wl-copy";
      g = "git";
      ga = "git add";
      gc = "git commit";
      gl = "git log --oneline --graph --decorate --all";
      gs = "git status -sb";
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

  programs.starship = {
    enable = true;
    interactiveOnly = true;
    settings = {
      add_newline = false;
      scan_timeout = 10;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
      directory = {
        truncation_length = 3;
        truncation_symbol = "…/";
      };
      git_branch = {
        symbol = " ";
      };
    };
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
}
