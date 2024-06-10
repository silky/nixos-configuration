{ name, config, pkgs, unstable, ... }:
let
  unstablePkgs = import unstable { };
in
{

  # See: https://nixos.wiki/wiki/Fwupd
  #
  #   fwupmgr refresh
  #   fwupmgr get-updates
  #   fwupmgr update
  #
  services.fwupd.enable = true;


  programs.atop.enable = true;

  # ---------------------------------------------------------------------------
  #
  # ~ System Packages
  #
  # ---------------------------------------------------------------------------
  environment.systemPackages = with pkgs;
    let
      sys = [
        # gcc # Sometimes useful
        acpi # For power information
        alsa-utils # Music control
        arandr # Graphical xrandr
        autoconf # ???
        automake # ???
        bashmount # Mount disks via TUI
        binutils # ???
        brightnessctl # Useful to change brightness
        cachix # Nix Caching
        curl # No explanation needed
        dmenu # Launcher; used in XMonad setup
        duf # Modern df
        fuse # ???
        git
        git-lfs
        git-crypt
        gmp # ??
        gnumake # ??
        htop # Process viewer
        libnotify # Notifications
        libtool # ???
        lsof # ???
        neovim # Standard one; not customised.
        ntfs3g # ???
        p7zip # Yet another archive format
        pavucontrol # Audio
        procs # Modern ps
        psmisc # ???
        qmk # ???
        tree # Tree view of directory
        unzip
        wget
        xclip # Copy things to clipboard
        xorg.xev # See key codes
        xorg.xkill # Kill windows
        xorg.xmodmap # Key mappings
        xsel # Copy things to clipboard (used in init.vim)
        zip
      ];
      dev = [
        csview # For viewing csv's
        delta # Delta git diff configuration
        difftastic # Modern diffing
        docker-compose
        fd # Nicer find
        fx # Json viewer
        google-cloud-sdk # Inescapable
        hexyl # Hex viewer
        httpie # Simpler curl
        hyperfine # Benchmarking
        jc # Convert many outputs to json for further investigation
        jd-diff-patch # JSON diff
        jo # Create JSON
        jq # JSON explorer
        lychee # Markdown link checker
        nix-tree # Browse nix dependency graphs
        nvd # Nix package version diff
        openssl # Sometimes useful
        ripgrep # File searcher
        unstablePkgs.ijq # Interactive JQ
        unstablePkgs.konsole # Terminal
        yq # jq for yaml
      ];
      app = [
        age # Encryption tools
        asciicam # Terminal webcam
        asciinema # Terminal recorder
        asciinema-agg # Convert asciinema to .gif
        bandwhich # Bandwidth monitor
        baobab # Disk space analyser
        chafa # Terminal image viewer
        feh # Set background images
        ffmpeg_6-full # Video things
        gimp-with-plugins # For making memes
        glow # Terminal Markdown renderer
        gnome.eog # Image viewer
        gnome.nautilus # File browser
        hunspell # Spelling
        hunspellDicts.en-gb-ise # Spelling
        imagemagick # Essential image tools
        inkscape # Meme creation
        lyx # For writing WYSIWYG TeX
        meld # Visual diff tool
        nix-output-monitor # Nicer build info when nixing
        okular # PDF viewing
        optipng # Optimise pngs
        pandoc # Occasionally useful
        pkgs.gedit # When times get desperate
        texlive.combined.scheme-full # Full TeX environment
        unstablePkgs.flameshot # Take screenshots
        unstablePkgs.vokoscreen-ng # Screen recording for videos
        vlc # For videos
        xournalpp # PDF writing
      ];
    in
    sys ++ dev ++ app
  ;

  # ---------------------------------------------------------------------------
  #
  # ~ Nix
  #
  # ---------------------------------------------------------------------------
  nix = {
    # Wild guess.
    # See: <https://github.com/NixOS/nix/issues/1281>
    # settings.auto-optimise-store = false;
    settings.trusted-users = [ "root" "noon" "gala" ];
    extraOptions = ''
      experimental-features = nix-command flakes recursive-nix ca-derivations repl-flake
      log-lines = 300
      warn-dirty = false
    '';
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-25.9.0"
    ];
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Window Manager
  #
  # ---------------------------------------------------------------------------
  services = {
    displayManager = {
      autoLogin = {
        user = "noon";
        enable = true;
      };
    };
  };

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
      options = "caps:escape";
    };
    # https://mynixos.com/nixpkgs/option/services.xserver.xrandrHeads
    displayManager = {
      gdm.enable = true;
      sessionCommands = ''
        # Set a background.
        ~/.fehbg || true

        # No screen saving.
        xset s off -dpms
      '';
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

  # Bluetooth
  hardware = {
    # https://nixos.wiki/wiki/Bluetooth
    bluetooth = {
      enable = true;
      package = pkgs.bluez;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
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
    firewall.allowedTCPPorts = [ ];
    firewall.enable = true;
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Audio
  #
  # ---------------------------------------------------------------------------
  sound.enable = false;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
    alsa = {
      enable = true;
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
    vnstat.enable = true;
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
  time.timeZone = "Europe/London";
  # time.timeZone      = "America/Mexico_City";
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

  users.users.noon = {
    isNormalUser = true;
    description = "noon";
    extraGroups = [ "networkmanager" "wheel" "dialout" "audio" "docker" ];
  };

  users.users.gala = {
    isNormalUser = true;
    description = "gala";
    extraGroups = [ "networkmanager" "wheel" "dialout" "audio" "docker" ];
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
