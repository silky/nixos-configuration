{
  inputs = {
    nixpkgs.url                  = "nixpkgs/nixos-23.11";
    unstable.url                 = "nixpkgs/nixos-unstable";
    home-manager.url             = "github:nix-community/home-manager/release-23.11";
    nixos-hardware.url           = "github:NixOS/nixos-hardware/master";
    cooklang-chef.url            = "github:silky/cooklang-chef/nix-hacking";
    haskell-hacking-notebook.url = "github:silky/haskell-hacking-notebook/main";
    # nix-doom-emacs.url           = "github:nix-community/nix-doom-emacs";
  };


  outputs =
    { self
    , nixpkgs
    , unstable
    , home-manager
    , nixos-hardware
    , cooklang-chef
    , haskell-hacking-notebook
    # , nix-doom-emacs
    }@attrs:
  let
    commonOverlays = self: super: {
      fcitx-engines = self.fcitx5;
    };

    mkSystem = name: { user, overlays }:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs // { inherit user name unstable; };
        modules = [
          { nixpkgs.overlays = overlays; }

          # Common system configuration
          ./users/${user}/common-configuration.nix

          # Specific machine configuration
          ./machines/${name}/configuration.nix

          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${user} = import ./users/${user}/home.nix;
            home-manager.extraSpecialArgs = {
              inherit
              unstable
              cooklang-chef
              haskell-hacking-notebook
              # nix-doom-emacs
              ;
            };
          }
        ];
      };
  in
  {
    nixosConfigurations.eqpac = mkSystem "eqpac" {
      user     = "noon";
      overlays = [
        commonOverlays
      ];
    };
    nixosConfigurations.nqpac = mkSystem "nqpac" {
      user     = "noon";
      overlays = [
        commonOverlays
      ];
    };
  };
}
