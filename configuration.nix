# /etc/nixos/configuration.nix

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ config, pkgs, ... }:
  let customNvim =
    pkgs.neovim.override {
      configure = {
        customRC = "source " + /home/noon/dev/dotfiles/init.vim;
        plug.plugins = with pkgs.vimPlugins; [
          vim-go
        ];
      };
    };

  in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  fonts.fonts = [
    (pkgs.nerdfonts.override { fonts = ["FiraCode" "VictorMono"]; })
    pkgs.raleway
  ];

  nix.extraOptions = ''
      experimental-features = nix-command flakes recursive-nix ca-derivations
      log-lines = 30
      warn-dirty = false
    '';

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "otherwise"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.utf8";

  services.xserver = {
    enable = true;
    layout = "us";
    xkbVariant = "";
    windowManager {
      xmonad = {
        enable = true;
        enableContribAndExtras = true;
        extraPackages = p: [ p.split ];
        config = /home/noon/dev/dotfiles/.xmonad/xmonad.hs;
      };
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.noon = {
    isNormalUser = true;
    description = "noon";
    extraGroups = [ "networkmanager" "wheel" "dialout" ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
    openssh = {
      authorizedKeys.keys = [];
    }
    # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGpcsiEomaNhn2TWqq30hnjLcNCXfbNmoVCGygkiFWXR noon@tweaglt" ];
  };

  # Enable automatic login for the user.
  services.getty.autologinUser = "noon";

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
    vscode-with-extensions
    # os
    cachix
    efibootmgr
    feh
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
    home-manager
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
