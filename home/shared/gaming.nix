{ pkgs, ... }:
{
  home.packages = with pkgs; [
    heroic
    lutris
    mangohud
    protonup-qt
  ];
}
