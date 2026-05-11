{ userName, secondaryUserName, pkgs, config, ... }:
{
  users.users = {
    ${userName} = {
      isNormalUser = true;
      description = userName;
      hashedPasswordFile = config.sops.secrets."users/${userName}/password-hash".path;
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      shell = pkgs.zsh;
    };

    ${secondaryUserName} = {
      isNormalUser = true;
      description = secondaryUserName;
      hashedPasswordFile = config.sops.secrets."users/${secondaryUserName}/password-hash".path;
      extraGroups = [
        "networkmanager"
      ];
      shell = pkgs.zsh;
    };
  };
}
