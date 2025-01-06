{ pkgs, nixos-hardware, ... }:
{
  imports =
    [
      ./hardware.nix
      nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen
    ];
  # ---------------------------------------------------------------------------
  #
  # ~ System
  #
  # ---------------------------------------------------------------------------
  services.logind.lidSwitch = "suspend";

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
        device = "/dev/disk/by-uuid/a2c6e8d7-55c7-41ed-bc31-7f65973db197";
        keyFile = "/crypto_keyfile.bin";
      };
      secrets."/crypto_keyfile.bin" = null;
    };
  };

  # ---------------------------------------------------------------------------
  #
  # ~ NixOS
  #
  # ---------------------------------------------------------------------------
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
