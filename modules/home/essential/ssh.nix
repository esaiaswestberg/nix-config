{ config, osConfig, pkgs, lib, ... }:

{
  options = {};

  config = {
    programs.ssh = let
      standardFile = "~/.ssh/id_github";
    in {
      enable = true;
      matchBlocks = lib.mkIf (osConfig.profiles.work.enable) {
        "github.com" = {
          hostname = "github.com";
          identityFile = standardFile;
        };
      };
    };
  };
}