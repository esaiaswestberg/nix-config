{ pkgs, userName, ... }:
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  users.users.${userName}.extraGroups = [ "docker" ];

  environment.systemPackages = with pkgs; [
    docker-buildx
    docker-compose
  ];
}
