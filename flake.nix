{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";

    # Home-manager also needs to be unstable.
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";

    cooklang-chef.url = "github:silky/cooklang-chef/nix-hacking";
    cooklang-chef.inputs.nixpkgs.follows = "nixpkgs";

    haskell-hacking-notebook.url = "github:silky/haskell-hacking-notebook/main";
    haskell-hacking-notebook.inputs.nixpkgs.follows = "nixpkgs";

    cornelis.url = "github:isovector/cornelis";
    cornelis.inputs.nixpkgs.follows = "nixpkgs";

    ghostty.url = "github:ghostty-org/ghostty/v1.3.1";
    ghostty.inputs.nixpkgs.follows = "nixpkgs";

    old-flameshot.url = "github:nixos/nixpkgs/1c1c9b3f5ec0421eaa0f22746295466ee6a8d48f";

    # ungoogled-chromium 151.x broke clipboard copy/paste; pinned back to the
    # last known-good nixpkgs revision (150.0.7871.186) until upstream fixes it.
    old-chromium.url = "github:nixos/nixpkgs/8623c4c20aa4ca2f5fb81510d2944066c3fb0d96";

    nix-formatter-pack.url = "github:Gerschtli/nix-formatter-pack";
    nix-formatter-pack.inputs.nixpkgs.follows = "nixpkgs";

    gh-gfm-preview.url = "github:thiagokokada/gh-gfm-preview";
    gh-gfm-preview.inputs.nixpkgs.follows = "nixpkgs";

    # Bubblewrap jails for (agent) derivations.
    jail-nix.url = "sourcehut:~alexdavid/jail.nix";

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
          ungoogled-chromium =
            let
              p = import inputs.old-chromium { system = "x86_64-linux"; };
            in
            p.ungoogled-chromium;
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
