{ config, lib, pkgs, ... }:

{
  options = {};

  config = {
    networking.hostName = config.systemSettings.name;

    # Enable networking
    networking.networkmanager.enable = true;
  };
}
