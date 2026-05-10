{ userName, pkgs, ... }:
{
  users.users.${userName} = {
    isNormalUser = true;
    description = userName;
    initialPassword = "nixos";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.zsh;
  };
}
