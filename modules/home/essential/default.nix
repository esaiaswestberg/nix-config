{ config, pkgs, lib, ... }:

{
  imports = [
    ./git.nix
    ./ssh.nix
  ];

  options = {};

  config = {};
}