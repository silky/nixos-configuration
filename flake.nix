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

    nix-formatter-pack.url = "github:Gerschtli/nix-formatter-pack";
    nix-formatter-pack.inputs.nixpkgs.follows = "nixpkgs";

    gh-gfm-preview.url = "github:thiagokokada/gh-gfm-preview";
    gh-gfm-preview.inputs.nixpkgs.follows = "nixpkgs";

    feedback.url = "github:NorfairKing/feedback";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };


  outputs =
    { nixpkgs
    , home-manager
    , cooklang-chef
    , haskell-hacking-notebook
    , cornelis
    , nix-formatter-pack
    , gh-gfm-preview
    , feedback
    , flake-parts
    , ...
    }@inputs:
    let
      overlays = [
        (self: super: {
          fcitx-engines = self.fcitx5;
          gh-gfm-preview = inputs.gh-gfm-preview.packages.x86_64-linux.default;
          feedback = inputs.feedback.packages.x86_64-linux.default;
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
        cornelis.overlays.cornelis
      ];
      pkgs = import nixpkgs { system = "x86_64-linux"; };

      mkSystem = name:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs // { inherit name; };
          modules = [
            { nixpkgs.overlays = overlays; }
            # Common system configuration
            ./users/noon/common-configuration.nix

            # Specific machine configuration
            ./machines/${name}/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.noon = import ./users/noon/home.nix;
              home-manager.users.gala = import ./users/gala/home.nix;
              home-manager.extraSpecialArgs = {
                inherit
                  cooklang-chef
                  haskell-hacking-notebook
                  ;
              };
            }
          ];
        };
    in
    {
      imports = [
        inputs.flake-parts.flakeModules.modules
      ];

      formatter."x86_64-linux" =
        nix-formatter-pack.lib.mkFormatter {
          pkgs = nixpkgs.legacyPackages."x86_64-linux";
          config.tools = {
            deadnix.enable = true;
            nixpkgs-fmt.enable = true;
            statix.enable = true;
          };
        };


      nixosConfigurations.eqpac = mkSystem "eqpac";
      nixosConfigurations.nqpac = mkSystem "nqpac";
      nixosConfigurations.lqpac = mkSystem "lqpac";
    };
}
