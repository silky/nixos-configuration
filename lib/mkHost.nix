# Build a NixOS configuration for a single host.
#
#   inputs   — the flake's `inputs` attrset
#   overlays — list of nixpkgs overlays to apply
#
# The returned function takes a host attrset:
#   { name, users ? [ "noon" "gala" ], modules ? [] }
#
# For each entry in `users` we import both the user's system declaration
# (../users/<u>/system.nix) and their home-manager config
# (../users/<u>/home.nix), so the user list is the single source of truth.
{ inputs, overlays }: { name, users ? [ "noon" "gala" ], modules ? [ ] }:
inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = inputs // { inherit name; };
  modules = [
    { nixpkgs.overlays = overlays; }

    ../modules/nixos/common.nix
    ../hosts/${name}/configuration.nix

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users = inputs.nixpkgs.lib.genAttrs users
        (u: import ../users/${u}/home.nix);
      home-manager.extraSpecialArgs = {
        inherit (inputs)
          cooklang-chef
          haskell-hacking-notebook
          ;
      };
    }
  ]
  ++ map (u: ../users/${u}/system.nix) users
  ++ modules;
}
