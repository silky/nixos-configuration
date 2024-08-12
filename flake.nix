{
  inputs = {
    # nixpkgs.url = "nixpkgs/nixos-24.05";
    # Let's just try everything unstable
    nixpkgs.url = "nixpkgs/nixos-unstable";
    unstable.url = "nixpkgs/nixos-unstable";

    # home-manager.url = "github:nix-community/home-manager/release-24.05";
    # Home-manager also needs to be unstable.
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    cooklang-chef.url = "github:silky/cooklang-chef/nix-hacking";
    haskell-hacking-notebook.url = "github:silky/haskell-hacking-notebook/main";

    cornelis.url = "github:isovector/cornelis";
    cornelis.inputs.nixpkgs.follows = "nixpkgs";

    # nur.url = "github:nix-community/NUR";

    nix-formatter-pack.url = "github:Gerschtli/nix-formatter-pack";
    nix-formatter-pack.inputs.nixpkgs.follows = "nixpkgs";
  };


  outputs =
    { nixpkgs
    , unstable
    , home-manager
    , cooklang-chef
    , haskell-hacking-notebook
    , cornelis
      # , nur
    , nix-formatter-pack
    , ...
    }@inputs:
    let
      overlays = [
        (self: _super: { fcitx-engines = self.fcitx5; })
        cornelis.overlays.cornelis
      ];
      pkgs = import nixpkgs { system = "x86_64-linux"; };

      mkSystem = name:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs // { inherit name unstable; };
          modules = [
            { nixpkgs.overlays = overlays; }
            # TODO: Re-instate
            # nur.nixosModules.nur

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
                  unstable
                  cooklang-chef
                  haskell-hacking-notebook
                  ;
              };
            }
          ];
        };
    in
    {
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
    };
}
