{
  imports = [
    ./software.nix
    ./gaming.nix
    ./terminal.nix
    ./ssh.nix
  ];

  home.username = "esaiaswestberg";
  home.homeDirectory = "/home/esaiaswestberg";
  home.stateVersion = "25.11";
}
