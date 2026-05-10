{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = {
          x = 8;
          y = 8;
        };
        dynamic_padding = true;
        opacity = 0.98;
      };

      font = {
        normal.family = "JetBrains Mono";
        size = 12.0;
      };

      selection.save_to_clipboard = true;

      colors = {
        primary = {
          background = "0x111111";
          foreground = "0xe5e5e5";
        };
      };
    };
  };

  home.packages = with pkgs; [
    cliphist
    grim
    libnotify
    slurp
    swappy
    wl-clipboard
  ];
}
