{ lib, hostName, userName, secondaryUserName, config, ... }:
let
  homeDirs = [
    "/home/${userName}"
    "/home/${secondaryUserName}"
  ];
in
{
  services.restic.backups.${hostName} = {
    initialize = true;
    paths = [
      "/etc/nixos"
    ] ++ homeDirs;
    exclude = lib.concatMap (homeDir: [
      "${homeDir}/.cache"
      "${homeDir}/.local/share/Trash"
      "${homeDir}/.steam"
      "${homeDir}/.local/share/Steam"
      "${homeDir}/.local/state/Steam"
    ]) homeDirs;
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
