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
  boot.loader.grub.double-minegrub-menu = {
    enable = true;

    #main menu configurations
    main_menu_background = "1.21.5 - [Spring to Life].png";
    splash_text = "random";

    #world selection theme configurations
    world_selection_background_scaled = "1366x768";
    world_selection_custom_icons = with config.system.nixos; [
      {
        name = distroId;
        lineTop = distroName + " " + codeName + " (" + version + ")";
        lineBottom = "Survival Mode, No Cheats, Version: " + release;

        # Icon: you can use an icon from the remote repo, or load from a local file
        imgName = "nixos";
        
        # customImg = builtins.path {
        #   path = ./nixos-logo.png;
        #   name = "nixos-img";
        # };
      }
    ];
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
