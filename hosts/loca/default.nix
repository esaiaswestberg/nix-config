{ lib
, pkgs
, inputs
, hostName
, userName
, secondaryUserName
, ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./luks.nix
    ../../modules/common.nix
    ../../modules/backup.nix
    ../../modules/desktop/ux.nix
    ../../modules/gaming.nix
    ../../modules/input.nix
    ../../modules/docker.nix
    ../../modules/shell.nix
    ../../modules/ssh-client-keys.nix
    ../../modules/security.nix
    ../../modules/vpn.nix
    ../../modules/desktop/cosmic.nix
    ../../modules/secrets.nix
    ../../modules/users.nix
  ];

  networking.hostName = hostName;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs hostName userName secondaryUserName;
    };
    users.${userName} = import ../../home/${userName};
    users.${secondaryUserName} = import ../../home/${secondaryUserName};
  };

  system.stateVersion = "25.11";
}
