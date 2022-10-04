{
  inputs = {
    nixpkgs.url  = "nixpkgs/nixos-22.05";
    unstable.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helic.url = github:/tek/helic;
  };

  outputs = { self, nixpkgs, unstable, home-manager, nixos-hardware, helic }:
  {
    nixosConfigurations.otherwise = nixpkgs.lib.nixosSystem {
      system      = "x86_64-linux";
      specialArgs = { inherit nixpkgs;  };

      modules     = [
        nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen

        helic.nixosModule

        ./configuration.nix

        home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.noon = import ./home.nix;
        }
      ];
    };
  };

}
