# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/4e7adc6b-639b-4c3c-a265-b39b0c65042d";
      fsType = "ext4";
    };

  boot.initrd.luks.devices."luks-97e17cc6-0847-47ee-afb9-689f6cbdb5e2".device = "/dev/disk/by-uuid/97e17cc6-0847-47ee-afb9-689f6cbdb5e2";

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/75A7-80A9";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/15c46ad9-e85e-4c02-a863-917a17ff2a08"; }
    ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
