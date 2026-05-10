{ userName, ... }:
{
  imports = [
    ./software.nix
    ./gaming.nix
  ];

  home.username = userName;
  home.homeDirectory = "/home/${userName}";
  home.stateVersion = "25.11";

  programs.git.enable = true;
  programs.zsh.enable = true;
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  programs.starship.enable = true;
}
