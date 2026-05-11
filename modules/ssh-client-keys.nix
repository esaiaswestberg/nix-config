{ pkgs, hostName, userName, ... }:
{
  systemd.services.generate-ssh-client-key = {
    description = "Generate the default SSH client key if missing";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    unitConfig.ConditionPathExists = "!/home/${userName}/.ssh/id_ed25519";
    serviceConfig = {
      Type = "oneshot";
      User = userName;
    };
    script = ''
      set -euo pipefail

      ssh_dir="$HOME/.ssh"
      key_file="$ssh_dir/id_ed25519"

      install -d -m 700 "$ssh_dir"
      ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -C "${userName}@${hostName}" -f "$key_file"
    '';
  };
}
