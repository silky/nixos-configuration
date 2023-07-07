{
  inputs = {
    nixpkgs.url        = "nixpkgs/nixos-23.05";
    unstable.url       = "nixpkgs/nixos-unstable";
    home-manager.url   = "github:nix-community/home-manager/release-23.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
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
      overlays = [
        (self: super: {
          fcitx-engines = self.fcitx5;
        })
      ];
    };
  };
}
