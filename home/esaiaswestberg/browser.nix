{ inputs, pkgs, ... }:
let
  zenBrowser = inputs.zen-browser.packages.${pkgs.system}.default;
in
{
  home.packages = [
    zenBrowser
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplicationPackages = [ zenBrowser ];
  };
}
