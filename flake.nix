{
  inputs = {
    nixpkgs.url  = "nixpkgs/nixos-22.11";
    unstable.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-22.11";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    # helic.url = github:/tek/helic;

    # nix-alien.url = "github:thiagokokada/nix-alien";
    # nix-ld.url = "github:Mic92/nix-ld/main";
  };


  outputs = { self, nixpkgs, unstable, home-manager, nixos-hardware }:
  {
    nixosConfigurations.otherwise = nixpkgs.lib.nixosSystem {
      system      = "x86_64-linux";
      specialArgs = { inherit nixpkgs; };

      modules     = [
        nixos-hardware.nixosModules.lenovo-thinkpad-x1-10th-gen

        # helic.nixosModule

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
