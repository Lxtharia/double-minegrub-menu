{pkgs, config, ...}:{

  system.stateVersion = "26.05";

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = false;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = ["wheel" "users" "audio" "networkmanager" "video" "render"];
    initialPassword = "nixos";
  };

  # Test the module
  services.double-minegrub-menu = {
    enable = true;
    main_menu_background = "backgrounds/1.13 - [Aquatic update].png";
    splash_text = "100% Declarative";
  };

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://mirror.sjtu.edu.cn/nix-channels/store" 
        "https://mirrors.ustc.edu.cn/nix-channels/store" 
        "https://nix-community.cachix.org"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    grub2
  ];
}
