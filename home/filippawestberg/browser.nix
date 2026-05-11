{ pkgs, ... }:
let
  chrome = pkgs.google-chrome;
in
{
  home.packages = [
    chrome
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplicationPackages = [ chrome ];
  };
}
