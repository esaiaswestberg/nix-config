{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };

      david = {
        host = "100.108.24.47";
        user = "ubuntu";
      };

      eloquentiastudios = {
        host = "100.88.115.52";
        user = "eloquentiastudios";
      };

      github = {
        host = "github.com";
        user = "git";
      };

      jake = {
        host = "100.111.162.55";
        user = "jake";
      };

      loca = {
        host = "loca";
      };
    };
  };
}
