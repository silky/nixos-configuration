{ pkgs, nixos-hardware, ... }:
{
  imports =
    [
      ./hardware.nix
      nixos-hardware.nixosModules.lenovo-thinkpad-x1-6th-gen
    ];
  # ---------------------------------------------------------------------------
  #
  # ~ System/Kernel
  #
  # ---------------------------------------------------------------------------
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_10;

  # ---------------------------------------------------------------------------
  #
  # ~ Additional Hardware
  #
  # ---------------------------------------------------------------------------
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    loader.efi.efiSysMountPoint = "/boot/efi";

    initrd = {
      luks.devices."luks-6a40db75-3164-4b54-bef0-308fec1e5e6d" = {
        device = "/dev/disk/by-uuid/6a40db75-3164-4b54-bef0-308fec1e5e6d";
        keyFile = "/crypto_keyfile.bin";
      };
      secrets."/crypto_keyfile.bin" = null;
    };
  };
}
