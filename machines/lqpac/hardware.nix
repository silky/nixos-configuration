{ modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  # boot.initrd.kernelModules = [ ];
  # boot.kernelModules = [ "kvm-intel" ];
  # boot.extraModulePackages = [ ];

  # fileSystems."/" =
  #   {
  #     device = "/dev/disk/by-uuid/046b2ffa-998c-4a69-88f3-44f9d159847e";
  #     fsType = "ext4";
  #   };

  # boot.initrd.luks.devices."luks-bfb79fb3-664e-411b-a779-e73fac19ff54".device = "/dev/disk/by-uuid/bfb79fb3-664e-411b-a779-e73fac19ff54";

  # fileSystems."/boot/efi" =
  #   {
  #     device = "/dev/disk/by-uuid/8504-4A1B";
  #     fsType = "vfat";
  #   };

  # swapDevices =
  #   [{ device = "/dev/disk/by-uuid/44cffa9b-46b9-450d-a6a0-190822a63994"; }];

  # # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # # (the default) this is the recommended approach. When using systemd-networkd it's
  # # still possible to use this option, but it's recommended to use it in conjunction
  # # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  # networking.useDHCP = lib.mkDefault true;
  # # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  # nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  # powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  # hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
