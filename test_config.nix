{pkgs, config, ...}:{

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  services.double-minegrub-menu = {
    enable = true;
    background = "random";
    splashText = "random";
  }; 
  
  system.stateVersion = "26.05";
}
