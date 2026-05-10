{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

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
