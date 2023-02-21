# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

   let vim-autoread = pkgs.vimUtils.buildVimPlugin {
        name = "vim-autoread";
        src = pkgs.fetchFromGitHub {
          owner = "djoshea";
          repo = "vim-autoread";
          rev = "7e83d47a71fdafc271005fc39c89863204278c77";
          sha256 = "sha256-IGgJ/D2AGDtbO+RZk2zd+zO9ZtANsle4QSjsh+VOXpg=";
        };
      };
      noon-light-theme = pkgs.vimUtils.buildVimPlugin {
        name = "noon-light-theme";
        src = pkgs.fetchFromGitHub {
          owner = "silky";
          repo = "noon-light-vim";
          rev = "5746f68d4a407ddbc3add2f60db758b9b178dcc4";
          sha256 = "sha256-OLDb/yMs6sUDSrt8fFa82pF6p9eeNi02N2PKrto/C6I=";
        };
      };
      vim-syntax-shakespeare = pkgs.vimUtils.buildVimPlugin {
        name = "vim-syntax-shakespeare";
        src = pkgs.fetchFromGitHub {
          owner = "pbrisbin";
          repo = "vim-syntax-shakespeare";
          rev = "2f4f61eae55b8f1319ce3a086baf9b5ab57743f3";
          sha256 = "sha256-sdCXJOvB+vJE0ir+qsT/u1cHNxrksMnqeQi4D/Vg6UA=";
        };
      };
      cabal-project-vim = pkgs.vimUtils.buildVimPlugin {
        name = "cabal-project-vim";
        src = pkgs.fetchFromGitHub {
          owner = "vmchale";
          repo = "cabal-project-vim";
          rev = "0d41e7e41b1948de84847d9731023407bf2aea04";
          sha256 = "sha256-j1igpjk1+j/1/y99ZaI3W5+VYNmQqsFp2qX4qzkpNpc=";
        };
      };

      customKonsole = pkgs.konsole.overrideAttrs (old: {
        patches = [ ./home/konsole.diff ];
      });

    customNvim = pkgs.neovim.override {
      configure = {
        # Note: Hack.
        customRC = "source " + /home/noon/dev/dotfiles/init.vim;
        packages.neovimPlugins = with pkgs.vimPlugins; {
          start = [
          cabal-project-vim
          dhall-vim
          editorconfig-vim
          elm-vim
          fzf-vim
          fzfWrapper
          haskell-vim
          noon-light-theme
          purescript-vim
          supertab
          typescript-vim
          unicode-vim
          vim-autoread
          vim-commentary
          vim-easy-align
          vim-easymotion
          vim-nix
          vim-ormolu
          vim-syntax-shakespeare
          vim-toml
          vim-vue
          xterm-color-table
        ];};
      };
    };
  in

{
  imports =
    [ ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  # hardware.pulseaudio.package = pkgs.pulseaudioFull;
  # hardware.pulseaudio.enable = true;

  hardware.video.hidpi.enable = lib.mkDefault true;

# environment.variables = {
# GDK_SCALE = "2";
# GDK_DPI_SCALE = "0.5";
# };

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_1;

  # Enable swap on luks
  boot.initrd.luks.devices."luks-cfcef1a8-76eb-4434-9e88-277e42b11d87".device = "/dev/disk/by-uuid/cfcef1a8-76eb-4434-9e88-277e42b11d87";
  boot.initrd.luks.devices."luks-cfcef1a8-76eb-4434-9e88-277e42b11d87".keyFile = "/crypto_keyfile.bin";

  networking.hostName = "otherwise"; # Define your hostname.

  nix.extraOptions = ''
    experimental-features = nix-command flakes recursive-nix ca-derivations
    log-lines = 300
    warn-dirty = false
  '';

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.utf8";

  # services.helic.enable = true;
  services.vnstat.enable = true;

  services.xserver = {
    enable = true;
    xkbOptions = "caps:escape";
    layout = "us";
    xkbVariant = "";
    xkbOptions = "caps:escape";
    displayManager = {
      sessionCommands = ''
        # Set a background.
        /home/noon/.fehbg

        # No screen saving.
        xset s off -dpms

        # Default to the office layout; fallback to laptop.
        /home/noon/.screenlayout/work.sh || /home/noon/.screenlayout/laptop-only.sh
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

  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = ["FiraCode"]; })
    raleway
    source-code-pro
    source-sans-pro
    source-serif-pro
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.noon = {
    isNormalUser = true;
    description = "noon";
    extraGroups = [ "networkmanager" "wheel" "dialout" "audio" "docker" ];
  };

  # Enable automatic login for the user.
  services.getty.autologinUser = "noon";

  # Firmware updating ...
  # See: https://nixos.wiki/wiki/Fwupd
  #
  #   fwupmgr refresh
  #   fwupmgr get-updates
  #   fwupmgr update
  #
  services.fwupd.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings.trusted-users = [ "root" "noon" ];


  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login = {
    enableGnomeKeyring = true;
  };

  # Bluetooth. Off for now :(
  #   <https://nixos.wiki/wiki/PipeWire>
  hardware.bluetooth.enable = false;
  # hardware.bluetooth.package = pkgs.bluezFull;
  # hardware.bluetooth.hsphfpd.enable = true;
  services.blueman.enable = false;
  # environment.etc = { "wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
  #     bluez_monitor.properties = {
  #       ["bluez5.enable-sbc-xq"] = true,
  #       ["bluez5.enable-msbc"] = true,
  #       ["bluez5.enable-hw-volume"] = true,
  #       ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
  #     }
  #   '';
  # };

  # rtkit is optional but recommended
  security.rtkit.enable = true;

  sound.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };


  environment.systemPackages = with pkgs; [
    alsa-utils
    arandr
    autoconf
    automake
    bat
    binutils
    cachix
    customKonsole
    customNvim
    dmenu
    docker
    docker-compose
    exa
    feh
    firefox
    flameshot
    fzf
    gcc
    git
    git-lfs
    gmp
    gnome.gedit
    gnome.nautilus
    gnome.seahorse
    gnumake
    gnupg
    google-chrome
    htop
    httpie
    kdiff3
    inkscape
    jc
    jq
    libtool
    nethogs
    nixpkgs-fmt
    okular
    pass
    pavucontrol
    pkg-config
    psmisc
    python310
    python310Packages.keyring
    ripgrep
    stack
    texlive.combined.scheme-full
    tree
    unzip
    vim
    wget
    xclip
    xorg.xkill
    xsel
    zip
    zsh
  ];

  virtualisation.docker.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  services.openssh.enable = false;


  environment.variables = {
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";
  };

  # Open ports in the firewall.
  # TODO: Why does this still allow ports?
  networking.firewall.allowedTCPPorts = [ ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
