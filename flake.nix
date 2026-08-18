{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    # Home-manager also needs to be unstable.
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    cooklang-chef.url = "github:silky/cooklang-chef/nix-hacking";
    haskell-hacking-notebook.url = "github:silky/haskell-hacking-notebook/main";

    cornelis.url = "github:isovector/cornelis";
    cornelis.inputs.nixpkgs.follows = "nixpkgs";

    ghostty.url = "github:ghostty-org/ghostty/v1.3.1";
    ghostty.inputs.nixpkgs.follows = "nixpkgs";

    old-flameshot.url = "github:nixos/nixpkgs/1c1c9b3f5ec0421eaa0f22746295466ee6a8d48f";

    nix-formatter-pack.url = "github:Gerschtli/nix-formatter-pack";
    nix-formatter-pack.inputs.nixpkgs.follows = "nixpkgs";

    gh-gfm-preview.url = "github:thiagokokada/gh-gfm-preview";
    gh-gfm-preview.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
  };


  outputs =
    { nixpkgs
    , nix-formatter-pack
      # , nix
    , ...
    }@inputs:
    let
      overlays = [
        (self: super: {
          fcitx-engines = self.fcitx5;
          gh-gfm-preview = inputs.gh-gfm-preview.packages.x86_64-linux.default;
          ghostty = inputs.ghostty.packages.x86_64-linux.default;
          pulsemixer = super.pulsemixer.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              ./modules/nixos/pulsemixer-focus-default.patch
            ];
          });
          flameshot =
            let
              p = import inputs.old-flameshot { system = "x86_64-linux"; };
            in
            p.flameshot;
          # nix = nix.packages.x86_64-linux.default;
          # This is how to get a new linux firmware
          # linux-firmware = super.linux-firmware.overrideAttrs (
          #   old: {
          #     src = super.fetchgit{
          #       url = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
          #       rev = "fa42eda204398542aa9b92fe462d4dd069897de0";
          #       sha256 = "sha256-TJ97A9I0ipsqgg7ex3pAQgdhDJcLbkNCvuLppt9a07o=";
          #     };
          #   }
          # );
        })
        inputs.cornelis.overlays.cornelis
      ];

      mkHost = import ./lib/mkHost.nix { inherit inputs overlays; };

      pkgs = import nixpkgs { system = "x86_64-linux"; inherit overlays; };
    in
    {
      devShells."x86_64-linux".xmonad =
        let
          ghc = pkgs.haskellPackages.ghcWithPackages (p: with p; [
            xmonad
            xmonad-contrib
            xmonad-extras
            split
          ]);
        in
        pkgs.mkShell {
          name = "xmonad-build";
          packages = [
            ghc
            pkgs.haskell-language-server
          ];
          shellHook = ''
            echo "xmonad dev shell. Build with:"
            echo "  ghc --make -threaded -O2 users/noon/xmonad.hs -o /tmp/xmonad-test"
          '';
        };

      formatter."x86_64-linux" =
        nix-formatter-pack.lib.mkFormatter {
          pkgs = nixpkgs.legacyPackages."x86_64-linux";
          config.tools = {
            deadnix.enable = true;
            nixpkgs-fmt.enable = true;
            statix.enable = true;
          };
        };

      nixosConfigurations.eqpac = mkHost {
        name = "eqpac";
        users = [ "noon" "gala" ];
        defaultUser = "noon";
      };

      nixosConfigurations.nqpac = mkHost {
        name = "nqpac";
        users = [ "noon" "gala" ];
        defaultUser = "noon";
      };

      nixosConfigurations.lqpac = mkHost {
        name = "lqpac";
        users = [ "noon" "gala" ];
        defaultUser = "noon";
      };
    };
}
