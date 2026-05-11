{ userName, config, ... }:
let
  homeDir = "/home/${userName}";
in
{
  services.restic.backups.workstation = {
    initialize = true;
    paths = [
      "/etc/nixos"
      homeDir
    ];
    exclude = [
      "${homeDir}/.cache"
      "${homeDir}/.local/share/Trash"
      "${homeDir}/.steam"
      "${homeDir}/.local/share/Steam"
      "${homeDir}/.local/state/Steam"
    ];
    repositoryFile = config.sops.secrets."backup/restic/repository".path;
    passwordFile = config.sops.secrets."backup/restic/password".path;
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
    extraBackupArgs = [
      "--exclude-caches"
    ];
  };
}
