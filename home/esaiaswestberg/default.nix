{ userName, ... }:
{
  imports = [
    ./software.nix
    ./gaming.nix
    ./terminal.nix
    ./ssh.nix
  ];

  home.username = userName;
  home.homeDirectory = "/home/${userName}";
  home.stateVersion = "25.11";
}
