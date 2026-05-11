{
  imports = [
    ../esaiaswestberg/software.nix
    ../esaiaswestberg/gaming.nix
    ./browser.nix
    ../esaiaswestberg/terminal.nix
    ../esaiaswestberg/ssh.nix
  ];

  home.username = "filippawestberg";
  home.homeDirectory = "/home/filippawestberg";
  home.stateVersion = "25.11";
}
