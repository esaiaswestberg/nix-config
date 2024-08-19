{ config, lib, pkgs, ... }:

{

  options = {
    systemSettings.desktop.hyprland = {
      monitors = lib.mkOption {
        type = lib.types.listOf lib.types.lines;
        default = [ ", preferred, auto, 1" ];
        description = "Configure monitors for Hyprland";
      };

      workspaces = lib.mkOption {
        type = lib.types.listOf lib.types.lines;
	      description = "Configure workspaces for Hyprland";
      };

    };
  };

  config = lib.mkIf (config.systemSettings.desktop.enable == "hyprland") {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    environment.sessionVariables.NIXOS_OZONE_WL = 1;

    xdg.portal = {
      enable = true;
      configPackages = [ pkgs.xdg-desktop-portal-hyprland ];
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    environment.systemPackages = with pkgs; [
    	hyprpaper

      # Extra programs for hyprland
      wofi
      swaynotificationcenter
      
      # Utilities
      nautilus
    ];
  };

}
