# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
  let customNvim =
    pkgs.neovim.override {
      configure = {
        customRC = "source " + /home/noon/dev/dotfiles/init.vim;
        plug.plugins = with pkgs.vimPlugins; [
          fzfWrapper
        ];
      };
    };
in

{
  imports =
    [ # Include the results of the hardware scan.
      <nixos-hardware/lenovo/thinkpad/x1/9th-gen>
      ./hardware-configuration.nix
    ];

  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = ["FiraCode"]; })
    raleway
    source-code-pro
    source-sans-pro
    source-serif-pro
  ];

  hardware.video.hidpi.enable = lib.mkDefault true;

  nix.extraOptions = ''
      experimental-features = nix-command flakes recursive-nix ca-derivations
      log-lines = 30
      warn-dirty = false
    '';

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_5_19;

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  # Enable swap on luks
  boot.initrd.luks.devices."luks-a697f63f-f54e-4d05-b906-1062408e785c".device = "/dev/disk/by-uuid/a697f63f-f54e-4d05-b906-1062408e785c";
  boot.initrd.luks.devices."luks-a697f63f-f54e-4d05-b906-1062408e785c".keyFile = "/crypto_keyfile.bin";

  networking.hostName = "otherwise"; # Define your hostname.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.utf8";

  # Configure console keymap
  console.keyMap = "us";

  # Define a user account.
  users.users.noon = {
    isNormalUser = true;
    description = "noon";
    extraGroups = [ "networkmanager" "wheel" "dialout" ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
    openssh = {
      authorizedKeys.keys = [];
    };
  };

  services.xserver = {
    enable = true;
    xkbOptions = "caps:escape";
    layout = "us";
    xkbVariant = "";

    displayManager = {
      sessionCommands = ''
        # Set a background.
        /home/noon/.fehbg

        # To kill the screen saver.
        xset s off -dpms

        # Default to the laptop layout.
        /home/noon/.screenlayout/laptop.sh
      '';

      autoLogin = {
        user = "noon";
        enable = true;
      };
    };

    windowManager = {
      xmonad = {
        enable = true;
        enableContribAndExtras = true;
        extraPackages = p: [ p.split ];
        config = /home/noon/dev/dotfiles/.xmonad/xmonad.hs;
      };
    };
  };


  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # net
    dnsutils
    httpie
    inetutils
    jnettop
    ngrep
    nmap
    rsync
    socat
    websocat
    wget
    # files
    bat
    delta
    diskonaut
    dos2unix
    duf
    exa
    fd
    file
    lsd
    ranger
    ripgrep
    sd
    tree
    unzip
    watchexec
    zip
    # shell
    bc
    bpytop
    choose
    fx
    gnupg
    htop
    iotop
    jc
    jq
    lsof
    pass
    zsh
    # dev
    customNvim
    difftastic
    docker
    docker-compose
    gdb
    git
    konsole
    lazygit
    tmate
    universal-ctags
    kdiff3
    vscode-with-extensions
    # os
    feh
    service-wrapper
    arandr
    firefox
    flameshot
    google-chrome
    nix-diff
    nix-du
    nix-index
    nix-output-monitor
    nox
    pciutils
    usbutils
    # build
    autoconf
    automake
    binutils
    gcc
    gmp
    gnumake
    libffi
    libffi.dev
    libtool
    pkg-config
    stack
    zlib
    zlib.dev
    # misc
    alsa-utils
    blender
    dmenu
    inkscape
    obsidian
    pandoc
    xsel
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  environment.variables = {
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
