{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  # heroic depends on electron_39, which is marked insecure (EOL) upstream;
  # accepted until nixpkgs bumps heroic to a maintained electron version.
  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = "UTC";

  i18n.defaultLocale = "en_US.UTF-8";

  networking.networkmanager.enable = true;
  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = with pkgs; [
    curl
    fd
    git
    ripgrep
    vim
    wget
  ];
}
