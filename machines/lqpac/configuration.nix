{ pkgs, ... }:
{
  imports =
    [
      ./hardware.nix
      # TODO: Use something appropriate here
      # nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen
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
