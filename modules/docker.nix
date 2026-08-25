{ pkgs, userName, ... }:
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    package = pkgs.docker_29;
  };

  users.users.${userName}.extraGroups = [ "docker" ];

  environment.systemPackages = with pkgs; [
    docker-buildx
    docker-compose
  ];
}
