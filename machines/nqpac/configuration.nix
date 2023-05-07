{ user, name, config, pkgs, lib, nixos-hardware, ... }:
{
  imports =
    [ ./hardware.nix
      nixos-hardware.nixosModules.lenovo-thinkpad-x1-6th-gen
    ];


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
        device  = "/dev/disk/by-uuid/6a40db75-3164-4b54-bef0-308fec1e5e6d";
        keyFile = "/crypto_keyfile.bin";
      };
      secrets."/crypto_keyfile.bin" = null;
    };
  };


  # ---------------------------------------------------------------------------
  #
  # ~ System/Kernel
  #
  # ---------------------------------------------------------------------------
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_1;

  # See: https://nixos.wiki/wiki/Fwupd
  #
  #   fwupmgr refresh
  #   fwupmgr get-updates
  #   fwupmgr update
  #
  services.fwupd.enable = true;


  # ---------------------------------------------------------------------------
  #
  # ~ System Packages
  #
  # ---------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    autoconf
    automake
    bashmount
    binutils
    cachix
    curl
    fuse
    gcc
    git
    git-lfs
    gmp
    gnumake
    htop
    libtool
    lsof
    neovim # Standard one; not customised.
    nixpkgs-fmt
    ntfs3g
    pavucontrol
    psmisc
    ripgrep
    tree
    unzip
    wget
    xorg.xev
    xorg.xkill
    xsel
    zip
  ];


  # ---------------------------------------------------------------------------
  #
  # ~ Nix
  #
  # ---------------------------------------------------------------------------
  nix = {
    settings.trusted-users = [ "root" "${user}" ];
    extraOptions = ''
      experimental-features = nix-command flakes recursive-nix ca-derivations repl-flake
      log-lines = 300
      warn-dirty = false
    '';
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-12.2.3" # For etcher; See https://github.com/NixOS/nixpkgs/issues/153537
    ];
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Window Manager
  #
  # ---------------------------------------------------------------------------
  services.xserver = {
    enable     = true;
    layout     = "us";
    xkbVariant = "";
    xkbOptions = "caps:escape";
    displayManager = {
      sessionCommands = ''
        # Set a background.
        /home/noon/.fehbg || true

        # No screen saving.
        xset s off -dpms
      '';
      autoLogin = {
        user   = "${user}";
        enable = true;
      };
    };
    windowManager = {
      xmonad = {
        enable = true;
        enableContribAndExtras = true;
        extraPackages = p: [ p.split ];
        config = ../../users/${user}/xmonad.hs;
      };
    };
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Networking
  #
  # ---------------------------------------------------------------------------
  networking = {
    hostName = "${name}";
    networkmanager.enable = true;
    firewall.allowedTCPPorts = [];
    firewall.enable = true;
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Audio
  #
  # ---------------------------------------------------------------------------
  sound.enable = false;
  services.pipewire = {
    enable             = true;
    pulse.enable       = true;
    wireplumber.enable = true;
    alsa = {
      enable       = true;
      support32Bit = true;
    };
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Misc
  #
  # ---------------------------------------------------------------------------
  services = {
    openssh.enable = false;
    vnstat.enable  = true;
  };

  virtualisation.docker.enable = true;

  fonts.fonts = with pkgs; [
    nerdfonts
    raleway
    source-code-pro
    source-sans-pro
    source-serif-pro
  ];


  # ---------------------------------------------------------------------------
  #
  # ~ Internationalisation / i18n
  #
  # ---------------------------------------------------------------------------
  time.timeZone      = "Europe/London";
  i18n.defaultLocale = "en_GB.utf8";


  # ---------------------------------------------------------------------------
  #
  # ~ Security
  #
  # ---------------------------------------------------------------------------
  services = {
    gnome.gnome-keyring.enable = true;
  };

  security = {
    rtkit.enable = true;
    pam.services.login.enableGnomeKeyring = true;
  };

  users.users.${user} = {
    isNormalUser = true;
    description  = "${user}";
    extraGroups  = [ "networkmanager" "wheel" "dialout" "audio" "docker" ];
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
