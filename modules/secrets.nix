{ ... }:
{
  sops = {
    age.generateKey = true;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    defaultSopsFile = ../secrets/workstation.yaml;

    secrets = {
      "backup/restic/repository" = {
        owner = "root";
        group = "root";
        mode = "0400";
      };

      "backup/restic/password" = {
        owner = "root";
        group = "root";
        mode = "0400";
      };

      "backup/restic/ssh-key" = {
        path = "/root/.ssh/id_ed25519";
        owner = "root";
        group = "root";
        mode = "0600";
      };
    };
  };
}
