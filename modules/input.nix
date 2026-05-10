{
  console.keyMap = "sv-latin1";

  services.xserver.xkb = {
    layout = "se";
    variant = "";
  };

  services.libinput = {
    enable = true;
    mouse = {
      accelProfile = "adaptive";
      naturalScrolling = false;
      middleEmulation = true;
    };
    touchpad = {
      tapping = true;
      accelProfile = "adaptive";
      naturalScrolling = false;
      middleEmulation = true;
      disableWhileTyping = true;
    };
  };
}
