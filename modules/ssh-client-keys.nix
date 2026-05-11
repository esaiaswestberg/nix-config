{ lib, pkgs, hostName, userName, secondaryUserName, ... }:
let
  userNames = [
    userName
    secondaryUserName
  ];
in
{
  systemd.services = lib.listToAttrs (map (name: {
    name = "generate-ssh-client-key-${name}";
    value = {
      description = "Generate the default SSH client key for ${name} if missing";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      unitConfig.ConditionPathExists = "!/home/${name}/.ssh/id_ed25519";
      serviceConfig = {
        Type = "oneshot";
        User = name;
      };
      script = ''
        set -euo pipefail

        ssh_dir="$HOME/.ssh"
        key_file="$ssh_dir/id_ed25519"

        install -d -m 700 "$ssh_dir"
        ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -C "${name}@${hostName}" -f "$key_file"
      '';
    };
  }) userNames);
}
