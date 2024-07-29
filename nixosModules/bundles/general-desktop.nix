{
  pkgs,
  lib,
  ...
}: {
  myNixOS.sddm.enable = lib.mkDefault false;
  myNixOS.autologin.enable = lib.mkDefault true;
  myNixOS.xremap-user.enable = lib.mkDefault true;
  myNixOS.system-controller.enable = lib.mkDefault false;
  myNixOS.virtualisation.enable = lib.mkDefault true;
  myNixOS.stylix.enable = lib.mkDefault true;
  myNixos.Israel-timezone.enable = lib.mkDefault true;
  
  # Enable sound with pipewire.
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  fonts.packages = with pkgs; [
    (pkgs.nerdfonts.override {fonts = ["JetBrainsMono" "Iosevka" "FiraCode"];})
    cm_unicode
    corefonts
  ];

  # fonts.enableDefaultPackages = true;
  # fonts.fontconfig = {
  #   defaultFonts = {
  #     monospace = ["JetBrainsMono Nerd Font Mono"];
  #     sansSerif = ["JetBrainsMono Nerd Font"];
  #     serif = ["JetBrainsMono Nerd Font"];
  #   };
  # };

  # battery
  services.upower.enable = true;
}
