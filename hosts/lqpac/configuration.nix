{ pkgs, nixos-hardware, ... }:
{
  imports =
    [
      ./hardware.nix
      nixos-hardware.nixosModules.lenovo-thinkpad-x1-13th-gen
      ../../modules/nixos/desktop-xmonad.nix
    ];
  # ---------------------------------------------------------------------------
  #
  # ~ System/Kernel
  #
  # ---------------------------------------------------------------------------
  boot.kernelPackages = pkgs.linuxPackages_latest;
  services.logind.settings.Login.HandleLidSwitch = "suspend";

  # ---------------------------------------------------------------------------
  #
  # ~ Additional Hardware
  #
  # ---------------------------------------------------------------------------
  boot = {
    loader.systemd-boot.enable = true;
    # The ESP carries systemd-boot 261.1 from the one day this config
    # tracked nixos-unstable (2026-08-18, commit cf1c985); that
    # generation is long garbage-collected, but bootctl never downgrades,
    # so the loader stayed. nixos-26.05 ships 260.x, and bootctl 260
    # exits non-zero when it skips a newer loader unless --graceful is
    # given, which aborted the whole switch before activation
    # (2026-10-10). With --graceful the skip is a no-op. The newer
    # loader boots fine. Drop this once 26.05 (or the next release)
    # ships a systemd above 261.1, or after a
    # `nixos-rebuild switch --install-bootloader', which force-writes
    # the config's version.
    loader.systemd-boot.graceful = true;
    loader.efi.canTouchEfiVariables = true;
  };

  system.stateVersion = "25.05";
}
