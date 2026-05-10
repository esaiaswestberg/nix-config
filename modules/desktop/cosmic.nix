{
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  services.displayManager.defaultSession = "cosmic";

  programs.dconf.enable = true;
  services.dbus.enable = true;

  hardware.graphics.enable = true;
}
