{ user, name, config, pkgs, lib, nixos-hardware, unstable, ... }:
let
  unstablePkgs = import unstable {};
in
{

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
    # Wild guess.
    # See: <https://github.com/NixOS/nix/issues/1281>
    # settings.auto-optimise-store = false;
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
      "electron-24.8.6"
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
        config = ./xmonad.hs;
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
    udev.packages = [ pkgs.qmk-udev-rules ];
  };

  virtualisation.docker = {
    package = unstablePkgs.docker;
    enable = true;
  };

  fonts = {
    packages = with pkgs; [
      nerdfonts
      noto-fonts-emoji
      raleway
      source-code-pro
      source-sans-pro
      source-serif-pro
      symbola
      twitter-color-emoji
    ];
    enableDefaultPackages = true;
    # Note: Unfortunately, this isn't exactly working.
    fontconfig = {
      defaultFonts = {
        monospace = [ "Fira Code" ];
        emoji = [ "Twemoji" "Noto Color Emoji" "Symbola" ];
      };
    };
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Internationalisation / i18n
  #
  # ---------------------------------------------------------------------------
  # time.timeZone      = "Europe/London";
  time.timeZone      = "America/Mexico_City";
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
