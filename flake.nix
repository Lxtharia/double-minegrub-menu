{
  description = "A Minegrub double-theme flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{self, nixpkgs, ...}: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in 
    {
      #nixos configuration for testing the module (running on VM)
      nixosConfigurations.test-module = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          self.nixosModules.default
          ./test_config.nix
        ];
      };
 
      nixosModules.default = { config, lib, pkgs, ... }:
        with lib; 
        let
          cfg = config.services.double-minegrub-menu;

          # check the value of background and splashText options
          backgroundArg = if cfg.background == "random" then "" else cfg.background;
          splashTextArg = if cfg.splashText == "random" then "" else cfg.splashText;

          minegrub-theme = pkgs.fetchFromGitHub {
            owner = "Lxtharia";
            repo = "minegrub-theme";
            rev = "v3.1.0";
            sha256 = "sha256-wusELfq9vxbkbZy8cPprcOldqoqSbKltxt++EW9gQ9g=";
          };

          minegrub-world-sel = pkgs.fetchFromGitHub {
            owner = "Lxtharia";
            repo = "minegrub-world-sel-theme";
            rev = "v1.1.0";
            sha256 = "sha256-Hlp081T6HUd4n6CaTf3aousZwBuBly6+0T+Y2d5y+SE=";
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
          options.services.double-minegrub-menu = {
            enable = mkEnableOption "enable the double menu";

            #Optional configuration
            background = mkOption {
              type = types.str;
              default = "random";
              description = "the grub background";
            };

            splashText = mkOption {
              type = types.str;
              default = "random";
              description = "the text that appear on Minegrub logo";
            };
          };

          # enable this configuration if services.double-minegrub-menu.enable = true;
          config = mkIf cfg.enable {

            #grub configuration
            boot.loader.grub = {
              # Set the initial theme to the world-selection theme
              theme = "${minegrub-world-sel}/minegrub-world-selection";

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
                "grub/mainmenu.cfg" = "./mainmenu.cfg";
              } // themeFileEntries // bgFileEntries;

              # 3. Inject the logic from 05_twomenus into grub.cfg
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
