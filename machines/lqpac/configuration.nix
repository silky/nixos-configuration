{ pkgs, nixos-hardware, ... }:
{
  imports =
    [
      ./hardware.nix
      nixos-hardware.nixosModules.lenovo-thinkpad-x1-12th-gen
    ];
  # ---------------------------------------------------------------------------
  #
  # ~ System/Kernel
  #
  # ---------------------------------------------------------------------------
  boot.kernelPackages = pkgs.linuxPackages_latest;
  services.logind.lidSwitch = "suspend";

  # ---------------------------------------------------------------------------
  #
  # ~ Additional Hardware
  #
  # ---------------------------------------------------------------------------
  boot = {
     loader.systemd-boot.enable = true;
     loader.efi.canTouchEfiVariables = true;
  };

  system.stateVersion = "25.05";
}
