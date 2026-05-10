{ pkgs, ... }:
{
  home.packages = with pkgs; [
    alejandra
    bat
    cmake
    direnv
    eza
    fd
    fzf
    gcc
    gnumake
    htop
    jq
    less
    man-pages
    nodejs
    nixd
    pkg-config
    python3
    ripgrep
    shellcheck
  ];
}
