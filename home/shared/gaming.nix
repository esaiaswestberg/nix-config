{ pkgs, ... }:
{
  home.packages = with pkgs; [
    heroic
    lutris
    mangohud
    prismlauncher
    protonup-qt
  ];
}
