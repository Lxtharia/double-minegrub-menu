{
  description = "A Minegrub double-theme flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    minegrub-world-sel-theme = {
      url = "github:Lxtharia/minegrub-world-sel-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{self, nixpkgs, ...}: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in 
    {
      # Nixos tester configuration file for testing the module (running on VM) 
      nixosConfigurations.test-module = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          self.nixosModules.default
          ./module_tester.nix
        ];
      };
 
      nixosModules.default = { config, lib, pkgs, ... }:
        with lib; 
        let
          cfg = config.boot.loader.grub.double-minegrub-menu;

          # check the value of background and splashText options
          backgroundArg = if cfg.main_menu_background == "random" then "" else "backgrounds/${cfg.main_menu_background}";
          splashTextArg = if cfg.splash_text == "random" then "" else cfg.splash_text;

          minegrub-theme = pkgs.fetchFromGitHub {
            owner = "Lxtharia";
            repo = "minegrub-theme";
            rev = "142f67baed783b4f6774f316476f46ff7ab1823a";
            sha256 = "sha256-2qP9aYUmFTmMYenLfbfYJ8P+XUGJYJFDdbQBheasr8k=";
          };

          # Python environment bundled with Pillow
          pythonEnv = pkgs.python313.withPackages (ps: [
            ps.pillow
          ]);

          # Mock fetch tool to return a format update_theme.py understands: "Packages: <count> (nix)"
          fakeFetch = pkgs.writeShellScriptBin "fastfetch" ''
            # Count installed paths in the system profile
            PKG_COUNT=$(ls -d /nix/var/nix/profiles/system/sw/bin/* 2>/dev/null | wc -l)
            echo "Packages: $PKG_COUNT (nix)"
          '';

          # Wrapper script
          minegrubUpdateScript = pkgs.writeShellScriptBin "minegrub-update" ''
            cd /boot/grub/themes/minegrub
            export PATH="${fakeFetch}/bin:${pythonEnv}/bin:$PATH"
            exec ${pythonEnv}/bin/python3 update_theme.py \
              ${escapeShellArg backgroundArg} \
              ${escapeShellArg splashTextArg}
          '';
        in
        {
          imports = [
            inputs.minegrub-world-sel-theme.nixosModules.default
          ];

          options.boot.loader.grub.double-minegrub-menu = {
            enable = mkEnableOption "enable the double menu";

            #Optional configuration for configuring main menu background and splash text
            main_menu_background = mkOption {
              type = types.str;
              default = "random";
              description = "main menu background";
            };

            splash_text = mkOption {
              type = types.str;
              default = "random";
              description = "the text that appear on Minegrub logo";
            };

            world_selection_custom_icons = mkOption {
              type = types.listOf (types.attrsOf types.anything);
              default = [];
              description = "Custom icons for the Minegrub world-selection menu.";
            };
            
            world_selection_background_scaled = mkOption {
              type = types.str;
              default = "1920x1080";
              description = "Resolution to which the world-selection background is scaled";
            };
          };

          # enable this configuration if boot.loader.grub.double-minegrub-menu.enable = true;
          config = mkIf cfg.enable {

            #grub configuration
            boot.loader.grub = {

              # Set world-selection theme as the initial theme 
              minegrub-world-sel = {
                enable = true;
                customIcons = cfg.world_selection_custom_icons;
                background = "assets/background-scaled/background-${cfg.world_selection_background_scaled}.png";
              };
              
              # Copy the second theme and the secondary config file to /boot/grub/
              extraFiles = let
                themeDir = "${minegrub-theme}/minegrub";
                bgDir = "${minegrub-theme}/background_options";
                
                allFiles = pkgs.lib.filesystem.listFilesRecursive themeDir;
                allBgs = pkgs.lib.filesystem.listFilesRecursive bgDir;

                # Strip the base themeDir prefix to get the relative subpath for each file
                themeFileEntries = builtins.listToAttrs (map (file: {
                  name = builtins.unsafeDiscardStringContext (
                  "grub/themes/minegrub" + pkgs.lib.removePrefix (toString themeDir) (toString file)
                  );
                  value = file;
                }) allFiles);
                
                bgFileEntries = builtins.listToAttrs (map (file: {
                  name = builtins.unsafeDiscardStringContext (
                  "grub/themes/minegrub/backgrounds" + pkgs.lib.removePrefix (toString bgDir) (toString file)
                  );
                  value = file; 
                }) allBgs);
              in
              {
                "grub/mainmenu.cfg" = ./mainmenu.cfg;
              } // themeFileEntries // bgFileEntries;

              # Inject the logic from 05_twomenus into grub.cfg
              extraConfig = ''
                exec tail -n +3 $0
                
                if [ -z "$chosen" ] ; then
                  if [ "''${config_file}" ] ; then
                    configfile $prefix/$config_file
                  fi
                fi
              '';
            };

            # enable systemd service for updating splash text and background
            environment.systemPackages = [
              minegrubUpdateScript
            ];
            
            systemd.services.minegrub-update = {
              description = "Update Minegrub splash text and background";
              after = [ "local-fs.target" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                Type = "oneshot";
                ExecStart = "${minegrubUpdateScript}/bin/minegrub-update";
                User = "root";
              };
            }; 
          };
        };
    };
}
