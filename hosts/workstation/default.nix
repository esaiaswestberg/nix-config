{ lib
, pkgs
, inputs
, hostName
, userName
, ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./luks.nix
    ../../modules/common.nix
    ../../modules/security.nix
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
      inherit inputs hostName userName;
    };
    users.${userName} = import ../../home/${userName};
  };

  system.stateVersion = "25.11";
}
