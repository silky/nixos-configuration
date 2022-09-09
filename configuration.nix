# Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
  let customNvim =

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

    in

    pkgs.neovim.override {
      configure = {
        customRC = "source " + /home/noon/dev/dotfiles/init.vim;
        plug.plugins = with pkgs.vimPlugins; [
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
        ];
      };
    };
  in
{
  imports =
    [ # Include the results of the hardware scan.
      <nixos-hardware/lenovo/thinkpad/x1/9th-gen>
      /etc/nixos/hardware-configuration.nix
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

  environment.interactiveShellInit = ''
    alias v='nvim'

    function rb {
      nixos-rebuild switch -p "$(date '+%Y-%m-%d %H:%M:%S') - $1"
    }
  '';

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
