{
  inputs = {
    nixpkgs.url  = "nixpkgs/nixos-22.11";
    unstable.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-22.11";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
  };


  outputs = { self, nixpkgs, unstable, home-manager, nixos-hardware }@attrs:
  let
    mkSystem = name: { user, overlays }:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs // { inherit user name; };
        modules = [
          { nixpkgs.overlays = overlays; }

          ./machines/${name}/configuration.nix

          # Home-manager stuffs.
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${user} = import ./users/${user}/home.nix;
            home-manager.extraSpecialArgs = { inherit unstable; };
          }
        ];
      };
  in
  {
    nixosConfigurations.nqpac = mkSystem "nqpac" {
      user     = "noon";
      overlays = [];
    };


    # nixosConfigurations.nqpac = nixpkgs.lib.nixosSystem {
    #   system      = "x86_64-linux";
    #   specialArgs = attrs;
    #   modules     = [
    #     nixos-hardware.nixosModules.lenovo-thinkpad-x1-6th-gen

    #     ./configuration.nix

    #     home-manager.nixosModules.home-manager {
    #       home-manager.useGlobalPkgs = true;
    #       home-manager.useUserPackages = true;
    #       home-manager.users.noon = import ./home.nix;
    #       home-manager.extraSpecialArgs = { inherit unstable; };
    #     }
    #   ];
    # };
  };
}
