{ config, lib, pkgs, modulesPath, ... }:
{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/52af8fb1-0e34-4e30-83a7-c7ad0b346459";
      fsType = "ext4";
    };

  boot.initrd.luks.devices."luks-40ec1a9f-e76b-4808-a411-ed5cad3f472e".device = "/dev/disk/by-uuid/40ec1a9f-e76b-4808-a411-ed5cad3f472e";

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/B4C4-0960";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/d09d938c-2996-414d-b40f-d3f2f716cfc4"; }
    ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s31f6.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp4s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
