{ userName, ... }:
{
  imports = [
    ./software.nix
    ./gaming.nix
    ./terminal.nix
  ];

  home.username = userName;
  home.homeDirectory = "/home/${userName}";
  home.stateVersion = "25.11";
}
